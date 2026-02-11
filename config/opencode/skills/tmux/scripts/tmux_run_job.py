#!/usr/bin/env python3
"""Start tmux-opencode jobs in background; wait is optional."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shlex
import subprocess
import sys
import time

DEFAULT_SESSION = "tmux-opencode"
DEFAULT_WINDOW_PREFIX = "oc-job"
EVENT_PREFIX = "oc-done"
CRON_MARKER = "# BEGIN TMUX-OPENCODE-HEALTHCHECK"
HINT_TTL_SECONDS = 86400


def run(
    cmd: list[str], timeout: float | None = None
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        check=False,
        timeout=timeout,
    )


def maybe_print_cron_hint() -> None:
    if os.environ.get("TMUX_OPENCODE_SUPPRESS_CRON_HINT"):
        return

    stamp = Path("/tmp/tmux-opencode-cron-hint.stamp")
    now = time.time()
    try:
        if stamp.exists() and (now - stamp.stat().st_mtime) < HINT_TTL_SECONDS:
            return
    except OSError:
        pass

    cron = run(["crontab", "-l"])
    if cron.returncode == 0 and CRON_MARKER in cron.stdout:
        try:
            stamp.touch(exist_ok=True)
        except OSError:
            pass
        return

    print(
        "[tmux_run_job] tip: install automatic cleanup once with "
        "`python3 scripts/tmux_healthcheck_cron.py --action install`",
        file=sys.stderr,
    )
    try:
        stamp.touch(exist_ok=True)
    except OSError:
        pass


def normalize(text: str) -> str:
    out = "".join(ch if ch.isalnum() else "-" for ch in text).strip("-")
    return out or "x"


def event_name(session: str, window: str) -> str:
    return f"{EVENT_PREFIX}-{normalize(session)}-{normalize(window)}"


def ensure_session(session: str) -> None:
    if run(["tmux", "has-session", "-t", session]).returncode == 0:
        return
    created = run(["tmux", "new-session", "-d", "-s", session, "-n", "main"])
    if created.returncode != 0:
        raise RuntimeError(created.stderr.strip() or "failed to create session")


def choose_window_name(session: str, requested: str | None) -> str:
    listed = run(["tmux", "list-windows", "-t", session, "-F", "#{window_name}"])
    if listed.returncode != 0:
        raise RuntimeError(listed.stderr.strip() or "failed to list windows")
    names = set(listed.stdout.splitlines())

    if requested:
        base = requested if requested.startswith("oc-") else f"oc-{requested}"
    else:
        base = f"{DEFAULT_WINDOW_PREFIX}-{int(time.time())}"

    candidate = base
    idx = 1
    while candidate in names:
        candidate = f"{base}-{idx}"
        idx += 1
    return candidate


def drain_stale_signal(event: str) -> None:
    for _ in range(3):
        try:
            drained = run(["tmux", "wait-for", event], timeout=0.05)
        except subprocess.TimeoutExpired:
            return
        if drained.returncode != 0:
            return


def send_wrapped_command(target: str, event: str, command: str) -> None:
    target_q = shlex.quote(target)
    event_q = shlex.quote(event)
    wrapped = (
        f"( {command} ); status=$?; "
        f'tmux set-option -w -t {target_q} @oc_exit "$status" >/dev/null 2>&1; '
        "printf '__OPENCODE_EXIT__ %s\\n' \"$status\"; "
        f"tmux wait-for -S {event_q}; exit $status"
    )
    payload = "bash -lc " + shlex.quote(wrapped)
    sent = run(["tmux", "send-keys", "-t", target, payload, "C-m"])
    if sent.returncode != 0:
        raise RuntimeError(sent.stderr.strip() or "failed to start job")


def wait_for_event(event: str, timeout_seconds: int) -> None:
    timeout = timeout_seconds if timeout_seconds > 0 else None
    try:
        waited = run(["tmux", "wait-for", event], timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"wait timed out after {timeout_seconds}s: {event}") from exc
    if waited.returncode != 0:
        raise RuntimeError(waited.stderr.strip() or "wait-for failed")


def read_exit_code(target: str) -> int | None:
    opt = run(["tmux", "show-options", "-w", "-v", "-t", target, "@oc_exit"])
    if opt.returncode != 0:
        return None
    value = opt.stdout.strip()
    if not value or value == "-":
        return None
    try:
        return int(value)
    except ValueError:
        return None


def maybe_close(target: str, mode: str, exit_code: int) -> None:
    should_close = mode == "always" or (mode == "success" and exit_code == 0)
    if should_close:
        run(["tmux", "kill-window", "-t", target])


def start_job(args: argparse.Namespace) -> int:
    if not args.command:
        raise RuntimeError("--command is required unless --wait-target is used")
    if args.close_window != "never" and not args.wait:
        raise RuntimeError("--close-window requires --wait or --wait-target")

    maybe_print_cron_hint()

    ensure_session(args.session)
    window = choose_window_name(args.session, args.window)
    created = run(["tmux", "new-window", "-t", args.session, "-n", window, "-d"])
    if created.returncode != 0:
        raise RuntimeError(created.stderr.strip() or "failed to create window")

    target = f"{args.session}:{window}"
    event = event_name(args.session, window)
    run(["tmux", "set-option", "-w", "-t", target, "@oc_event", event])
    run(["tmux", "set-option", "-w", "-t", target, "@oc_exit", "-"])
    drain_stale_signal(event)
    send_wrapped_command(target, event, args.command)

    if not args.wait:
        print(f"target={target}")
        print(f"event={event}")
        return 0

    code = read_exit_code(target)
    if code is None:
        wait_for_event(event, args.wait_timeout_seconds)
        code = read_exit_code(target)
    if code is None:
        code = 2
    maybe_close(target, args.close_window, code)
    return code


def wait_existing_job(args: argparse.Namespace) -> int:
    if ":" not in args.wait_target:
        raise RuntimeError("target must be session:window")
    session, window = args.wait_target.split(":", 1)
    if not session or not window:
        raise RuntimeError("target must be session:window")
    target = f"{session}:{window}"
    event = event_name(session, window)
    code = read_exit_code(target)
    if code is None:
        wait_for_event(event, args.wait_timeout_seconds)
        code = read_exit_code(target)
    if code is None:
        code = 2
    maybe_close(target, args.close_window, code)
    return code


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Start tmux job in background or wait later by target"
    )
    parser.add_argument("--session", default=DEFAULT_SESSION, help="session name")
    parser.add_argument("--window", help="window name (auto-prefixed with oc-)")
    parser.add_argument("--command", help="command to start in a new window")
    parser.add_argument("--wait", action="store_true", help="wait immediately")
    parser.add_argument("--wait-target", help="wait for an existing session:window")
    parser.add_argument(
        "--wait-timeout-seconds", type=int, default=0, help="wait timeout; 0=no timeout"
    )
    parser.add_argument(
        "--close-window",
        choices=["never", "success", "always"],
        default="never",
        help="close target window after waiting",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if bool(args.command) == bool(args.wait_target):
            raise RuntimeError("provide exactly one of --command or --wait-target")
        if args.wait_target and args.wait:
            raise RuntimeError("--wait-target already implies waiting")
        return wait_existing_job(args) if args.wait_target else start_job(args)
    except RuntimeError as exc:
        print(f"[tmux_run_job] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
