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


def run(command: list[str]) -> str:
    result = subprocess.run(command, check=True, text=True, capture_output=True)
    return result.stdout.strip()


def get_repo() -> str:
    repo = run(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"])
    if not re.fullmatch(r"[^/\s]+/[^/\s]+", repo):
        raise RuntimeError(f"Could not resolve repository owner/name: {repo!r}")
    return repo


def default_config_path() -> Path:
    root = Path(run(["git", "rev-parse", "--show-toplevel"]))
    return root / ".claude" / "pr-stack-reviewers.json"


def get_pr_data(pr_url: str) -> tuple[str, set[str]]:
    raw = run([
        "gh", "pr", "view", pr_url, "--json", "author,reviewRequests",
        "--jq", "{author: .author.login, reviewRequests: [.reviewRequests[].login]}",
    ])
    data = json.loads(raw)
    author = data.get("author") or ""
    requested = {str(login).casefold() for login in data.get("reviewRequests", [])}
    return author.casefold(), requested


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


def default_state_path(repo: str, group: str) -> Path:
    root = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    safe_repo = repo.replace("/", "__")
    safe_group = re.sub(r"[^A-Za-z0-9_.-]", "_", group)
    return root / "claude-pr-stack-review" / safe_repo / f"{safe_group}.json"


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

        repo = get_repo()
        state_path = Path(args.state_file) if args.state_file else default_state_path(repo, args.group)
        state_path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        lock_path = state_path.with_suffix(state_path.suffix + ".lock")
        lock_path.touch(mode=0o600, exist_ok=True)

        with lock_path.open("r+") as lock:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
            if state_path.exists():
                state = json.loads(state_path.read_text(encoding="utf-8"))
                cursor = int(state.get("cursor", 0)) % len(reviewers)
            else:
                cursor = 0

            author, requested = get_pr_data(args.pr_url)
            selected_index = None
            for offset in range(len(reviewers)):
                index = (cursor + offset) % len(reviewers)
                login = reviewers[index]
                if login.casefold() != author and login.casefold() not in requested:
                    selected_index = index
                    break
            if selected_index is None:
                raise RuntimeError("No eligible configured reviewer remains for this PR")

            login = reviewers[selected_index]
            try:
                run(["gh", "pr", "edit", args.pr_url, "--add-reviewer", login])
            except subprocess.CalledProcessError as error:
                # A network error can happen after GitHub accepted the request.
                _, requested_after_error = get_pr_data(args.pr_url)
                if login.casefold() not in requested_after_error:
                    detail = error.stderr.strip() if error.stderr else str(error)
                    raise RuntimeError(f"GitHub did not confirm reviewer request for @{login}: {detail}") from error

            _, requested_after = get_pr_data(args.pr_url)
            if login.casefold() not in requested_after:
                raise RuntimeError(f"GitHub did not show @{login} in this PR's review requests; rotation was not advanced")

            next_cursor = (selected_index + 1) % len(reviewers)
            write_state(state_path, {
                "repo": repo,
                "group": args.group,
                "cursor": next_cursor,
                "last_assigned": login,
                "last_pr": args.pr_url,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            })
            print(f"Assigned @{login} to {args.pr_url}; next rotation position is {next_cursor + 1}/{len(reviewers)}.")
        return 0
    except (OSError, ValueError, json.JSONDecodeError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
