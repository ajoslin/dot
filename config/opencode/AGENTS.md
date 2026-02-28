# AGENTS.md

Instructions for AI coding agents working with this codebase.

<!-- opensrc:start -->

## Source Code Reference

Source code for dependencies is available in `opensrc/` for deeper understanding of implementation details.

See `opensrc/sources.json` for the list of available packages and their versions.

Use this source code when you need to understand how a package works internally, not just its types/interface.

### Fetching Additional Source Code

To fetch source code for a package or repository you need to understand, run:

```bash
npx opensrc <package>           # npm package (e.g., npx opensrc zod)
npx opensrc pypi:<package>      # Python package (e.g., npx opensrc pypi:requests)
npx opensrc crates:<package>    # Rust crate (e.g., npx opensrc crates:serde)
npx opensrc <owner>/<repo>      # GitHub repo (e.g., npx opensrc vercel/ai)
```

<!-- opensrc:end -->

## Review Routing

If the user asks for a code review in natural language - including "code review", "review", "review PR", or "audit changes" - prefer invoking `/code-review` instead of doing an ad-hoc review flow.

## Research Routing

If the user asks for research, investigation, or exploratory analysis, prefer this routing:

- `explore`: default first hop for discovery (local and external); fast pattern and hotspot mapping.
- `oracle`: deep reasoning on architecture, trade-offs, and root-cause analysis.
- `librarian`: deep external libraries/docs internals and multi-repo comparisons when needed.

Default routing policy:

- Start with `explore` for nearly all investigation requests, including when users provide GitHub URLs, package names, or ask "can I use/build this with X?"
- Use `explore` to quickly gather concrete evidence first, then escalate only if needed.
- Escalate to `librarian` for deeper external repo/package internals, cross-repo comparisons, or when primary docs/history are required.
- Escalate to `oracle` for architecture decisioning, trade-off analysis, and root-cause reasoning.

For non-trivial research requests, run `explore` plus at least one of `oracle` or `librarian` in parallel and synthesize the result.

### Intent Gate (Before Routing)

Before choosing tools/agents, classify all investigation requests using this quick frame:

- Literal request: what the user explicitly asked.
- Underlying need: what decision or action they are trying to unblock.
- Success criteria: what evidence is enough for a confident next step.

Route based on the underlying need, not only the literal wording.

### Ambiguity Protocol (Explore First)

- If missing information might exist in code/docs/history, do not ask immediately; run `explore` first.
- If multiple interpretations are plausible, cover the top likely interpretations with parallel `explore` searches.
- Ask the user only when the decision materially changes outcome and cannot be resolved via repository evidence.

### Trigger Phrase Routing (Fast Heuristics)

- GitHub/repo/package URL or name provided -> start `explore` immediately.
- "look into", "investigate", "trace", "where is", "how does X work" -> start `explore` immediately.
- "can I use/build this with X" -> start `explore` first; then escalate to `librarian` if external internals/docs are needed.
- "why is this failing" with architecture uncertainty -> run `explore` and `oracle` in parallel.

### Parallel Research Examples

- External feasibility question: `explore` + `librarian` in parallel, then synthesize recommendation.
- Root-cause investigation: `explore` + `oracle` in parallel, then synthesize fix path.
- Broad unknowns: multiple `explore` calls in parallel; escalate once evidence plateaus.

## Build Routing

For implementation-heavy requests (feature work, bug fixes, refactors with concrete changes), prefer `build` as the primary agent.

- Use `build` for end-to-end coding and verification.
- Within `build`, still route discovery through `explore` first when scope is unclear.
- Escalate to `oracle` for difficult architecture/debug decisions and `librarian` for deep external internals.
