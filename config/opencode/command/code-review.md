---
description: Run unified tri-model code review via @code-review
agent: plan
---

Run a single unified review flow by invoking `@code-review`.

Guidance: $ARGUMENTS

Requirements:
1. `@code-review` must spawn exactly three subagents in parallel: `@code-review-sonnet`, `@code-review-codex`, and `@code-review-glm`.
2. Review scope precedence:
   - PR/MR diff when user supplies link/number
   - Otherwise uncommitted Git changes
   - Otherwise latest Git commit
3. Apply baseline rubric and repo policy files (`.opencode/review/policy.md`, `.opencode/review/checklist.md`, `.opencode/review/severity.yml`) with additive semantics.
4. Correlate and dedupe panel findings, then validate with `@oracle` before finalizing.
5. Return one final severity-ranked report with confirmed, uncertain/rejected findings, concrete fix guidance, and action required.
