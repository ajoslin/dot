---
name: overseer-orchestrate
description: Execute an Overseer parent task by delegating children to subagents with hard-retry resilience, TodoWrite mirroring, parent/subagent session task-list seeding, and interruption-safe resume after comment/review detours.
license: MIT
references:
  - references/flow.md
---

# Overseer Orchestrate

Execute an Overseer parent task to completion by delegating each child task to a subagent, retrying non-catastrophic failures, mirroring Overseer status into TodoWrite, and pre-seeding parent and subagent session task lists.

## Use When

- Running `/overseer_orchestrate` for a parent task with depth=1 children.
- Needing interruption-safe execution when comment/review work temporarily preempts orchestration.
- Needing a TodoWrite mirror that exposes stable Overseer lookup references.
- Needing each spawned subagent to start with a seeded session task list built from Overseer child subtasks.

## Parameters

- `taskRef` (optional): Overseer parent task ID (`task_...`) or title/search text.
- If `taskRef` is omitted, resume from TodoWrite by finding the active `ovr-parent-*` entry.

## Execution Contract

1. Resolve parent task from `taskRef`; if missing, recover parent ID from TodoWrite mirror.
2. Load or initialize persistent run state at `.overseer/{parent.id}/state.json`.
3. Fetch all depth=1 children for the parent and depth=2 subtasks for each child.
4. Upsert TodoWrite mirror entries for parent and every child while preserving unrelated todos.
5. Pre-seed parent session todos that reflect orchestration work planned for this run.
6. For each incomplete child: start task, write context, detect agent, build subagent todo seed from child+subtasks, spawn subagent via `task`, retry until verified completion.
7. Persist attempt history and last error after every failed attempt.
8. Refresh mirror and parent session todo statuses after every state change (start, retry, completion, catastrophic abort).
9. Mark parent complete only after all children complete; then mark mirrored parent todo complete.

## Usage

```
/overseer_orchestrate task_01JQAZ1234567890ABCDEF
/overseer_orchestrate "Implement user authentication"
/overseer_orchestrate
```

The third form resumes from an active mirror entry in TodoWrite.

## TodoWrite Mirror Rules

- Use stable IDs:
  - Parent: `ovr-parent-{parentId}`
  - Child: `ovr-child-{childId}`
- Encode Overseer references in `content`:
  - Parent: `[overseer-parent:{parentId}] resume:/overseer_orchestrate {parentId}`
  - Child: `[overseer-task:{childId}] parent:{parentId}`
- Map status:
  - Overseer complete -> `completed`
  - Current executing child -> `in_progress`
  - Remaining incomplete children -> `pending`
  - Overseer cancelled -> `cancelled`
- Map priority: Overseer `2|1|0` -> TodoWrite `high|medium|low`.
- Preserve non-`ovr-*` todos on each mirror update.

## Session Task List Rules

- Keep Overseer as the source of truth for real completion state.
- Maintain a second TodoWrite view for session execution guidance:
  - Parent run-plan IDs: `ovr-run-{parentId}-*`.
  - Subagent seed IDs: `ovr-sub-{childId}-*` (inside the spawned subagent session).
- Seed parent run-plan todos before processing children, then update them as execution advances.
- Seed subagent todos immediately at subagent start from known Overseer subtasks (or fallback plan items when no subtasks exist).
- Spawn subagents with the `task` tool prompt that includes explicit `todowrite` seed payload.
- Preserve unrelated todos in every `todowrite` write; only replace orchestrate-managed IDs.

## Task Spawn Prompt Template

Use this shape when delegating each child via `task` so subagent todo seeding is deterministic:

```javascript
await task({
  subagent_type: agent,
  description: `Execute ${child.id}`,
  prompt: [
    `Read @file ${ctxFile}.`,
    "Before implementation, call todowrite exactly once with this seed payload:",
    "```json",
    JSON.stringify(seedTodos, null, 2),
    "```",
    `Then execute ${child.id} attempt ${attempt} to completion. Keep exactly one todo in_progress. Do not mark Overseer tasks complete; orchestrator handles completion.`
  ].join("\\n")
});
```

`seedTodos` must be the precomputed `ovr-sub-{childId}-*` list derived from Overseer subtasks (or fallback plan items when no subtasks exist).

## Expected Runtime Behavior

For parent `task_parentA` with children `task_child1`, `task_child2`, mirror entries look like:

```json
[
  {
    "id": "ovr-parent-task_parentA",
    "content": "[overseer-parent:task_parentA] resume:/overseer_orchestrate task_parentA",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "id": "ovr-child-task_child1",
    "content": "[overseer-task:task_child1] parent:task_parentA Implement API",
    "status": "in_progress",
    "priority": "medium"
  },
  {
    "id": "ovr-child-task_child2",
    "content": "[overseer-task:task_child2] parent:task_parentA Add tests",
    "status": "pending",
    "priority": "medium"
  }
]
```

After a comment/review detour, scan TodoWrite for `ovr-parent-*` with `in_progress`, extract parent ID, and continue with `/overseer_orchestrate {parentId}`.

## Interruption and Resume

- Treat comment/review requests as temporary detours, not orchestration completion.
- Flush run state and TodoWrite mirror before switching context.
- After detour completion, inspect TodoWrite for an `ovr-parent-*` item in `in_progress`.
- Resume with `/overseer_orchestrate {parentId}` from that mirror reference.
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
- `syncTodoMirror()` - TodoWrite upsert logic
- `resolveParent()` - parent lookup by argument or mirror entry
- `classifyError()` - retryable/recoverable/catastrophic classification

## Subagent Responsibility

Each subagent:
- Calls `todowrite` first to install the seeded `ovr-sub-*` list from orchestrator prompt payload.
- Reads the context file via `@file`
- Implements everything described
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
