---
description: Switch to build mode (stops voice input if running)
agent: build
---

Switching to build mode...

!`if [ -f /tmp/opencode-voice.pid ]; then kill $(cat /tmp/opencode-voice.pid) 2>/dev/null && rm /tmp/opencode-voice.pid && echo "🔇 Voice input stopped"; fi`

Now in build mode - ready for coding tasks.
