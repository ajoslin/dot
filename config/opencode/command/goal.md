---
description: Manage the active goal for this session
---

<user-request>
$ARGUMENTS
</user-request>

You are handling the `/goal` custom command. Interpret the user request
literally and manage the existing goal state only as explicitly requested.

Critical guardrail:
- Do NOT call `create_goal` just because `/goal` was invoked, because the user
  is describing work, or because no goal exists.
- Call `create_goal` ONLY when the user explicitly commands goal creation or
  setting. Explicit commands include a bare `/goal` invocation with an objective
  in `$ARGUMENTS`, direct wording such as `invoke create_goal` / `call
  create_goal`, or unmistakable wording such as `create`, `start`, `set`,
  `begin`, `new goal`, or `goal:` followed by the objective.
- If the request is empty, ambiguous, informational, status-oriented, or asks to
  inspect/manage an existing goal, call `get_goal` first and respond based on the
  current state.
- If no goal exists and the user did not explicitly command creation, report
  that no active goal exists and tell them the exact form to use, e.g.
  `/goal create <objective>`.

Allowed actions:
- Status/show/list/current/check -> `get_goal` only.
- Complete/done/finish -> `update_goal` only after the full objective is
  actually complete and an audit can be provided.
- Bare `/goal <objective>`, create/start/set/begin/new goal/goal: <objective>,
  or direct `create_goal` invocation requests -> `create_goal` only when no goal
  exists.
