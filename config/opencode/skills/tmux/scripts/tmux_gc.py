#!/usr/bin/env python3
"""Garbage-collect legacy stale tmux sessions (opencode-*)."""

from __future__ import annotations

import argparse
import subprocess
import time


def tmux_list_sessions() -> list[tuple[str, int, int]]:
    fmt = "#{session_name}\t#{session_created}\t#{session_attached}"
    result = subprocess.run(
        ["tmux", "list-sessions", "-F", fmt],
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode != 0:
        return []

    sessions = []
    for line in result.stdout.splitlines():
        name, created, attached = line.split("\t")
        sessions.append((name, int(created), int(attached)))
    return sessions


def kill_session(name: str, dry_run: bool) -> None:
    if dry_run:
        print(f"DRY_RUN kill-session {name}")
        return
    result = subprocess.run(["tmux", "kill-session", "-t", name], check=False)
    if result.returncode == 0:
        print(f"killed {name}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Kill stale legacy tmux sessions by prefix"
    )
    parser.add_argument("--prefix", default="opencode-", help="Session name prefix")
    parser.add_argument(
        "--max-age-minutes",
        type=int,
        default=240,
        help="Kill sessions older than this age (default: 240)",
    )
    parser.add_argument(
        "--include-attached",
        action="store_true",
        help="Also kill attached sessions",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print only")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    now = int(time.time())
    threshold = args.max_age_minutes * 60

    for name, created, attached in tmux_list_sessions():
        if not name.startswith(args.prefix):
            continue
        if attached and not args.include_attached:
            continue
        if now - created < threshold:
            continue
        kill_session(name, args.dry_run)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
