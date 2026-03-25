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
3. Find the top 1-3 highest-signal readability problems.
4. Apply only fixes that are clearly safe and make the code easier to consume.
5. Run the smallest relevant verification.
6. Report what got simpler, what was skipped, and why it was safe.

Do not force a cleanup pass if nothing clearly gets better.

## Hunt These First

Start with the changes most likely to improve readability fast:

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

If the answer is weak, skip it.

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
