---
name: depot-container-builds
description: Configure and run Depot remote container builds using `depot build` and `depot bake`.
---

# Depot Container Builds

Use this skill when building Docker images with Depot instead of local `docker build` or `docker buildx`.

## What It Owns

- `depot build` and `depot bake` usage
- multi-platform image builds
- cache behavior and remote builder tradeoffs
- registry push / load / save behavior
- debugging common Depot build failures

## Core Rules

- Prefer `depot build` as the direct replacement for `docker buildx build`.
- Use `--push`, `--load`, or `--save` intentionally; do not assume local images exist after a remote build.
- Prefer native multi-platform builds instead of emulation when Depot supports the target architectures.
- Treat remote cache behavior as the default, not an add-on.

## Typical Workflow

1. Confirm the target Dockerfile, build context, and output mode.
2. Choose whether the image should be loaded locally, pushed, or saved remotely.
3. Run the narrowest useful build command first.
4. If builds fail, debug Dockerfile issues before assuming Depot-specific problems.

## Important Caveats

- Remote builds do not automatically load into the local Docker daemon.
- Provenance settings can affect registry platform metadata.
- Secrets, SSH forwarding, and registry auth should be configured explicitly.
