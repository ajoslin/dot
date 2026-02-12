# Flow Implementation

Hard-retry orchestration details for `/overseer_orchestrate` with TodoWrite mirroring, parent/subagent task-list seeding, and interruption-safe resume.

## Main Flow

```javascript
async function overseerOrchestrate(taskRef, chatTodos = []) {
  const parent = await resolveParent(taskRef, chatTodos);
  const ctxDir = `.overseer/${parent.id}`;
  await fs.mkdir(ctxDir, { recursive: true });

  const state = await loadRunState(parent.id);
  const policy = buildFailurePolicy();
  const children = await tasks.list({ parentId: parent.id, depth: 1 });
  const pending = children.filter(c => !c.completed && !c.cancelled);
  const childSubtasks = await listChildSubtasks(children);

  await syncTodoMirror({ parent, children, activeChildId: null, chatTodos });
  await seedParentRunTodos({ parent, children, activeChildId: null, chatTodos });

  for (const child of pending) {
    await tasks.start(child.id);
    await syncTodoMirror({ parent, children, activeChildId: child.id, chatTodos });
    await seedParentRunTodos({ parent, children, activeChildId: child.id, chatTodos });
    const childStartCommit = await getHeadCommit();

    while (true) {
      const attempt = recordAttempt(state, child.id);
      const agent = detectAgent(child) || "build";
      const ctxFile = await writeContext(child, parent, ctxDir, { attempt, agent });
      const seedTodos = buildSubagentSeedTodos(child, childSubtasks.get(child.id) || []);

      try {
        const result = await task({
          subagent_type: agent,
          description: `Execute ${child.id}`,
          prompt: buildSubagentPrompt({ child, ctxFile, attempt, seedTodos })
        });

        await verifyChildCompleted(child.id, result);
        await verifyChildCommitCheckpoint({ child, startCommit: childStartCommit });
        await tasks.complete(child.id, { result: result.summary || `Completed after ${attempt} attempt(s)` });

        child.completed = true;
        state.lastProgressAt = new Date().toISOString();
        setChildState(state, child.id, { completed: true, attempts: attempt, lastError: null, classification: null, lastAgent: agent });
        await saveRunState(parent.id, state);
        await syncTodoMirror({ parent, children, activeChildId: null, chatTodos });
        await seedParentRunTodos({ parent, children, activeChildId: null, chatTodos });
        break;
      } catch (err) {
        const classification = classifyError(err, { state, policy });
        setChildState(state, child.id, { completed: false, attempts: attempt, lastError: String(err), classification, lastAgent: agent });
        await saveRunState(parent.id, state);
        await syncTodoMirror({ parent, children, activeChildId: child.id, chatTodos });
        await seedParentRunTodos({ parent, children, activeChildId: child.id, chatTodos });
        if (classification === "catastrophic") throw new Error(`Catastrophic failure on ${child.id}: ${String(err)}`);
        await recoverAndBackoff({ child, err, attempt, classification });
      }
    }
  }

  await tasks.complete(parent.id, { result: `All ${children.filter(c => !c.cancelled).length} children completed` });
  parent.completed = true;
  await syncTodoMirror({ parent, children, activeChildId: null, chatTodos, forceParentCompleted: true });
  await seedParentRunTodos({ parent, children, activeChildId: null, chatTodos, forceCompleted: true });
}
```

## TodoWrite Mirror

