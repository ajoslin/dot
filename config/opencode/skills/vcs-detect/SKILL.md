---
name: vcs-detect
description: Detect whether the current project uses jj (Jujutsu) or git for version control. Run this before VCS commands to use the correct CLI.
---

# VCS Detection Skill

Detect the version control system in use before running VCS commands.

## Why This Matters

- jj and git have different CLIs and workflows.
- Running git commands in a jj repo (or vice versa) causes avoidable errors.
- Some repos are colocated (both `.jj/` and `.git/` exist).

## Detection Logic

Priority order:

1. `jj root` succeeds -> jj
2. else `git rev-parse --show-toplevel` succeeds -> git
3. else -> none

## Detection Command

```bash
if jj root &>/dev/null; then echo "jj"
elif git rev-parse --show-toplevel &>/dev/null; then echo "git"
else echo "none"
fi
```

## Common Command Mapping

| Operation | git | jj |
|---|---|---|
| Status | `git status` | `jj status` |
| Log | `git log` | `jj log` |
| Diff | `git diff` | `jj diff` |
| Commit | `git commit` | `jj commit` / `jj describe` |
| Branch list | `git branch` | `jj branch list` |
| New branch | `git checkout -b <name>` | `jj branch create <name>` |
| Push | `git push` | `jj git push` |
| Fetch/Pull | `git fetch` / `git pull` | `jj git fetch` |
| Rebase | `git rebase` | `jj rebase` |

## Usage

Before VCS operations:

1. Run the detection command.
2. Use the matching CLI (`jj` or `git`).
3. If `none`, report that the directory is not version controlled.

## Colocated Repos

If both `.jj/` and `.git/` exist, prefer jj commands and use git compatibility subcommands when needed.
