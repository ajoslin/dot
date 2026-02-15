# Kimaki Quick Reference

Primary docs: `https://kimaki.xyz`

## Quick Start

```bash
npx -y kimaki@latest
```

Run command and complete interactive setup for bot creation, permissions, and project-channel mapping.

## Core Slash Commands

- `/session <prompt>` start a new session in current channel
- `/resume <session>` continue an existing session
- `/abort` stop current running session
- `/add-project <project>` map an existing local project to Discord channel(s)
- `/create-new-project <name>` create folder and start session
- `/new-worktree <name>` create worktree-backed session
- `/merge-worktree` merge worktree branch into default branch
- `/model` set model for channel or session
- `/agent` set agent for channel or session
- `/share` generate public session URL
- `/fork` fork from prior message
- `/queue <message>` enqueue follow-up while assistant is busy
- `/clear-queue` clear queued follow-ups
- `/undo` revert last assistant action
- `/redo` re-apply last undone action

## Core CLI Commands

```bash
# Start or re-open interactive bot bridge
npx -y kimaki@latest

# Add project mapping without starting session
npx -y kimaki project add [directory]

# Start session in a channel
npx -y kimaki send --channel <channel-id> --prompt "your prompt"

# Continue existing thread
npx -y kimaki send --thread <thread-id> --prompt "follow-up"

# Continue by session mapping
npx -y kimaki send --session <session-id> --prompt "follow-up"

# Start session in isolated worktree
npx -y kimaki send --channel <channel-id> --prompt "task" --worktree <name>

# Post event without triggering agent immediately
npx -y kimaki send --channel <channel-id> --prompt "event" --notify-only
```

## Permission Model

Allow interaction when user is:

- Server Owner
- Administrator
- Has Manage Server permission
- Assigned role named `Kimaki` (case-insensitive)

Block interaction when user has role named `no-kimaki`.

## Common Failure Checks

1. Verify Kimaki process is running on machine where project directory exists.
2. Verify bot is installed in target server.
3. Verify target channel maps to intended directory.
4. Verify bot intents and permissions were enabled during setup.
5. Verify one-bot-per-machine architecture for multi-host setups.
