---
name: matt-pocock
description: Routes software work through Matt Pocock planning and execution philosophy. Use when the user mentions Matt Pocock, PRD-first planning, PRD-to-issues decomposition, vertical slices, Ralph loop, behavior-first TDD, interface options, or refactor planning.
---

# Matt Pocock Workflow Router

Use this as a meta-skill that classifies work, routes to the right downstream skills, and enforces planning-before-execution.

## Core Flow

`idea -> write-a-prd -> prd-to-issues -> execute vertical slices -> manual QA`

Do not skip required artifacts. If required artifact is missing, route backward to generate it.

## Routing Table

| Situation | Route |
|---|---|
| New feature, unclear scope, ambiguous requirements | `write-a-prd` |
| PRD exists but implementation tasks are not decomposed | `prd-to-issues` |
| Bugfix or behavior change needs confidence | `tdd` |
| High-impact API/UI contract or unclear interface | `design-an-interface` |
| Multi-file risky refactor | `request-refactor-plan` |
| Commit safety / branch hygiene needed | `git-guardrails-claude-code` |

## Guardrails

1. Do not execute medium/large implementation work without clear acceptance criteria.
2. Prefer vertical slices over horizontal layer-by-layer execution.
3. Require dependency mapping when multiple issues/agents are involved.
4. Require behavior-first test evidence for bugfixes and non-trivial changes.
5. Keep artifacts concise and machine-operable.

## Handoff Contract

Each routing hop should output explicit artifacts:

- `write-a-prd` -> `prd.md` with scope, stories, constraints, acceptance criteria.
- `prd-to-issues` -> issue list with dependencies, owners/agents, and slice boundaries.
- `tdd` -> failing test intent, implementation notes, passing evidence.
- `design-an-interface` -> compared options, chosen design, tradeoff rationale.
- `request-refactor-plan` -> invariants, sequence, rollback points, verification steps.

## Reading Order

1. `references/workflow-philosophy.md`
2. `references/skill-graph.md`
3. `references/planning-execution-loop.md`
4. `references/vertical-slice-playbook.md`
5. `references/trw-adaptation-notes.md`

## Anti-Patterns

- Starting implementation before artifact readiness
- Creating oversized, ambiguous tasks
- Horizontal-only execution (db -> api -> ui) with late integration
- Duplicate doctrine across files instead of linking references

## In This Reference

- `references/workflow-philosophy.md` - principles and decision heuristics
- `references/skill-graph.md` - routing DAG and branch rules
- `references/planning-execution-loop.md` - end-to-end operating loop
- `references/vertical-slice-playbook.md` - slice design and quality checks
- `references/trw-adaptation-notes.md` - how to apply this in TRW
