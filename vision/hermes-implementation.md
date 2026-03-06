# Hermes Agent Implementation Plan

Canonical implementation plan for AJ's personal AI operating system.
Replaces `spacebot-implementation.md`. Written from Hermes's perspective.

Primary narrative source: `vision/original-vision-message.md`

---

## 1. What Hermes Actually Is

Hermes is not a concept or a future build. It is running right now.

AJ talks to Hermes via Telegram. Hermes has full shell access to AJ's MBP, can browse the web, read and write files, search the internet, run code, manage background processes, schedule future work, spawn parallel subagents, and persist memory across sessions.

The core is the AIAgent class in `run_agent.py`: a loop that takes a user message, calls an LLM with tools, executes tool calls, feeds results back, and repeats until a text response is produced. Up to 60 iterations per turn. OpenAI-compatible API via OpenRouter. Claude Opus as the default model.

This is the platform. Everything in this document builds on what already exists.

### What Hermes Has Today

| Capability | Status | Notes |
|---|---|---|
| Telegram chat interface | Running | Primary interaction surface |
| Discord adapter | Running | Available but secondary |
| Full terminal access (local) | Running | Shell on AJ's MBP |
| Docker/SSH/Modal/Singularity backends | Available | Not actively used |
| Web search + extraction | Running | Firecrawl-backed |
| Browser automation | Running | Navigate, click, type, screenshot |
| Persistent memory | Running | User profile + memory notes, survives sessions |
| Session search (history recall) | Running | FTS5 across past conversations |
| Skills system | Running | Progressive disclosure, YAML frontmatter |
| Scheduled cronjobs | Running | One-shot, interval, cron expressions |
| Parallel subagents (delegate_task) | Running | Up to 3 concurrent, isolated contexts |
| Code execution sandbox | Running | Python with access to Hermes tools |
| Send messages to platforms | Running | Telegram, Discord, arbitrary channels |
| Vision analysis | Running | Image understanding |
| Text-to-speech | Running | Voice memos |
| MCP client | Running | Native MCP server integration |
| Event hooks | Available | gateway:startup, session:start/reset, agent lifecycle |
| Background process management | Running | Start, poll, wait, kill, stdin write |
| Dangerous command approval | Running | Safety checks on local/SSH backends |
| DM pairing system | Running | One-time codes, rate-limited |

---

## 2. Architecture

```
                    +---------------------------+
                    |   Telegram  |  Discord    |
                    +------+------+------+------+
                           |             |
                     Gateway (Adapters)
                           |
                    +------+------+
                    |   AIAgent   |
                    |  (run loop) |
                    +------+------+
                           |
          +----------------+----------------+
          |                |                |
     Tool Registry    Memory Store    Cron Scheduler
          |                |                |
    +-----+-----+    +----+----+     +-----+-----+
    | terminal   |    | user    |     | one-shot  |
    | file ops   |    | profile |     | interval  |
    | web/browse |    | memory  |     | cron expr |
    | code exec  |    | notes   |     | timestamp |
    | delegate   |    +---------+     +-----------+
    | send_msg   |         |               |
    | vision     |    session_search   Fresh AIAgent
    | MCP        |    (FTS5 history)   (full tools,
    | skills     |                      no context)
    +------------+

    Config: ~/.hermes/config.yaml
    Secrets: ~/.hermes/.env
    Skills: ~/.hermes/skills/
    Hooks: ~/.hermes/hooks/
    State: ~/.hermes/state.db (SQLite)
    Cron: ~/.hermes/cron/
```

### Key Difference from the Spacebot Vision

The Spacebot architecture diagram showed separate "Branch (reasoning)" and "Worker (execution)" nodes, a separate Memory Graph, and a Task Board. That architecture was aspirational and implied custom infrastructure that did not exist.

Hermes is simpler and real: one agent loop, one tool registry, one memory store, one cron scheduler. The sophistication comes from composition, not from custom infrastructure layers.

---

## 3. Mapping "Hands" to Hermes Cronjobs

The Spacebot vision defined "Hands" as autonomous loops. A Hand has: trigger, inputs, instructions, tools, memory policy, output contract, risk policy.

In Hermes, a **cronjob IS a Hand**. The mapping is direct:

| Hand Concept | Hermes Equivalent |
|---|---|
| Trigger | Cronjob schedule (cron expr, interval, one-shot, timestamp) |
| Inputs | Self-contained prompt that tells the agent what data to fetch |
| Instructions | The cronjob prompt itself (must be comprehensive and standalone) |
| Tools | Full tool access (terminal, files, web, code execution, etc.) |
| Memory policy | Global memory (read on start, can write during execution) |
| Output contract | Prompt specifies output format; delivery target routes the result |
| Risk policy | Encoded in prompt instructions (read-only vs propose vs execute) |

