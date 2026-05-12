# `/goal` Plugin Full Specification (OpenCode Harness)

## 1) Scope and Objective

This specification defines a production-ready `/goal` command plugin for OpenCode, targeting the local harness under:

- `/Users/andrew/dot/config/opencode/plugin/`

The plugin mirrors the behavior and architecture of the `openai/codex` goal system **within reason** for an OpenCode plugin environment.

Primary outcomes:

1. Add a robust `/goal` command family (`/goal`, `/goal <objective>`, `/goal pause|resume|clear`)
2. Persist goal state per session/thread
3. Support status transitions and usage accounting metadata
4. Mirror high-value Codex test behaviors 1:1 where platform constraints allow
5. Keep architecture deep, testable, and AI-navigable

---

## 2) Source of Truth and Behavioral Reference

Behavioral source: `openai/codex` repository, especially:

- TUI slash command parsing/dispatch
- goal state/runtime management
- tool contracts and goal lifecycle constraints
- app-server goal APIs and examples
- templates used for continuation/budget-limited behavior
- tests around slash command semantics and queued behavior

OpenCode harness constraint: this is plugin-level integration, so we implement equivalent semantics via OpenCode event hooks and local persistence.

---

## 3) Glossary (architecture vocabulary)

- **Module**: a unit with interface + implementation.
- **Interface**: what callers depend on (types, invariants, error behavior).
- **Implementation**: internal mechanics.
- **Depth**: high leverage behind a small interface.
- **Seam**: place where behavior can change without invasive edits.
- **Adapter**: concrete implementation at a seam.
- **Locality**: changes and bugs stay concentrated.
- **Leverage**: capability exposed to callers with low complexity.

---

## 4) Functional Requirements

## 4.1 Supported commands

1. `/goal`
   - If goal exists: show summary (status, objective, usage, command hints)
   - If no goal: show usage + no-goal message
2. `/goal <objective...>`
   - Set or replace goal objective
3. `/goal pause`
   - Set status to `paused`
4. `/goal resume`
   - Set status to `active`
5. `/goal clear`
   - Remove goal

## 4.2 Command parsing behavior

- Control words recognized case-insensitively: `clear`, `pause`, `resume`
- Any other non-empty argument string after `/goal` is objective text (no flag parser)
- Objective text is trimmed before validation

## 4.3 Validation

- Objective must be non-empty for set/replace
- Objective max length: **4000 chars**
- `tokenBudget` (if exposed in any setter path) must be positive

## 4.4 Status model

Allowed statuses:

- `active`
- `paused`
- `budget_limited`
- `complete`

User command transitions:

- `/goal pause` -> `paused`
- `/goal resume` -> `active`
- `/goal clear` -> deleted state

System transitions:

- May set `budget_limited` when usage/budget policy indicates

Completion policy (if model-tool parity path is implemented):

- Completion should be explicit and only when objective is achieved

## 4.5 Thread/session readiness and queueing

- If `/goal <objective>` occurs before session/thread is ready, queue command intent and replay once ready
- Bare `/goal` and control commands should not silently submit as user prompt text

---

## 5) Data Model

Per session/thread id:

```ts
type GoalStatus = "active" | "paused" | "budget_limited" | "complete";

type GoalEntry = {
  goalId: string;
  threadId: string;
  objective: string;
  status: GoalStatus;
  tokenBudget: number | null;
  tokensUsed: number;
  timeUsedSeconds: number;
  createdAt: number;
  updatedAt: number;
};
```

Persistence file:

- `${projectRoot}/.opencode/state/goals.json`

State container:

```ts
type GoalStateFile = {
  sessions: Record<string, GoalEntry>;
};
```

---

## 6) Architecture

## 6.1 High-level shape

```text
OpenCode Events/Commands
        |
        v
goal.ts (plugin adapter)
        |
        v
goal-orchestrator.ts (deep module)
   |             |
   v             v
goal-state.ts    goal-ui.ts
   |
   v
.opencode/state/goals.json
```

## 6.2 Module boundaries

File layout constraint:

- The only file that belongs directly in `.config/opencode/plugin/` is the plugin entrypoint: `.config/opencode/plugin/goal.ts`.
- All supporting implementation files belong under `.config/opencode/plugin/goal/`, for example `goal/goal-orchestrator.ts`, `goal/goal-state.ts`, `goal/goal-ui.ts`, `goal/goal-parse.ts`, `goal/goal-usage.ts`, and test infrastructure files.
- The entrypoint should stay thin: register hooks, extract events, and delegate into modules under `plugin/goal/`.

