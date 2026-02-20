Execute the active Caffeine plan in continuous mode.

Rules:
- Do not stop after announcing a phase or `nextAction`.
- If `nextAction=build`, immediately implement that phase.
- Keep looping: execute -> build work -> execute -> test/review when requested -> execute.
- Ask the user only when absolutely blocked by one of: missing external credential/input, irreversible decision ambiguity, or explicit user pause.
- Never use `git stash`/`git stash pop`.

Gate discipline:
- In live execution, `test` and `review` must record evidence (`--set pass|fail`).
- Do not burn turns on status-only gate reads during active execution.

Idle fallback:
- If interrupted/idle while `liveExecution` is active, run `caffeine autocontinue-loop` as recovery.
- Autocontinue is fallback; primary mode is active continuous execution in this session.
