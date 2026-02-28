# Audit: Transfer from `vision/middleman` to `vision/middleman-v2`

## Source Files Audited

- `vision/middleman/MIDDLEMAN_KIMAKI_PR_ORCHESTRATOR_SPEC_V1.md`
- `vision/middleman/HANDOFF_CHECKLIST_V1.md`

## Destination Files Audited

- `vision/middleman-v2/01-pass-system-summary.md`
- `vision/middleman-v2/02-pass-data-model-and-interaction.md`
- `vision/middleman-v2/03-pass-detailed-spec.md`

## Transfer Status

- Core architecture and two-layer split: transferred
- Project scope and machine routing policy: transferred
- Queue semantics (FIFO, one active item, pause backlog): transferred
- Polling model, dedupe, high-water marks, rate-limit strategy: transferred
- Retry and exhaustion behavior (max 3, pause key): transferred
- Worktree constraints (max 30, recency gate, reset procedure): transferred
- Security and branch push policy: transferred
- Notification contract + attach hint: transferred
- Open effort map semantics and thresholds: transferred
- Operator command surface: transferred
- Persistence and crash recovery requirements: transferred
- Acceptance criteria: transferred and expanded

## Knowledge Gaps Remaining

None identified for V1 parity.

## Recommendation

`vision/middleman` is now safe to deprecate from a planning-doc standpoint.

Suggested deprecation process:
1. Keep folder for one short grace window (for human review).
2. Add an internal note: "Superseded by `vision/middleman-v2/*`."
3. Delete `vision/middleman` after review confirmation.