### The Critical Cronjob Constraint

Each cronjob runs in a **fresh session with NO conversation context**. The prompt must be completely self-contained. This means:

1. Every cronjob prompt must include all context the agent needs: what to check, where the data is, what credentials/paths to use, what format to output, where to deliver results.
2. There is no "memory of last run" unless the cronjob explicitly reads from a known file or database.
3. The prompt IS the instruction pack. It replaces the "Hand spec" concept entirely.

### How to Structure a Cronjob Prompt (Hand Equivalent)

```
You are running a scheduled task: [HAND NAME]

PURPOSE: [What this hand does and why]

DATA SOURCES:
- [Explicit paths, databases, APIs, commands to run]

PROCEDURE:
1. [Step-by-step what to do]
2. [Including error handling]

OUTPUT FORMAT:
- [Exact schema or template for the report]

DELIVERY:
- [Where to send: telegram, discord, file]

CONSTRAINTS:
- [Risk tier: read-only / propose only / can execute]
- [What NOT to do]

PREVIOUS STATE (if applicable):
- Read previous run state from: [file path]
- Write updated state to: [file path]
```

### Cronjob Delivery Options

- `"origin"` -- back to the chat that created it
- `"telegram"` -- to AJ's Telegram
- `"discord"` -- to Discord
- `"platform:chat_id"` -- specific channel
- `"local"` -- write to files only

---

## 4. What Cronjobs Cannot Do (Honest Gaps)

### Gap 1: No Event-Driven Triggers

Cronjobs are time-based only. There is no webhook listener, no "trigger when X happens" capability. Everything is polling on a schedule.

**Workaround**: Use frequent polling intervals for time-sensitive monitoring (every 5-15 minutes). For truly event-driven needs, an external webhook-to-cronjob bridge would need to be built.

**Infrastructure needed**: A lightweight HTTP endpoint that can create one-shot cronjobs on demand. This is a small build but does not exist today.

### Gap 2: No Mid-Execution Approval Gate

The `clarify` tool does not work in cronjobs (no interactive session). This means no approval flow mid-execution. A cronjob cannot pause and ask "should I proceed?" before executing a financial transfer.

**Workaround for Tier 2-3 operations**:
- Cronjob generates a proposal and sends it to Telegram via `send_message`
- AJ reviews and replies in the interactive session
- AJ tells Hermes to execute (or a second one-shot cronjob handles execution after delay)

**Infrastructure needed for true approval gates**: A queue system where cronjobs can park pending actions and a separate mechanism (Telegram inline buttons, reply-based approval) triggers execution. This is a meaningful build.

### Gap 3: Memory is Global, Not Per-Hand Scoped

All cronjobs share the same memory stores. There is no namespacing like "billing-guard memory" vs "qa-sweep memory." If two hands write conflicting notes to memory, they collide.

**Workaround**: Use files for per-hand state. Each hand writes its state to a dedicated path like `~/.hermes/hands/{hand-name}/state.json`. Memory is reserved for cross-cutting user context.

**Infrastructure needed**: None -- this is a convention, not a code change. But it means hand prompts must explicitly manage their own state files.

### Gap 4: No Structured Run Ledger

There is no built-in log of "hand X ran at time Y, produced output Z, took N seconds." The Spacebot vision called for a `data/hands-runs/` directory with deterministic run IDs.

**Workaround**: Each hand prompt can include instructions to append a run record to a JSONL file: `~/.hermes/hands/{hand-name}/runs.jsonl` with timestamp, status, findings count, and delivery confirmation.

**Infrastructure needed**: A proper run ledger would be a small addition to the cron system -- automatically logging start time, end time, success/failure, output length for every cronjob execution. Worth building.

### Gap 5: No Output Length Guarantee

Cronjob outputs go through the LLM, which means output length and format are probabilistic, not deterministic. A "daily digest" might be 500 words one day and 2000 the next.

**Workaround**: Strong prompt engineering with explicit format constraints. Use `execute_code` for deterministic data gathering, with the LLM only handling synthesis.

---

## 5. Skills as Hand Instruction Packs

The Skills system (`~/.hermes/skills/`) maps cleanly to the "Hand instruction pack" concept from the Spacebot vision.

A Skill is a YAML-frontmatter markdown file with:
- Name, description, version
- Detailed instructions
- Reference files (API specs, templates, domain docs)
- Tags and related skills

**For the Hands pattern, Skills serve as the domain knowledge base that cronjob prompts reference.** Instead of embedding a 2000-word TRW architecture guide in every cronjob prompt, the cronjob can load it from a skill.

### Proposed Skill Structure for Hands

