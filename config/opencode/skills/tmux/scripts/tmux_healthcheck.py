#!/usr/bin/env python3
"""Inspect and optionally clean stale windows in tmux-opencode."""

from __future__ import annotations

import argparse
import subprocess
import sys
import time

DEFAULT_SESSION = "tmux-opencode"


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, capture_output=True, text=True, check=False)


def has_session(session: str) -> bool:
    return run(["tmux", "has-session", "-t", session]).returncode == 0


def ensure_session(session: str) -> None:
    if has_session(session):
        return
    created = run(["tmux", "new-session", "-d", "-s", session, "-n", "main"])
    if created.returncode != 0:
        raise RuntimeError(created.stderr.strip() or "failed to create session")


def list_windows(session: str) -> list[tuple[str, int, int]]:
    fmt = "#{window_name}\t#{window_active}\t#{window_activity}"
    listed = run(["tmux", "list-windows", "-t", session, "-F", fmt])
    if listed.returncode != 0:
        raise RuntimeError(listed.stderr.strip() or "failed to list windows")

    windows: list[tuple[str, int, int]] = []
    for line in listed.stdout.splitlines():
        name, active, activity = line.split("\t")
        windows.append((name, int(active), int(activity)))
    return windows


def kill_window(session: str, window: str, dry_run: bool) -> None:
    target = f"{session}:{window}"
    if dry_run:
        print(f"DRY_RUN kill-window {target}")
        return
    killed = run(["tmux", "kill-window", "-t", target])
    if killed.returncode == 0:
        print(f"killed {target}")


def list_sessions() -> list[tuple[str, int, int]]:
    fmt = "#{session_name}\t#{session_created}\t#{session_attached}"
    listed = run(["tmux", "list-sessions", "-F", fmt])
    if listed.returncode != 0:
        return []

    sessions: list[tuple[str, int, int]] = []
    for line in listed.stdout.splitlines():
        name, created, attached = line.split("\t")
        sessions.append((name, int(created), int(attached)))
    return sessions


def kill_session(session: str, dry_run: bool) -> None:
    if dry_run:
        print(f"DRY_RUN kill-session {session}")
        return
    killed = run(["tmux", "kill-session", "-t", session])
    if killed.returncode == 0:
        print(f"killed {session}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Healthcheck and cleanup for tmux-opencode"
    )
    parser.add_argument(
        "--session",
        default=DEFAULT_SESSION,
        help=f"session to inspect (default: {DEFAULT_SESSION})",
    )
    parser.add_argument(
        "--ensure-session",
        action="store_true",
        help="create session when missing",
    )
    parser.add_argument(
        "--window-prefix",
        default="oc-",
        help="cleanup only windows with this prefix (default: oc-)",
    )
    parser.add_argument(
        "--max-idle-minutes",
        type=int,
        default=240,
        help="cleanup threshold for idle windows (default: 240)",
    )
    parser.add_argument(
        "--cleanup",
        action="store_true",
        help="kill stale windows in the inspected session",
    )
    parser.add_argument("--dry-run", action="store_true", help="print actions only")
    parser.add_argument(
        "--cleanup-legacy-sessions",
        action="store_true",
        help="also cleanup old opencode-* sessions",
    )
    parser.add_argument(
        "--legacy-prefix",
        default="opencode-",
        help="legacy session prefix (default: opencode-)",
    )
    parser.add_argument(
        "--legacy-max-age-minutes",
        type=int,
        default=240,
        help="legacy cleanup session age in minutes (default: 240)",
    )
    parser.add_argument(
        "--include-attached-legacy",
        action="store_true",
        help="also kill attached legacy sessions",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        if args.ensure_session:
            ensure_session(args.session)

        if not has_session(args.session):
            print(f"missing session: {args.session}")
        else:
            now = int(time.time())
            threshold = args.max_idle_minutes * 60
            windows = list_windows(args.session)

            for name, active, activity in windows:
                idle_seconds = max(0, now - activity)
                idle_minutes = idle_seconds // 60
                print(
                    f"window={name} active={active} idle_minutes={idle_minutes}",
                )

                stale = (
                    args.cleanup
                    and name != "main"
                    and name.startswith(args.window_prefix)
                    and active == 0
                    and idle_seconds >= threshold
                )
                if stale:
                    kill_window(args.session, name, args.dry_run)

        if args.cleanup_legacy_sessions:
            now = int(time.time())
            legacy_threshold = args.legacy_max_age_minutes * 60
            for session, created, attached in list_sessions():
                if not session.startswith(args.legacy_prefix):
                    continue
                if attached and not args.include_attached_legacy:
                    continue
                if now - created < legacy_threshold:
                    continue
                kill_session(session, args.dry_run)
    except RuntimeError as exc:
        print(f"[tmux_healthcheck] {exc}", file=sys.stderr)
        return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
