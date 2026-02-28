# Claude Cowork Post: Summary + Fit To Your Vision

Related sources:
- `vision/references/claude-cowork-setup-guide.md`
- `vision/original-vision-message.md`
- `vision/main-vision.md`
- `vision/spacebot-implementation.md`

## Executive Summary

The post argues that AI leverage comes less from clever prompts and more from a stable operating system of context, clarifying questions, specialist packs, persistent instructions, and live connectors. The strongest idea is the **context compounding loop**: better files + standing instructions + iterative clarification yield reliably better outputs over time.

## What Is Most Relevant To Your Vision

For your "systemize to create space" goal, the post maps well to these priorities:

- **TRW factory model**: use file-backed context + role-specific hand packs to standardize bug triage, QA, billing risk analysis, and reporting.
- **Telegram-first execution**: the connector mindset mirrors your plan to route action through messaging surfaces and avoid manual copy-paste.
- **Management bandwidth**: AskUserQuestion-style forced clarification is useful for reducing rework in dev delegation and report generation.
- **Personal ops reliability**: instructions + folder context align with your need for repeatable mail/todo/calendar workflows under fragmented time.

## Spacebot/Hands Translation (Direct)

Cowork concept -> Your architecture equivalent:

- File System Access -> `trw-context` data folder contracts + hand input manifests
- AskUserQuestion -> pre-execution alignment phase in each hand (`question gate`)
- Plugins -> hand-specific prompt packs and slash-style command sets
- Global/Folder Instructions -> versioned global policy + project-level hand instructions
- Connectors -> Spacebot integrations (Telegram/Discord/Drive/Notion/Slack/Trello/etc.)

## What To Adopt Immediately

1. **Context folder pattern per domain**
   - Create domain folders with stable files:
     - `about-domain.md`
     - `operating-rules.md`
     - `output-contracts.md`
     - `known-failure-modes.md`
2. **Mandatory clarification gate for non-trivial tasks**
   - Every hand asks high-signal questions before execution unless runbook conditions are fully satisfied.
3. **Instruction layering**
   - Global: your voice, risk policy, escalation defaults
   - Folder/project: TRW-specific schemas, billing terms, hot spots, owner map
4. **Connector-first ingestion**
   - Replace manual copy workflows with connector-driven data pull and referenced evidence in outputs.

## Gaps / Caveats Relative To Your Needs

The post is strong for knowledge work but not enough alone for your high-stakes environment:

- It under-specifies **finance safety controls** (idempotency keys, approval thresholds, rollback plans).
- It does not cover **24/7 autonomous operational resilience** deeply (health checks, retry policies, incident runbooks).
- It assumes a desktop-centric workflow; your stack needs robust daemonized multi-loop execution with explicit observability.

## Recommended Additions For Your System

- Add a **risk-tier policy** to every hand (read-only, propose-only, low-risk auto, approval-required).
- Add **run ledger + evidence ledger** for every autonomous action.
- Add **false-positive tracking** per hand to improve prioritization over time.
- Add **owner routing + SLA tags** for TRW bug/leak findings.

## Synthesis: Does this post change direction?

Yes on execution quality, no on platform direction.

- **No directional change**: continue Spacebot + Hands-style architecture.
- **Execution upgrade**: adopt Cowork’s strongest pattern: structured context files + mandatory clarification + connector-first operations.

## Next practical step

Implement a "Cowork-style bootstrap" for each TRW hand in `trw-context`:

- Add per-hand context files
- Add preflight clarification template
- Add output schema with evidence anchors
- Add instruction versioning and run summaries

This gives you the compounding quality effect from the post, but inside your existing Spacebot/OpenCode/Kimaki system.
