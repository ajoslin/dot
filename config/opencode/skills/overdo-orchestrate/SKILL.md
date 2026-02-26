---
name: overdo-orchestrate
description: Execute an existing Overdo task graph safely via MCP with lease-aware dispatch, validation loops, retries/escalation, and resumable progress.
---

# overdo-orchestrate

Run Overdo task graphs to completion using MCP as the only mutation boundary.

## Use when

- User asks to run/continue an imported plan.
- User asks to recover after interruption or failure.

## Required flow

1. Confirm Overdo MCP tools are available in this session.
2. Read next ready task(s) from Overdo.
3. Claim work with lease-safe dispatch.
4. Execute required gates (`lint`, `unit`, `integration`, `e2e`).
5. Record loop iteration and decision (`retry`, `escalate`, `complete`).
6. Apply task transitions and release leases.
7. Enqueue/process commit via commit coordinator.
8. Emit concise progress + evidence summary.

## Tool availability gate (must pass first)

Before orchestration, verify these MCP tools are present:

- `overdo_task_next_ready`
- `overdo_task_start`
- `overdo_task_complete`
- `overdo_task_progress`
- `overdo_orchestrate_autocontinue`

If any are missing:

- Stop immediately.
- Report that Overdo MCP is not attached for this session.
- Do not orchestrate via ad-hoc shell commands.

## MCP tools to call (required)

Use Overdo MCP tools directly for orchestration:

1. `overdo_task_next_ready`
2. `overdo_task_start`
3. `overdo_task_complete`
4. `overdo_task_progress`
5. `overdo_orchestrate_autocontinue` for continuous advancement without manual step-by-step prompts

When user asks for "autocontinue", prefer `overdo_orchestrate_autocontinue` with a bounded `maxSteps` and report progress after each run.

## Guardrails

- Never mutate orchestration state outside MCP.
- Respect task blockers/dependency ordering.
- Persist every failed attempt with artifact/repro details.
- Resume from current SQLite state first; do not reinitialize existing DB.
- Keep commit processing serialized (single commit owner at a time).

## Failure behavior

- On gate failure, record iteration and retry only within policy limits.
- On exhausted retries, escalate with actionable failure context.
- On crash/restart, continue from persisted state rather than replaying manual steps.

## Output format

- **Active task(s):** claimed IDs and worker owner.
- **Gate results:** pass/fail per required gate.
- **Loop decision:** retry/escalate/complete with reason.
- **State updates:** transitions, lease release, commit queue status.
- **Next action:** exact command/prompt to continue.

## Example invocation

`/overdo-orchestrate --db .overdo/tasks.db --autocontinue`
