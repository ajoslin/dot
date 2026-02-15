---
name: init-review-policy
description: Initialize repo-scoped code review policy files under .opencode/review. Use when setting up project-specific review rules for /code-review.
---

# Initialize Review Policy

Create a repo-local review policy package for use by `/code-review` and `/review`.

## Goal

Initialize these files:

- `.opencode/review/policy.md` (required)
- `.opencode/review/checklist.md` (optional but recommended)
- `.opencode/review/severity.yml` (optional but recommended)

## Behavior

1. Detect repo root (prefer `vcs-detect` if available).
2. Create `.opencode/review/` if missing.
3. If files do not exist, create them from templates below.
4. If files exist, preserve user content and only add missing sections.
5. Ask for domain-specific overrides from user input and apply them.
6. Return a short summary with created/updated file paths.

## policy.md template

```markdown
# Review Policy

## Scope
- Applies to all code reviews in this repository.
- Overrides generic review defaults where explicitly stated.

## Critical Domains
- Authentication and authorization
- Data integrity and migrations
- Secrets, credentials, and PII handling
- Billing, quota, and financial calculations

## Must-Flag Findings
- Security vulnerabilities with practical exploit paths
- Silent data loss or corruption risks
- Backward-incompatible API or schema changes without migration plan
- Missing rollback/guardrails for risky deploy paths

## Usually Ignore
- Pure style nits unless they hide correctness issues
- Hypothetical edge cases without realistic trigger paths

## Repo-Specific Rules
- Add project rules here (framework constraints, architecture boundaries, test expectations)

## Required Review Output
- Severity: critical | high | medium | low
- File and line reference for every issue
- Why this is a bug/risk in this repository
- Concrete fix suggestion
```

## checklist.md template

```markdown
# Review Checklist

## Correctness
- Logic matches intended behavior and existing contracts
- Error handling is explicit and testable

## Security
- No new injection/authz/secrets/PII exposure paths

## Data and Migrations
- Schema changes include compatibility and rollback notes

## Performance
- No obvious unbounded hot-path regressions

## Operations
- Logging/metrics/alerts are sufficient for new risk areas

## Testing
- Critical paths have adequate coverage for changed behavior
```

## severity.yml template

```yaml
severity:
  critical:
    - remote code execution
    - auth bypass
    - irreversible data loss
  high:
    - privilege escalation
    - data corruption risk
    - breaking migration without rollback
  medium:
    - reliability regression on common paths
    - significant performance regression
  low:
    - minor maintainability risk
    - non-blocking robustness gaps
rules:
  require_file_line_reference: true
  require_concrete_fix: true
  deduplicate_findings: true
```

## Notes

- Keep rules concise and specific to this repository.
- Prefer concrete examples over abstract policy language.
