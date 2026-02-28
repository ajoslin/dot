# Spacebot Implementation Plan (Hands-Style)

Primary narrative source: `vision/original-vision-message.md`

## 1) Architecture You Want

You prefer Spacebot for most workflows, but want OpenFang-style "Hands" behavior (24/7 monitor + analyze + report + act loops).

```text
                 +-------------------------+
                 |   Telegram / Discord    |
                 +-----------+-------------+
                             |
                        Spacebot Channel
                             |
        +--------------------+--------------------+
        |                    |                    |
   Branch (reasoning)   Worker (execution)   Cron/Event Trigger
        |                    |                    |
        +--------- Hands-Style Runtime ----------+
                             |
      +----------------------+----------------------+
      |                                             |
 Memory Graph + Task Board                     Reports + Alerts
 (context, lessons, state)                     (daily/ad-hoc)
```

## 2) What "Hands" Means Here

A Hand is a packaged autonomous loop, not idle reprompting. Each Hand has:

- Trigger: cron/event/manual
- Inputs: explicit data sources (Mongo, checkoutdb, PostHog, files)
- Instructions: deep domain playbook and guardrails
- Tools: explicit allowlist
- Memory policy: what to read/write and retention rules
- Output contract: fixed report/action schema
- Risk policy: auto-exec vs approval required

## 3) Item-by-Item Implementation (your wishlist)

This section maps directly to your original vision message, including work, management, business, and personal-life constraints.

## Financial Integrations (Business reporting)

- **Goal**: detect low balances, recommend/execute rebalance, log transfer rationale.
- **Spacebot implementation**:
  - `hand-finance-monitor`: poll balances + thresholds, emit risk events.
  - `hand-finance-rebalance`: create transfer proposal with source/target/amount/reason.
  - `hand-finance-ledger`: write bookkeeping rows (Google Sheets/ledger store).
- **Guardrails**:
  - read-only mode first
  - approval required above threshold
  - idempotency key per transfer window

## Tax / bookkeeping export and quarterly prep

- **Goal**: continuous expense normalization and quarterly estimate prep.
- **Implementation**:
  - `hand-tax-rollup`: weekly normalize + map categories.
  - `hand-quarterly-close`: monthly pre-close checklist + variance report.

## Email triage and folders

- **Goal**: no critical email misses.
- **Implementation**:
  - `hand-email-triage`: classify incoming email into urgency lanes.
  - `hand-email-escalation`: reminder loop for unresolved critical threads.

## Calendar with Telegram delivery

- **Goal**: proactive agenda and conflict alerts.
- **Implementation**:
  - `hand-calendar-brief`: morning/afternoon agenda with prep notes.
  - `hand-calendar-conflict`: detect collisions + propose reschedules.

## Telegram-first control plane

- **Goal**: run everything from Telegram, keep Discord for richer ops.
- **Implementation**:
  - Telegram as command surface
  - Discord as analytics/report sink for long outputs
  - Keep Kimaki/OpenCode-heavy workflows in Discord where needed, but route action prompts and reminders to Telegram by default.

## Social connection cadence

- **Goal**: monthly relationship maintenance.
- **Implementation**:
  - `hand-social-touch`: shortlist review + 1 outreach draft/month.

## Note taking / reading / second brain

- **Goal**: capture and retrieval without friction.
- **Implementation**:
  - `hand-knowledge-capture`: ingest links/notes/snippets.
  - `hand-knowledge-digest`: weekly synthesis and retrieval index.

## Todos (Trello MCP + Telegram)

- **Goal**: reliable externalized task system.
- **Implementation**:
  - `hand-task-router`: convert intents to Trello cards/checklists.
  - `hand-task-followup`: stale card nudges and deadline reminders.

## Physical mail ingestion

- **Goal**: never miss bills/legal notices.
- **Implementation**:
  - `hand-mail-ingest`: OCR + classify + deadline extraction.
  - `hand-mail-escalate`: unresolved deadline reminder ladder.

## Bible thread (daily theologian question)

- **Goal**: steady spiritual discussion cadence.
- **Implementation**:
  - `hand-bible-daily`: daily verse + theologian prompt + discussion seed.

## TRW QA + Parchi + 24/7 E2E

- **Goal**: continuous regression detection and actionable defect reports.
- **Implementation**:
  - `hand-trw-qa-sweep`: scheduled e2e runs + flaky detection + trend report.
  - `hand-trw-release-guard`: pre/post deploy smoke + rollback signals.
  - `hand-trw-parchi-link`: ingest Parchi outputs into QA prioritization queue and convert into reproducible test tasks.

## Crypto bot support

- **Goal**: keep live execution healthy with risk-aware maintenance.
- **Implementation**:
  - `hand-crypto-watch`: execution health, slippage anomalies, strategy drift alerts.

