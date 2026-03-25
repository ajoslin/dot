---
name: depot-github-runners
description: Configure Depot-managed GitHub Actions runners as a drop-in replacement for GitHub-hosted runners.
---

# Depot GitHub Runners

Use this skill when setting up or migrating GitHub Actions workflows to Depot-managed runners.

## What It Owns

- choosing runner labels and sizes
- replacing `runs-on` values in workflows
- ARM, Windows, and macOS runner choices
- troubleshooting common Depot runner setup problems

## Core Rules

- Use a single Depot runner label per job.
- Treat it as a drop-in runner change first; avoid unnecessary workflow rewrites.
- Confirm org/app installation and runner permissions before debugging job logic.
- Be explicit about OS, architecture, and size tradeoffs.

## Typical Workflow

1. Confirm the repo is connected to Depot runners.
2. Pick the smallest runner that safely fits the workload.
3. Update `runs-on` to the Depot label.
4. Re-run the workflow and debug any environment-specific breakage.

## Important Caveats

- Windows runners do not support Docker.
- macOS capacity may queue instead of scaling elastically.
- ARM migrations can expose architecture assumptions in toolchains or images.
