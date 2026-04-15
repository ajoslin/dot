---
name: prepare-branch-context
description: Build an actionable branch/PR/commit context pack so follow-up agents can act immediately with the right scope, hotspots, risks, and review intent.
---

# Prepare Branch Context

Build a **standardized, actionable context pack** for the current branch so follow-up agents can act immediately without re-discovery.

**Execution Mode:** This skill MUST always be executed in a **subagent**. Default subagent type is `thrifty`. Use a different subagent type only when explicitly requested.

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
- Gather intent context (PR title/body).
- Read code changes with scale-aware strategy for large diffs.
- Identify **hotspots** and produce a **risk-ranked file list** (including test coverage gaps).
- Map **interface boundaries** for hotspot files — what they connect to in the codebase.
- Run a single **high-hotspot gap-fill pass** so top-risk areas are not under-read.
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

- Prefer the remote-tracking base branch as the comparison source. Fetch it first:

  ```bash
  git fetch origin "$BASE_BRANCH"
  ```

  If fetch succeeds, set `COMPARE_REF="origin/$BASE_BRANCH"` and use that for merge-base, diff, and log commands.

- If fetch fails, confirm the local branch exists and fall back to it:

  ```bash
  git branch --show-current
  git rev-parse --verify "$BASE_BRANCH"
  ```

  In that fallback case, set `COMPARE_REF="$BASE_BRANCH"` and say the remote fetch failed.

- If invoked with `commits <rev-range>` or `files <path1,path2,...>`, scope the entire analysis to that subset.

- Early exit: if there is no divergence from `COMPARE_REF`, emit a minimal summary stating no branch delta and stop.

### 2. Capture full repository state

Collect committed, staged, and unstaged deltas separately:

```bash
git branch --show-current
git status --short --branch
git merge-base HEAD "$COMPARE_REF"
git diff --name-only                    # unstaged
git diff --cached --name-only           # staged
git diff "$COMPARE_REF"...HEAD --name-only  # committed branch delta
```

All three matter. A mid-work invocation needs to distinguish what's committed vs. in-flight.

### 3. Pull PR context before reading code

```bash
gh pr list --head "$(git branch --show-current)" --json number,title,body,url,state
```

If a PR exists, also read its title/body directly:

```bash
gh pr view <number> --json title,body,url,state
```

Extract:

- acceptance criteria
- implementation notes
- requested follow-ups or known risks

### 4. Gather diff with scale-aware strategy

First, always collect shape (cheap):

```bash
git diff "$COMPARE_REF"...HEAD --stat
git diff "$COMPARE_REF"...HEAD --name-status
git log "$COMPARE_REF"..HEAD --oneline
```

Then choose read depth based on total diff lines changed:

| Diff size | Strategy |
|-----------|----------|
| **Small** (< ~1000 lines) | Read full patch: `git diff "$COMPARE_REF"...HEAD` |
| **Medium** (1000-4000 lines) | Read full patch for all hotspot files (Step 5). Stat-only for low-signal files (lockfiles, generated code, test snapshots, vendored deps) — list them as "skipped - low signal". |
| **Large** (> 4000 lines) | Read full patch for top ~10-12 hotspot files. Stat-only for the rest. Delegate to `explore` for boundary context on files you couldn't read inline (see below). |

**Always read the actual diff for hotspot files regardless of total size.** The diff is the payload — stat lines and labels don't let the downstream agent reason about correctness. What you trim is the low-signal tail, not the important files.

**Large diff delegation to `explore`:**

For diffs over ~4000 lines, delegate to `explore` to fill in context the skill couldn't read inline:

- Pass the full `--stat` and `--name-status` output
- Pass your hotspot risk ranking from Step 5
- Ask `explore` to investigate boundary context (callers, dependencies, surrounding code) for the hotspot files, and provide summary context for files you skipped
- `explore` supplements the diff — it does not replace reading it

Read individual file patches with:

```bash
git diff "$COMPARE_REF"...HEAD -- <path>
```

### 5. Build hotspot and risk map