1. `goal.ts` (adapter seam)
   - Hook registration
   - Event extraction
   - Delegate to orchestrator

2. `goal-orchestrator.ts` (deep module, primary interface)
   - Parse command intents
   - Enforce validation + transitions
   - Decide effects (toast, prompt, state mutation)
   - Queue/replay behavior

3. `goal-state.ts` (persistence adapter)
   - Read/write/prune state file
   - No business policy logic

4. `goal-ui.ts` (render adapter)
   - Summary strings
   - Usage/help strings
   - Command hints by status

5. `goal-parse.ts` (input normalization)
   - Parse `/goal` forms into typed command values

6. `goal-usage.ts` (optional helper module)
   - Time/tokens update arithmetic
   - Budget-limited checks

Production constraint:

- `goal.ts` is the only production OpenCode runtime seam.
- Production code must use OpenCode plugin hooks/events directly; it must not require the OpenCode SDK as a runtime dependency.
- Any OpenCode SDK/server wrapper belongs to test infrastructure only.

## 6.3 Test infrastructure seam

1. `opencode-test-adapter.ts` (integration harness only)
   - Wrap the real OpenCode SDK/server session APIs behind a narrow test interface
   - Expose session lifecycle, command dispatch, interrupt, idle, and message/result observation primitives for integration tests
   - Exercise the same orchestrator interface that `goal.ts` calls from production plugin hooks
   - Keep SDK/server orchestration out of production plugin modules

## 6.4 Why this is deep

- Single interface concentrates goal policy
- Adapters stay shallow and replaceable
- Tests hit orchestrator behavior without requiring UI transport
- Deletion test: removing orchestrator would force logic duplication in hooks/tests

---

## 7) Plugin Interface Contract

## 7.1 Inputs observed

- `command.executed` events (for slash command detection)
- session lifecycle/status events (for queue replay and accounting triggers)
- optional message/task events for activity timestamps

## 7.2 Outputs/effects

- User-facing notifications/info messages
- Optional prompt injections (if continuation mode enabled)
- Goal state mutation in `.opencode/state/goals.json`

## 7.3 Error handling

- Validation errors are user-visible, non-fatal
- Persistence failures surface warning/toast and fail closed (no partial in-memory-only success)
- Unknown command forms return usage hints

---

## 8) Detailed Behavioral Spec

## 8.1 `/goal` (bare)

If session has goal:

- Show:
  - `Goal`
  - `Status`
  - `Objective`
  - `Time used`
  - `Tokens used`
  - `Token budget` (if present)
  - command hints by current status

If session has no goal:

- Show usage: `Usage: /goal <objective>`
- Hint: no goal currently set

---

## 9) 2026-05-07 Parity Spike Notes

Verified OpenCode runtime:

- `opencode --version` -> `1.14.41`
- Focused verification command: `bun test plugin/goal`
- Live harness starts OpenCode through `@opencode-ai/sdk` `createOpencode(...)` with `plugin: [file:///.../plugin/goal.ts]`.
- Live tool registration check calls `client.tool.ids({ query: { directory } })` against the spawned OpenCode server and observed `get_goal`, `create_goal`, and `update_goal`.

OpenCode API/source checked before implementation:

- Installed plugin types: `node_modules/@opencode-ai/plugin/dist/index.d.ts`
  - Plugin hook shape includes `event`, `tool`, `tool.execute.before/after`, `command.execute.before`, and chat transform hooks.
- Installed tool types: `node_modules/@opencode-ai/plugin/dist/tool.d.ts`
  - Tool registration uses `tool({ description, args, execute(args, context) })`.
  - Tool context includes `sessionID`, `messageID`, `directory`, `worktree`, `agent`, `abort`, and metadata helpers.
- Installed SDK event types: `node_modules/@opencode-ai/sdk/dist/gen/types.gen.d.ts`
  - `message.updated` carries `properties.info`.
  - assistant messages carry aggregate `tokens`.
  - `step-finish` parts carry per-step token totals.
  - `session.status` and `session.idle` are plugin-visible events.
- Installed SDK tool endpoints: `node_modules/@opencode-ai/sdk/dist/gen/sdk.gen.d.ts`
  - `client.tool.ids(...)` lists dynamically registered tools from a real OpenCode runtime.

Codex behavioral source checked:

- `https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/src/goals.rs`
  - Runtime lifecycle owns accounting, continuation, budget steering, external mutations, and interrupt pause behavior.
- `https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/templates/goals/continuation.md`
  - Continuation steering is template-backed and objective-aware.
- `https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/templates/goals/budget_limit.md`
  - Budget-limit steering summarizes instead of starting new work.
