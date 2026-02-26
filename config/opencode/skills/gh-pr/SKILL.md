---
name: gh-pr
description: Run simple GitHub PR operations in natural language: open PR, pull new comments idempotently, and mark one or many comments pending/addressed.
references:
  - scripts/README.md
---

# gh-pr

Use this skill for minimal, direct PR operations.

## When to use

- User says `gh pr` and asks to open PR, check new comments, or mark comments pending/addressed.
- User wants idempotent comment triage between pushes.

## Defaults

- `ADDRESSED_REACTION=+1` (`:thumbsup:`) means addressed.
- `PENDING_REACTION=eyes` (`:eyes:`) means in progress.
- `BOT_REPLY_PREFIX=🤖` marks bot-authored replies.
- New comment = no pending/addressed reaction and body does not start with bot prefix.

## Core operations

### 1) Open PR

Use native CLI and avoid over-automation:

```bash
gh pr create --title "<title>" --body-file <body.md> --base <base-branch>
```

### 2) Pull new comments (idempotent)

Use helper script:

```bash
bun skills/gh-pr/scripts/gh_pr_ops.ts queue --repo <owner/repo> --pr <number>
```

This fetches issue + inline review comments and returns only unmarked, non-bot-prefixed items.

### 3) Mark pending/addressed (one or many)

```bash
# mark pending when you start work
bun skills/gh-pr/scripts/gh_pr_ops.ts mark --repo <owner/repo> --pr <number> --ids 12345 --status pending

# mark addressed when done
bun skills/gh-pr/scripts/gh_pr_ops.ts mark --repo <owner/repo> --pr <number> --ids 12345 --status addressed

# many
bun skills/gh-pr/scripts/gh_pr_ops.ts mark --repo <owner/repo> --pr <number> --ids 12345,12346,12347 --status addressed
```

### 4) Address comment(s) end-to-end

When user says "address comment" (or equivalent), execute this full sequence:

1. Mark selected comment(s) `pending` (`:eyes:`).
2. Implement the requested fix.
3. Run relevant verification (tests/lint/build as appropriate).
4. Commit changes with a clear message.
5. Push branch.
6. Mark selected comment(s) `addressed` (`:+1:`) only after push and only if actually resolved.

If verification fails or the fix is incomplete, keep the comment in `pending` state and report what remains.

## Workflow

1. Pull new comments from queue.
2. Mark picked comments as `pending` (`:eyes:`).
3. Implement the fix.
4. Verify.
5. Commit.
6. Push.
7. Mark as `addressed` (`:+1:`) only if the comment is actually resolved.

## Guardrails

- Keep behavior deterministic; do not mutate unrelated PR metadata.
- Never treat bot-prefixed replies as new feedback.
- Mark only comments that were actually handled.
- Preserve source URLs and IDs in summaries.
