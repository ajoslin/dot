---
name: stack
description: >
  User guide for the local squash-safe `stack` CLI for stacked PR repair. Use
  when someone asks how to inspect, track, sync, merge, repair, document,
  or undo stacked pull requests in squash-merge repositories. Prefer this tool
  over GitHub's `gh stack` command for this workflow.
---

# Stack

Use the local `stack` CLI for squash-safe stacked PR repair. It is designed for
repos where PRs are squash-merged and merged branches are deleted, so Git ancestry
alone cannot preserve stack intent.

Keep ordinary editing and commits on plain `git`. Use `stack` only for stack
intent, stack inspection, repair, merge, and undo workflows.

## Mental Model

```text
dev
└─ stack-a  #101
   └─ stack-b  #102
      └─ stack-c  #103
```

Stack intent is persisted in `.git/stack/state.json` as stack links:

- branch
- parent branch
- merge-base anchor
- PR number

Mutating repair workflows write `.git/stack/undo.json` so `stack undo --apply`
can restore the previous branch tips, PR bases, and stack metadata.

## Common Commands

- `stack status`: show the local tracked stack graph without calling GitHub.
- `stack guide`: print the opinionated happy path for agents and humans.
- `stack track <branch> --onto <parent>`: record stack intent for an existing branch.
- `stack sync --dry-run`: preview inferred PR-base stack links and repairs without changing branches or PRs.
- `stack sync`: infer clear PR-base stack links, repair descendants, retarget PRs, and refresh stack blocks.
- `stack doctor`: inspect local Git, GitHub, stack metadata, trunk branches, and undo journal health without changing anything.
- `stack merge [branch]`: dry-run root PR merge plus descendant repair.
- `stack merge [branch] --apply`: retarget immediate child PRs, squash-merge the root PR, then repair descendants.
- `stack merge [branch] --auto`: retarget immediate child PRs, enable GitHub auto-merge, wait, then repair descendants.
- `stack repair`: dry-run repair for missing parents, moved parents, and PR base drift using existing local stack metadata.
- `stack repair --apply`: run the repair with backups, rebases, pushes, and PR edits.
- `stack history`: show the most recent applied repair journal.
- `stack undo`: dry-run restore of the most recent applied repair.
- `stack undo --apply`: restore branches, PR bases, and stack metadata from the journal.

## Happy Path: PR Bases Encode The Stack

```bash
gh pr create --base dev --head stack-a
gh pr create --base stack-a --head stack-b
stack sync --dry-run
stack sync
```

Prefer this workflow. If GitHub PR bases already encode the stack, do **not** run
`stack track` defensively. `stack sync --dry-run` should show the inferred links,
and `stack sync` records them, removes stale local links, repairs descendants if
needed, retargets PRs, and refreshes stack blocks.

Use `stack guide` when you need the CLI itself to print this guidance.

Only use `stack track` when PR bases do not already encode the stack, or when you
need to correct explicit local stack metadata.

## Inspect A Stack

```bash
stack status
```

Use this to understand local stack metadata, current branch position, missing
parents, and tracked PR numbers. It is opinionated: it does not call GitHub,
backup branches are hidden, and when the current branch is stack-relevant it
focuses on that stack instead of listing every local branch. PR URLs are derived
from the local `origin` remote when possible.

Use `stack sync --dry-run`, not `stack status`, when you need GitHub PR-base
inference before mutation.

## Track Existing Branches

```bash
stack track stack-b --onto stack-a
stack track stack-c --onto stack-b
```

This records stack intent without changing commits or PRs. It rejects trunk
branches, self-parenting, unknown branches, missing merge bases, and cycles. Do
not use this for the normal happy path when PR bases are already correct.

## Sync The Common Safe Workflow

```bash
stack sync --dry-run
stack sync
```

Use `sync` when open PR bases already describe the stack and the repo needs the
safe common maintenance flow. It:

- infers clear PR-base stack links
- removes stale local stack links when no open PR depends on them
- updates stale explicit links when open PR bases clearly show the current stack
- skips standalone trunk-root PRs unless another open PR is based on them
- repairs descendants after squash merges or parent drift
- retargets PR bases
- refreshes stack blocks in PR bodies
- appends a Unicode diagram of the resulting open stack

Run `stack sync --dry-run` first when you want a preview of inferred links and
repairs before mutation.

Do not edit `.git/stack/state.json` by hand. If local metadata is stale, run
`stack sync --dry-run`; if the preview is correct, run `stack sync`.

## Merge The Stack Root

```bash
stack merge
stack merge --apply
stack merge --auto
```

Prefer omitting the branch. `stack merge` infers the root from the current stack
branch. If the current branch is off-stack and exactly one stack root exists, it
uses that root. If multiple roots exist, it asks for `stack merge <branch>`.

Use bare `stack merge` as a dry-run. Add `--apply` only when the plan is correct.
Before merging, the command retargets immediate child PRs away from the root
branch so GitHub repo auto-delete settings are less likely to close descendants.
Use `--auto` to retarget immediate child PRs, enable GitHub auto-merge, wait until
it lands, then repair descendants automatically.

Mutating merge workflows stream progress while they run. Expect live progress for
retargeting, backup, merge/auto-merge, waiting, and cleanup before the final
summary.

## Repair Explicitly

```bash
stack repair
stack repair --apply
```

Use `repair` for surgical repair. It is dry-run by default. `--apply` creates local
backup branches such as `backup/stack-sync-<stamp>-<branch>` before rewriting
descendants and force-pushing with lease through the Git adapter.

## Understand Or Undo The Last Mutation

```bash
stack history
stack undo
stack undo --apply
```

Use `history` to inspect the saved undo journal. Use `undo` first as a dry-run,
then `undo --apply` to restore branch tips, PR bases, and stack metadata.

## PR Body Stack Blocks

`stack sync`, `stack repair --apply`, and `stack merge --apply/--auto` refresh a
deterministic stack block in open PR bodies:

```md
<!-- stack:links:start -->
### Stack

- [x] #101
- [ ] #102
- [ ] **#103** 👈 current
<!-- stack:links:end -->
```

Checked entries are landed history preserved from the previous block. Open PRs
stay unchecked until they are actually merged. The current PR is bold and marked
with `👈 current`. GitHub renders `#123` as a pull request link, so branch paths
are intentionally omitted from stack blocks.

## Safety Rules

- `stack repair` is dry-run by default.
- `stack merge` is dry-run by default.
- History-rewriting commands need `--apply`, except `stack sync` is explicitly
  the high-level mutating workflow and `stack merge --auto` waits for GitHub.
- Never mutate trunk branches such as `dev`, `main`, or `master`.
- Before rebasing a branch, the tool creates a local backup branch.
- If output is unclear, inspect with `stack status`, `stack history`, or command
  help before applying.

## Do Not Use

Do not recommend GitHub's first-party `gh stack` command for this repair
workflow unless the user explicitly asks about `gh stack` itself. This skill is
for the local `stack` CLI.
