#!/usr/bin/env python3
"""Assign one configured reviewer to a GitHub PR and persist local rotation."""

from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse


def run(command: list[str]) -> str:
    result = subprocess.run(command, check=True, text=True, capture_output=True)
    return result.stdout.strip()


def get_repo() -> tuple[str, str]:
    raw = run(["gh", "repo", "view", "--json", "nameWithOwner,url"])
    data = json.loads(raw)
    repo = data.get("nameWithOwner", "")
    host = (urlparse(data.get("url", "")).hostname or "").casefold()
    if repo.count("/") != 1 or any(char.isspace() or char == "\\" for char in repo):
        raise RuntimeError(f"Could not resolve repository owner/name: {repo!r}")
    if not host:
        raise RuntimeError(f"Could not resolve GitHub host from repository URL: {data.get('url')!r}")
    return host, repo


def default_config_path() -> Path:
    root = Path(run(["git", "rev-parse", "--show-toplevel"]))
    return root / ".claude" / "pr-stack-reviewers.json"


def get_pr_data(pr_url: str) -> tuple[str, set[str], bool, set[str]]:
    raw = run([
        "gh", "pr", "view", pr_url, "--json", "author,reviewRequests,isDraft,latestReviews",
        "--jq", "{author: .author.login, reviewRequests: [.reviewRequests[].login], isDraft: .isDraft, reviewedBy: [.latestReviews[].author.login]}",
    ])
    data = json.loads(raw)
    author = data.get("author") or ""
    requested = {str(login).casefold() for login in data.get("reviewRequests", [])}
    reviewed_by = {str(login).casefold() for login in data.get("reviewedBy", [])}
    return author.casefold(), requested, bool(data.get("isDraft")), reviewed_by


def assignment_key(pr_url: str) -> str:
    parsed = urlparse(pr_url)
    match = re.fullmatch(r"/([^/]+)/([^/]+)/pull/([0-9]+)/?", parsed.path)
    if parsed.scheme != "https" or not parsed.hostname or not match:
        raise RuntimeError(f"Expected a GitHub pull request URL, got {pr_url!r}")
    return f"{parsed.hostname.casefold()}/{match.group(1).casefold()}/{match.group(2).casefold()}/pull/{match.group(3)}"


def write_state(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(data, stream, indent=2, sort_keys=True)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(tmp_name, path)
    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)


