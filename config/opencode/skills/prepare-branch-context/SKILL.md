---
name: prepare-branch-context
description: Build a fast, actionable branch/PR/commit context pack with scope, intent, changed files, hotspots, risks, and next actions. Use before handing work to another agent, reviewing a branch, resuming unfamiliar work, or preparing a PR/code-review prompt.
---

# Prepare Branch Context

Create a read-only handoff pack so the next agent can act without re-running basic discovery. Optimize for speed: gather shape first, read only the highest-signal patches, and state unknowns instead of exhaustively proving every edge.

**Execution mode:** run in a subagent. Default: `thrifty` unless the user explicitly asks for another agent.

## Inputs

- Preferred: `prepare-branch-context from <base-branch>`
- Also supports: omitted base branch, `commits <rev-range>`, or `files <path1,path2,...>`
- If no base is given: detect GitHub default branch; if that fails, fall back to `staging` and say so.

## Fast workflow

1. **Resolve scope**
   - Determine current branch and `BASE_BRANCH`.
   - `git fetch origin "$BASE_BRANCH"`; use `origin/$BASE_BRANCH` when available, otherwise local `$BASE_BRANCH` with a note.
   - Respect explicit commit/file subset scopes.
   - If there is no diff from the compare ref, emit a minimal summary and stop.

2. **Collect cheap facts**
   - Run: branch, status, merge-base, PR lookup, diff stat, name-status, commit log.
   - If a PR exists, read title/body for intent, acceptance criteria, constraints, and known risks.
   - Keep committed, staged, and unstaged deltas separate.

3. **Read patches selectively**
   - Always read full patches for high-risk files.
   - For small diffs, reading the full patch is fine.
   - For medium/large diffs, skip low-signal tails: lockfiles, generated files, snapshots, vendored code, bulk formatting. List them as skipped.
   - For huge diffs, cap inline patch reads around the top 8-10 files. Do not delegate unless the missing context blocks a useful summary.

4. **Rank hotspots**
   - Risk signals: critical path, API/schema/contract boundary, shared library, large/complex control-flow change, concurrency/state, data migration, auth/access, payments, encryption, test gap.
   - Output every changed file as `[high|medium|low] <path> - <reason>`.
   - Treat behavior-changing source without related tests as a real hotspot signal.

5. **Map only necessary boundaries**
   - For `[high]` hotspots only, capture one-hop context when cheap: changed signatures/exports, obvious callers, and important internal imports/dependencies.
   - Do not build a full dependency graph.
   - If context is expensive, record the unknown and the exact next lookup.

## Output

Start with the standard handoff fields:

```text
answer: <1-3 sentence branch intent/readiness summary>
evidence:
  - <command/output/path/PR section> - <what it proves>
confidence: <0.00-1.00>
next_step: <single best continuation>
```

Then emit this block:

```text
BRANCH_CONTEXT_SUMMARY

SCOPE:
  current_branch: ...
  base_branch: ...
  compare_ref: ...
  mode: pr | branch | commits | files
  pr: #<number> | none

INTENT:
  objective: ...
  acceptance_criteria:
    - ...
  open_questions:
    - ...

CHANGESET:
  commits: <count>
    - <sha> <message>
  files_changed: <count>
    - <path> (<A|M|D>, +X/-Y)
  skipped_low_signal:
    - <path> - <why>

HOTSPOTS:
  - [high] <path> - <why>
  - [medium] <path> - <why>
  - [low] <path> - <why>

BOUNDARIES:
  - <high-hotspot-path>::<changed signature/export>
    callers:
      - <path>:<line> | not checked - <why>
    deps:
      - <import/path>

WORKTREE:
  clean: yes | no
  staged:
    - <path>
  unstaged:
    - <path>

RISK_SUMMARY: <1-2 sentences>
OPEN_UNKNOWNS:
  - <path> - <unknown + exact next lookup>
READY: yes
NEXT_ACTIONS:
  - ...
```

## Hard rules

- Read-only: never edit files.
- Never silently assume the base branch.
- Prefer `origin/<base>` after fetch; explicitly note fallback.
- Read PR title/body before deep diff reading when a PR exists.
- Always include risk-ranked hotspots and test-gap signals.
- Always read actual patches for `[high]` hotspots.
- Stay fast: one pass plus at most one targeted follow-up for a high hotspot. Report remaining unknowns instead of looping.
- Always emit `answer`, `evidence`, `confidence`, `next_step`, then `BRANCH_CONTEXT_SUMMARY`.
