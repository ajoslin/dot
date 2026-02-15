---
name: kimaki-expert
description: Provide expert support for Kimaki setup, Discord bot wiring, OpenCode session orchestration, slash-command troubleshooting, and automation workflows. Use when users mention Kimaki, kimaki.xyz, Discord-controlled coding agents, or channel-to-project mapping.
references:
  - references/kimaki-quick-reference.md
---

# Kimaki Expert

Use this skill to configure and operate Kimaki as a Discord control plane for OpenCode projects.

## Trigger Conditions

Activate when a request includes one or more of these signals:

- Mentions `kimaki`, `kimaki.xyz`, or `npx -y kimaki@latest`
- Requests Discord bot setup for coding agents
- Asks to map project directories to Discord channels
- Needs help with Kimaki slash commands, queueing, session resume/fork/share
- Wants CI or automation via `kimaki send` or `kimaki project add`

## Operating Procedure

1. Identify target mode: initial setup, ongoing operations, or automation.
2. Validate prerequisites: Discord app, bot token, project directory, and running Kimaki bridge process.
3. Guide through smallest viable flow first: start bot, link one project, send one message.
4. Expand to advanced features only after baseline path works.
5. Prefer exact commands and short checklists over conceptual explanations.

## Standard Workflows

### First-Time Setup

- Run `npx -y kimaki@latest` and follow interactive prompts.
- Ensure required Discord intents are enabled during bot creation.
- Install bot into target server.
- Add at least one project-channel mapping and test with a short prompt message.

### Day-2 Operations

- Use slash commands for session control: `/session`, `/resume`, `/abort`, `/queue`, `/clear-queue`, `/undo`, `/redo`.
- Use `/model` and `/agent` to tune execution context per channel or session.
- Keep one dedicated server for agent traffic and access-control hygiene.

### Automation and CI

- Start jobs programmatically with `npx -y kimaki send --channel <id> --prompt "..."`.
- Continue existing threads with `--thread` or `--session`.
- Create isolated runs with `--worktree <name>`.
- Use `--notify-only` for context events without immediate execution.

## Troubleshooting Heuristics

- If messages do nothing, verify permissions and role policy (`Kimaki` role and no `no-kimaki` blocker role).
- If sessions fail to start, verify Kimaki process is running on machine hosting target project.
- If channels are missing, re-run mapping with `/add-project` or `kimaki project add`.
- If multi-machine routing is confusing, enforce one bot per machine and explicit channel labeling.

## Response Style

- Lead with exact command(s), then expected result.
- Include one validation step after each critical action.
- Keep guidance operational and concise.
- Use `references/kimaki-quick-reference.md` for commands and recipes.
