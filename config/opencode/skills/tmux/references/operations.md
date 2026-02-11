# tmux Operations Reference

## Helper Selection

| Helper | Use when | Example |
| --- | --- | --- |
| `scripts/tmux_run_job.py` | Default flow; start background job; optional immediate `--wait` or later `--wait-target` | `python3 scripts/tmux_run_job.py --window server --command "npm start"` |
| `scripts/tmux_healthcheck.py` | Inspect and cleanup stale `oc-` windows; optional legacy session cleanup | `python3 scripts/tmux_healthcheck.py --cleanup --dry-run` |
| `scripts/tmux_healthcheck_cron.py` | Install/status/remove managed cron entry for automatic cleanup | `python3 scripts/tmux_healthcheck_cron.py --action install` |
| `scripts/tmux_gc.py` | Legacy cleanup for old `opencode-*` session naming | `python3 scripts/tmux_gc.py --prefix opencode- --max-age-minutes 240 --dry-run` |

## wait-for Mental Model

- `tmux wait-for EVENT` blocks until signal arrives.
- `tmux wait-for -S EVENT` sends the signal.
- `wait-for` does not detect idle windows or process completion automatically.
- Emit signal manually at command end.

Wrapper behavior:

- `scripts/tmux_run_job.py` always emits a completion signal from inside the window.
- Script returns immediately by default (background mode).
- Add `--wait` to block immediately, or `--wait-target session:window` to wait later.
- Event name is deterministic per target: `oc-done-<normalized-session>-<normalized-window>`.
- Script stores exit code in tmux window option `@oc_exit`, so repeated `--wait-target` calls return immediately after completion.

Low-level event pattern:

```bash
EVENT="oc-done-tmux-opencode-oc-build"
tmux new-window -t "tmux-opencode" -n "oc-build" -d
tmux send-keys -t "tmux-opencode:oc-build" "bash -lc 'npm run build; status=$?; tmux wait-for -S ${EVENT}; exit $status'" C-m
tmux wait-for "$EVENT"
```

## Crash Recovery and Periodic Cleanup

One-time startup recovery:

```bash
python3 scripts/tmux_healthcheck.py --cleanup --max-idle-minutes 240 --cleanup-legacy-sessions
```

Optional blocking run pattern:

```bash
python3 scripts/tmux_run_job.py --window build --command "npm run build" --wait --wait-timeout-seconds 1800
```

Wait-after-start pattern:

```bash
python3 scripts/tmux_run_job.py --window build --command "npm run build"
python3 scripts/tmux_run_job.py --wait-target "tmux-opencode:oc-build"
```

Periodic check (cron every 15 minutes):

```bash
python3 scripts/tmux_healthcheck_cron.py --action install
python3 scripts/tmux_healthcheck_cron.py --action install --dry-run
```

Custom schedule install:

```bash
python3 scripts/tmux_healthcheck_cron.py --action install --schedule "*/10 * * * *" --max-idle-minutes 180 --cleanup-legacy-sessions
```

View or remove managed entry:

```bash
python3 scripts/tmux_healthcheck_cron.py --action status
python3 scripts/tmux_healthcheck_cron.py --action remove
```
