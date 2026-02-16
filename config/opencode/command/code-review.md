---
description: Run 3 parallel code reviews (Opus, Codex, GLM) and correlate findings
agent: plan
---

Review code changes using THREE (3) parallel reviewers: `@code-review-opus`, `@code-review-codex`, and `@code-review-glm`.

Guidance: $ARGUMENTS

Process requirements:
1. Use Git commands directly.
2. Always run a complete baseline review rubric (correctness, security, data integrity, concurrency/async side effects, error handling, performance hot spots, API/schema contracts, maintainability).
3. Load repo-specific review policy files if present, in this order:
   - `.opencode/review/policy.md` (primary)
   - `.opencode/review/checklist.md` (optional)
   - `.opencode/review/severity.yml` (optional)
4. Treat repo policy as additive constraints, not as the full review scope. Findings that do not map to policy must still be reported when they are real defects.
5. If policy files are missing, continue with default reviewer rubric and include a note suggesting `/init-review-policy`.
6. Review uncommitted Git changes by default. If there are no uncommitted changes, review the latest Git commit.
7. Run all three reviewers in parallel against the same scope, user guidance, and loaded repo policy.
8. Require each reviewer to cite which policy section (if any) each finding maps to, and mark `General` when no policy mapping exists.
9. Correlate results, remove duplicates, and rank by severity.
10. Then consult `@oracle` to validate each finding for correctness and architectural context. Do not skip this step.
11. Return a final report with:
   - Loaded policy files (or missing-file note)
   - Remediation Mode (`apply` or `advise`) and why it was selected
   - Confirmed issues (severity-ranked)
   - Rejected or uncertain findings
   - Suggested fixes with file paths and line numbers
   - Action Required

12. Determine remediation mode for the final report using this precedence:
    1. Explicit user instruction (`review-only` => `advise`, `fix-now` => `apply`)
    2. Execution capability (non-editing contexts like plan mode or external PR review => `advise`)
    3. Default policy (`apply` when edits are possible, otherwise `advise`)

13. In `apply` mode:
    - Instruct the caller to address all confirmed issues by default.
    - Allow deferment only with explicit rationale and a follow-up task/issue reference.
    - Do not require action on rejected or uncertain findings unless revalidated.

14. In `advise` mode:
    - Do not instruct immediate code changes.
    - Return a prioritized remediation plan the caller can execute later.
    - When relevant, include suggested PR comments and/or follow-up tickets.

If the user provides a PR or MR link/number, fetch it with GitHub/GitLab CLI tools and review that Git diff instead.
