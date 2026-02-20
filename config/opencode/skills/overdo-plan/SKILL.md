---
name: overdo-plan
description: Digest a markdown implementation plan into validated Overdo tasks and blockers, then write through Overdo MCP. Use when a user asks to import/specify a plan document.
---

# overdo-plan

Convert markdown plans into Overdo task graphs with validation before mutation.

## Use when

- User asks to ingest/import a plan markdown file.
- User asks to convert a spec into Overdo tasks.

## Required flow

1. Read the target markdown file.
2. Confirm Overdo MCP tools are available in this session.
3. Parse milestones and numbered tasks.
4. Build task graph with blockers and validation gates.
5. Validate the graph before creating any tasks.
6. If valid, write tasks via Overdo MCP only.
7. Return an execution handoff (`/overdo-orchestrate ...`).

## Tool availability gate (must pass first)

Before doing plan work, verify these MCP tools are present:

- `overdo_init`
- `overdo_plan_import`
- `overdo_task_list` (or `overdo_task_progress`)

If any are missing:

- Stop immediately.
- Return `Mutation status: not applied`.
- Report: `Overdo MCP not attached in this session; restart OpenCode session after install.`
- Do not use shell commands as a substitute for MCP writes.

## MCP tools to call (required)

Use Overdo MCP tools, not ad-hoc state mutation:

1. `overdo_init` (if DB may not exist yet)
2. `overdo_plan_import` with `markdownPath` and optional `dbPath`
3. `overdo_task_list` or `overdo_task_progress` for post-import verification

`overdo_plan_import` is the canonical import path and should create the full task tree (tasks + blockers) in one operation.

## Validation rules (must pass before MCP writes)

- At least one milestone task must exist.
- Every blocker reference must resolve to an existing task ID.
- No task can block itself.
- Dependency graph must be acyclic.
- Gates must be restricted to: `lint`, `unit`, `integration`, `e2e`.

## Failure behavior

- If validation fails, do not write anything through MCP.
- Return a concise error list with exact blocker/task IDs that failed.
- Suggest the minimum markdown edits needed to make the import valid.

## Output format

- **Plan source:** file path used.
- **Validation:** pass/fail plus concrete issues.
- **Task payload preview:** task IDs, titles, blockers, gates.
- **Mutation status:** `applied` or `not applied`.
- **Next step:** exact `/overdo-orchestrate ...` command when applied.

## Example invocation

`/overdo-plan docs/specs/feature-x/SPEC.md --db .overdo/tasks.db`
