---
description: Run unified tri-model code review via @code-review
agent: code-review
---

Run a single unified review flow.

Guidance: $ARGUMENTS

Execution order (required):
1. In the **main thread**, run `prepare-branch-context` first.
   - If the user specifies a base branch, use `prepare-branch-context from <base-branch>`.
   - Otherwise use the skill default behavior.
2. Capture that result as `BRANCH_CONTEXT_SUMMARY`.
3. Invoke `@code-review` and include:
   - the original user guidance,
   - `BRANCH_CONTEXT_SUMMARY` verbatim,
   - an instruction to pass the same `BRANCH_CONTEXT_SUMMARY` into each child reviewer prompt.

Requirements:
1. `@code-review` must spawn exactly three subagents in parallel: `@code-review-a`, `@code-review-b`, and `@code-review-c`.
2. Each child reviewer must receive the same `BRANCH_CONTEXT_SUMMARY` produced in step 1.
3. Review scope precedence:
   - PR/MR diff when user supplies link/number
   - Otherwise uncommitted Git changes
   - Otherwise latest Git commit
4. Apply baseline rubric and repo policy files (`.opencode/review/policy.md`, `.opencode/review/checklist.md`, `.opencode/review/severity.yml`) with additive semantics.
5. Correlate and dedupe panel findings inside `@code-review` before finalizing.
6. Return one final severity-ranked report with confirmed, uncertain/rejected findings, concrete fix guidance, and action required.
