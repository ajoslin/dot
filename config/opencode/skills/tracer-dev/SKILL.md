---
name: tracer-dev
description: Execute tracer bullet development - implement tasks with validation, code review gates, demos, and learning propagation.
---

# Tracer Development

Execute the build-validate-review cycle for tracer bullet development.

## Locate State Files

Before any flow, find the plan files:

- Search `docs/tracers/**/state.json`
- If multiple matches, list them and use the ask question tool to ask questions about which feature to work on
- If none, STOP: "Run prd-tracers first to create a plan"

Two files per feature:
- `state.json` - Machine state (task passes, commits, current tracer)
- `PROGRESS.md` - Human-readable plan and learnings

All state updates go to `state.json`. Learnings are appended to `PROGRESS.md`.

## Decision Tree

```
Check state.json:
│
├─ No state.json found
│  └─ STOP: "Run prd-tracers first to create a plan"
│
├─ Current tracer has tasks with passes: false
│  └─ → NEXT-TASK FLOW
│
├─ All tasks pass, tracer status != "complete"
│  └─ → REVIEW-TRACER FLOW
│
├─ Tracer complete, more tracers remain
│  └─ Advance currentTracer → NEXT-TASK FLOW
│
└─ All tracers status: "complete"
   └─ DONE: "Feature complete!"
```

---

# NEXT-TASK FLOW

## Precondition Check

```
Is lastReviewedTracer == currentTracer - 1?
├─ No → "Complete tracer review first"
└─ Yes → Continue
```

If feature `status` is `planning`, update it to `in_progress` in state.json before starting work.

Proceed immediately to Step 1 without asking for confirmation once preconditions are satisfied.

## Step 1: Select Task

Read state.json and find first task with `passes: false` in the current tracer.

Also read the `context` block for patterns and key files to guide exploration.

## Step 2: Write Micro-Plan

Before ANY code, produce a brief plan:

```markdown
## Micro-Plan: Task X.Y - <name>

**Goal**: <one sentence>

**Implementation** (minimal):
1. <step>
2. <step>
...

**Validation**:
- <how we prove this works>

**Not doing** (explicit scope):
- <what we're deferring>
```

## Step 3: Implement

Key principles:
- Use EXISTING abstractions before creating new ones
- Minimal code that satisfies the task
- Production bar: types + error handling
- No speculative features

## Step 4: Validate

Run ALL verification steps from the task's `steps` array. Also run project validation (typecheck, tests, lint).

- Detect project scripts (package.json, Makefile) or use the ask question tool to ask questions if unclear
- If a step cannot run, mark SKIPPED with reason
- All steps must pass before proceeding

## Step 5: Code Review Gate (BLOCKING)

```bash
afplay /System/Library/Sounds/Ping.aiff
```

Present to user:

```
## Code Review: Task X.Y

Files changed:
- <file> (+X, -Y)

Verification steps:
- <step 1>: PASS
- <step 2>: PASS

Project validation:
- Typecheck: PASS or SKIPPED (reason)
- Tests: PASS or SKIPPED (reason)
- Lint: PASS or SKIPPED (reason)

Request approval inline (do not open question mode): reply **"lgtm"** to approve, or provide feedback.
```

**WAIT FOR USER RESPONSE**

- **"lgtm"** (exactly) → Continue to commit
- **Any other response** → Treat as feedback, revise, re-request review

Loop until user says "lgtm".

After "lgtm", proceed immediately to commit, mark the task complete, and start the next task without asking for confirmation.

## Step 6: Commit + State Update (Background Agent)

After approval, **always commit** the task. This ensures the next task's review only shows new changes.

Run the commit and state.json update using a background agent with `openrouter/z-ai/glm-4.7-flash`.

```bash
git add -A && git commit -m "feat(<scope>): <task description>"
```

## Step 7: Mark Task Complete

Update state.json for the task (handled by the background agent):
```json
{
  "passes": true,
  "commit": "<commit-hash>"
}
```

Continue to next task, or if all tasks in current tracer have `passes: true` → REVIEW-TRACER FLOW.

---

# REVIEW-TRACER FLOW

## Precondition

All tasks in current tracer have `passes: true` in state.json.

## Step 1: Definition of Done Audit

Check each criterion from the tracer's `proves` field:

```markdown
## DoD Audit: Tracer N

proves: "<what this tracer validates>"

Evidence:
- [x] <criterion>: <evidence>
- [x] <criterion>: <evidence>
- [ ] <criterion>: MISSING - <what's needed>
```

If any criterion unmet → Add tasks to state.json (with `passes: false`), return to NEXT-TASK FLOW.
If tasks are added after a tracer was reviewed, set in state.json:

```json
{
  "lastReviewedTracer": N-1,
  "currentTracer": N
}
```

## Step 2: Demo

```bash
afplay /System/Library/Sounds/Hero.aiff
```

Present demo instructions:

```
## Demo: Tracer N

Please run:

    <demo command from PROGRESS.md>

Expected result:
<expected output from PROGRESS.md>

Request response inline (do not open question mode): run the demo and reply "pass" to continue, or describe what went wrong.
```

**WAIT FOR USER RESPONSE**

### Continuation Logic

- **"pass"** → Continue to learnings
- **Any other response** → Treat as feedback, discuss adjustments, may add tasks

## Step 3: Record Learnings

Use the ask question tool to ask questions:
```
What did we learn from this tracer?
- Decisions made?
- Surprises?
- Things to remember for future tracers?
```

Update both files:

**state.json** - Add to tracer's `learnings` array:
```json
{
  "learnings": ["<learning>", "<learning>"]
}
```

**PROGRESS.md** - Append under the tracer's Learnings section:
```markdown
### Learnings

- <learning>
- <learning>
```

## Step 4: Update Future Tracers

Review remaining tracers in light of learnings:

```
## Future Tracer Review

Based on learnings from Tracer N:

Tracer N+1: <name>
- Still makes sense? [yes/adjust]
- Demo still valid? [yes/adjust]  
- New tasks needed? [no/add]
```

Update PROGRESS.md if any changes needed.

## Step 5: Mark Tracer Complete

Update state.json:
```json
{
  "lastReviewedTracer": N,
  "currentTracer": N+1,
  "tracers": [{
    "id": N,
    "status": "complete",
    "completed": "<ISO date>"
  }]
}
```

If this was the final tracer, also set:
```json
{
  "status": "complete"
}
```

## Step 6: Celebrate

```bash
afplay /System/Library/Sounds/Funk.aiff
```

```
Tracer N complete!

Progress: N/<total> tracers done
Next: Tracer N+1 - <name>

Continuing to the next tracer.
```