## 4) TRW-Context Deep Dive (current state)

Your current pipeline in `~/dev/realworld/trw-context` already provides a strong base:

- Daily context extraction: `scripts/daily-context.ts`
- PG health/churn/revenue snapshots: `scripts/daily-health-pg.ts`
- PostHog usage snapshots: `scripts/daily-posthog.ts`
- Pass-2 LLM message intelligence: `scripts/daily-pass2-llm.ts`
- Complaint clustering + n8n context: `scripts/council-complaint-context.ts`
- Multi-round council: `scripts/business-council.ts`
- Final synthesis: `scripts/daily-synthesis.ts`

## Existing Data Architecture (from repo)

```text
Mongo messages -> raw JSONL -> local complaint/intents -> snapshots/diffs
Postgres queries (churn/revenue/subscribers) -> health snapshots
PostHog HogQL -> DAU/WAU/MAU/stickiness/events
Pass-2 LLM -> structured wants/bugs/positives
Council rounds -> recommendations
Daily synthesis -> board-ready md/json
```

## Key hotspots to monitor (bugs/improvements/features/billing)

- Billing failures, rebill failures, cancels vs recoveries, charge/refund disputes
- Lesson/workflow breakage clusters (n8n, node/field mismatch, Google Sheets errors)
- Support latency and unresolved help requests
- Moderation/ban complaint spikes
- Stickiness decay (`DAU/MAU`) and chat sender erosion

## 5) Convert `trw-context` Into Hands-Style Ad-Hoc Intelligence

You specifically want ad-hoc, high-detail analysis with DB/PostHog access and app-architecture hotspots.

## Proposed TRW Hands Set

1. `hand-trw-signal-ingest`
   - Runs frequent snapshot refresh (Mongo + PostHog + checkoutdb)
   - Writes normalized state and data quality diagnostics

2. `hand-trw-anomaly-detect`
   - Compares current vs baseline windows
   - Flags churn spikes, complaint-density spikes, event drop-offs

3. `hand-trw-root-cause-investigator`
   - Uses structured + discovered queries (Mongo, checkoutdb, PostHog)
   - Produces ranked hypotheses + confidence + required follow-up queries

4. `hand-trw-billing-guard`
   - Focused on rebills, failed payments, dispute clusters, net churn delta
   - Emits finance-risk alerts with expected revenue impact estimate

5. `hand-trw-feature-opportunity`
   - Mines "top wants" + positive drivers + retention correlation hints
   - Outputs scoped feature candidates with measurable KPI target

6. `hand-trw-exec-digest`
   - Produces leadership report (what changed, why, what to do now)

## Hand Prompting Standard (for your ad-hoc depth)

Each TRW hand prompt should include:

- Product architecture map (domains, ownership, known risky subsystems)
- Data source contract (Mongo collections, checkoutdb query packs, PostHog events)
- Known failure patterns (billing, workflow, support, moderation)
- Mandatory output schema:
  - finding
  - evidence (query/file references)
  - confidence
  - business impact
  - proposed action
  - owner

## 6) How Memory/Learning Works in this design

- Not model retraining.
- Procedural learning loop:
  - Persist findings and outcomes
  - Retrieve relevant historical context next run
  - Adjust recommendations based on previous true/false positives

```text
Run N findings -> Action outcomes -> Memory update -> Run N+1 prompt context -> Better prioritization
```

## 7) Instruction Update Model

- Version hand instructions in files (semantic versions)
- Track drift with:
  - false positive rate
  - missed incident rate
  - action completion/impact
- Promote only validated prompt/policy revisions

## 8) Rollout Plan

## Phase 1 (read-only, 2 weeks)

- Build 3 TRW hands: ingest, anomaly, digest
- No auto actions; report-only with confidence scoring

## Management and reporting lane (parallel)

- Add `hand-mgmt-status`: weekly dev throughput + blocker digest for team-of-4 management cadence.
- Add `hand-exec-brief`: concise management report combining product velocity, risk, and finance highlights.

## Phase 2 (guided actions, 2-4 weeks)

- Add root-cause + billing guard
- Auto-create task tickets with owner and SLA

## Phase 3 (selective autonomy)

- Auto-execute low-risk remediations
- Keep approval gate for money-impacting operations

## 9) First Build Targets in `trw-context`

1. Add `hands/` specs and prompt packs.
2. Add run ledger (`data/hands-runs/`) with deterministic run IDs.
3. Add risk-tier execution policy in config.
4. Extend synthesis to include "ad-hoc hand findings" section.

## 10) Final Recommendation for your stated preference

- Commit to **Spacebot as primary platform**.
- Implement **Hands as a pattern** (not vendor lock to OpenFang).
- Start with TRW loops where you already have high-quality data plumbing.
- Use OpenCode/Kimaki integration for orchestration, but keep outputs deterministic and auditable.
