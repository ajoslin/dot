# overdo-plan

Convert markdown plans into Overdo-executable task graphs.

Use when:

- Creating a new implementation plan
- Translating spec sections into task/dependency units

Workflow:

1. Read the target markdown plan.
2. Extract milestones and ordered tasks.
3. Encode dependencies and required validation gates.
4. Emit task creation payloads for Overdo MCP.
5. Return next orchestration command.

Output requirements:

- Include task IDs and blockers
- Include gate policy (`lint`, `unit`, `integration`, `e2e`)
- Include resumability note for crash/retry handling
