---
name: prepare-branch-context
description: Build an actionable branch/PR/commit context pack so follow-up agents can act immediately with the right scope, hotspots, risks, and review intent.
---

# Prepare Branch Context

Build a **standardized, actionable context pack** for the current branch so follow-up agents can act immediately without re-discovery.

Preferred invocation:

- `prepare-branch-context from <base-branch>`

Optional extensions:

- `prepare-branch-context` (auto-resolve base branch)
- `prepare-branch-context from <base-branch> commits <rev-range>`
- `prepare-branch-context from <base-branch> files <path1,path2,...>`

Default behavior:

- If `<base-branch>` is omitted, auto-detect the repo default branch first. If that fails, fall back to `staging` and say so.
- Prefer an explicitly named base branch whenever the user provides one.

## Outcome

- Resolve the correct review scope (PR/MR, branch diff, or explicit commit/file subset).
- Gather intent context (PR body, review threads, linked tickets).
- Read code changes with scale-aware strategy for large diffs.
- Identify **hotspots** and produce a **risk-ranked file list**.
- Evaluate **test coverage signal** for changed behavior.
- Emit a structured `BRANCH_CONTEXT_SUMMARY` block for downstream agents.
- Use the same handoff phrasing style as `explore`/`librarian` (`answer`, `evidence`, `confidence`, `next_step`).

## Steps

### 1. Resolve scope and base branch

- Parse `<base-branch>` from `prepare-branch-context from <base-branch>` when present.
- If omitted, auto-detect:

  ```bash
  gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
  ```

  Use result as `BASE_BRANCH`. If detection fails, fall back to `staging` and state the fallback.

- Confirm the branch exists:

  ```bash
  git branch --show-current
  git rev-parse --verify "$BASE_BRANCH"
  ```

  If local `$BASE_BRANCH` is missing but `origin/$BASE_BRANCH` exists, use `origin/$BASE_BRANCH`.

- Early exit: if current branch equals base branch, or there is no divergence, emit a minimal summary stating no branch delta and stop.

### 2. Capture full repository state

Collect committed, staged, and unstaged deltas separately:

```bash
git branch --show-current
git status --short --branch
git merge-base HEAD "$BASE_BRANCH"
git diff --name-only                    # unstaged
git diff --cached --name-only           # staged
git diff "$BASE_BRANCH"...HEAD --name-only  # committed branch delta
```

All three matter. A mid-work invocation needs to distinguish what's committed vs. in-flight.

### 3. Pull PR context before reading code

```bash
gh pr list --head "$(git branch --show-current)" --json number,title,body,url,state
```

If a PR exists, also pull review threads and comments:

```bash
gh pr view <number> --json title,body,url,state,comments,reviews
```

Extract:

- acceptance criteria
- implementation notes
- **unresolved reviewer concerns** (highest signal for downstream agents)
- requested follow-ups or known risks

### 4. Pull linked ticket context (Linear or equivalent)

- Search PR body, comments, and review threads for ticket links (e.g. `linear.app`, Jira, etc.).
- If integration is available, read ticket title, problem statement, scope, and acceptance criteria.
- If tooling is unavailable, note limitation and continue.

### 5. Gather diff with scale-aware strategy

First, collect shape:

```bash
git diff "$BASE_BRANCH"...HEAD --stat
git diff "$BASE_BRANCH"...HEAD --name-status
git log "$BASE_BRANCH"..HEAD --oneline
```

Then choose read depth based on diff size:

| Diff size | Strategy |
|-----------|----------|
| **Small** (< ~500 lines) | Read full patch |
| **Medium** (500–2000 lines) | Read full patch; if context window pressure, summarize low-signal files |
| **Large** (> 2000 lines) | Map all files via `--stat` and `--name-status`. Fully read top hotspot files. Summarize the rest from stat + commit messages. |

Patch command:

```bash
git diff "$BASE_BRANCH"...HEAD
```

For selective reads on large diffs:

