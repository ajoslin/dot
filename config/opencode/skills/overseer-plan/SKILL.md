---
name: overseer-plan
description: Convert markdown planning documents to Overseer tasks via MCP codemode, then hand off execution by telling the user to run /overseer_orchestrate.
license: MIT
references:
  - references/api.md
  - references/implementation.md
  - references/examples.md
metadata:
  author: dmmulroy
  version: "1.1.0"
---

# Converting Markdown Documents to Overseer Tasks

Use `/overseer-plan` to convert any markdown planning document into trackable Overseer tasks and prepare a clean handoff to `/overseer_orchestrate`.

## When to Use

- After completing a plan in plan mode
- Converting specs/design docs to implementation tasks
- Creating tasks from roadmap or milestone documents

## Usage

```
/overseer-plan <markdown-file-path>
/overseer-plan <file> --priority 3           # Set priority (1-5)
/overseer-plan <file> --parent <task-id>     # Create as child of existing task
```

## What It Does

1. Reads markdown file
2. Extracts title from first `#` heading (strips "Plan: " prefix)
3. Creates Overseer milestone (or child task if `--parent` provided)
4. Analyzes structure for child task breakdown
5. Creates child tasks (depth 1) or subtasks (depth 2) when appropriate
6. Returns task ID and breakdown summary
7. Returns an explicit next-step handoff command for the user to run `/overseer_orchestrate`

## Handoff Rule

- Do not invoke `/overseer_orchestrate` from `/overseer-plan`
- Always include a next-step message in the result: `Next: /overseer_orchestrate <created-parent-id>`
- If `--parent` is used, still include the parent task id in the handoff command

## Hierarchy Levels

| Depth | Name | Example |
|-------|------|---------|
| 0 | **Milestone** | "Add user authentication system" |
| 1 | **Task** | "Implement JWT middleware" |
| 2 | **Subtask** | "Add token verification function" |

## Breakdown Decision

**Create subtasks when:**
- 3-7 clearly separable work items
- Implementation across multiple files/components
- Clear sequential dependencies

**Keep single milestone when:**
- 1-2 steps only
- Work items tightly coupled
- Plan is exploratory/investigative

## Orchestrate-Ready Breakdown

- Prefer depth 1 child tasks with clear `Done when` criteria for each child
- Add depth 2 subtasks when child execution needs iterative loops (implement -> validate -> feedback)
- Encode feedback-loop intent in task context when review/rework is likely:
  - `Feedback loop: collect reviewer/test feedback, apply fixes, re-run validation`
- If plan ambiguity materially changes feedback-loop structure, ask one targeted question with a default recommendation

## Task Quality Criteria

Every task must be:
- **Atomic**: Single committable unit of work
- **Validated**: Has tests OR explicit acceptance criteria in context ("Done when: ...")
- **Clear**: Technical, specific, imperative verb

Every milestone must:
- **Demoable**: Produces runnable/testable increment
- **Builds on prior**: Can depend on previous milestone's output

## Review Workflow

1. Analyze document → propose breakdown
2. **Invoke Oracle** to review breakdown and suggest improvements
3. Incorporate feedback
4. Create in Overseer (persists to SQLite via MCP)
5. Return handoff message telling user to run `/overseer_orchestrate <id>`

## After Creating

```javascript
await tasks.get("<id>");                    // TaskWithContext (full context + learnings)
await tasks.list({ parentId: "<id>" });     // Task[] (children without context chain)
await tasks.start("<id>");                  // Task (VCS required - creates bookmark)
await tasks.complete("<id>", { result: "...", learnings: [...] });  // Task (VCS required - commits, bubbles learnings)
```

**VCS Required**: `start` and `complete` require jj or git (fail with `NotARepository` if none found). CRUD operations work without VCS.

**Note**: Priority must be 1-5. Blockers cannot be ancestors or descendants.

## When NOT to Use

- Document incomplete or exploratory
- Content not actionable
- No meaningful planning content

---

## Reading Order

| Task | File |
|------|------|
| Understanding API | @file references/api.md |
| Agent implementation | @file references/implementation.md |
| See examples | @file references/examples.md |

## In This Reference

| File | Purpose |
|------|---------|
| `references/api.md` | Overseer MCP codemode API types/methods |
| `references/implementation.md` | Step-by-step execution instructions for agent |
| `references/examples.md` | Complete worked examples |
