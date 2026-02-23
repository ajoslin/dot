# Workflow Philosophy

## Goal

Convert fuzzy ideas into reliable delivery by making planning artifacts explicit, then executing in small vertical slices.

## Principles

1. Planning quality determines execution quality.
2. Decomposition quality determines autonomy quality.
3. Vertical slices beat horizontal phases for fast integration feedback.
4. Human QA remains the final gate.
5. Simpler orchestration is preferred until complexity proves necessary.

## Decision Heuristics

- If scope is unclear, route to PRD creation first.
- If dependencies are unclear, route to issue decomposition and mapping.
- If risk is high, route to refactor/interface planning before edits.
- If behavior is critical, route to behavior-first test workflow.

## Minimal Artifact Standard

- PRD has explicit outcomes and acceptance criteria.
- Issues are small, testable, and dependency-linked.
- Each execution unit has verification and QA checks.
