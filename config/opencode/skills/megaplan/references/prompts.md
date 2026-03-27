# Megaplan Prompt Templates

**Context hygiene rule**: Subagents read their own artifacts from disk whenever possible. The orchestrator passes file paths and short identifiers, NOT full file contents. This keeps the orchestrator's context clean across long plans.

For early steps (plan, critique, gate, revise, finalize), the orchestrator passes the plan directory path and lets the subagent read what it needs. For plan/critique the idea and user notes are short enough to inline. Never inline finalize.json, full plan text, or flag registries into the orchestrator's own context.

`runbook.md` is the continuity source of truth for resume and next-action routing. Every resumed session should read it first.

## Plan Prompt (delegate to `build`)

```
You are creating an implementation plan for the following idea.

Idea: {idea}
{if user_notes}
User notes and answers:
{notes_short}
{end}

Project directory: {project_dir}
Plan directory: {plan_dir}

If a state.json exists in the plan directory, read it for prior clarification context. Also read `runbook.md` for the current step and next action. Otherwise, identify ambiguities, ask clarifying questions, and state your assumptions.

Requirements:
- Inspect the actual repository before planning.
- Produce a concrete implementation plan in markdown.
- Define observable success criteria.
- Use the `questions` field for ambiguities that would materially change implementation.
- Use the `assumptions` field for defaults you are making so planning can proceed now.
- Prefer cheap validation steps early.
- If user notes answer earlier questions, incorporate them into the draft plan instead of re-asking them.

Plan structure requirements:
- One H1 title
- `## Overview` section
- Numbered step sections: `## Step N: Description` (flat) or `### Step N: Description` (under `## Phase` headers)
- Each step: file references in backticks, numbered substeps, scope tag
- `## Execution Order` or `## Validation Order` section

Return your answer as JSON with these fields:
- plan: string (the full markdown plan)
- questions: string[] (ambiguities that would materially change implementation)
- success_criteria: string[] (observable verification criteria)
- assumptions: string[] (defaults you are making)
```

## Critique Prompt (parallel council -- 3x `deep`)

Run three `deep` critics in parallel. Each gets the same base prompt below, with a **lens preamble** prepended. Launch all three as simultaneous Task calls.

### Base critique prompt (shared by all three)

```
{lens_preamble}

You are an independent reviewer. Critique the plan against the actual repository.

Project directory: {project_dir}
Plan directory: {plan_dir}

Idea: {idea}
{if user_notes}
User notes: {notes_short}
{end}

Read these artifacts yourself:
- The latest plan_v*.md in {plan_dir} (the plan to critique)
- The latest plan_v*.meta.json in {plan_dir} (plan metadata)
- {plan_dir}/faults.json (existing flags, if it exists)
- {plan_dir}/state.json (for iteration context)
- {plan_dir}/runbook.md (for current step / next action)

Robustness level: {robustness}. {robustness_instruction}

Requirements:
- Consider whether the plan is at the right level of abstraction.
- Reuse existing flag IDs when the same concern is still open.
- `verified_flag_ids` should list previously addressed flags that now appear resolved.
- Focus on concrete issues that would cause real problems.
- Verify the plan remains aligned with the user's original intent.
- Check plan structure: H1 title, Overview, numbered steps with file refs, execution/validation order.
- Flag scope creep when the plan grows beyond the original idea. Use "Scope creep:" prefix.
- Assign severity_hint carefully: `likely-significant`, `likely-minor`, or `uncertain`.

Return JSON:
- flags: array of { id, concern, category, severity_hint, evidence }
  - category: correctness | security | completeness | performance | maintainability | other
  - severity_hint: likely-significant | likely-minor | uncertain
