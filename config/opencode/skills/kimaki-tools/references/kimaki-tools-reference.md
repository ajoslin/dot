# Kimaki Tools Reference

## 1) Link Existing OpenCode Session to Discord

Use this when a session exists in OpenCode but was not started by Kimaki.

```bash
bash scripts/link-session-to-discord.sh --session-id <sessionId> --project "$(pwd)" --user "lp"
```

What it does:

1. Finds the mapped Kimaki channel for the project
2. Creates a notify-only Discord thread in that channel
3. Inserts/updates `thread_sessions(thread_id, session_id)` in Kimaki DB
4. Prints a verification listing from `kimaki session list --project ... --json`

## 2) List Projects

```bash
npx -y kimaki project list --json
```

## 3) Open Current Project Channel in Discord

```bash
npx -y kimaki project open-in-discord
```

## 4) List Sessions For Current Project

```bash
npx -y kimaki session list --project "$(pwd)" --json
```

## 5) Read Session As Markdown

```bash
npx -y kimaki session read <sessionId> --project "$(pwd)" > ./tmp/session.md 2>/dev/null
```

## 6) Send Prompt To Project Channel

```bash
npx -y kimaki send --project "$(pwd)" --prompt "your prompt" --user "lp"
```

## 7) Continue Existing Session Thread

```bash
npx -y kimaki send --session <sessionId> --prompt "follow-up"
```

## 8) Start Worktree Session

```bash
npx -y kimaki send --project "$(pwd)" --prompt "task" --worktree feat-task --user "lp"
```

## 9) Archive Thread + Stop Mapped Session

```bash
npx -y kimaki session archive <threadId>
```
