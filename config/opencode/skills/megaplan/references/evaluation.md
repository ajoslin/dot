# Gate Evaluation Logic

The orchestrator runs this logic directly. Do not delegate gate signal computation.

## Flag Severity Resolution

When critique returns `severity_hint`, resolve to final severity:
- `likely-significant` -> `significant`
- `likely-minor` -> `minor`
- `uncertain` -> `significant`

## Flag Statuses

- `open`: raised by critique, not yet addressed
- `addressed`: planner claims to have fixed it
- `verified`: critic confirmed it's resolved
- `disputed`: critic disagrees with the flag
- Blocking statuses: `open`, `disputed`

## Weighted Score

Compute the weighted score from unresolved significant flags:

| Category | Weight |
|----------|--------|
| security | 3.0 |
| correctness | 2.0 |
| completeness | 1.5 |
| performance | 1.0 |
| maintainability | 0.75 |
| other | 1.0 |

Implementation-detail signals in concerns (column, schema, field, pseudocode, placeholder) get weight 0.5 regardless of category.

`weighted_score = sum(weight for each unresolved significant flag)`

## Gate Signals

Before delegating the gate decision to `build`, compute and include these signals:

```json
{
  "iteration": <current iteration>,
  "idea": "<original idea>",
  "significant_flags": <count of unresolved significant>,
  "unresolved_flags": [{ "id", "concern", "category", "severity", "status" }],
  "resolved_flags": [{ "id", "concern", "resolution" }],
  "weighted_score": <number>,
  "weighted_history": [<scores from previous iterations>],
  "plan_delta_from_previous": <percent change or null if first>,
  "recurring_critiques": [<concerns appearing in consecutive critiques>],
  "scope_creep_flags": [<flag IDs with scope creep terms>],
  "loop_summary": "<iteration N. trajectory. deltas. recurring count. resolved count. open count.>"
}
```

## Plan Delta

If a previous plan version exists, compute approximate percent change. Use your judgment -- if the plan changed substantially (>30%), note it. If it barely changed (<5%), the loop may be churning.

## Recurring Critiques

Compare consecutive critique files. If the same concern appears in both (same normalized text), it's recurring. Recurring critiques that the loop can't fix are candidates for force-proceed or escalation.

## Preflight Checks

Before accepting a PROCEED recommendation:
1. Project directory exists and is writable
2. Success criteria are present in plan metadata
3. No unresolved significant flags remain (or they're accepted as tradeoffs)

If preflight fails with PROCEED recommendation, treat as "PROCEED but blocked" -- stay in critiqued state, next step is revise.

## Gate Decision Routing

After receiving gate JSON from `build`:

| Recommendation | Preflight | Next State | Next Step |
|---------------|-----------|------------|-----------|
| PROCEED | pass | gated | finalize |
| PROCEED | fail | critiqued | revise |
| ITERATE | n/a | critiqued | revise |
| ESCALATE | n/a | critiqued | ask user |

## Orchestrator Guidance

Generate a plain-language summary for the user:

- First iteration: "First iteration; follow gate recommendation."
- PROCEED + pass: "Plan passed gate and preflight. Proceed to finalize."
- PROCEED + fail: "Gate says PROCEED but preflight blocked. Fix: {failing checks}."
- ESCALATE: "Gate escalated. Ask the user: force-proceed, add-note, or abort."
- ITERATE + plateaued + recurring: "Score plateaued with recurring critiques. Consider force-proceeding."
- ITERATE + improving: "Score improving ({old} -> {new}). Continue to revise."
- ITERATE + worsening: "Score worsening ({old} -> {new}). Investigate divergence."

## Iteration Limits

- Iteration >= 5: warn about high iteration count
- Iteration >= 12: strongly recommend escalation
- Score plateaued with recurring critiques: suggest force-proceed

## Force-Proceed Override

When user chooses to force-proceed after ESCALATE:
1. Set `override_forced: true` in gate.json
2. Accept remaining flags as tradeoffs
3. Advance state to "gated"
4. Proceed to finalize
