---
description: Check todo continuation enforcer state
---

Read `~/.config/opencode/oh-my-opencode.json` and report whether `todo-continuation-enforcer` is currently enabled.

Rules:
- If `disabled_hooks` contains `todo-continuation-enforcer`, report: `todo-continuation-enforcer: OFF`.
- Otherwise report: `todo-continuation-enforcer: ON`.
- Do not modify any files.

<user-request>
$ARGUMENTS
</user-request>
