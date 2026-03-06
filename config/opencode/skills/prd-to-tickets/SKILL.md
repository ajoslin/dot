---
name: prd-to-tickets
description: Break a PRD into independently-grabbable Linear tickets using tracer-bullet vertical slices, grouped under a parent ticket with child subtickets.
---

# PRD to Tickets

Break a PRD into independently-grabbable Linear tickets using vertical slices (tracer bullets).

## Process

### 1. Locate the PRD

Ask where the PRD lives (doc URL, markdown file path, GitHub issue/PR, Notion page, or pasted text).

If the PRD is not in context, fetch or read it first.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand current constraints and integration points.

### 3. Draft vertical slices

Break the PRD into tracer-bullet slices. Each slice should be a thin end-to-end path through all layers, not a horizontal layer-only task.

Slices may be `HITL` or `AFK`.

- `HITL`: requires human interaction (architecture/design/policy sign-off)
- `AFK`: can be implemented and merged without human interaction

Prefer `AFK` where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but complete path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: `HITL` or `AFK`
- **Blocked by**: required preceding slices, if any
- **User stories covered**: which PRD user stories this slice addresses

Ask:

- Does granularity feel right? (too coarse or too fine)
- Are dependency relationships correct?
- Should slices be merged or split further?
- Are `HITL` and `AFK` marks correct?

Iterate until approved.

### 5. Create Linear parent ticket + subtickets via MCP

Use the Linear MCP to create tickets.

Default hierarchy:

1. Create one parent ticket representing the PRD rollout.
2. Create one child subticket per approved slice.
3. Link all child tickets to the parent.
4. Add dependency links between child tickets (`blocked by`) where needed.

If the workspace does not support hierarchy, fall back to:

- shared project
- shared labels (`prd`, `slice`, `afk`, `hitl`)
- parent ticket key included in each child description

Before creation, resolve:

- Linear **team**
- Linear **project** (if used)
- Ticket **state** (Backlog or Todo)
- Label set
- Parent strategy (new parent vs existing parent key)

Create blockers first so dependencies can reference existing ticket IDs.

Use this template for each child ticket description.

<linear-ticket-template>
## Parent PRD

<Link or identifier for parent PRD>

## What to build

A concise description of this vertical slice. Describe end-to-end behavior, not layer-by-layer implementation. Reference specific PRD sections instead of duplicating content.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- <TICKET-123> (if any)

Or "None - can start immediately" if no blockers.

## User stories addressed

Reference by number or identifier from the PRD:

- User story 3
- User story 7

## Execution mode

`AFK` or `HITL`
</linear-ticket-template>

Do not modify the parent PRD source unless the user asks.

## Hand-off

After tickets are created, suggest `tdd` as the implementation skill for each child ticket.
