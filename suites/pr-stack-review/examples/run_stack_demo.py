#!/usr/bin/env python3
"""Print deterministic PR-stack gate demos without contacting GitHub."""

from __future__ import annotations

import argparse


def create_pr(number: int, title: str) -> None:
    print(f"CREATE #{number} {title}")


def report_gate(number: int, checks: list[tuple[str, str]], review: str) -> bool:
    for name, state in checks:
        print(f"  CI {name}={state}")
    print(f"  Reviewer={review}")

    passed = bool(checks) and all(state == "pass" for _, state in checks)
    approved = review == "APPROVED"
    if passed and approved:
        print("  GATE=PASS")
        return True

    reasons = []
    if not checks:
        reasons.append("no checks reported")
    if any(state != "pass" for _, state in checks):
        reasons.append("one or more checks did not pass")
    if not approved:
        reasons.append("review is not approved")
    print(f"  GATE=BLOCKED ({'; '.join(reasons)})")
    return False


def run_pass() -> None:
    print("Scenario: pass (fictional data; no GitHub calls)")
    create_pr(41, "audit schema")
    if not report_gate(41, [("unit-tests", "pass"), ("lint", "pass")], "APPROVED"):
        print("Unexpected block at #41")
        return

    create_pr(42, "audit API")
    if not report_gate(
        42,
        [("unit-tests", "pass"), ("integration-tests", "pass"), ("lint", "pass")],
        "APPROVED",
    ):
        print("Unexpected block at #42")
        return

    create_pr(43, "audit CLI")
    if report_gate(43, [("unit-tests", "pass"), ("lint", "pass")], "APPROVED"):
        print("STACK=COMPLETE")


def run_blocked() -> None:
    print("Scenario: blocked (fictional data; no GitHub calls)")
    create_pr(41, "audit schema")
    if not report_gate(41, [("unit-tests", "pass"), ("lint", "pass")], "APPROVED"):
        print("Unexpected block at #41")
        return

    create_pr(42, "audit API")
    if not report_gate(
        42,
        [("unit-tests", "pass"), ("integration-tests", "fail"), ("lint", "pass")],
        "PENDING",
    ):
        print("STOP: repair #42 in place; #43 is not created")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Demonstrate PR-stack pass and stop behavior using local fixtures only."
    )
    parser.add_argument("scenario", choices=("pass", "blocked"))
    args = parser.parse_args()

    if args.scenario == "pass":
        run_pass()
    else:
        run_blocked()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
