---
name: tmux
description: Manage tmux windows to run background processes, capture logs, and control long-running tasks without blocking the main shell.
---

# Tmux

## Overview

Use tmux to spawn background processes, inspect output, and control long-running tasks in dedicated windows. Prefer this skill when starting dev servers, watchers, or builds that must keep running while continuing other work.

## Verify Environment

Confirm tmux is available before issuing commands.

```bash
echo $TMUX
```

If empty, avoid tmux commands and run processes in the foreground instead.

List current windows for visibility before creating new ones.

```bash
tmux list-windows
```

## Spawn a Background Process

Create a detached window with a descriptive name.

```bash
tmux new-window -n "server-log" -d
```

Send the command to that window and execute it.

```bash
tmux send-keys -t "server-log" "npm start" C-m
```

Replace the window name and command with task-specific values.

## Inspect Output

Capture the visible screen output for quick checks.

```bash
tmux capture-pane -p -t "server-log"
```

Capture full scrollback history when output may have scrolled off.

```bash
tmux capture-pane -p -S - -t "server-log"
```

## Control the Process

Send an interrupt (Ctrl+C) to stop the running process.

```bash
tmux send-keys -t "server-log" C-c
```

Kill the entire window when cleanup is needed.

```bash
tmux kill-window -t "server-log"
```

## Chain Commands

Chain tmux commands in a single invocation when efficiency matters.

```bash
tmux new-window -n "server-log" -d ';' send-keys -t "server-log" "npm start" C-m
```

## Quick Pattern

Use this three-step flow for most tasks.

1. `tmux new-window -n "ID" -d`
2. `tmux send-keys -t "ID" "CMD" C-m`
3. `tmux capture-pane -p -t "ID"`
