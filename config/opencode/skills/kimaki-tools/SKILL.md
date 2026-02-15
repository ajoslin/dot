---
name: kimaki-tools
description: Run common Kimaki project/session operations from OpenCode, especially linking an existing OpenCode session into Discord and Kimaki session listings. Use when users ask to manage Kimaki projects, sessions, or thread mappings from CLI.
references:
  - references/kimaki-tools-reference.md
---

# Kimaki Tools

Use this skill to execute repeatable Kimaki CLI operations from an OpenCode session.

## Trigger Conditions

Activate when the user asks to do Kimaki operations such as:

- Add/link the current OpenCode session to Discord/Kimaki
- List Kimaki projects or sessions
- Read archived session logs
- Start a Kimaki session from CLI (`kimaki send`)
- Start a worktree session from CLI

## Core Capability: Link Current Session

When the user says to add/link the current OpenCode session to Kimaki/Discord:

1. Resolve the current session ID.
   - Prefer explicit user-provided session ID.
   - Else use the session ID from system context.
2. Run:

```bash
bash scripts/link-session-to-discord.sh --session-id <sessionId> --project "$(pwd)" --user "lp"
```

3. Report:
   - Created/used Discord thread ID + URL
   - Confirmation that mapping was inserted in `thread_sessions`
   - Result from `kimaki session list --project <path>` showing `source: kimaki`

## Common Operations

Use commands from `references/kimaki-tools-reference.md` for:

- Project discovery (`project list`, `project open-in-discord`)
- Session inspection (`session list`, `session read`)
- Dispatching prompts (`send --channel`, `send --session`, `--wait`)
- Worktree sessions (`send --worktree`)
- Thread/session cleanup (`session archive`)

## Operational Rules

- Prefer exact commands over conceptual guidance.
- Validate with one follow-up command after each write operation.
- If current directory is not a Kimaki project, instruct how to register it with `kimaki project add`.
- If linking fails because the project mapping is missing, stop and provide the exact fix command.
