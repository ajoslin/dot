---
name: overseer-orchestrate
description: Execute an Overseer parent task by delegating children to subagents with hard-retry resilience, commit checkpoint validation, and interruption-safe resume after comment/review detours.
license: MIT
references:
  - references/flow.md
---

# Overseer Orchestrate

Execute an Overseer parent task to completion by delegating each child task to a subagent and retrying non-catastrophic failures. Overseer is the only task system used for orchestration state.

## Use When

- Running `/overseer_orchestrate` for a parent task with depth=1 children.
- Needing interruption-safe execution when comment/review work temporarily preempts orchestration.
- Needing deterministic retries until true completion across all child tasks.

## Parameters

- `taskRef` (required): Overseer parent task ID (`task_...`) or title/search text.

## Execution Contract

1. Resolve parent task from `taskRef`.
2. Load or initialize persistent run state at `.overseer/{parent.id}/state.json`.
3. Fetch all depth=1 children for the parent and depth=2 subtasks for each child.
4. For each incomplete child: start task, write context, detect agent, spawn subagent via `task`, retry until verified completion and commit checkpoint validation.
5. Persist attempt history and last error after every failed attempt.
6. Mark parent complete only after all children complete.

## Usage

```
/overseer_orchestrate task_01JQAZ1234567890ABCDEF
/overseer_orchestrate "Implement user authentication"
```

## Commit Hardening Rules

- Treat commit cadence as mandatory verification, not optional hygiene.
- For each child task, require at least one new commit authored during that child's execution window.
- Require checkpoint commits during long-running child execution:
  - at least every 20-30 minutes, or
  - after each meaningful green checkpoint (tests/build/typecheck passing).
- If code changed but no commit was produced, classify as recoverable failure and retry the child with a commit-first instruction.
- If commit is blocked by hooks or failing checks, subagent must fix the blocker and create a new commit before claiming completion.
- If a child is genuinely blocked and cannot commit, persist the blocker in run state and keep that child incomplete.

## Task Spawn Prompt Template

Use this shape when delegating each child via `task`:

```javascript
await task({
  subagent_type: agent,
  description: `Execute ${child.id}`,
  prompt: [
    `Read @file ${ctxFile}.`,
    `Then execute ${child.id} attempt ${attempt} to completion. Commit at meaningful checkpoints (at least every 20-30 minutes) and include at least one commit for this child before declaring done. Do not mark Overseer tasks complete; orchestrator handles completion.`
  ].join("\n")
});
```

## Interruption and Resume

- Treat comment/review requests as temporary detours, not orchestration completion.
- Flush run state before switching context.
- Resume with `/overseer_orchestrate {parentId}`.
- Continue from `.overseer/{parentId}/state.json`; do not restart completed children.

## Agent Selection

- Default agent: `build`.

- Override if task text contains:
  - `delegate to @agent-name`
  - `use @agent-name`
  - `@agent-name` token
  - `agent: agent-name` in context

## Flow

Follow [references/flow.md](./references/flow.md) for implementation details:
- `overseerOrchestrate()` - main execution flow
- `resolveParent()` - parent lookup by argument
- `classifyError()` - retryable/recoverable/catastrophic classification

## Subagent Responsibility

Each subagent:
- Reads the context file via `@file`
- Implements everything described
- Commits frequently during execution and produces at least one commit tied to the delegated child task
- Does not pause for questions; makes reasonable assumptions
- Executes to completion with retries on transient/recoverable failure
- Leaves completion marking to the orchestrator

## Error Handling

Classify each failure:

1. **Retryable**: timeout, flaky test, transient tool/API/network failure
2. **Recoverable**: context mismatch, conflict, partial implementation requiring strategy change
3. **Catastrophic**: irrecoverable Overseer/MCP corruption, repository unusable, filesystem unavailable, explicit user cancellation

For retryable/recoverable failures:
1. Log and persist error in run state
2. Apply recovery strategy (backoff, regenerate context, switch agent or prompt strategy)
3. Retry until success
4. Never mark child complete from failure path

For catastrophic failures:
1. Persist failure details to run state
2. Stop orchestration immediately
3. Leave unfinished tasks incomplete for resumable recovery

Watchdog policy:
1. Track `lastProgressAt` in run state
2. If no successful child completion for a long threshold, classify run as catastrophic
3. Tune threshold to environment (default: 45 minutes)

The goal is guaranteed progress to true completion, not premature closure.
