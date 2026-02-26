---
name: prd-creator
description: Unified PRD creator that combines Matt Pocock discipline, breadboarding/shaping, and vertical slice planning. Use when the user wants a full PRD with acceptance tests, requirements, slices, and timeline.
---

# Unified PRD Creator

This skill composes three methods with explicit role separation:

1. Matt Pocock governance and quality gates (framing + readiness)
2. Breadboarding and shaping requirement development (core discovery)
3. Matt-aligned slice formalization and PRD output

Do not skip phases. If a required artifact is missing, move backward and produce it first.

## Core Flow

`intake -> matt framing gate -> shaping/breadboarding core -> rabbit-hole closure -> matt formalization gate -> slicing -> phased PRD -> acceptance + readiness checks`

Read details in:

1. `references/unified-flow.md`
2. `references/prd-template.md`

## Phase Contract

### Phase 0: Intake

Capture:

- problem statement
- target users/personas
- constraints (time, technical, business)
- non-goals
- success metrics

### Phase 1: Matt Rules Gate

Apply these non-negotiables:

- PRD-first; no implementation planning without acceptance criteria
- vertical slices over horizontal layers
- explicit dependency mapping between slices
- behavior-first validation criteria

If acceptance criteria are vague, refine them before continuing.

Role in this phase: governance wrapper (quality constraints), not full requirement discovery.

### Phase 2: Breadboarding + Shaping

Produce:

- places, affordances, connections (breadboard topology)
- appetite (timebox) and bounded scope
- rabbit holes with explicit patches
- out-of-bounds list

If major unknowns remain, stay in this phase.

Role in this phase: requirement-development core that turns ambiguity into bounded, testable requirements.

### Phase 3: Slice Design

Split into independent vertical slices, each with:

- user-visible outcome
- modules/touchpoints
- dependencies (blocked-by, unblocks)
- definition of done
- acceptance tests

Role in this phase: Matt-aligned formalization of shaped requirements into executable slices.

### Phase 4: PRD Assembly

Render the final PRD using `references/prd-template.md`.

Required PRD sections:

- problem, goals, non-goals
- personas and baseline
- shaped solution summary
- full requirements list
- feature conditions and edge cases
- vertical slice plan
- acceptance test matrix
- phase timeline
- risks and mitigation
- launch/readiness checklist

## Output Requirements

The final PRD must include all of the following:

1. Measurable acceptance criteria for every feature
2. Requirement IDs (`R-001`, `R-002`, ...)
3. Slice IDs (`S-01`, `S-02`, ...)
4. A phase timeline with duration and dependencies
5. Explicit assumptions and open questions
6. In-scope and out-of-scope boundaries
7. Phase acceptance conditions for every `P-*` timeline phase

## Quality Gates

- Gate A (after shaping): unknowns are patched or explicitly deferred
- Gate B (after slicing): each slice is independently testable
- Gate C (before final PRD): every requirement maps to at least one acceptance test

Do not emit a "final PRD" if any gate fails.

## Clarification Protocol (Mandatory)

For each timeline phase `P-*`, acceptance conditions must be explicit and testable.

If any phase acceptance condition is ambiguous, missing measurable thresholds, or lacks evidence signals, ask targeted clarification questions before finalizing.

Minimum required question set per unclear phase:

1. What exact pass/fail condition defines phase completion?
2. What observable evidence proves completion (test, log, metric, API response)?
3. What is explicitly out of scope for this phase?

If answers are unavailable, mark the phase as `Draft` and list blocking unknowns; do not mark the PRD as final-ready.

## Anti-Patterns

- jumping to feature lists without shaped problem framing
- mixing implementation tasks with PRD requirements
- horizontal decomposition (backend first, frontend later)
- requirements without acceptance tests
- timelines without dependency links

## Suggested Invocation

Use this skill when users ask for:

- full PRDs
- requirement decomposition
- phase planning and scope shaping
- acceptance-test driven specs

Example:

`Use prd-creator to produce a full PRD for [initiative], including slices, timeline, and acceptance tests.`
