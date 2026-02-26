---
name: thrifty
description: Delegate tasks to the cost-effective opencode/glm-5 model. Use when you need inexpensive task execution, simple research, or delegating work that doesn't require the most powerful models.
---

# Thrifty Task Delegation

Use this skill to delegate tasks to opencode/glm-5, a cost-effective model ideal for:
- Simple research and information gathering
- Code exploration and file searches
- Document processing and summarization
- Routine automation tasks
- Parallel processing of independent subtasks

## Usage Pattern

Invoke glm-5 via the task tool:

```
task({
  description: "Brief task summary",
  prompt: "Detailed instructions for the agent",
  subagent_type: "general"  // glm-5 is the default model
})
```

## Cost Guidelines

| Task Type | Recommended Model | Est. Cost |
|-----------|-------------------|-----------|
| Simple search/explore | glm-5 (default) | Low |
| Code review | code-review-glm | Low |
| Complex architecture | oracle | Medium |
| Deep debugging | code-review-sonnet | Higher |

## Best Practices

1. **Break large tasks into smaller chunks** - glm-5 handles focused tasks well
2. **Provide clear, specific instructions** - reduces iteration and context usage
3. **Use for parallel work** - delegate multiple independent tasks simultaneously
4. **Verify complex outputs** - have a stronger model review critical results
5. **Batch similar operations** - group related file operations together

## Example Delegations

**File exploration:**
```
task({
  description: "Find auth-related files",
  prompt: "Search the codebase for all files related to authentication. Return a list of file paths and brief descriptions of what each does.",
  subagent_type: "general"
})
```

**Documentation summarization:**
```
task({
  description: "Summarize API docs",
  prompt: "Read docs/api.md and provide a 3-bullet summary of the main endpoints and their purposes.",
  subagent_type: "general"
})
```

**Parallel processing:**
```
// Delegate multiple independent tasks concurrently
const tasks = [
  task({ description: "Analyze utils.ts", prompt: "...", subagent_type: "general" }),
  task({ description: "Analyze helpers.ts", prompt: "...", subagent_type: "general" }),
  task({ description: "Analyze constants.ts", prompt: "...", subagent_type: "general" })
];
await Promise.all(tasks);
```

## When NOT to Use glm-5

- Complex multi-step architectural decisions
- Security-critical code review
- Novel problem-solving requiring creativity
- Tasks requiring deep contextual understanding

For these, use `oracle`, `code-review-sonnet`, or other specialized subagents instead.
