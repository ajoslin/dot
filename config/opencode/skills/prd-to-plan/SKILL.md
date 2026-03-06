---
name: prd-to-plan
description: Turn a PRD into a multi-phase implementation plan using tracer-bullet vertical slices, saved as a local Markdown file in ./plans/.
---

# PRD to Plan

Break a PRD into a phased implementation plan using vertical slices (tracer bullets). Output is a Markdown file in `./plans/`.

## Process

### 1. Confirm the PRD is in context

The PRD should already be in the conversation. If it is not, ask the user to paste it or point to the file.

### 2. Explore the codebase

If you have not already explored the codebase, do so to understand architecture, existing patterns, and integration layers.

### 3. Identify durable architectural decisions

Before slicing, identify high-level decisions unlikely to change during implementation:

- route structures or URL patterns
- database schema shape
- key data models
- authentication or authorization approach
- third-party service boundaries

Include these in the plan header so every phase can reference them.

### 4. Draft vertical slices

Break the PRD into tracer-bullet phases. Each phase is a thin vertical slice that cuts through all integration layers end-to-end, not a horizontal layer slice.

<vertical-slice-rules>
- Each slice delivers a narrow but complete path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
- Do not include specific file names, function names, or fragile implementation details
- Do include durable decisions: route paths, schema shapes, data model names
</vertical-slice-rules>

### 5. Quiz the user

Present the breakdown as a numbered list. For each phase show:

- **Title**: short descriptive name
- **User stories covered**: which PRD user stories this phase addresses

Ask:

- Does granularity feel right? (too coarse or too fine)
- Should phases be merged or split further?

Iterate until approved.

### 6. Write the plan file

Create `./plans/` if it does not exist.
Write the plan as a Markdown file named after the feature (for example `./plans/user-onboarding.md`).
Use this template:

<plan-template>
# Plan: <Feature Name>

> Source PRD: <brief identifier or link>

## Architectural decisions

Durable decisions that apply across all phases:

- **Routes**: ...
- **Schema**: ...
- **Key models**: ...
- (add/remove sections as appropriate)

---

## Phase 1: <Title>

**User stories**: <list from PRD>

### What to build

A concise description of this vertical slice. Describe end-to-end behavior, not layer-by-layer implementation.

### Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## Phase 2: <Title>

**User stories**: <list from PRD>

### What to build

...

### Acceptance criteria

- [ ] ...

<!-- Repeat for each phase -->
</plan-template>
