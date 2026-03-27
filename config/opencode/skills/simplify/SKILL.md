---
name: simplify
description: Pre-commit readability pass for pending diffs. Use when simplifying changed code to make it easier to consume, skimmable, non-clever, and locally obvious without changing behavior or important boundaries.
---

# Simplify

Run a narrow readability pass on a real diff.

Make code easy to consume. Optimize for readability, skimmability, directness, and early returns. Avoid cleverness.

This is not a redesign skill. It is a pre-commit cleanup pass.

If the current repo has a local `simplify` skill, apply that addendum after this base skill.

## When to Use

- before every commit on the pending diff
- when asked to simplify, clean up, or reduce slop
- when code works but feels noisy, indirect, over-abstracted, or hard to scan

## Goal

Simplify changed code without changing:

- externally observable behavior
- compatibility surfaces
- ownership boundaries
- validation, auth, telemetry, logging, or safety guards

Bias toward:

- deletion over addition
- derived values over stored flags
- tagged states over boolean soup and optional bags
- early returns over nested branches
- explicit function contracts over mixed side effects
- direct names over clever helpers
- local code over one-off abstractions
- tables or maps when branches only differ by data
- existing canonical patterns over new micro-patterns

## Read This First

Always read:

- repo `AGENTS.md` if present
- nearest package or subdirectory `AGENTS.md` if present

Read only if needed:

- repo architecture or ownership docs when system boundaries are unclear
- the current repo's local `simplify` skill, if one exists
- [Simplify Gotchas](./references/gotchas.md) when deciding whether a cleanup is real simplification or fake simplification
- [Simplify Checklist](./references/simplify-checklist.md) before applying or reporting changes

## Hard Stops

Do not:

- change behavior just to make code look cleaner
- remove compatibility paths or migrate domains during simplify-only work
- replace established model, service, or context helpers with raw access when those helpers enforce invariants
- remove validation, telemetry, logging, auth, or guard code
- store derived state just to save a line of computation
- widen types into optional bags when a tagged shape would remove ambiguity
- let a pure helper quietly mutate data
- mix mutation and return-value semantics in a way that hides side effects
- introduce a new abstraction unless it makes the code clearly easier to read

If safety is unclear, downgrade to `proposal-only` or skip it.

## Core Loop

1. Build scope from explicit path, otherwise working diff, otherwise latest commit.
2. If there is no diff, stop with `nothing to simplify`.
3. List all changed files. If **more than 6 files**, use the parallel strategy below. Otherwise, process inline.
4. Sweep every changed file. Find **all** readability problems, not just a few. Be thorough — scan every function, every branch, every type, every import.
5. Apply every fix that passes the Safe Fix Test below. Do not self-limit to a small count.
6. Run the smallest relevant verification.
7. Report what got simpler, what was skipped, and why it was safe.

Do not force a cleanup pass if nothing clearly gets better, but do not artificially stop early when there is more to fix.

## Parallel Strategy (Large Diffs)

When the diff touches **more than 6 files**, split the work across parallel subagents to avoid context bloat and attention drift.

1. Group changed files into batches of **up to 6 files each**. Keep related files together when obvious (e.g. a component and its test, a module and its types).
2. Launch one subagent per batch using the Task tool. **Max 5 subagents at once** to avoid bogging down the device. If there are more batches, run them in waves of 5 until all are addressed.
3. Each subagent prompt: `Load the simplify skill. Run it on only these files: <list>. Do not run verification — just apply fixes and report back.`
4. After all waves complete, the orchestrator runs verification once and produces the unified Output report.

## Hunt These (All of Them)

Sweep every changed file for all of these. Do not stop after the first few wins:

- wrappers that only rename or forward behavior
- one-off exported types or interfaces with no real reuse
- boolean mode soup and optional bags that want a tagged state
- effect-driven derived state or mirrored state
- speculative memoization or callback churn
- helper extraction that moves logic away from the source of truth
- hard-to-skim branching that wants early returns
- repeated branches that all return the same shape and want a table
- tiny abstractions added for aesthetics, not clarity

## Safe Fix Test

Apply a simplification only when the answer is clearly yes:

- Is the code easier to scan than before?
- Did we remove a layer, branch, flag, or rename-only wrapper?
- Did we make the state model or function contract more explicit?
- Does the code still live in the same correct home?
- Would a new reviewer understand the flow faster?
- Is verification straightforward?

If the answer is weak, move it to `proposal-only` instead of silently skipping.

## Verification

Use the smallest check that proves the cleanup is safe:

- targeted tests for changed modules when available
- the smallest relevant typecheck or lint command
- add focused checks beyond typecheck when async behavior, interaction flow, or visible UI changed
- if no automated check exists, state the manual verification plan explicitly

Typecheck alone is not enough when the cleanup changes async behavior, interaction flow, or visible UI structure.

## Output

Return concise sections:

- `Scope used`
- `Applied fixes`
- `Skipped or proposal-only items`
- `Verification evidence`
- `Residual risks or assumptions`

For each applied fix, say:

- path
- what got simpler
- why it is safe

## In This Reference

| File | Purpose |
|------|---------|
| [references/gotchas.md](./references/gotchas.md) | High-signal pitfalls: fake simplification, boundary drift, and readability traps |
| [references/simplify-checklist.md](./references/simplify-checklist.md) | Quick safety and verification checklist |