```bash
git diff "$BASE_BRANCH"...HEAD -- <path>
```

### 6. Build hotspot and risk map

For every changed file, evaluate risk using these signals:

- **Critical path:** auth, payments, data migration, encryption, access control
- **Blast radius:** API/schema/contract boundary changes, shared library edits
- **Complexity:** large line delta, complex control-flow edits, concurrency/state changes
- **Test gap:** behavior-changing source edit with no corresponding test change
- **Review heat:** file mentioned in unresolved reviewer feedback

Produce a ranked list: `[high|medium|low] <path> - <reason>`.

Files with multiple risk signals should rank higher.

### 7. Evaluate test coverage signal

- Identify changed test files and map them to changed source files.
- Flag source files with behavior changes but **no corresponding test updates**.
- If PR discussion or review threads mention missing tests, call those out explicitly.
- Note any new modules/endpoints/handlers introduced without test scaffolding.

### 8. Commit history narrative

```bash
git log "$BASE_BRANCH"..HEAD --oneline
```

Use commit messages to understand branch evolution: was it a clean progression, or lots of fix-ups? Note if commits suggest unfinished work (WIP, fixup, squash candidates).

### 9. (Optional) Commit-range or file-scoped lens

- If invoked with `commits <rev-range>`, scope the entire analysis to that range.
- If invoked with `files <path1,path2,...>`, provide targeted hotspots/risks for those files only.

### 10. Emit standardized handoff output

Use the common cross-agent handoff fields first:

```text
answer: <1-3 sentence direct summary of branch intent and readiness>
evidence:
  - <path-or-url>:<line or section> - <what this proves>
confidence: <0.00-1.00>
next_step: <single actionable continuation>
```

Then include the branch payload block exactly:

```text
BRANCH_CONTEXT_SUMMARY

SCOPE:
  current_branch: ...
  base_branch: ...
  compare_ref: ... (e.g. origin/main...HEAD)
  mode: pr | branch | commits | files
  pr: #<number> | none
  ticket: <url> | none

INTENT:
  objective: <one sentence>
  acceptance_criteria:
    - ...
  open_questions:
    - ...

CHANGESET:
  commits: <count>
    - <sha> <message>
  files_changed: <count>
    - <path> (<A|M|D>, +X/-Y)
  subsystems:
    - ...

HOTSPOTS:
  - [high] <path> - <why>
  - [medium] <path> - <why>
  - [low] <path> - <why>

TEST_SIGNAL:
  tests_changed: yes | no
  coverage_gaps:
    - <source path> - <what's untested>
  suggested_tests:
    - ...

REVIEW_CONTEXT:
  unresolved_feedback:
    - <reviewer>: <concern>
  constraints:
    - ...

WORKTREE:
  clean: yes | no
  staged:
    - <path>
  unstaged:
    - <path>

RISK_SUMMARY: <1-2 sentence overall assessment>

READY: yes
NEXT_ACTIONS:
  - ...
```

### 11. Signal readiness

State that this summary is ready to pass directly into downstream agents (review, implementation, etc.).

## Rules

- Read-only skill. Do not change files.
- Do not silently assume any base branch. Auto-detect or use explicit input.
- If auto-detection fails, fall back to `staging` and state the fallback.
- If PR exists, read PR discussion and review threads before deep diff analysis.
- Read actual patch content for high-signal files, not stats alone.
- Always produce a **risk-ranked hotspot list**.
- Always include **test coverage signal**.
- Scale diff reading to diff size. Do not dump 5000-line patches blindly.
- If current branch equals base branch or there is no divergence, emit a minimal summary and stop.
- Always emit the structured `BRANCH_CONTEXT_SUMMARY` block. Downstream agents depend on this format.
- Always include `answer`, `evidence`, `confidence`, and `next_step` fields before `BRANCH_CONTEXT_SUMMARY`.
- Keep the summary actionable. Another LLM should be able to act immediately without re-running git commands.
