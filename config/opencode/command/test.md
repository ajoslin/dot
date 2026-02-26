Record or read test gate status for a plan phase.

Rules:
- During active live execution, run with `--set pass|fail`.
- Do not use `test` as a status-only poll in an active loop.
- Use `--final` only for final acceptance after all phases are complete.
