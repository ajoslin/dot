# Unified Flow

## Purpose

Create high-confidence PRDs by composing:

1. Matt Pocock governance (framing constraints + quality gates)
2. Shape Up style shaping and breadboarding (requirement-development core)
3. Matt-aligned vertical slicing and formal PRD assembly

## Detailed Sequence

### 1) Problem Framing (Matt discipline)

- Define the exact user problem and baseline behavior.
- Record constraints and non-goals.
- State success metrics as observable outcomes.

Exit criteria:

- problem is specific
- boundaries are explicit
- success is measurable

Role note: this is governance and framing discipline, not full requirement discovery.

### 2) Shaping and Breadboarding

- Define core places (screens, states, touchpoints).
- Define affordances (actions, controls, feedback).
- Connect flows (place -> affordance -> next state).
- Set appetite (timebox).
- Identify rabbit holes and choose patches.
- Declare out-of-bounds.

Exit criteria:

- critical unknowns closed or explicitly deferred
- topology is coherent end-to-end
- appetite and boundaries are realistic

Role note: this is the core requirement-development engine.

### 3) Disciplined Slicing

Split shaped solution into vertical slices.

For each slice define:

- intent and user-visible value
- included components and dependencies
- done conditions
- acceptance tests

Exit criteria:

- each slice independently testable and demoable
- dependency graph has no ambiguous edges

Role note: this is formalization of shaped requirements into build-ready slices.

### 4) Timeline and Delivery Plan

- Group slices into phases.
- Assign durations and dependency order.
- Mark risks and fallback plans per phase.
- Define explicit pass/fail acceptance conditions for each phase.

Exit criteria:

- timeline is dependency-safe
- risks have mitigations

If any phase acceptance condition is unclear, ask clarification questions and do not finalize the PRD:

- What exact pass/fail condition defines phase completion?
- What observable evidence proves completion?
- What is out of scope for this phase?

### 5) PRD Finalization

- Compile requirements, conditions, features, tests, and timeline.
- Validate traceability: every requirement maps to at least one test.
- Validate completeness: every feature has conditions and boundaries.

Exit criteria:

- full PRD ready for implementation kickoff

## Traceability Rules

- Every requirement `R-*` maps to one or more acceptance tests `AT-*`.
- Every acceptance test maps to at least one slice `S-*`.
- Every slice maps to one phase `P-*`.

## Definition of Ready

PRD is ready only if:

- no unresolved critical unknowns
- all high-risk assumptions are explicit
- slices are dependency-mapped
- acceptance tests are measurable
- in-scope and out-of-scope are explicit
