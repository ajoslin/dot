---
description: Toggle todo continuation enforcer on/off
---

Toggle `todo-continuation-enforcer` in `~/.config/opencode/oh-my-opencode.json`.

Behavior:
- If `disabled_hooks` includes `todo-continuation-enforcer`, remove it (turn continuation ON).
- If it does not include it, add it (turn continuation OFF).
- If `disabled_hooks` does not exist, create it with `todo-continuation-enforcer`.
- If removing leaves `disabled_hooks` empty, remove the `disabled_hooks` key.

After toggling:
- Validate JSON syntax.
- Print final state as one line: `todo-continuation-enforcer: ON` or `todo-continuation-enforcer: OFF`.

<user-request>
$ARGUMENTS
</user-request>
