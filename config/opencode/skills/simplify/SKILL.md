---
name: simplify
description: Review pending code changes for reuse, quality, and efficiency, then apply worthwhile fixes. Use when asked to simplify, clean up, optimize, or review recent edits.
---

# Simplify: Review and Cleanup

Run a focused review on the user's real diff, then fix high-value issues.

## Guiding Question

Apply this exact question during review:

"Without violating locked requirements, acceptance criteria, and externally observable behavior, how can we simplify this change? Can we remove an abstraction? Use plain TypeScript? Omit a dependency? Infer data? Infer types? Avoid recording data? Remove deprecated types/features? Remove secondary paths like smoke tests?"

For every candidate simplification, classify it as `safe-to-apply`, `proposal-only`, or `do-not-apply`.

## Outcome

- Find concrete improvements in three lanes: reuse, quality, efficiency.
- Apply worthwhile fixes directly.
- Return a concise report of what changed and what was skipped.

## Non-Negotiable Locks

- Do not remove required behavior, acceptance criteria coverage, or externally observable behavior.
- Do not auto-remove smoke tests or secondary paths unless they are clearly non-requirements.
- Do not auto-delete types/abstractions that enforce contracts, boundaries, or compatibility.
- Do not reduce validation, observability, telemetry, or auditability unless explicitly requested.
- If uncertainty remains, downgrade to `proposal-only`.

## Requirement Witness Ledger (Per Project)

Use a project-scoped ledger at `.opencode/simplify-ledger.md`.

Purpose:
- Store requirement-preservation evidence so simplification gets safer over time.
- Prevent repeated over-optimization against smoke tests, secondary paths, and contract types.

Rules:
- Read ledger before analysis when it exists.
- If missing, create it with the template in this skill.
- Every candidate simplification must have a witness entry.
- If no credible witness can be produced, force `proposal-only`.

Ledger entry fields:
- `id`: stable short identifier.
- `scope`: file/API/test scope.
- `requirement`: locked behavior/acceptance criterion.
- `preservation-proof`: tests, types, API contract, or observable checks.
- `risk-note`: what could regress.
- `decision`: `safe-to-apply` | `proposal-only` | `do-not-apply`.

## Phase 0: Load Ledger Context

1. Locate `.opencode/simplify-ledger.md` in the current project.
2. If present, read relevant entries for touched files/APIs/tests.
3. If absent, create it using this starter template:

```markdown
# Simplify Ledger

Project-scoped requirement witness ledger for `/simplify`.

## Entries

<!--
- id: RWL-0001
  scope: src/foo.ts, api/bar
  requirement: Public API response shape remains backward compatible.
  preservation-proof: tests/api/bar.test.ts passes; type contract unchanged.
  risk-note: Hidden consumers may depend on optional field ordering.
  decision: proposal-only
-->
```

## Phase 1: Build Runtime Diff Context

Do not embed code in this skill. Collect the diff at runtime and pass it to subagents.

1. Choose scope in this precedence order:
   - PR/MR diff if user provided PR context.
   - Working tree diff otherwise (`git diff` or `git diff HEAD` if staged changes exist).
   - Latest commit diff if no uncommitted changes (`git show --patch --format=fuller HEAD`).
2. Capture:
   - `DIFF_TEXT`: full patch text.
   - `CHANGED_FILES`: stable file list in diff order.
3. If no changes are found, stop and report that there is nothing to simplify.

## Phase 2: Launch Three Parallel Reviewers

Launch all three reviewers concurrently in one message using `task(...)`. Every reviewer must receive the same `DIFF_TEXT`.

### Reviewer A: Reuse

Goal: reduce duplicate or hand-rolled logic.

Checks:
- Existing utilities/helpers that can replace new inline logic.
- Newly added functions that duplicate existing functionality.
- Ad-hoc parsing, normalization, path/env/type-guard logic that should reuse shared helpers.

### Reviewer B: Quality

Goal: improve maintainability and abstraction boundaries.

Checks:
- Redundant state or derivations that can be simplified.
- Parameter sprawl instead of better structure.
- Copy-paste variants that should be unified.
- Leaky abstractions and boundary breaks.
- Stringly-typed additions where existing constants/unions/enums exist.

### Reviewer C: Efficiency

Goal: remove unnecessary work and hot-path cost.

Checks:
- Redundant computation, repeated I/O/API calls, N+1 patterns.
- Missed concurrency for independent operations.
- New blocking work in hot paths.
- TOCTOU-style pre-checks that should be direct operation + error handling.
- Memory growth/leaks and overly broad reads/loads.

## Phase 3: Aggregate Findings

Merge all reviewer findings into one deduplicated list.

For each finding:
- Keep only concrete, evidence-backed issues.
- Mark priority: `high`, `medium`, `low`.
- Score `value` (0-3), `risk` (0-3), and `confidence` (0-3).
- Attach a requirement witness:
  - `requirement`
  - `preservation-proof`
  - `risk-note`
- Classify action:
  - `safe-to-apply` if `risk <= 1` and `confidence >= 2` and all locks are preserved.
  - `proposal-only` if behavior/scope may change or evidence is incomplete.
  - `do-not-apply` if it violates locks.
- Add a one-line rationale for the classification.

## Phase 4: Apply Worthwhile Fixes

Apply only `safe-to-apply` findings directly with minimal safe edits.

Rules:
- Prefer existing project abstractions over new helpers.
- Keep behavior unchanged unless user asked for behavior changes.
- Avoid speculative refactors unrelated to changed code.
- Never apply `proposal-only` or `do-not-apply` items automatically.

## Phase 6: Update Ledger

Append or update entries in `.opencode/simplify-ledger.md` for all reviewed candidates:

- Add new witness entries for new simplification decisions.
- Update existing entries when evidence or risk changed.
- Keep concise wording and stable IDs where possible.

## Phase 5: Verify

Run the smallest sufficient checks that prove correctness for touched code.

Typical order:
1. Targeted tests for changed modules.
2. Project lint/typecheck if relevant and available.
3. Any focused build/check command tied to touched area.

If checks fail, iterate on fixes and re-run checks before final output.

## Large Diff Fallback

If `DIFF_TEXT` is too large for a single prompt:

1. Split by file or hunk while preserving patch boundaries.
2. Run the same three-lane review in parallel on chunks.
3. Merge chunk findings, dedupe globally, then continue with Phase 4.

## Final Output Format

Return a concise report with:

- Scope used (PR diff / working tree / latest commit).
- Findings summary by lane (reuse, quality, efficiency).
- Classification summary (`safe-to-apply`, `proposal-only`, `do-not-apply`).
- Fixes applied (file + what changed).
- Skipped findings with one-line reasons.
- Ledger updates in `.opencode/simplify-ledger.md` (added/updated IDs).
- Verification commands and status.