- verified_flag_ids: string[] (previously addressed flags now resolved)
- disputed_flag_ids: string[] (flags you disagree with)
```

### Lens preambles

**Feasibility critic** (`deep`):
```
CRITIQUE LENS: FEASIBILITY
Focus on feasibility: does this plan match the actual codebase? Are file references real and pointing to the right locations? Can the steps be executed as written? Are dependencies ordered correctly? Will the executor hit blocking surprises? Inspect the repository to ground every flag in concrete evidence.
```

**Architecture critic** (`deep`):
```
CRITIQUE LENS: ARCHITECTURE
Focus on architecture: is this the simplest approach that solves the stated problem? Does it introduce unnecessary complexity, layers, or abstractions? Will it create maintenance burden? Could the same goal be achieved with fewer steps or less machinery? Over-engineering concerns should use category `maintainability` and prefix the concern with "Over-engineering:".
```

**Risk critic** (`deep`):
```
CRITIQUE LENS: RISK
Focus on risk: what could go wrong during or after execution? What edge cases are missed? What are the security implications? What happens when assumptions are wrong? What failure modes exist that the plan doesn't account for? What regression risk does this introduce?
```

### Flag merging after all three return

1. Collect all flags from all three critics into a single list
2. For each pair of flags, compute Jaccard similarity on normalized word sets of the `concern` field
3. If similarity > 0.5, they are duplicates:
   - Keep the flag with higher severity_hint (`likely-significant` > `uncertain` > `likely-minor`)
   - Append to evidence: "Cross-validated: flagged independently by {N}/3 critics ({critic_names})"
   - If 2+ critics flagged it, force severity_hint to `likely-significant`
4. Renumber all merged flags sequentially: FLAG-001, FLAG-002, ...
5. Union all verified_flag_ids and disputed_flag_ids across critics

### Robustness instructions

- **light**: "Be pragmatic. Only flag issues that would cause real failures. Ignore style, minor edge cases, and issues the executor will naturally resolve."
- **standard**: "Use balanced judgment. Flag significant risks, but do not spend flags on minor polish or executor-obvious boilerplate."

## Gate Prompt (delegate to `build`)

The orchestrator computes gate signals (see evaluation.md) and passes them inline -- this is the ONE place the orchestrator inlines computed data, because the signals are a small JSON blob it already computed.

```
You are the gatekeeper for the megaplan workflow. Make the continuation decision.

Project directory: {project_dir}
Plan directory: {plan_dir}

Idea: {idea}

Read the latest plan_v*.md from {plan_dir} for context.
Read {plan_dir}/runbook.md for current step and next action.

Gate signals (computed by orchestrator):
{gate_signals_json}

Requirements:
- Decide exactly one of: PROCEED, ITERATE, ESCALATE.
- Use weighted score, flag details, plan delta, recurring critiques, and loop summary as judgment context.
- PROCEED when execution should move forward now.
- ITERATE when revising the plan is the best next move.
- ESCALATE when the loop is stuck or churn is recurring.
- When recommending PROCEED with unresolved flags, populate accepted_tradeoffs.

Return JSON:
- recommendation: PROCEED | ITERATE | ESCALATE
- rationale: string
- signals_assessment: string (score trajectory, plan delta, recurring critiques, flag weight)
- warnings: string[]
- settled_decisions: array of { id, decision, rationale }
- accepted_tradeoffs: array of { flag_id, subsystem, concern, rationale } (only when PROCEED)
```

## Revise Prompt (delegate to `build`)

```
You are revising an implementation plan after critique and gate feedback.

Project directory: {project_dir}
Plan directory: {plan_dir}

Idea: {idea}
{if user_notes}User notes: {notes_short}{end}

Read these artifacts yourself:
- The latest plan_v*.md in {plan_dir} (current plan to revise)
- The latest plan_v*.meta.json (plan metadata)
- {plan_dir}/gate.json (gate feedback)
- {plan_dir}/faults.json (flag registry -- focus on flags with status "open" and severity "significant")
- {plan_dir}/runbook.md (current step / next action)

Requirements:
- Update the plan to address the significant issues.
- Keep the plan readable and executable.
- Return flags_addressed with the exact flag IDs you addressed.
- Verify the plan remains aligned with the user's original intent.
- Remove unjustified scope growth.
- Maintain structure: H1 title, Overview, phase/step sections, execution/validation order.

Return JSON:
- plan: string (updated markdown)
- changes_summary: string
- flags_addressed: string[] (exact flag IDs)
- assumptions: string[]
- success_criteria: string[]
- questions: string[]
```

## Finalize Prompt (delegate to `build`)

```
You are preparing an execution-ready briefing from the approved plan.