- `https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/src/tools/handlers/goal.rs`
  - Completion is model-tool driven, not inferred from assistant text.

Implemented Codex-like behavior:

- Versioned state file: `{ version: 1, sessions }`, with backward-compatible migration from legacy `{ sessions }`.
- Goal entries retain completed goals until `/goal clear`.
- Completion requires `update_goal` with `status: "complete"` and non-empty audit.
- Interrupt events persist active goals as `paused` with `pausedReason: "interrupted"`.
- Ordinary user messages after interrupt do not resume goals.
- `/goal resume` resumes explicitly, clears pause reason, and injects rich continuation steering.
- Idle continuation uses rich template rendering with `<untrusted_objective>`, usage/budget fields, and `update_goal` instructions.
- Budget-limit steering fires once per goal ID and does not start new substantive work.
- Message token accounting uses real assistant token totals where plugin-visible, with idempotent per-message deltas.
- Runtime guards track in-flight continuations, goal replacement, budget-limit reporting, and 30s debounce.

Integration coverage boundary:

- The live harness verifies that model tools are registered in an actual spawned OpenCode runtime and that real OpenCode command events flow through `client.event.subscribe(...)`.
- OpenCode does not expose a public SDK endpoint for executing an arbitrary model tool by name outside a model turn, so exact `get_goal`, `create_goal`, and `update_goal` handler semantics are covered by executing the registered plugin tool definitions directly with an OpenCode-shaped tool context.
- Provider-voluntary tool selection is intentionally not a deterministic test gate because it depends on configured model/provider behavior rather than plugin correctness.

## 8.2 `/goal <objective>`

1. Trim objective
2. Validate non-empty and length <= 4000
3. If session not ready, queue for replay
4. If existing goal with same objective and non-terminal status:
   - update status/budget metadata only
5. Else replace/create goal:
   - new `goalId`
   - reset `tokensUsed = 0`, `timeUsedSeconds = 0`
   - `status = active`

## 8.3 `/goal pause`

- Requires existing session/thread
- If goal exists: set status `paused`
- If no goal: user-visible message

## 8.4 `/goal resume`

- Requires existing session/thread
- If goal exists: set status `active`
- If no goal: user-visible message

## 8.5 `/goal clear`

- Delete goal entry for session
- Idempotent: if missing, report no goal to clear

## 8.6 Budget policy

- If `tokenBudget` exists and `tokensUsed >= tokenBudget`, set `budget_limited`
- In `budget_limited`, command hints should only advertise `clear` unless resumed policy explicitly allows user `resume`

## 8.7 Completion policy

- If completion path is added, completion must only be applied when objective is achieved
- Completion should not be used as a generic stop signal

---

## 9) Templates (optional parity path)

If autonomous continuation behavior is added, include:

1. `continuation` template
   - Continue concrete next action
   - Audit completion against objective
   - Avoid false-completion proxies

2. `budget_limit` template
   - Do not start substantive new work
   - Summarize progress, blockers, next step

Store templates in:

- `plugin/goal/templates/continuation.md`
- `plugin/goal/templates/budget_limit.md`

---

## 10) Test Strategy (mirror Codex within reason)

Framework: `bun:test`

## 10.1 Test files

- `plugin/goal/goal.e2e.test.ts`
- `plugin/goal/goal-state.test.ts`
- `plugin/goal/goal-parse.test.ts`
- `plugin/goal/goal-ui.test.ts`

## 10.2 1:1 mirror targets

1. `/goal <objective>` emits set-goal intent
2. Mentions remain plain objective text
3. Attachments are not treated as regular prompt payload for goal-setting
4. Bare `/goal` drains pending submission artifacts
5. `/goal clear|pause|resume` emit correct state mutations
6. Queued `/goal <objective>` before session-start replays after start
7. Queued replay preserves current draft metadata
8. Restored queued state still replays correctly

State/runtime parity tests:

9. Insert does not overwrite without replace path
10. Replace resets usage counters
11. Update status preserves usage
12. Budget must be positive when provided
13. Budget crossing triggers `budget_limited`
14. Pause/resume transitions are valid
15. Clear is idempotent
16. Objective empty rejected
17. Objective >4000 rejected

## 10.3 Real OpenCode integration pass/fail harness

The final test layer must run against real OpenCode behavior, not only synthetic command fixtures. The harness may use OpenCode SDK/server APIs through test-only `opencode-test-adapter.ts`, but the production plugin must still run through `goal.ts` and OpenCode plugin hooks/events. The purpose of the test adapter is to drive a real runtime and exercise the same orchestrator interface that production hooks call into, not to replace the plugin architecture.

