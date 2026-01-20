---
description: Switch to plan mode (stops voice input if running)
agent: plan
---

Switching to plan mode...

!`if [ -f /tmp/opencode-voice.pid ]; then kill $(cat /tmp/opencode-voice.pid) 2>/dev/null && rm /tmp/opencode-voice.pid && echo "🔇 Voice input stopped"; fi`

Now in plan mode - I'll suggest approaches without making changes.