```
~/.hermes/skills/
  hands/
    trw-domain/
      SKILL.md          # TRW architecture, data sources, known failure patterns
      references/
        mongo-collections.md
        postghog-events.md
        billing-flow.md
        known-issues.md
    finance-domain/
      SKILL.md          # Account structure, thresholds, transfer procedures
      references/
        account-map.md
        threshold-config.yaml
    personal-domain/
      SKILL.md          # Contact list, calendar structure, admin deadlines
```

**Limitation**: Skills are loaded via the `skill_view` tool during an agent session. In cronjobs, the agent can call `skill_view` as its first step to load domain context. This works but adds tool-call overhead to every run. An alternative is to inline critical context directly in the cronjob prompt.

---

## 6. Memory + Session Search as the Learning Loop

The Spacebot vision described a procedural learning loop:
```
Run N findings -> Action outcomes -> Memory update -> Run N+1 prompt context -> Better prioritization
```

Hermes has the primitives for this:

### Memory (Persistent Cross-Session)
- **User profile**: Facts about AJ (role, preferences, constraints). Auto-maintained. ~1375 chars.
- **Memory notes**: Observations, learnings, patterns. Auto-maintained. ~2200 chars.
- Both appear in the system prompt of every session, including cronjobs.
- Both are updated organically during conversations.

### Session Search (Historical Recall)
- FTS5 index across all past conversations.
- A cronjob can search past sessions to find relevant historical context.
- Enables "what did we learn last time about billing churn?" type retrieval.

### The Learning Loop in Practice

1. **Hand runs** (cronjob executes, produces findings)
2. **State file updated** (`~/.hermes/hands/{name}/state.json` with latest findings, baselines, false positive notes)
3. **Memory updated** if findings are cross-cutting (e.g., "TRW billing processor X has been flaky since Feb")
4. **Next run** reads state file to compare against, reads memory for cross-cutting context
5. **Interactive review** -- AJ discusses results with Hermes, Hermes updates memory with corrections ("that anomaly was actually expected because of the promo")

### Gap: No Automatic Feedback Loop

The learning loop requires manual closing. If a hand flags an anomaly and AJ says "ignore this, it's expected," that correction only persists if:
- AJ tells Hermes in an interactive session (memory updates)
- The hand's state file is manually updated
- A follow-up cronjob is scheduled to process feedback

**Infrastructure needed**: A feedback mechanism where AJ can reply to a hand's output and that reply gets routed back to the hand's state. Could be as simple as: reply to the Telegram message -> Hermes parses it as feedback -> writes to the hand's state file.

---

## 7. Middleman V2: Separate Software, Hermes-Orchestrated

The Middleman V2 spec (`vision/middleman-v2/`) describes a deterministic execution kernel for PR queue management. This is NOT something Hermes cronjobs can replace. It requires:

- FIFO queue ordering with exactly-once processing
- Transactional state transitions with crash recovery
- Worktree management with hard caps (30 per project)
- Branch policy enforcement
- Retry logic with attempt tracking (max 3)
- Idempotency keys

These are properties of deterministic software, not LLM-driven agents. An LLM agent is probabilistic by nature and cannot guarantee FIFO ordering, exactly-once semantics, or transactional state management.

### Hermes's Role with Middleman V2

Hermes is the **orchestration and interaction layer** on top of Middleman V2:

1. **Notification bridge**: Middleman V2 emits events; Hermes translates them into human-readable Telegram messages for AJ.
2. **Command surface**: AJ tells Hermes "retry that PR" or "pause the queue for trw-app"; Hermes calls Middleman V2's API.
3. **Monitoring hand**: A cronjob polls Middleman V2 status and alerts AJ to stuck queues, exhausted retries, or policy violations.
4. **Context provider**: When Middleman V2 needs to create a retry prompt, Hermes can enrich it with session search and memory context.

### Build Sequence for Middleman V2

Middleman V2 is a separate codebase (likely TypeScript or Rust, given the determinism requirements). It exposes an HTTP API. Hermes talks to it via terminal (curl/httpie) or a dedicated MCP server.

This is Phase 2-3 work. It should not block Phase 1 (read-only hands).

---

## 8. MCP as the Integration Layer

Hermes has native MCP (Model Context Protocol) client support. MCP servers can be configured in `config.yaml` and their tools become available to the agent.

### High-Value MCP Servers for the Vision

| Integration | MCP Server | Status | Unlocks |
|---|---|---|---|
| Trello | trello-mcp | Needs setup | Todo system for AJ + wife |
| Google Workspace | google-workspace-mcp | Needs setup | Gmail triage, Calendar briefs |
| Google Sheets | google-sheets-mcp | Needs setup | Finance bookkeeping automation |
| GitHub | github-mcp | Needs setup | PR/issue management, repo access |
| Linear | linear-mcp | Needs setup | Dev team task management |
| PostHog | Custom or API via terminal | Needs build | Product analytics queries |
| Stripe/Payments | Custom via terminal | Existing scripts | Payment monitoring |
| Blofin | Custom via terminal | Needs build | Crypto bot monitoring |