Target test file:

- `plugin/goal/goal.integration.test.ts`

Harness responsibilities:

1. Start an isolated OpenCode server/runtime with the `/goal` plugin loaded
2. Create or attach to a real session/thread
3. Send `/goal` commands through the same pathway a user command uses
4. Observe real lifecycle events, assistant activity, idle transitions, interrupt behavior, and persisted `.opencode/state/goals.json`
5. Tear down the server/runtime and temporary project state after each scenario

Required pass/fail model:

- Assertions must be **behavioral and qualitative**, not deterministic text snapshots of LLM output.
- The harness should check observable capabilities and invariants:
  - Can a goal be started from a real session?
  - Does persisted state contain the expected objective, status, timestamps, and usage metadata?
  - Does `/goal` status reporting work without submitting unintended prompt text?
  - Do `pause`, `resume`, and `clear` mutate state correctly through the real production plugin path?
  - Does queued goal setup replay when a session becomes ready?
  - Does malformed state fail closed and recover to normalized state without losing unrelated sessions?
  - Does idle continuation occur when the session goes idle with an active goal and remaining budget?
  - Does an explicit interrupt stop the current activity and **not** silently auto-continue unless the user or policy explicitly resumes it?
  - Does budget exhaustion move the goal to `budget_limited` and prevent substantive continuation?
  - Does a resumed active goal continue from persisted context after runtime restart?

Recommended scenario suite:

1. **Start and persist**: spawn runtime, create session, send `/goal write a short plan`, verify active state and visible acknowledgement.
2. **Status is informational**: send bare `/goal`, verify no regular prompt submission occurred and status metadata is shown/observable.
3. **Lifecycle replay**: submit `/goal <objective>` before ready, mark session ready, verify queued intent replays once.
4. **Idle continuation**: start a small multi-step goal, wait for runtime idle, verify a continuation action is scheduled or prompt injection occurs through the production plugin path.
5. **Interrupt boundary**: interrupt an active run, verify no automatic continuation happens solely because of the interrupt.
6. **Pause/resume**: pause suppresses continuation on idle; resume allows continuation again.
7. **Budget limit**: configure a small token budget, cross it, verify `budget_limited` and no new substantive work starts.
8. **Restart recovery**: stop and restart runtime, attach to existing session, verify active goal state is recovered and can continue.
9. **Clear idempotency**: clear twice through real commands, verify first deletes and second reports no goal without error.

The harness should expose a compact result contract for each scenario:

```ts
type GoalIntegrationResult = {
  scenario: string;
  passed: boolean;
  observedEvents: string[];
  stateAssertions: string[];
  qualitativeAssertions: string[];
  failureReason?: string;
};
```

This integration layer complements the plugin adapter and orchestrator test suites. Unit tests may use fake plugin events for deterministic edge cases, but the final pass/fail gate must prove real OpenCode startup, plugin hook registration, session lifecycle, continuation policy, and persistence path work together. SDK/server helpers are allowed only as test drivers.

---

## 11) Non-Functional Requirements

1. **Deterministic behavior**: no hidden side effects in parser/state modules
2. **Testability**: orchestrator is pure or near-pure with injectable clock/persistence
3. **Locality**: all business rules in orchestrator, not spread in hooks
4. **Backwards safety**: plugin should fail closed on malformed state file, and recover by rewriting normalized state
5. **Low coupling**: plugin must not depend on unrelated command plugins

---

## 12) Implementation Plan

1. Create domain types + parser + validators
2. Implement state adapter (`goals.json` read/write/normalize)
3. Implement orchestrator and effect model
4. Wire plugin hooks in `goal.ts`
5. Add summary/help renderer
6. Build full mirrored tests
7. Build test-only real OpenCode SDK/server integration harness
8. Validate with `bun test` suite, including the real integration gate where runtime prerequisites are available

---

## 13) Risks and Mitigations

1. **Event model mismatch vs Codex**
   - Mitigation: keep command parsing isolated and test against synthetic event fixtures
2. **State corruption / partial writes**
   - Mitigation: atomic write pattern + normalization on read
3. **Behavior drift from Codex semantics**
   - Mitigation: test names and assertions intentionally mapped to codex-goal scenarios

---

## 14) Acceptance Criteria

A. `/goal` command family works end-to-end with persisted state
B. Validation and transitions match this spec
C. Mirrored test suite passes (within OpenCode constraints)
D. Architecture keeps one deep module with clear seams and adapters
E. Spec is kept as the implementation contract for future iterations
F. Real OpenCode integration harness passes qualitative lifecycle, idle, interrupt, persistence, and continuation checks
