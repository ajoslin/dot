# Script helpers

## `gh_pr_ops.py`

Small helper for idempotent PR comment operations.

### Queue

```bash
python3 skills/gh-pr/scripts/gh_pr_ops.py queue --repo owner/repo --pr 123
python3 skills/gh-pr/scripts/gh_pr_ops.py queue --repo owner/repo --pr 123 --json
```

### Mark addressed

```bash
python3 skills/gh-pr/scripts/gh_pr_ops.py mark --repo owner/repo --pr 123 --ids 111
python3 skills/gh-pr/scripts/gh_pr_ops.py mark --repo owner/repo --pr 123 --ids 111,222,333
```

### Environment

- `MARKER_REACTION` (default: `hooray`)
- `BOT_REPLY_PREFIX` (default: `🤖`)
