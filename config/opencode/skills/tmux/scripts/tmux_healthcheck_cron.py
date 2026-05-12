#!/usr/bin/env python3
"""Manage cron install for tmux-opencode healthcheck."""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import shlex
import subprocess
import sys

START_MARKER = "# BEGIN TMUX-OPENCODE-HEALTHCHECK"
END_MARKER = "# END TMUX-OPENCODE-HEALTHCHECK"
CRON_PATH = "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"


def run(
    cmd: list[str], input_text: str | None = None
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd, input=input_text, capture_output=True, text=True, check=False
    )


def read_crontab() -> list[str]:
    result = run(["crontab", "-l"])
    if result.returncode == 0:
        return result.stdout.splitlines()
    if "no crontab" in result.stderr.lower():
        return []
    raise RuntimeError(result.stderr.strip() or "failed to read crontab")


def write_crontab(lines: list[str]) -> None:
    content = "\n".join(lines).rstrip("\n")
    if content:
        content += "\n"
    result = run(["crontab", "-"], input_text=content)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "failed to write crontab")


def strip_managed_block(lines: list[str]) -> list[str]:
    cleaned: list[str] = []
    in_block = False
    for line in lines:
        stripped = line.strip()
        if stripped == START_MARKER:
            in_block = True
            continue
        if stripped == END_MARKER:
            in_block = False
            continue
        if not in_block:
            cleaned.append(line)
    return cleaned


def get_managed_block(lines: list[str]) -> list[str]:
    block: list[str] = []
    in_block = False
    for line in lines:
        stripped = line.strip()
        if stripped == START_MARKER:
            in_block = True
            block.append(line)
            continue
        if stripped == END_MARKER and in_block:
            block.append(line)
            break
        if in_block:
            block.append(line)
    return block


def build_cron_command(args: argparse.Namespace) -> str:
    skill_dir = Path(__file__).resolve().parent.parent
    python_exe = shutil.which("python3") or str(Path(sys.executable).resolve())
    script_args = [
        python_exe,
        "scripts/tmux_healthcheck.py",
        "--cleanup",
        "--session",
        args.session,
        "--window-prefix",
        args.window_prefix,
        "--max-idle-minutes",
        str(args.max_idle_minutes),
    ]
    if args.cleanup_legacy_sessions:
        script_args += [
            "--cleanup-legacy-sessions",
            "--legacy-max-age-minutes",
            str(args.legacy_max_age_minutes),
        ]
    command = " ".join(shlex.quote(part) for part in script_args)
    return (
        f"cd {shlex.quote(str(skill_dir))} && "
        f"{command} >> {shlex.quote(args.log_path)} 2>&1"
    )


def install(args: argparse.Namespace) -> int:
    current = read_crontab()
    cleaned = strip_managed_block(current)
    cron_line = f"{args.schedule} {build_cron_command(args)}"
    if args.dry_run:
        print("DRY_RUN install tmux-opencode healthcheck cron entry")
        print(cron_line)
        return 0
    write_crontab(cleaned + [START_MARKER, CRON_PATH, cron_line, END_MARKER])
    print("installed tmux-opencode healthcheck cron entry")
    print(cron_line)
    return 0


def remove() -> int:
    current = read_crontab()
    cleaned = strip_managed_block(current)
    if cleaned == current:
        print("no tmux-opencode cron entry found")
        return 0
    write_crontab(cleaned)
    print("removed tmux-opencode healthcheck cron entry")
    return 0


def status() -> int:
    block = get_managed_block(read_crontab())
    if not block:
        print("tmux-opencode cron status: not installed")
        return 0
    print("tmux-opencode cron status: installed")
    print("\n".join(block))
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Install or manage tmux-opencode cron")
    parser.add_argument(
        "--action",
        choices=["install", "remove", "status"],
        default="install",
        help="action to perform (default: install)",
    )
    parser.add_argument(
        "--schedule",
        default="*/15 * * * *",
        help="cron schedule expression (default: */15 * * * *)",
    )
    parser.add_argument(
        "--log-path",
        default="/tmp/tmux-opencode-healthcheck.log",
        help="cron output log path",
    )
    parser.add_argument("--dry-run", action="store_true", help="print without writing")
    parser.add_argument("--session", default="tmux-opencode", help="session name")
    parser.add_argument("--window-prefix", default="oc-", help="window cleanup prefix")
    parser.add_argument(
        "--max-idle-minutes",
        type=int,
        default=240,
        help="stale window threshold in minutes",
    )
    parser.add_argument(
        "--cleanup-legacy-sessions",
        action="store_true",
        help="also cleanup old opencode-* sessions",
    )
    parser.add_argument(
        "--legacy-max-age-minutes",
        type=int,
        default=240,
        help="legacy session age threshold in minutes",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.action == "install":
            return install(args)
        if args.action == "remove":
            return remove()
        return status()
    except RuntimeError as exc:
        print(f"[tmux_healthcheck_cron] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