Project directory: {project_dir}
Plan directory: {plan_dir}

Idea: {idea}

Read these artifacts yourself:
- The latest plan_v*.md in {plan_dir} (approved plan)
- The latest plan_v*.meta.json (plan metadata, includes success_criteria)
- {plan_dir}/gate.json (gate decision and accepted tradeoffs)
- {plan_dir}/faults.json (flag registry)
- {plan_dir}/runbook.md (source of truth for next execution step)

Requirements:
- Produce structured JSON only.
- `tasks`: ordered array, each with: id (T1, T2...), description, depends_on, status ("pending"), executor_notes (""), reviewer_verdict ("")
- `watch_items`: runtime risks, critique concerns, assumptions to keep visible
- `sense_checks`: one per task, each with: id (SC1...), task_id, question, verdict ("")
- `meta_commentary`: execution guidance, gotchas, judgment calls
- Output should be self-contained: an executor reading only finalize.json should have everything needed to work.

Return JSON matching the schema above.
```

## Execute Loop Guidance

Execution now happens in the main thread. Delegate only fresh-eyes tasks: `simplify`, `review`, and specialist verification when needed.

## Never-stop orchestration note

Before the first WorkingBatch, the orchestrator should run `/never-stop` for the current session using the exact `## Continue` section from `runbook.md`.

`Read runbook.md first and trust it over conversational memory. If Step is execute, find the next unblocked WorkingBatch, implement it in the main thread, delegate fresh simplify, delegate fresh review, fix anything required, commit atomically, update runbook.md, and repeat. Stop only on COMPLETE or BLOCKED.`

After each meaningful step, restate or refresh the same continuation and update `runbook.md` so idle or resumed sessions resume the loop.

When execution exits `COMPLETE` or `BLOCKED`, run `/never-stop-clear` immediately.

## Simplify Prompt (delegate to a fresh subagent)

```
Load the `simplify` skill and run it on the current pending diff.

Keep changes scoped to the current work and return a short summary.
```

## Pre-Commit Review Prompt (delegate to a fresh subagent)

```
Review the current pending diff before commit.

Read these artifacts yourself:
- {plan_dir}/runbook.md
- {plan_dir}/finalize.json
- {plan_dir}/plan_v*.meta.json (latest)
- The latest plan_v*.md in {plan_dir}
- current git diff and git status

Re-run the smallest relevant verification needed. Check whether the diff is complete, safe to commit, aligned with the current batch, and still consistent with the overall approved plan.

Return JSON:
- verdict: approve | needs_changes
- summary: string
- issues: string[]
- commands_run: string[]
```

## Review Prompt (delegate to `deep`)

The review subagent reads all artifacts itself. The orchestrator passes only the path and key identifiers -- NOT the file contents.

```
Review the megaplan execution results.

Project directory: {project_dir}
Plan directory: {plan_dir}
Plan name: {plan_name}

Idea: {idea}

Read these artifacts yourself:
- {plan_dir}/runbook.md (source of truth for execution status and next action)
- {plan_dir}/finalize.json (task list with execution updates)
- {plan_dir}/plan_v*.meta.json (latest -- contains success_criteria)
- {plan_dir}/gate.json (gate decision and accepted tradeoffs)
- Run `git log --oneline` to see the megaplan batch commits

Requirements:
- Verify each task was completed correctly by inspecting the actual repository files.
- Check that files_changed in each task actually exist and contain the expected changes.
- Review the git commits: each batch should be a clean atomic commit.
- Check success criteria from plan metadata -- each must pass with concrete evidence.
- Verify sense checks.
- Provide evidence-backed verdicts, not rubber stamps. "Pass" or "Looks good" without evidence is insufficient.
- If issues are found, identify which batch commit(s) contain the problem.

Return JSON:
- review_verdict: approved | needs_rework
- criteria: array of { name, pass (boolean), evidence }
- issues: string[] (problems found, reference batch/commit when relevant)
- summary: string
- task_verdicts: array of { task_id, reviewer_verdict, evidence_files }
- sense_check_verdicts: array of { sense_check_id, verdict }
```
