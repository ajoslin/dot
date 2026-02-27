---
description: Authenticate with Supermemory via browser
---

# Supermemory Login

Run this command to authenticate the user with Supermemory:

```bash
bunx opencode-supermemory@latest login
```

This will:
1. Start a local server on port 19877
2. Open the browser to Supermemory's authentication page
3. After the user logs in, save credentials to ~/.supermemory-opencode/credentials.json

Wait for the command to complete, then inform the user whether authentication succeeded or failed.

If the user wants to log out instead, run:
```bash
bunx opencode-supermemory@latest logout
```
