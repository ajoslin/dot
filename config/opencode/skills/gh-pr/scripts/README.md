# Script helpers

## `gh_pr_ops.ts`

Small helper for idempotent PR comment operations.

### Queue

```bash
bun skills/gh-pr/scripts/gh_pr_ops.ts queue --repo owner/repo --pr 123
bun skills/gh-pr/scripts/gh_pr_ops.ts queue --repo owner/repo --pr 123 --json
```

### Mark pending / addressed

`--status addressed` resolves GitHub review threads for PR review comments. Issue comments remain reaction-based.

```bash
# mark pending (eyes)
bun skills/gh-pr/scripts/gh_pr_ops.ts mark --repo owner/repo --pr 123 --ids 111 --status pending

# mark addressed (thumbs up)
bun skills/gh-pr/scripts/gh_pr_ops.ts mark --repo owner/repo --pr 123 --ids 111 --status addressed
bun skills/gh-pr/scripts/gh_pr_ops.ts mark --repo owner/repo --pr 123 --ids 111,222,333 --status addressed
```

### Test

```bash
bun test skills/gh-pr/scripts/gh_pr_ops.test.ts
```

### Environment

- `ADDRESSED_REACTION` (default: `+1`)
- `PENDING_REACTION` (default: `eyes`)
- `MARKER_REACTION` (legacy fallback for addressed reaction)
- `BOT_REPLY_PREFIX` (default: `🤖`)
