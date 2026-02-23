---
description: Run code review with Codex reviewer
agent: plan
---

Review code changes using `@code-review-codex`.

Guidance: $ARGUMENTS

Process requirements:
1. Use Git commands directly.
2. Always run a complete baseline review rubric (correctness, security, data integrity, concurrency/async side effects, error handling, performance hot spots, API/schema contracts, maintainability).
3. Load repo-specific review policy files if present, in this order:
   - `.opencode/review/policy.md` (primary)
   - `.opencode/review/checklist.md` (optional)
   - `.opencode/review/severity.yml` (optional)
4. Treat repo policy as additive constraints; findings without mapping should be labeled `General`.
5. If policy files are missing, continue with default rubric and suggest `/init-review-policy`.
6. Review uncommitted Git changes by default. If there are no uncommitted changes, review the latest Git commit.
7. Then consult `@oracle` to validate each finding for correctness and architectural context.
8. Return:
   - Loaded policy files (or missing-file note)
   - Confirmed issues (severity-ranked)
   - Rejected or uncertain findings
   - Suggested fixes with file paths and line numbers
   - Action Required

If the user provides a PR or MR link/number, fetch it with GitHub/GitLab CLI tools and review that Git diff instead.
