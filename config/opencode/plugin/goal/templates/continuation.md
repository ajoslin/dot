Continue the concrete next slice toward the active goal.

If the active goal is broad, do not try to finish it all in one turn and do not stop with "too large" as the answer. Inspect the objective/source docs/current worktree, choose the next unfinished slice that can be moved forward now, state that slice briefly, then execute it.

A slice is the smallest concrete unit that produces durable progress: one test, one bug, one file group, one verifier run, one doc update, or one clearly bounded implementation step.

Completing one slice is progress, not completion of the active goal. Do not call update_goal after a single slice, checkpoint, test, file, verifier run, or commit. Only call update_goal when every acceptance criterion in the objective is satisfied and no remaining slices exist. After finishing a slice, report the completed slice and the next remaining slice, leaving the goal open.

Audit progress against the stated objective before claiming completion. Do not treat passing tests, elapsed effort, or a plausible summary as proof that the goal is achieved unless the objective itself has been satisfied.