```javascript
const OVR_PARENT_PREFIX = "ovr-parent-";
const OVR_CHILD_PREFIX = "ovr-child-";
const OVR_RUN_PREFIX = "ovr-run-";

function todoPriority(priority = 1) { return priority >= 2 ? "high" : priority === 1 ? "medium" : "low"; }
function todoStatus(task, activeChildId) { if (task.cancelled) return "cancelled"; if (task.completed) return "completed"; return task.id === activeChildId ? "in_progress" : "pending"; }
function toParentTodo(parent, done = false) { return { id: `${OVR_PARENT_PREFIX}${parent.id}`, content: `[overseer-parent:${parent.id}] resume:/overseer_orchestrate ${parent.id} state:.overseer/${parent.id}/state.json`, status: done || parent.completed ? "completed" : "in_progress", priority: todoPriority(parent.priority ?? 1) }; }
function toChildTodo(child, parentId, activeChildId) { return { id: `${OVR_CHILD_PREFIX}${child.id}`, content: `[overseer-task:${child.id}] parent:${parentId} ${child.description}`, status: todoStatus(child, activeChildId), priority: todoPriority(child.priority ?? 1) }; }

async function syncTodoMirror({ parent, children, activeChildId, chatTodos, forceParentCompleted = false }) {
  const preserved = chatTodos.filter(t => !t.id.startsWith(OVR_PARENT_PREFIX) && !t.id.startsWith(OVR_CHILD_PREFIX));
  const mirror = [toParentTodo(parent, forceParentCompleted), ...children.map(c => toChildTodo(c, parent.id, activeChildId))];
  await todowrite({ todos: [...preserved, ...mirror] });
}
```

## Parent + Subagent Task-List Seeding

```javascript
function toParentRunTodos(parent, children, activeChildId, forceCompleted = false) {
  const base = [{ id: `${OVR_RUN_PREFIX}${parent.id}-orchestrate`, content: `[run:${parent.id}] Orchestrate ${children.length} child tasks`, status: forceCompleted ? "completed" : "in_progress", priority: "medium" }];
  const childItems = children.map(c => ({ id: `${OVR_RUN_PREFIX}${parent.id}-${c.id}`, content: `[run-child:${c.id}] Delegate and verify`, status: forceCompleted || c.completed ? "completed" : c.id === activeChildId ? "in_progress" : "pending", priority: todoPriority(c.priority ?? 1) }));
  return [...base, ...childItems];
}

async function seedParentRunTodos({ parent, children, activeChildId, chatTodos, forceCompleted = false }) {
  const withoutRun = chatTodos.filter(t => !t.id.startsWith(OVR_RUN_PREFIX));
  const runTodos = toParentRunTodos(parent, children, activeChildId, forceCompleted);
  await todowrite({ todos: [...withoutRun, ...runTodos] });
}

async function listChildSubtasks(children) {
  const entries = await Promise.all(children.map(async c => [c.id, await tasks.list({ parentId: c.id, depth: 2 })]));
  return new Map(entries);
}

function buildSubagentSeedTodos(child, subtasks) {
  const units = subtasks.length ? subtasks : [{ id: `${child.id}-impl`, description: child.description, priority: child.priority ?? 1, completed: false, cancelled: false }];
  return units.filter(u => !u.completed && !u.cancelled).map((u, i) => ({ id: `ovr-sub-${child.id}-${u.id}`, content: `[subtask:${child.id}] ${u.description}`, status: i === 0 ? "in_progress" : "pending", priority: todoPriority(u.priority ?? 1) }));
}

function buildSubagentPrompt({ child, ctxFile, attempt, seedTodos }) {
  return [
    `Read @file ${ctxFile}.`,
    "Before implementation, call todowrite exactly once with this seed payload:",
    "```json",
    JSON.stringify(seedTodos, null, 2),
    "```",
    `Then execute ${child.id} attempt ${attempt} to completion. Keep exactly one todo in_progress. Do not mark Overseer tasks complete; orchestrator handles completion.`
  ].join("\n");
}
```

## Resume Helpers

```javascript
async function resolveParent(taskRef, chatTodos = []) {
  if (taskRef) return findTask(taskRef);
  const activeParent = chatTodos.find(t => t.id.startsWith(OVR_PARENT_PREFIX) && t.status === "in_progress");
  if (!activeParent) throw new Error("Missing taskRef and no active ovr-parent-* todo entry");
  return findTask(activeParent.id.replace(OVR_PARENT_PREFIX, ""));
}

async function resumeAfterCommentOrReview(chatTodos = []) {
  const activeParent = chatTodos.find(t => t.id.startsWith(OVR_PARENT_PREFIX) && t.status === "in_progress");
  if (!activeParent) return;
  await overseerOrchestrate(activeParent.id.replace(OVR_PARENT_PREFIX, ""), chatTodos);
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
