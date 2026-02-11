---
name: overseer-orchestrate
description: Execute an Overseer parent task by delegating all children to subagents. Simple, non-blocking execution.
license: MIT
references:
  - references/flow.md
---

# Overseer Orchestrate

Execute an Overseer parent task by delegating each child task to a subagent. No pausing, no questions, just execution.

## Execution Contract

1. Get parent task from Overseer (by ID or title search)
2. For each **child** (depth=1) of the parent:
   - Write context to a file
   - Determine agent (custom if mentioned in task, otherwise "build")
   - Spawn subagent with context file
   - Wait for completion
   - Mark task complete
   - Ensure all work is committed to the original branch
3. Continue until all children done
4. Mark parent complete

## Usage

```
/overseer_orchestrate task_01JQAZ1234567890ABCDEF
/overseer_orchestrate "Implement user authentication"
```

## Parameters

- `taskRef` (required): Overseer task ID (`task_...`) or task description/title to search for

## Agent Selection

**Default**: `"build"`

**Override**: Task description mentions an agent name:
- `delegate to @agent-name`
- `use @agent-name`
- `@agent-name` anywhere in description
- `agent: agent-name` in context

## Flow

See [references/flow.md](./references/flow.md) for complete implementation details including:
- `overseerExecute()` - main execution flow
- `detectAgent()` - agent name extraction
- `writeContext()` - context file generation
- `findTask()` - task lookup by ID or search

## Subagent Responsibility

Each subagent:
- Reads the context file via `@file`
- Implements everything described
- **Does not pause for questions** - makes reasonable assumptions
- Executes to completion
- Orchestrator verifies completion and marks task done

## No Pausing

This skill does **not**:
- Ask for user confirmation
- Stop for "blockers"
- Prompt about PR creation
- Wait for external approvals

It runs start to finish autonomously.

## Error Handling

If a subagent fails:
1. Log the error
2. Retry once with same context
3. If still failing, mark task complete with error note and continue
4. Parent task result will include which children had errors

The goal is always progress, not perfection.
