# Flow Implementation

Hard-retry orchestration details for `/overseer_orchestrate` with Overseer as the single task system and interruption-safe resume via run state.

## Main Flow

```javascript
async function overseerOrchestrate(taskRef) {
  const parent = await resolveParent(taskRef);
  const ctxDir = `.overseer/${parent.id}`;
  await fs.mkdir(ctxDir, { recursive: true });

  const state = await loadRunState(parent.id);
  const policy = buildFailurePolicy();
  const children = await tasks.list({ parentId: parent.id, depth: 1 });
  const pending = children.filter(c => !c.completed && !c.cancelled);

  for (const child of pending) {
    await tasks.start(child.id);
    const childStartCommit = await getHeadCommit();

    while (true) {
      const attempt = recordAttempt(state, child.id);
      const agent = detectAgent(child) || "build";
      const ctxFile = await writeContext(child, parent, ctxDir, { attempt, agent });

      try {
        const result = await task({
          subagent_type: agent,
          description: `Execute ${child.id}`,
          prompt: buildSubagentPrompt({ child, ctxFile, attempt })
        });

        await verifyChildCompleted(child.id, result);
        await verifyChildCommitCheckpoint({ child, startCommit: childStartCommit });
        await tasks.complete(child.id, { result: result.summary || `Completed after ${attempt} attempt(s)` });

        child.completed = true;
        state.lastProgressAt = new Date().toISOString();
        setChildState(state, child.id, {
          completed: true,
          attempts: attempt,
          lastError: null,
          classification: null,
          lastAgent: agent
        });
        await saveRunState(parent.id, state);
        break;
      } catch (err) {
        const classification = classifyError(err, { state, policy });
        setChildState(state, child.id, {
          completed: false,
          attempts: attempt,
          lastError: String(err),
          classification,
          lastAgent: agent
        });
        await saveRunState(parent.id, state);
        if (classification === "catastrophic") {
          throw new Error(`Catastrophic failure on ${child.id}: ${String(err)}`);
        }
        await recoverAndBackoff({ child, err, attempt, classification });
      }
    }
  }

  await tasks.complete(parent.id, {
    result: `All ${children.filter(c => !c.cancelled).length} children completed`
  });
}
```

## Subagent Prompt Builder

```javascript
function buildSubagentPrompt({ child, ctxFile, attempt }) {
  return [
    `Read @file ${ctxFile}.`,
    `Then execute ${child.id} attempt ${attempt} to completion. Keep the focus on this child only. Commit at meaningful checkpoints (at least every 20-30 minutes) and include at least one commit for this child before declaring done. Do not mark Overseer tasks complete; orchestrator handles completion.`
  ].join("\n");
}
```

## Resume Helpers

```javascript
async function resolveParent(taskRef) {
  if (!taskRef) {
    throw new Error("Missing taskRef. Use /overseer_orchestrate <task-id-or-search>");
  }
  return findTask(taskRef);
}

async function resumeRun(parentId) {
  if (!parentId) throw new Error("Missing parentId for resume");
  await overseerOrchestrate(parentId);
}
```

## Failure Classification

```javascript
function buildFailurePolicy() {
  return {
    watchdogNoProgressMs: 45 * 60 * 1000,
    catastrophicMatchers: ["database is malformed", "overseer mcp unavailable", "sqlite_corrupt", "not a git repository", "repository inaccessible", "filesystem readonly", "fatal: bad object", "permission denied", "no space left on device", "user cancelled"],
    recoverableMatchers: ["merge conflict", "context mismatch", "validation failed", "hook failed", "lockfile out of date", "rate limit", "temporary failure", "commit checkpoint failed", "no commit produced", "working tree dirty without commit"]
  };
}

function classifyError(err, { state, policy }) {
  const msg = String(err || "").toLowerCase();
  const lastProgressAt = Date.parse(state.lastProgressAt || state.startedAt || new Date().toISOString());
  if (Date.now() - lastProgressAt >= policy.watchdogNoProgressMs) return "catastrophic";
  if (policy.catastrophicMatchers.some(x => msg.includes(x))) return "catastrophic";
  if (policy.recoverableMatchers.some(x => msg.includes(x))) return "recoverable";
  return "retryable";
}
```

## Commit Checkpoint Helpers

```javascript
async function getHeadCommit() {
  try {
    return (await bash("git rev-parse HEAD")).trim();
  } catch {
    return null;
  }
}

async function hasUncommittedChanges() {
  try {
    const out = await bash("git status --porcelain");
    return out.trim().length > 0;
  } catch {
    return false;
  }
}

async function verifyChildCommitCheckpoint({ child, startCommit }) {
  const endCommit = await getHeadCommit();
  const dirty = await hasUncommittedChanges();

  if (startCommit && endCommit && startCommit !== endCommit) {
    return;
  }

  if (dirty) {
    throw new Error(`Commit checkpoint failed for ${child.id}: working tree dirty without commit`);
  }

  throw new Error(`Commit checkpoint failed for ${child.id}: no commit produced`);
}
```

## Existing Helpers

Reuse existing behavior unless project-specific override is required:
- `detectAgent(task)`
- `writeContext(child, parent, ctxDir, meta)`
- `findTask(taskRef)`
- `verifyChildCompleted(childId, result)`
- `verifyChildCommitCheckpoint({ child, startCommit })`
- `getHeadCommit()`, `hasUncommittedChanges()`
- `recoverAndBackoff(...)`
- `loadRunState(...)`, `saveRunState(...)`, `recordAttempt(...)`, `setChildState(...)`

`verifyChildCompleted` must throw on failed checks so retries continue.