def default_state_path(host: str, repo: str, group: str) -> Path:
    root = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    safe_repo = repo.replace("/", "__")
    # Preserve the github.com cursor path; isolate enterprise hosts.
    safe_host = re.sub(r"[^A-Za-z0-9_.-]", "_", host)
    host_dir = "" if host == "github.com" else f"host__{safe_host}"
    safe_group = re.sub(r"[^A-Za-z0-9_.-]", "_", group)
    return root / "claude-pr-stack-review" / host_dir / safe_repo / f"{safe_group}.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pr_url", help="GitHub pull request URL")
    parser.add_argument("--group", required=True, help="Reviewer group key in the config")
    parser.add_argument(
        "--config",
        default=None,
        help="JSON reviewer-group configuration",
    )
    parser.add_argument("--state-file", help=argparse.SUPPRESS)
    args = parser.parse_args()

    try:
        config_path = Path(args.config) if args.config else default_config_path()
        config = json.loads(config_path.read_text(encoding="utf-8"))
        reviewers = config.get("groups", {}).get(args.group)
        if not isinstance(reviewers, list) or not reviewers:
            raise RuntimeError(f"Reviewer group {args.group!r} is missing or empty in {config_path}")
        if any(not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?", name) for name in reviewers):
            raise RuntimeError("Reviewer usernames must be valid GitHub logins")
        if len({name.casefold() for name in reviewers}) != len(reviewers):
            raise RuntimeError("Reviewer group contains duplicate usernames")

        host, repo = get_repo()
        state_path = Path(args.state_file) if args.state_file else default_state_path(host, repo, args.group)
        state_path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        lock_path = state_path.with_suffix(state_path.suffix + ".lock")
        lock_path.touch(mode=0o600, exist_ok=True)

        with lock_path.open("r+") as lock:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
            if state_path.exists():
                state = json.loads(state_path.read_text(encoding="utf-8"))
            else:
                state = {}
            cursor = int(state.get("cursor", 0)) % len(reviewers)
            assignments = state.setdefault("assignments", {})
            pr_key = assignment_key(args.pr_url)
            if not pr_key.startswith(f"{host}/{repo.casefold()}/pull/"):
                raise RuntimeError(f"PR URL does not match the current repository {repo} on {host}")

            author, requested, is_draft, reviewed_by = get_pr_data(args.pr_url)
            if is_draft:
                raise RuntimeError(
                    "This PR is a draft. Obtain explicit user authorization, mark it ready with "
                    "`gh pr ready <PR-URL>`, then retry reviewer assignment."
                )

            record = assignments.get(pr_key)
            if record is not None and record.get("status") == "confirmed":
                login = record.get("reviewer", "").casefold()
                if requested - {login} or (login not in requested and login not in reviewed_by):
                    raise RuntimeError(
                        "The confirmed reviewer assignment no longer matches GitHub; reconcile it manually before retrying"
                    )
                print(f"Reviewer assignment for {args.pr_url} is already recorded as @{record.get('reviewer')}; rotation unchanged.")
                return 0
            if record is None:
                pending = [key for key, item in assignments.items() if item.get("status") == "pending"]
                if pending:
                    raise RuntimeError(
                        f"Another reviewer assignment is pending for {pending[0]}; retry it before assigning a different PR"
                    )

                configured_requests = [
                    index for index, login in enumerate(reviewers)
                    if login.casefold() in requested and login.casefold() != author
                ]
                if requested:
                    if len(configured_requests) == 1 and len(requested) == 1:
                        selected_index = configured_requests[0]
                    else:
                        raise RuntimeError(
                            "This PR already has reviewer requests that cannot be reconciled to exactly one configured reviewer"
                        )
                else:
                    selected_index = None
                    for offset in range(len(reviewers)):
                        index = (cursor + offset) % len(reviewers)
                        if reviewers[index].casefold() != author:
                            selected_index = index
                            break
                    if selected_index is None:
                        raise RuntimeError("No eligible configured reviewer remains for this PR")

                login = reviewers[selected_index]
                record = {
                    "reviewer": login,
                    "reviewer_index": selected_index,
                    "cursor_after": (selected_index + 1) % len(reviewers),
                    "status": "pending",
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                }
                assignments[pr_key] = record
                state.update({"host": host, "repo": repo, "group": args.group})
                # Save intent first so a retry can safely reuse this reviewer.
                write_state(state_path, state)
            else:
                login = record.get("reviewer", "")
                if login not in reviewers:
                    raise RuntimeError(
                        f"Stored reviewer @{login} is no longer in the configured group; reconcile the roster before retrying"
                    )
                selected_index = reviewers.index(login)
                if login.casefold() == author:
                    raise RuntimeError("Stored reviewer is now the PR author; reconcile this assignment manually")

            unexpected_requests = requested - {login.casefold()}
            if unexpected_requests:
                raise RuntimeError(
                    "This PR has a different reviewer request than the stored assignment; reconcile it manually before retrying"
                )
            if login.casefold() not in requested and login.casefold() not in reviewed_by:
                try:
                    run(["gh", "pr", "edit", args.pr_url, "--add-reviewer", login])
                except subprocess.CalledProcessError as error:
                    try:
                        _, requested_after_error, _, reviewed_after_error = get_pr_data(args.pr_url)
                    except (subprocess.CalledProcessError, ValueError, json.JSONDecodeError):
                        raise RuntimeError(
                            f"Could not determine whether GitHub accepted the request for @{login}; "
                            "the pending assignment was saved, so retry this same PR."
                        ) from error
                    if login.casefold() not in requested_after_error and login.casefold() not in reviewed_after_error:
                        detail = error.stderr.strip() if error.stderr else str(error)
                        raise RuntimeError(f"GitHub did not confirm reviewer request for @{login}: {detail}") from error

            _, requested_after, still_draft, reviewed_after = get_pr_data(args.pr_url)
            if still_draft:
                raise RuntimeError("The PR became a draft before reviewer assignment was confirmed")
            if login.casefold() not in requested_after and login.casefold() not in reviewed_after:
                raise RuntimeError(
                    f"GitHub did not show @{login} in this PR's review requests; the pending assignment was saved for retry"
                )

            next_cursor = int(record["cursor_after"])
            record.update({"status": "confirmed", "updated_at": datetime.now(timezone.utc).isoformat()})
            state.update({
                "host": host,
                "repo": repo,
                "group": args.group,
                "cursor": next_cursor,
                "last_assigned": login,
                "last_pr": args.pr_url,
            })
            write_state(state_path, state)
            print(
                f"Assigned @{login} to {args.pr_url}; next rotation position is "
                f"{next_cursor + 1}/{len(reviewers)}."
            )
        return 0
    except (OSError, ValueError, json.JSONDecodeError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
