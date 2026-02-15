---
name: gh-pr
description: Run simple GitHub PR operations in natural language: open PR, pull new comments idempotently, and mark one or many comments addressed.
references:
  - scripts/README.md
---

# gh-pr

Use this skill for minimal, direct PR operations.

## When to use

- User says `gh pr` and asks to open PR, check new comments, or mark comments addressed.
- User wants idempotent comment triage between pushes.

## Defaults

- `MARKER_REACTION=hooray` (`:tada:`) means addressed.
- `BOT_REPLY_PREFIX=🤖` marks bot-authored replies.
- New comment = no marker reaction and body does not start with bot prefix.

## Core operations

### 1) Open PR

Use native CLI and avoid over-automation:

```bash
gh pr create --title "<title>" --body-file <body.md> --base <base-branch>
```

### 2) Pull new comments (idempotent)

Use helper script:

```bash
python3 skills/gh-pr/scripts/gh_pr_ops.py queue --repo <owner/repo> --pr <number>
```

This fetches issue + inline review comments and returns only unmarked, non-bot-prefixed items.

### 3) Mark addressed (one or many)

```bash
# one
python3 skills/gh-pr/scripts/gh_pr_ops.py mark --repo <owner/repo> --pr <number> --ids 12345

# many
python3 skills/gh-pr/scripts/gh_pr_ops.py mark --repo <owner/repo> --pr <number> --ids 12345,12346,12347
```

## Guardrails

- Keep behavior deterministic; do not mutate unrelated PR metadata.
- Never treat bot-prefixed replies as new feedback.
- Mark only comments that were actually handled.
- Preserve source URLs and IDs in summaries.
