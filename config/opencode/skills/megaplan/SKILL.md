---
name: megaplan
description: Adversarial plan-critique-gate loop using build and deep subagents. Use when the user asks for megaplan, or a task is high-risk, multi-system, or ambiguous.
---

# Megaplan

High-rigor planning with adversarial critique, explicit gate decisions, and resumable execution.

## When to use it

- Multi-file, ambiguous, high-risk, or multi-stage work
- Work that benefits from critique before execution
- Tasks where resumability and execution discipline matter

Skip it for obvious, low-risk edits.

## Roles

| Role | Subagent | Purpose |
|---|---|---|
| Planner | `build` | plan, revise, finalize |
| Critics | 3x `deep` | feasibility, architecture, risk |
| Reviewer | `deep` | final independent review |
| Orchestrator | you | state, gate, execution loop |

## Workflow

`init -> plan -> critique -> gate -> revise/finalize -> execute -> review`

- `plan`, `revise`, `finalize` delegate to `build`
- `critique` runs 3 parallel `deep` critics and merges flags
- `gate` is computed by you, then decision delegated to `build`
- `execute` is owned by the main thread
- `review` delegates to `deep`

## Core rules

### 1. Continuity source of truth
Use `.megaplan/plans/<name>/runbook.md` as the continuity source of truth.

Trust `runbook.md` over conversational memory, especially after compaction or resume.

### 2. Main-thread execution
During `execute`, the main thread owns:
- batch selection
- implementation
- progress maintenance
- commits
- runbook updates

Delegate only fresh-eyes work:
- `simplify`
- pre-commit `review`
- specialist verification when needed

### 3. Fresh-eyes rule
The main thread must not approve its own diff unaided.

Before each commit:
1. delegate fresh `simplify`
2. delegate fresh pre-commit `review`
3. fix anything required
4. then commit atomically

### 4. Never-stop
During execution, set `/never-stop` using the exact `## Continue` section from `runbook.md`.

Refresh it after meaningful steps. Clear it on `complete` or `blocked`.

## Minimal runbook

Keep `runbook.md` minimal. It should contain only:
- `Status`
- `Step`
- `Next`
- `Batch`
- `Last commit`
- `Watch`
- `Blocker`
- `## Continue`

Do not turn the runbook into a diary. Keep history and evidence in other artifacts.

## Artifacts

Use `.megaplan/plans/<name>/`.

Essential artifacts:
- `runbook.md` — continuity control plane
- `plan_v<N>.md` and `plan_v<N>.meta.json`
- `faults.json`
- `gate.json`
- `finalize.json`
- `review.json`

Additional artifacts may be written as needed for critiques, execution evidence, and summaries.

## Execution loop

When `Step` is `execute`, use this loop:
1. Find next unblocked WorkingBatch
2. Implement in main thread
3. Delegate fresh `simplify`
4. Delegate fresh `review`
5. Fix anything required
6. Commit atomically
7. Update `runbook.md`
8. Repeat

Stop only on:
- `complete` — all planned work finished, reviewed, committed
- `blocked` — missing requirements, auth, permissions, secrets, or irreconcilable contradiction

## References

- Prompt templates: [references/prompts.md](./references/prompts.md)
- Gate logic: [references/evaluation.md](./references/evaluation.md)
