---
name: prd-creator
description: Create a PRD through deep user interviewing, codebase exploration, and explicit implementation/testing decisions. Use as the first step before prd-to-plan or prd-to-issues.
---

# PRD Creator

Use this skill when the user wants to create a PRD.

## Process

### 1. Gather detailed problem context

Ask the user for a long, detailed description of the problem they want to solve and any potential ideas for solutions.

### 2. Explore the repo

Explore the repo to verify user assertions and understand the current state of the codebase.

### 3. Interview relentlessly

Interview the user about every important aspect of the plan until you reach shared understanding.

Walk each major branch of the design tree and resolve dependencies between decisions one-by-one.

### 4. Sketch major modules

Sketch the major modules to build or modify.

Look for opportunities to extract deep modules that can be tested in isolation.

A deep module encapsulates substantial functionality behind a simple, testable interface that rarely changes.

Check with the user that the proposed modules match expectations.
Check with the user which modules should have tests.

### 5. Write the PRD

Once understanding is complete, write the PRD using the template below.

By default, format the PRD so it can be posted as a GitHub issue.

<prd-template>
## Problem Statement

The problem from the user's perspective.

## Solution

The proposed solution from the user's perspective.

## User Stories

A long, numbered list of user stories in this format:

1. As an <actor>, I want a <feature>, so that <benefit>

## Implementation Decisions

List implementation decisions, including:

- modules to build/modify
- interface changes
- technical clarifications
- architectural decisions
- schema changes
- API contracts
- specific interactions

Do not include specific file paths or code snippets.

## Testing Decisions

List testing decisions, including:

- what makes a good test (external behavior over implementation details)
- which modules will be tested
- prior-art tests in the codebase (if known)

## Out of Scope

Explicitly list what is not included.

## Further Notes

Any additional context needed for execution.
</prd-template>

## Hand-off

After PRD creation, suggest one of these next skills:

- `prd-to-plan` for phased execution planning
- `prd-to-issues` for immediate issue decomposition
