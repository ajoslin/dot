# Skill Graph

```text
matt-pocock (router/orchestrator)
├─ planning
│  └─ write-a-prd
├─ decomposition
│  └─ prd-to-issues
├─ execution quality
│  └─ tdd
├─ design quality
│  └─ design-an-interface
├─ refactor safety
│  └─ request-refactor-plan
└─ git hygiene
   └─ git-guardrails-claude-code
```

## Branch Rules

- No PRD -> route to `write-a-prd`.
- PRD exists, no issue map -> route to `prd-to-issues`.
- Bugfix/non-trivial behavior change -> route through `tdd`.
- Interface ambiguity -> route through `design-an-interface` first.
- Multi-file refactor risk -> route through `request-refactor-plan` first.

## Output Contracts

- Every node returns an artifact name and readiness status.
- Router only advances when readiness checks pass.

## Fallback

- If classification is ambiguous, choose planning/decomposition path over direct execution.