For every changed file, evaluate risk using these signals:

- **Critical path:** auth, payments, data migration, encryption, access control
- **Blast radius:** API/schema/contract boundary changes, shared library edits
- **Complexity:** large line delta, complex control-flow edits, concurrency/state changes
- **Test gap:** behavior-changing source edit with no corresponding test change

Produce a ranked list: `[high|medium|low] <path> - <reason>`.

Files with multiple risk signals should rank higher. Test gaps are a first-class risk signal — flag any new modules, endpoints, or handlers introduced without corresponding test changes.

### 6. Map interface boundaries for hotspots

For each high-risk hotspot file, capture the **immediate connection edges** so the downstream agent understands how the changed code wires into the system:

1. **Changed signatures:** list the function, method, class, or export signatures that were added, modified, or removed in the diff.
2. **Callers:** grep the repo for usages of those function/method names. Report as `<caller-path>:<line> calls <name>`.
3. **Dependencies:** list the key imports the changed code relies on (skip stdlib/builtins, focus on project-internal and critical external deps).

Keep this tight — only high-risk hotspots, only immediate edges (one hop). The goal is not a full dependency graph; it's enough context for the downstream agent to reason about blast radius and correctness without re-reading the codebase.

For large diffs where `explore` was invoked in Step 4, ask `explore` to include boundary edges in its investigation.

### 7. Run one high-hotspot gap-fill pass

After the initial diff read, hotspot ranking, and boundary mapping, do **one more targeted pass** over every `[high]` hotspot.

For each `[high]` hotspot, check:

- **patch read:** did you read the actual diff for this file?
- **one-hop context read:** did you read at least one caller, adjacent file, or surrounding module file?
- **tests checked:** did you read related tests, if any exist?
- **major unknowns:** is there still a major unanswered question about correctness, blast radius, or intent?

If any answer is **no**, do one targeted follow-up read now. Good follow-ups:

- read one more file patch or adjacent source file
- grep/read one caller or one callee
- grep/read related test files
- if the PR is huge, ask `explore` for the missing context on that hotspot only

This is a **single extra pass**, not an open-ended loop. Stop after this pass and report any remaining unknowns explicitly.

### 8. Emit standardized handoff output

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

BOUNDARIES:
  - <hotspot-path>::<changed-signature>
    callers:
      - <caller-path>:<line>
    deps:
      - <import-path>

OPEN_UNKNOWNS:
  - <hotspot-path> - <what still could not be confirmed after the gap-fill pass>

PR_CONTEXT:
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

## Rules

- Read-only skill. Do not change files.
- Do not silently assume any base branch. Auto-detect or use explicit input.
- If auto-detection fails, fall back to `staging` and state the fallback.
- Prefer `origin/<base-branch>` as the compare ref. Fetch it first and use it when available.
- If remote fetch fails, fall back to the local base branch and say so explicitly.
- If PR exists, read PR title/body before deep diff analysis.
- Read actual patch content for high-signal files, not stats alone.
- Always produce a **risk-ranked hotspot list** (test gaps are a hotspot signal, not a separate section).
- Always include **interface boundary edges** for high-risk hotspots.
- Always read the actual diff for hotspot files regardless of total diff size.
- Scale diff reading to diff size — trim the low-signal tail, not the important files.
- After the first pass, do one targeted gap-fill pass for every `[high]` hotspot.
- In that gap-fill pass, ensure patch read + one-hop context + tests checked where applicable.
- For diffs > 4000 lines, delegate to `explore` for boundary context on files you couldn't read inline.
- Do not spin in an open-ended sufficiency loop; one extra pass is enough for v1.
- If there is no divergence from `COMPARE_REF`, emit a minimal summary and stop.
- Always emit the structured `BRANCH_CONTEXT_SUMMARY` block. Downstream agents depend on this format.
- Always include `answer`, `evidence`, `confidence`, and `next_step` fields before `BRANCH_CONTEXT_SUMMARY`.
- Keep the summary actionable. Another LLM should be able to act immediately without re-running git commands.