### MCP vs Terminal for Integrations

Many integrations can be done via terminal (curl, scripts, CLI tools) without MCP. MCP provides:
- Structured tool schemas (the LLM knows exactly what parameters are available)
- Better error handling and type safety
- Reusable across sessions without re-explaining APIs

For v1, terminal-based integrations (running existing scripts, curling APIs) are faster to set up. MCP servers are worth building for frequently-used integrations where structured access matters (Trello, Google Workspace, GitHub).

---

## 9. Delegate Task as Parallel Execution

`delegate_task` spawns up to 3 parallel subagents with isolated contexts. Each subagent gets its own tool access and runs independently.

### Use Cases for the Vision

1. **Parallel data gathering**: One subagent queries Mongo, another queries PostHog, a third checks billing -- results merge for the digest.
2. **Independent hand execution**: Multiple hands that don't depend on each other can run simultaneously within a single cronjob.
3. **Research + action split**: One subagent researches a problem while another prepares the action template.

### Limitations
- Max 3 concurrent subagents
- Each subagent has isolated context (they can't talk to each other)
- Subagent results are returned to the parent, which must synthesize
- Default toolsets for delegation: terminal, file, web (configurable)
- Max 50 iterations per subagent

---

## 10. The Hands: Complete Inventory

Mapped from the original vision with Hermes-specific implementation notes.

### TRW Operations Hands

#### hand-trw-signal-ingest
- **Schedule**: Every 6 hours (`0 */6 * * *`)
- **What it does**: Runs the existing `trw-context` scripts (daily-context, daily-health-pg, daily-posthog). Normalizes output into a standard snapshot format. Writes to `~/.hermes/hands/trw-signal-ingest/latest.json`.
- **Tools needed**: terminal (to run scripts), file ops (to write state)
- **Risk tier**: 0 (read-only)
- **Prerequisite**: SSH or local access to TRW databases. The `~/dev/realworld/trw-context` scripts must be runnable from AJ's MBP.

#### hand-trw-anomaly-detect
- **Schedule**: Every 6 hours, offset 30min from signal-ingest (`30 */6 * * *`)
- **What it does**: Reads latest snapshot, compares against baseline windows (7-day, 30-day). Flags: churn spikes, complaint density spikes, event drop-offs, billing failure rate changes, DAU/MAU stickiness decay.
- **Tools needed**: file ops, execute_code (for statistical comparison)
- **Delivery**: Telegram (only if anomalies found; silent otherwise)
- **Risk tier**: 0 (read/report)
- **State file**: `~/.hermes/hands/trw-anomaly/baselines.json` (rolling averages)

#### hand-trw-root-cause-investigator
- **Schedule**: On-demand (triggered by AJ after anomaly alert, or weekly)
- **What it does**: Given an anomaly, runs targeted queries against Mongo, checkoutdb, PostHog. Produces ranked hypotheses with confidence, evidence, and follow-up queries.
- **Tools needed**: terminal (database queries), web (if external factors suspected), delegate_task (parallel query execution)
- **Risk tier**: 0 (read-only investigation)
- **Output schema**: finding, evidence (query refs), confidence (high/medium/low), business impact, proposed action, suggested owner

#### hand-trw-billing-guard
- **Schedule**: Every 4 hours (`0 */4 * * *`)
- **What it does**: Focused monitoring of rebills, failed payments, dispute clusters, net churn delta. Estimates revenue impact of detected issues.
- **Tools needed**: terminal (checkoutdb queries)
- **Delivery**: Telegram (always, even if clean -- brief "all clear" or detailed alert)
- **Risk tier**: 0 initially, escalate to 1 (propose actions) in Phase 2
- **State file**: `~/.hermes/hands/trw-billing/last-check.json`

#### hand-trw-feature-opportunity
- **Schedule**: Weekly (`0 9 * * 1`)
- **What it does**: Mines user feedback for top wants, positive drivers, retention correlation hints. Outputs scoped feature candidates with measurable KPI targets.
- **Tools needed**: terminal (data queries), execute_code (analysis)
- **Risk tier**: 0 (report only)
- **Delivery**: Telegram + file (`~/.hermes/hands/trw-features/weekly-report.md`)

#### hand-trw-exec-digest
- **Schedule**: Daily at 8am (`0 8 * * *`)
- **What it does**: Synthesizes all TRW hand outputs from the last 24 hours into a single leadership report. What changed, why, what to do now. Actionable deltas only -- no noise.
- **Tools needed**: file ops (read other hand state files), execute_code
- **Delivery**: Telegram
- **Risk tier**: 0
- **Dependencies**: Requires signal-ingest, anomaly-detect, and billing-guard to have run

#### hand-trw-qa-sweep
- **Schedule**: Daily (`0 6 * * *`)
- **What it does**: Runs E2E test suite, detects flaky tests, trend report on test health. Integrates Parchi outputs when available.
- **Tools needed**: terminal (run tests on Mac Studios via SSH)
- **Risk tier**: 0
- **Note**: The Mac Studios ($30k) should be the execution target for browser-based E2E testing. Needs SSH backend configuration.

#### hand-trw-release-guard
- **Schedule**: Event-driven (needs webhook bridge) or poll every 30min
- **What it does**: Pre/post deploy smoke tests. Rollback signal if critical tests fail after deploy.
- **Risk tier**: 1 (propose rollback, don't execute)

#### hand-trw-mgmt-status
- **Schedule**: Weekly, Friday 4pm (`0 16 * * 5`)
- **What it does**: Dev throughput digest. PRs merged, issues closed, blockers, velocity trends. For AJ's team-of-4 management cadence.
- **Tools needed**: terminal (GitHub API queries), web (Linear API)
- **Delivery**: Telegram + file
- **Risk tier**: 0

### Finance Hands

#### hand-finance-monitor
- **Schedule**: Every 2 hours (`0 */2 * * *`)
- **What it does**: Poll bank account and crypto wallet balances against thresholds. Emit risk events when below threshold.
- **Tools needed**: terminal (API calls to banking/crypto services)
- **Delivery**: Telegram (alert only when below threshold)
- **Risk tier**: 0 (read-only)
- **Thresholds**: Defined in `~/.hermes/hands/finance/thresholds.yaml`

#### hand-finance-rebalance
- **Schedule**: Triggered by finance-monitor alerts (manually via AJ for now)
- **What it does**: Creates transfer proposal with source, target, amount, reason. Sends to AJ for approval.
- **Risk tier**: 3 (ALWAYS requires approval for money movement)
- **Approval flow**: Proposal sent to Telegram. AJ replies with approval. Hermes executes transfer and logs.
- **Critical constraint**: Idempotency key per transfer window. No duplicate transfers.

#### hand-finance-ledger
- **Schedule**: After every transfer (triggered by rebalance completion)
- **What it does**: Write bookkeeping row to Google Sheets with: date, source, target, amount, reason, approval reference.
- **Tools needed**: Google Sheets MCP or terminal (gsheets CLI)
- **Risk tier**: 1 (write to ledger, but no money movement)

#### hand-tax-rollup
- **Schedule**: Weekly (`0 10 * * 0`)
- **What it does**: Normalize weekly expenses, map to tax categories, append to annual accounting export.
- **Tools needed**: file ops, Google Sheets MCP
- **Risk tier**: 1

#### hand-quarterly-close
- **Schedule**: Monthly on the 1st (`0 9 1 * *`)
- **What it does**: Pre-close checklist, variance report, quarterly estimated payment calculation.
- **Delivery**: Telegram + file
- **Risk tier**: 1 (propose, don't execute payments)

### Personal Admin Hands

#### hand-email-triage
- **Schedule**: Every 2 hours (`0 */2 * * *`)
- **What it does**: Classify incoming email into urgency lanes (critical/action-needed/informational/noise). Forward critical items to Telegram.
- **Tools needed**: Gmail MCP or Google Workspace MCP
- **Risk tier**: 0 (read + classify, no auto-reply)
- **Prerequisite**: Gmail API access via MCP

#### hand-calendar-brief
- **Schedule**: Daily at 7am and 1pm (`0 7,13 * * *`)
- **What it does**: Morning/afternoon agenda with prep notes. Conflict detection.
- **Tools needed**: Google Calendar MCP
- **Delivery**: Telegram
- **Risk tier**: 0

#### hand-task-router
- **Schedule**: Continuous (interactive, not cronjob)
- **What it does**: In interactive sessions, convert AJ's intents ("I need to renew my license plate") into Trello cards with due dates.
- **Tools needed**: Trello MCP
- **Risk tier**: 1 (create cards, don't delete)

#### hand-task-followup
- **Schedule**: Daily at 9am (`0 9 * * *`)
- **What it does**: Check Trello for stale cards, upcoming deadlines. Nudge via Telegram.
- **Tools needed**: Trello MCP
- **Delivery**: Telegram
- **Risk tier**: 0

#### hand-mail-ingest
- **Schedule**: Manual trigger (when AJ scans physical mail)
- **What it does**: OCR scanned mail images, classify (bill/legal/junk), extract deadlines, create Trello cards for action items.
- **Tools needed**: vision_analyze (OCR), Trello MCP
- **Risk tier**: 1

#### hand-social-touch
- **Schedule**: Monthly on the 15th (`0 10 15 * *`)
- **What it does**: Review shortlist of important contacts. Draft one outreach message. Send draft to AJ for review.
- **State file**: `~/.hermes/hands/social/contacts.yaml` (name, last contact date, notes)
- **Delivery**: Telegram
- **Risk tier**: 0 (draft only, AJ sends)

#### hand-knowledge-capture
- **Schedule**: Interactive (not cronjob)
- **What it does**: When AJ shares a link, quote, or insight, capture it to a structured knowledge base.
- **Storage**: Markdown files in `~/notes/` or Obsidian vault
- **Risk tier**: 1 (write files)

#### hand-knowledge-digest
- **Schedule**: Weekly on Sunday (`0 20 * * 0`)
- **What it does**: Synthesize week's captured knowledge. Surface connections. Update retrieval index.
- **Delivery**: Telegram (brief summary) + file (full digest)
- **Risk tier**: 0

#### hand-bible-daily
- **Schedule**: Daily at 6am (`0 6 * * *`)
- **What it does**: Select a verse, pair with a question from a theologian (from a curated list of ~100), seed a discussion prompt.
- **State file**: `~/.hermes/hands/bible/theologians.yaml` (list with rotation tracking)
- **Delivery**: Telegram (to a dedicated bible thread/topic)
- **Risk tier**: 0

### Crypto Hands

#### hand-crypto-watch
- **Schedule**: Every hour (`0 * * * *`)
- **What it does**: Monitor execution health of the quant trading bot. Check: slippage anomalies, strategy drift, position sizes, Blofin API health, taker fee rebate tracking.
- **Tools needed**: terminal (API queries to Blofin, bot health endpoints)
- **Delivery**: Telegram (alert on anomalies, daily summary)
- **Risk tier**: 0 (read-only monitoring)
- **State file**: `~/.hermes/hands/crypto/baselines.json`

---

## 11. Risk Tiers in Practice

| Tier | Policy | Hermes Behavior |
|---|---|---|
| 0 | Read/report only | Cronjob runs, gathers data, delivers report. No side effects. |
| 1 | Propose + queue actions | Cronjob generates proposal, sends to Telegram. No execution without AJ's confirmation in an interactive session. |
| 2 | Auto-execute low-risk | Cronjob can execute: create Trello cards, send emails from drafts, update spreadsheets, create GitHub issues. No money, no destructive ops. |
| 3 | Finance/money = approval gate always | Cronjob proposes transfer. AJ must explicitly approve in interactive session. Idempotency enforced. Full audit trail. |

### Implementing Tier 3 Without clarify

Since cronjobs cannot use `clarify` for mid-execution approval:

1. **Cronjob detects need for action** (e.g., account below threshold)
2. **Cronjob writes proposal** to `~/.hermes/hands/{name}/pending-actions/` with unique ID
3. **Cronjob sends proposal summary** to Telegram via `send_message`
4. **AJ replies in interactive session**: "approve transfer #xyz" or "deny #xyz"
5. **Interactive Hermes reads pending action**, validates, executes, logs
6. **Alternatively**: AJ schedules a one-shot cronjob with the approved action details

This is manual but safe. True inline approval (Telegram inline buttons) would require gateway-level changes.

---

## 12. What Can Be Built Today vs What Needs Infrastructure

### Build Today (No Infrastructure Changes)

These use existing Hermes capabilities as-is:

1. **All Tier 0 hands** -- any read-only monitoring and reporting cronjob
2. **hand-trw-exec-digest** -- daily digest synthesizing data from existing trw-context scripts
3. **hand-trw-anomaly-detect** -- statistical comparison of snapshots
4. **hand-trw-billing-guard** -- database query + threshold check + Telegram alert
5. **hand-bible-daily** -- simple generation + delivery
6. **hand-calendar-brief** -- if Google Calendar API is accessible via terminal
7. **hand-task-followup** -- if Trello API is accessible via terminal
8. **hand-crypto-watch** -- API polling + alert
9. **hand-trw-mgmt-status** -- GitHub API + synthesis
10. **Per-hand state files** -- convention, no code changes needed

### Needs MCP Server Setup (Configuration, Not Code)

1. **Trello MCP** -- unlocks task-router, task-followup
2. **Google Workspace MCP** -- unlocks email-triage, calendar-brief
3. **Google Sheets MCP** -- unlocks finance-ledger, tax-rollup
4. **GitHub MCP** -- enhances mgmt-status, release-guard

### Needs Small Infrastructure Builds

1. **Cron run ledger** -- automatic logging of every cronjob execution (start, end, status, output length). Small addition to cron system.
2. **Webhook-to-cronjob bridge** -- HTTP endpoint that creates one-shot cronjobs. Enables event-driven triggers (GitHub webhooks, deploy notifications).
3. **Hand state management convention** -- documented standard for `~/.hermes/hands/` directory structure.
4. **Feedback routing** -- mechanism to route Telegram replies to hand state files.

### Needs Significant Builds (Phase 2-3)

1. **Middleman V2** -- separate deterministic execution kernel. Significant software project. See Section 7.
2. **Approval queue system** -- for Tier 3 operations. Pending action storage + interactive approval flow.
3. **Mac Studio SSH backend** -- configure SSH access to Mac Studios for E2E test execution. Configuration + networking, not code.
4. **TRW database access** -- ensure AJ's MBP can query Mongo, checkoutdb, PostHog from the terminal. May need tunnels or VPN.

---

## 13. Rollout Plan

### Phase 1: Read-Only TRW Hands (Weeks 1-2)

**Goal**: Prove the cronjob-as-hand pattern works. Get daily value from automated monitoring.

**Build**:
1. Create `~/.hermes/hands/` directory structure
2. Write and schedule 3 cronjobs:
   - `hand-trw-signal-ingest` (runs existing trw-context scripts)
   - `hand-trw-anomaly-detect` (compares snapshots)
   - `hand-trw-exec-digest` (daily morning brief to Telegram)
3. Write hand-specific state file conventions
4. Deliver daily digest to AJ's Telegram every morning

**Validation**:
- AJ receives useful, actionable daily digest for 5 consecutive days
- False positive rate on anomaly detection is tracked
- Run reliability: no missed scheduled runs

**Parallel quick wins**:
- `hand-bible-daily` (simple, high personal value, proves the pattern)
- `hand-crypto-watch` (if Blofin API access is available)

### Phase 2: Guided Actions + Personal Admin (Weeks 3-6)

**Goal**: Add hands that propose actions. Set up MCP integrations for personal admin.

**Build**:
1. Set up Trello MCP, Google Workspace MCP
2. Add hands:
   - `hand-trw-billing-guard` (with revenue impact estimates)
   - `hand-trw-root-cause-investigator` (on-demand)
   - `hand-email-triage`
   - `hand-calendar-brief`
   - `hand-task-followup`
   - `hand-finance-monitor`
3. Build approval queue for Tier 1 actions (Trello card creation, issue filing)
4. Add cron run ledger to track hand execution history

**Validation**:
- No missed critical emails for 2 weeks
- Trello cards created from Telegram working reliably
- Finance monitor correctly identifying low balances

### Phase 3: Selective Autonomy + Middleman (Weeks 7-12)

**Goal**: Enable auto-execution of low-risk actions. Begin Middleman V2.

**Build**:
1. Promote proven Tier 1 hands to Tier 2 (auto-create Trello cards, auto-file GitHub issues)
2. Build approval queue for Tier 3 operations (finance transfers)
3. Start Middleman V2 core (state schema, queue engine, idempotency)
4. Add hands:
   - `hand-finance-rebalance` (with approval gate)
   - `hand-trw-release-guard`
   - `hand-trw-qa-sweep` (on Mac Studios via SSH)
   - `hand-mail-ingest`
   - `hand-knowledge-capture` / `hand-knowledge-digest`
5. Build webhook-to-cronjob bridge for event-driven triggers

**Validation**:
- Tier 2 auto-actions have zero unintended side effects for 2 weeks
- Finance proposals are accurate and properly gated
- Middleman V2 core processes test PR queue correctly

---

## 14. Success Criteria (90 Days)

### TRW
- Recurring bug/leak detection with owner assignment and measurable closure rate
- Daily exec digest with only actionable deltas, delivered by 8am
- Billing anomalies detected within 4 hours, with revenue impact estimates
- Team velocity report delivered weekly without manual effort

### Personal
- No missed critical admin deadlines (tax, DMV, license, bills)
- Email triage running: critical items surfaced to Telegram within 2 hours
- Todo system working via Trello + Telegram
- Bible thread running daily

### Finance
- Low-balance alerts firing reliably
- Transfer proposals generated with proper audit trail
- Quarterly tax prep automated (data gathering, not filing)

### Operations
- At least 50% of recurring reporting and triage done autonomously
- All hands have run ledger entries with reliability metrics
- False positive rate tracked and trending down

### Crypto
- Bot health monitoring running hourly
- Slippage and drift anomalies alerted within 1 hour

---

## 15. What is Fundamentally Different from the Spacebot Vision

### 1. No Separate Infrastructure Layers

The Spacebot vision described separate "Branch (reasoning)" and "Worker (execution)" nodes with a Memory Graph and Task Board. Hermes is one agent loop with one tool registry. The sophistication comes from scheduling, not from custom infrastructure.

### 2. Prompts Replace Specs

In the Spacebot vision, each Hand had a formal spec with structured fields (trigger, inputs, instructions, tools, memory policy, output contract, risk policy). In Hermes, all of this is encoded in the cronjob prompt itself. The prompt IS the spec. This is simpler but requires disciplined prompt engineering.

### 3. Polling Replaces Events

The Spacebot vision assumed event-driven triggers. Hermes is time-based only. This is a real limitation but workable with appropriately frequent polling intervals.

### 4. Files Replace Databases for State

The Spacebot vision implied a sophisticated state management layer. Hermes uses files. State goes in `~/.hermes/hands/{name}/`. This is simpler, more transparent, and audit-friendly, but lacks transactions and concurrent access safety.

### 5. Memory is Organic, Not Engineered

The Spacebot vision described deliberate "memory policy" per hand with retention rules. Hermes memory is organic -- the agent decides what to remember based on conversation. Per-hand state is managed via explicit files, not the memory system.

### 6. Middleman V2 is Acknowledged as Separate

The Spacebot vision blurred the line between the AI orchestration layer and the deterministic execution kernel. This plan is explicit: Middleman V2 is separate software that Hermes orchestrates but does not replace.

### 7. It Exists

The most fundamental difference: Hermes is running. The Spacebot vision was a design document for something that needed to be built. This plan builds on running infrastructure with proven capabilities.

---

## Appendix A: Directory Structure Convention

```
~/.hermes/
  hands/
    trw-signal-ingest/
      state.json          # Latest snapshot metadata
      runs.jsonl          # Run history ledger
    trw-anomaly/
      baselines.json      # Rolling statistical baselines
      runs.jsonl
    trw-billing/
      last-check.json     # Last billing health snapshot
      pending-actions/    # Tier 1+ action proposals
      runs.jsonl
    trw-exec-digest/
      runs.jsonl
    finance/
      thresholds.yaml     # Account balance thresholds
      pending-actions/    # Transfer proposals awaiting approval
      runs.jsonl
    bible/
      theologians.yaml    # Rotation tracking
      runs.jsonl
    social/
      contacts.yaml       # Shortlist with last-contact dates
      runs.jsonl
    crypto/
      baselines.json      # Trading bot health baselines
      runs.jsonl
  skills/
    hands/
      trw-domain/
        SKILL.md
        references/
      finance-domain/
        SKILL.md
      personal-domain/
        SKILL.md
```

## Appendix B: Example Cronjob Prompt (hand-trw-exec-digest)

```
You are running the TRW Executive Digest, a scheduled daily briefing.

PURPOSE: Produce a concise leadership report for AJ (CTO of The Real World) 
covering what changed in the last 24 hours, why it matters, and what to do now.

DATA SOURCES:
1. Read the latest signal-ingest snapshot: ~/.hermes/hands/trw-signal-ingest/state.json
2. Read anomaly detection results: ~/.hermes/hands/trw-anomaly/latest-findings.json
3. Read billing guard results: ~/.hermes/hands/trw-billing/last-check.json
4. Check if any pending actions exist: ~/.hermes/hands/*/pending-actions/

PROCEDURE:
1. Load all data sources above using read_file
2. Identify the top 3-5 most important changes or findings
3. For each finding, assess business impact (revenue, user experience, team velocity)
4. Prioritize by impact and actionability
5. If there are pending actions awaiting approval, list them prominently
6. Write the digest

OUTPUT FORMAT:
Send a message to Telegram with this structure:

TRW Daily Digest - [DATE]

CRITICAL (if any):
- [Finding with impact and recommended action]

NOTABLE:
- [Finding with context]

METRICS:
- DAU: [X] ([trend])
- Churn: [X]% ([trend])  
- Billing health: [status]
- Open incidents: [count]

PENDING APPROVALS: [count or "none"]
- [List if any]

CONSTRAINTS:
- This is a Tier 0 (read-only) operation. Do not execute any actions.
- Be concise. The digest should be readable in 60 seconds.
- Only include actionable deltas. If nothing changed, say "No significant changes" and stop.
- Do not fabricate data. If a data source is missing or empty, note it and move on.

DELIVERY:
Send the digest to Telegram using the send_message tool.

STATE:
After sending, append a run record to ~/.hermes/hands/trw-exec-digest/runs.jsonl:
{"timestamp": "[ISO8601]", "status": "success|partial|failed", "findings_count": N, "delivery": "telegram"}
```

## Appendix C: Mac Studio Utilization Plan

AJ has $30k of Mac Studios sitting idle. Intended uses:

1. **E2E Test Execution**: SSH backend for hand-trw-qa-sweep. Browser-based testing using local LLMs (Kimi, Qwen) for test generation, Mac Studios for execution.
2. **Local LLM Hosting**: Run open-weight models for cost-sensitive cronjob executions. Not all hands need Claude Opus -- many can run on smaller models.
3. **Middleman V2 Workers**: PR processing workers that need full dev environments (node, build tools, test suites).

Configuration needed:
- SSH keys for Hermes to access Mac Studios
- Terminal SSH backend configuration in `~/.hermes/config.yaml`
- Network/firewall setup between MBP and Studios
