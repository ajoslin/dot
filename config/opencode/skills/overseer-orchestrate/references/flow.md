# Flow Implementation

Complete implementation details for `overseer_orchestrate` skill.

## Main Execution Flow

```javascript
async function overseerOrchestrate(taskRef) {
  // 1. Find parent task
  const parent = await findTask(taskRef);

  // 2. Set session display name: "overseer_orchestrate: {task description}"
  // Implementation depends on OpenCode's session management system
  
  // 3. Setup context directory
  const ctxDir = `.overseer/${parent.id}`;
  await fs.mkdir(ctxDir, { recursive: true });
  
  // 4. Get children (depth=1 only, not grandchildren), filter out completed
  const allChildren = await tasks.list({ parentId: parent.id, depth: 1 });
  const pendingChildren = allChildren.filter(c => !c.completed);
  const completedCount = allChildren.length - pendingChildren.length;
  
  if (completedCount > 0) {
    console.log(`⏩ Resuming: ${completedCount} already complete, ${pendingChildren.length} remaining`);
  }
  
  // 5. Execute each pending child via subagent
  for (const child of pendingChildren) {
    const agent = detectAgent(child) || 'build';
    const ctxFile = await writeContext(child, parent, ctxDir);
    
    // Spawn and wait
    await tasks.start(child.id);
    const result = await spawnSubagent({
      type: agent,
      prompt: `Execute this task by reading @file ${ctxFile}. Implement everything described. Call overseer tasks.complete() when done.`,
      context: { taskId: child.id, ctxFile }
    });
    
    // Subagent is responsible for calling tasks.complete()
    // We just verify it happened
    const updated = await tasks.get(child.id);
    if (!updated.completed) {
      // Force complete if subagent didn't
      await tasks.complete(child.id, { result: result.summary || 'Completed by subagent' });
    }
  }
  
  // 6. Complete parent
  const totalCompleted = allChildren.length;
  await tasks.complete(parent.id, { 
    result: `All ${totalCompleted} children completed (${completedCount} resumed + ${pendingChildren.length} new)`
  });
  
  console.log(`✅ Completed ${pendingChildren.length} new tasks (${completedCount} were already done)`);
}
```

## Helper Functions

### detectAgent()

```javascript
function detectAgent(task) {
  // Check description for @agent mentions
  const patterns = [
    /@(\w[-\w]*)/,
    /(?:delegate|assign|use)\s+(?:to\s+)?@?(\w[-\w]*)/i
  ];
  
  for (const pattern of patterns) {
    const match = task.description?.match(pattern);
    if (match) return match[1].toLowerCase();
  }
  
  // Check context
  const ctxMatch = task.context?.match(/agent:\s*(\w+)/i);
  if (ctxMatch) return ctxMatch[1].toLowerCase();
  
  return null;
}
```

### writeContext()

```javascript
async function writeContext(child, parent, ctxDir) {
  const file = `${ctxDir}/${child.id}.md`;
  const agent = detectAgent(child) || 'build';
  
  const content = `# Task: ${child.description}

**ID**: ${child.id}
**Agent**: ${agent}
**Parent**: ${parent.id} - "${parent.description}"

## Your Context
${child.context?.own || child.context || 'No specific context provided'}

## Parent Context
${parent.context?.own || parent.context || 'N/A'}

## Instructions
1. Read this context file completely
2. Implement everything described in "Your Context"
3. Follow any specific instructions provided
4. When complete, the orchestrator will mark this task done

## Responsibility
You are solely responsible for completing this task. Execute fully without asking for clarification unless critical information is truly missing.
`;
  
  await fs.writeFile(file, content, 'utf-8');
  return file;
}
```

### findTask()

```javascript
async function findTask(taskRef) {
  if (taskRef.startsWith('task_')) {
    return await tasks.get(taskRef);
  }
  
  // Search by description
  const all = await tasks.list({ depth: 0 }); // milestones only
  const match = all.find(t => 
    t.description?.toLowerCase().includes(taskRef.toLowerCase())
  );
  
  if (!match) {
    // Try searching all tasks
    const allTasks = await tasks.list();
    const taskMatch = allTasks.find(t => 
      t.description?.toLowerCase().includes(taskRef.toLowerCase())
    );
    if (taskMatch) return taskMatch;
    throw new Error(`Task not found: "${taskRef}"`);
  }
  
  return match;
}
```

## Context File Format

Each subagent gets a context file at `.overseer/{parentId}/{childId}.md`:

```markdown
# Task: {child.description}

**ID**: {child.id}
**Agent**: {detectedAgent}
**Parent**: {parent.id}

## Context
{child.context.own}

## Parent Context
{parent.context}

## Full Tree
{tree}
```
