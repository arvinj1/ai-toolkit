from __future__ import annotations

import importlib.util
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

SCRIPT = Path(__file__).parents[1] / "skills" / "pr-stack-review" / "scripts" / "assign_next_reviewer.py"
SPEC = importlib.util.spec_from_file_location("assign_next_reviewer", SCRIPT)
assigner = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = assigner
SPEC.loader.exec_module(assigner)


class ReviewerAssignmentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.config = self.root / "reviewers.json"
        self.config.write_text(json.dumps({"groups": {"team": ["reviewer-a", "reviewer-b"]}}))
        self.env = patch.dict(os.environ, {"XDG_STATE_HOME": str(self.root / "state")})
        self.env.start()
        self.addCleanup(self.env.stop)
        self.requests = {}
        self.drafts = {}
        self.reviews = {}
        self.edits = []

    def tearDown(self):
        self.tmp.cleanup()

    def fake_run(self, command, **kwargs):
        if command[:3] == ["gh", "repo", "view"]:
            output = {"nameWithOwner": "octo/service", "url": "https://github.example.com/octo/service"}
        elif command[:3] == ["gh", "pr", "view"]:
            pr_url = command[3]
            output = {
                "author": "author",
                "reviewRequests": list(self.requests.get(pr_url, [])),
                "isDraft": self.drafts.get(pr_url, False),
                "reviewedBy": self.reviews.get(pr_url, []),
            }
        elif command[:3] == ["gh", "pr", "edit"]:
            pr_url, login = command[3], command[-1]
            self.edits.append((pr_url, login))
            self.requests.setdefault(pr_url, []).append(login)
            output = ""
        else:
            self.fail(f"Unexpected command: {command}")
        return SimpleNamespace(stdout=json.dumps(output) if not isinstance(output, str) else output, stderr="")

    def invoke(self, pr_url):
        with patch.object(sys, "argv", ["assign_next_reviewer.py", pr_url, "--group", "team", "--config", str(self.config)]):
            return assigner.main()

    def state_path(self):
        return (
            self.root / "state" / "claude-pr-stack-review" / "host__github.example.com"
            / "octo__service" / "team.json"
        )

    def test_service_repo_passes_validation(self):
        with patch.object(assigner, "run", return_value=json.dumps({
            "nameWithOwner": "octo/service",
            "url": "https://github.example.com/octo/service",
        })):
            self.assertEqual(assigner.get_repo(), ("github.example.com", "octo/service"))
        with patch.object(assigner, "run", return_value=json.dumps({
            "nameWithOwner": "octo/my repo",
            "url": "https://github.example.com/octo/my-repo",
        })):
            with self.assertRaises(RuntimeError):
                assigner.get_repo()

    def test_assignment_key_normalizes_host_repo_and_pr(self):
        self.assertEqual(
            assigner.assignment_key("https://GitHub.example.com/Octo/Service/pull/17"),
            "github.example.com/octo/service/pull/17",
        )

    def test_retry_reuses_reviewer_after_state_write_failure(self):
        pr = "https://github.example.com/octo/service/pull/17"
        real_write = assigner.write_state
        writes = 0

        def fail_confirmation_write(path, state):
            nonlocal writes
            writes += 1
            if writes == 2:
                raise OSError("simulated confirmation write failure")
            real_write(path, state)

        with patch.object(assigner.subprocess, "run", side_effect=self.fake_run):
            with patch.object(assigner, "write_state", side_effect=fail_confirmation_write):
                self.assertEqual(self.invoke(pr), 1)
            self.assertEqual(self.edits, [(pr, "reviewer-a")])
            self.assertEqual(self.invoke(pr), 0)
            self.assertEqual(self.invoke(pr), 0)

        self.assertEqual(self.edits, [(pr, "reviewer-a")])
        state = json.loads(self.state_path().read_text())
        self.assertEqual(state["cursor"], 1)
        record = state["assignments"][assigner.assignment_key(pr)]
        self.assertEqual(record["reviewer"], "reviewer-a")
        self.assertEqual(record["status"], "confirmed")

    def test_historical_review_does_not_replace_first_review_request(self):
        pr = "https://github.example.com/octo/service/pull/19"
        self.reviews[pr] = [{"login": "reviewer-a", "submittedAt": "2020-01-01T00:00:00Z"}]
        with patch.object(assigner.subprocess, "run", side_effect=self.fake_run):
            self.assertEqual(self.invoke(pr), 0)
        self.assertEqual(self.edits, [(pr, "reviewer-a")])

    def test_pending_retry_accepts_review_submitted_after_saved_attempt(self):
        pr = "https://github.example.com/octo/service/pull/20"
        pr_key = assigner.assignment_key(pr)
        self.state_path().parent.mkdir(parents=True)
        self.state_path().write_text(json.dumps({
            "cursor": 0,
            "assignments": {
                pr_key: {
                    "reviewer": "reviewer-a",
                    "reviewer_index": 0,
                    "cursor_after": 1,
                    "requested_at": "2020-01-01T00:00:00+00:00",
                    "status": "pending",
                }
            },
        }))
        self.reviews[pr] = [{"login": "reviewer-a", "submittedAt": "2020-01-02T00:00:00Z"}]
        with patch.object(assigner.subprocess, "run", side_effect=self.fake_run):
            self.assertEqual(self.invoke(pr), 0)
        self.assertEqual(self.edits, [])
        state = json.loads(self.state_path().read_text())
        self.assertEqual(state["assignments"][pr_key]["status"], "confirmed")

    def test_old_review_does_not_confirm_failed_request_attempt(self):
        pr = "https://github.example.com/octo/service/pull/21"
        self.reviews[pr] = [{"login": "reviewer-a", "submittedAt": "2020-01-01T00:00:00Z"}]

        def fail_reviewer_request(command, **kwargs):
            if command[:3] == ["gh", "pr", "edit"]:
                self.edits.append((command[3], command[-1]))
                raise assigner.subprocess.CalledProcessError(1, command, stderr="request failed")
            return self.fake_run(command, **kwargs)

        with patch.object(assigner.subprocess, "run", side_effect=fail_reviewer_request):
            self.assertEqual(self.invoke(pr), 1)
        self.assertEqual(self.edits, [(pr, "reviewer-a")])
        self.assertEqual(self.requests.get(pr, []), [])

    def test_confirmed_assignment_rejects_review_older_than_attempt(self):
        pr = "https://github.example.com/octo/service/pull/22"
        pr_key = assigner.assignment_key(pr)
        self.state_path().parent.mkdir(parents=True)
        self.state_path().write_text(json.dumps({
            "cursor": 1,
            "assignments": {
                pr_key: {
                    "reviewer": "reviewer-a",
                    "requested_at": "2021-01-01T00:00:00+00:00",
                    "status": "confirmed",
                }
            },
        }))
        self.reviews[pr] = [{"login": "reviewer-a", "submittedAt": "2020-01-01T00:00:00Z"}]
        with patch.object(assigner.subprocess, "run", side_effect=self.fake_run):
            self.assertEqual(self.invoke(pr), 1)
        self.assertEqual(self.edits, [])

    def test_draft_pr_stops_without_reviewer_request(self):
        pr = "https://github.example.com/octo/service/pull/18"
        self.drafts[pr] = True
        with patch.object(assigner.subprocess, "run", side_effect=self.fake_run):
            self.assertEqual(self.invoke(pr), 1)
        self.assertEqual(self.edits, [])


if __name__ == "__main__":
    unittest.main()
