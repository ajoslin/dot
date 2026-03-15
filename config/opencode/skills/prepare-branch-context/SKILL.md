---
name: prepare-branch-context
description: Analyze the current branch against a chosen base branch and related PR context so followup requests start with the right diff in mind. Use when asked to prepare branch context, especially as `prepare-branch-context from BRANCH_NAME`; encourage explicit base branch selection and default to `staging` when omitted.
---

# Prepare Branch Context

Build a working understanding of the current branch before handling followup requests.

Preferred invocation:

- `prepare-branch-context from <base-branch>`

Default behavior:

- If `<base-branch>` is omitted, use `staging`.
- Prefer an explicitly named base branch whenever the user provides one.

## Outcome

- Identify the current branch and chosen base branch.
- Pull related PR context when available.
- Read a linked Linear ticket when one is discoverable and the necessary Linear tooling is authenticated.
- Read the real diff and commit history from the chosen base branch to `HEAD`.
- Summarize what changed, where it changed, and any active review context.

## Steps

1. Resolve the base branch.

   - Parse `<base-branch>` from `prepare-branch-context from <base-branch>` when present.
   - Otherwise set `BASE_BRANCH=staging`.
   - Confirm the branch exists locally or remotely before using it.

   Example commands:

   ```bash
   git branch --show-current
   git rev-parse --verify "$BASE_BRANCH"
   ```

   If the local branch does not exist but `origin/$BASE_BRANCH` does, compare against `origin/$BASE_BRANCH` instead.

2. Identify current state.

   Collect:

   ```bash
   git branch --show-current
   git status --short --branch
   git merge-base HEAD "$BASE_BRANCH"
   ```

3. Check for a related PR before reading code.

   ```bash
   gh pr list --head "$(git branch --show-current)" --json number,title,body,url,state
   ```

   If a PR exists, read its title, body, and any accessible review discussion for:

   - acceptance criteria
   - implementation notes
   - open questions
   - review feedback still in play

4. Check for a linked Linear ticket before reading code.

   Look for a `linear.app` link in PR comments or other related PR discussion.

   If a `linear.app` link is present and a Linear tool or authenticated integration is available, read the ticket before reading the diff so you understand the product intent, scope, and acceptance criteria.

   If no Linear tool is available, note that limitation and continue with PR and code context.

5. Gather the branch diff from the chosen base.

   Read both the stat summary and the actual patch:

   ```bash
   git diff "$BASE_BRANCH"...HEAD --stat
   git diff "$BASE_BRANCH"...HEAD
   ```

   If using a remote tracking base, use the same commands with `origin/$BASE_BRANCH`.

   Read the diff carefully enough to understand:

   - files added, changed, or removed
   - the purpose of the changes
   - notable implementation patterns or decisions

6. Review commit history on this branch.

   ```bash
   git log "$BASE_BRANCH"..HEAD --oneline
   ```

   Use commit messages to understand how the branch evolved.

7. Summarize your understanding to the user.

   Include:

   - branch name and base branch used
   - associated PR, if found
   - linked Linear ticket, if found
   - high-level purpose of the branch
   - key files and subsystems affected
   - important design decisions or patterns visible in the diff
   - PR context or open review discussion, if any
   - Linear context or acceptance criteria, if any
   - current working tree state

8. Signal readiness.

   State that you are ready for followup questions or implementation work on this branch.

## Rules

- Read-only skill. Do not change files.
- Do not silently assume `main` or `origin/main` as the base branch.
- Prefer an explicitly specified base branch when the user provides one.
- If no base branch is specified, default to `staging` and say that you did.
- If an associated PR exists, read it before reading the code diff.
- If a linked Linear ticket can be discovered and tooling is available, read it before reading the code diff.
- Read the actual diff content, not only the summary.
- If the diff is large, first map the overall structure, then read the highest-signal files in detail.
- If the current branch is the chosen base branch, or there is no divergence from it, say there is nothing to analyze.
