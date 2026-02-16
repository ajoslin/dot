# overdo-orchestrate

Execute Overdo task graphs to completion with validation loops.

Use when:

- Running a task tree end-to-end
- Recovering from failed attempts or restarts

Workflow:

1. Fetch next ready task(s).
2. Dispatch worker claims with lease safety.
3. Run required validation gates.
4. Persist loop iteration result.
5. Retry/escalate based on policy.
6. Queue commit and finalize transaction.

Rules:

- Never mutate orchestration state outside MCP.
- Always persist evidence for retries/escalations.
- Resume from SQLite state after crash before starting new work.
