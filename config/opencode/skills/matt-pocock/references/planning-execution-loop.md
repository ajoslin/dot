# Planning to Execution Loop

## Loop

1. Capture idea and constraints.
2. Produce PRD.
3. Decompose PRD into small dependency-linked issues.
4. Execute unblocked issue as a vertical slice.
5. Run tests and validations.
6. Perform manual QA against acceptance criteria.
7. Repeat until issue graph is complete.

## Readiness Gates

- Gate A (before issue creation): PRD contains measurable acceptance criteria.
- Gate B (before implementation): issue has clear scope, dependencies, and verification plan.
- Gate C (before completion): automated checks pass and manual QA checklist is complete.

## Failure Recovery

- Missing context -> route backward to planning artifact.
- Repeated execution failures -> shrink issue scope and split further.
- Design conflict -> route to interface or refactor planning node.
