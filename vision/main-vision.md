# Personal AI Ops Vision

Source of truth narrative: `vision/original-vision-message.md`

## Outcome

Build a Spacebot-first personal operating system that creates decision space by automating recurring analysis, execution, and follow-through across:

- TRW product/engineering/business operations
- Crypto strategy and execution support
- Personal admin, finance, and family-aware planning

## Ground Truth Constraints

- Family bandwidth is real (young kids, limited deep-work windows), so automations must reduce coordination overhead and protect focus blocks.
- TRW includes highly custom payment rails and billing/dunning complexity, so finance workflows need strict approval and auditability.
- Management load (team reviews, reporting, decisions) is a first-class workload, not secondary to coding.

## Operating Principle

Use **Hands-style autonomous loops** on top of Spacebot (scheduled + event-driven workers with strict output contracts), not chat-only interactions.

```text
Signals (DB/PostHog/Chats/Email/Calendar) ---> Hand Loop ---> Action Queue ---> Human Approval/Auto-Exec
                                          \-> Memory + Reports -> Daily/Weekly Briefs -> Leadership Decisions
```

## Strategic Direction

1. **Spacebot as control plane**
   - Keep channel-first interaction (Telegram/Discord)
   - Recreate OpenFang Hands pattern as Spacebot worker packs
2. **TRW first, personal second, crypto third (parallelized)**
   - Highest ROI: reduce churn, fix breakages, improve shipping speed
3. **Autonomy with explicit risk tiers**
   - Tier 0: read/report only
   - Tier 1: propose + queue actions
   - Tier 2: auto-execute low-risk actions
   - Tier 3: finance/money movement requires approval gate

## Non-Negotiables

- Deterministic scheduled runs for core loops
- Full artifact trail (what data was used, why recommendation was made)
- Idempotent financial automations with rollback path
- Daily executive digest with only actionable deltas

## Immediate Build Priorities

1. TRW Hands layer over existing `trw-context`
2. Financial monitoring and transfer recommendation loop
3. Unified task and personal admin reminder engine (Telegram-first)

## Included Original Scope

- This plan explicitly includes the original asks around email triage, calendar via Telegram, Trello todo ops, paper-mail ingestion, social touchpoint cadence, and daily Bible thread prompts.

## Success Criteria (90 days)

- TRW: recurring bug/leak detection loop with owner assignment and measurable closure rate
- Personal: no missed critical admin deadlines (tax/DMV/tickets)
- Ops: at least 50% of recurring reporting and triage done autonomously
