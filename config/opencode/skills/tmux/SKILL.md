---
name: tmux
description: Manage long-running terminal jobs in a dedicated tmux-opencode session using wrapper scripts for run/wait, health checks, and crash-recovery cleanup.
references:
  - references/operations.md
---

# Tmux

## Overview

Use tmux to run background jobs while continuing other work. Keep all skill-managed windows in one session, `tmux-opencode`, so inspection and cleanup happen in one place. Default to wrapper scripts over manual command chaining. Do not block by default; opt in to blocking wait only when requested.

## Verify Environment

Confirm tmux availability before using this skill.

```bash
tmux -V
```

If tmux is unavailable, run commands in the foreground.

## Session Model

Standardize on a single session.

```bash
SESSION="tmux-opencode"
tmux new-session -d -s "$SESSION" -n "main" 2>/dev/null || true
tmux list-windows -t "$SESSION"
```

`scripts/tmux_run_job.py` auto-creates this session when missing.

## First-Time Setup

Install managed cron cleanup once per machine/user.

```bash
python3 scripts/tmux_healthcheck_cron.py --action install
```

Verify installation.

```bash
python3 scripts/tmux_healthcheck_cron.py --action status
```

## Run Jobs (Wrapper First)

Run a command in the background (default behavior).

```bash
python3 scripts/tmux_run_job.py --command "npm start"
```

Run in a named window (auto-normalized to `oc-*`).

```bash
python3 scripts/tmux_run_job.py --window server --command "npm start"
```

Block until completion only when requested.

```bash
python3 scripts/tmux_run_job.py --window build --command "npm run build" --wait
```

Wait later for an already-started job by target.

```bash
python3 scripts/tmux_run_job.py --wait-target "tmux-opencode:oc-build"
```

Use wait timeout when blocking behavior needs a guardrail.

```bash
python3 scripts/tmux_run_job.py --window build --command "npm run build" --wait --wait-timeout-seconds 1800
```

Auto-close successful windows when waiting.

```bash
python3 scripts/tmux_run_job.py --window lint --command "npm run lint" --wait --close-window success
```

## Inspect Output and Control Jobs

Capture visible output.

```bash
tmux capture-pane -p -t "tmux-opencode:oc-server"
```

Capture full scrollback.

```bash
tmux capture-pane -p -S - -t "tmux-opencode:oc-server"
```

Interrupt a running command.

```bash
tmux send-keys -t "tmux-opencode:oc-server" C-c
```

Kill one window.

```bash
tmux kill-window -t "tmux-opencode:oc-server"
```

## Cleanup and Healthcheck

Show window health (idle minutes, active state).

```bash
python3 scripts/tmux_healthcheck.py
```

Dry-run stale window cleanup.

```bash
python3 scripts/tmux_healthcheck.py --cleanup --max-idle-minutes 240 --dry-run
```

Run cleanup for stale windows and legacy sessions after interruptions or crashes.

```bash
python3 scripts/tmux_healthcheck.py --cleanup --max-idle-minutes 240 --cleanup-legacy-sessions
```

Install or update automatic periodic cleanup cron (idempotent managed entry).

```bash
python3 scripts/tmux_healthcheck_cron.py --action install
```

Preview cron line without writing.

```bash
python3 scripts/tmux_healthcheck_cron.py --action install --dry-run
```

Check installed cron status.

```bash
python3 scripts/tmux_healthcheck_cron.py --action status
```

Remove the managed cron entry.

```bash
python3 scripts/tmux_healthcheck_cron.py --action remove
```

## Quick Pattern

1. Start jobs with `scripts/tmux_run_job.py` (background by default).
2. Inspect output with `tmux capture-pane` when needed.
3. Add `--wait` for immediate blocking, or `--wait-target` for wait-after-start.
4. Run `scripts/tmux_healthcheck.py --cleanup` periodically or at session end.
5. Prefer `scripts/tmux_healthcheck_cron.py --action install` for automatic recovery cleanup.
