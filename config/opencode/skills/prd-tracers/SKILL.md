---
name: prd-tracers
description: Convert a PRD into phased tracer bullets with demos and executable tasks. Creates PROGRESS.md and state.json.
---

# PRD Tracers

Convert an approved PRD into phased tracer bullets and a runnable execution plan.

## When to Use

- A PRD exists in `docs/prd/<feature-slug>/PRD.md`
- Implementation needs an end-to-end tracer plan with demos and tasks

## Inputs

- Required: `docs/prd/<feature-slug>/PRD.md`
- Treat the PRD as the source of truth for problem, goals, constraints, and non-goals
- Do not re-litigate requirements unless the PRD is ambiguous or incomplete

## Preflight

- Search for existing tracer plans: `docs/tracers/**/PROGRESS.md`
- If a plan exists, confirm whether to update or create a new slug
- Confirm the feature slug (kebab-case) before writing files

## Phase-Focused Questions

Ask only what is needed to translate the PRD into tracers.

- "How should this ship in phases? What is the first usable slice?"
- "What end-to-end demo proves Phase 1 works?"
- "What must be explicitly deferred to later phases?"
- "Which systems must be touched in Phase 1?"
- "Are there phase-specific constraints or risks not in the PRD?"

## Workflow

1. Read the PRD and extract goals, constraints, risks, non-goals, dependencies, and demo path.
2. Propose tracer phases that align with the PRD scope and phasing.
3. For each tracer, define: proves, demo, expected output, deferred scope.
4. Decompose each tracer into atomic, independently committable tasks.
5. Add verification steps for every task.

## Output

Create two files in `docs/tracers/<feature-slug>/`:

### PROGRESS.md

```markdown
# <Feature Name>

## Summary
<1-2 sentences describing what the feature does when complete>

## Scope From PRD
- Goals: <summary>
- Constraints: <summary>
- Non-goals: <summary>

## Tracer 1: <Name>

**Proves:** <what integration this validates>

**Demo:** `<exact command or action>`

**Expected:** <what user should see>

**Deferred:** <what's explicitly NOT in this tracer>

### Tasks
1.1. <task>
1.2. <task>

---

## Tracer 2: <Name>

**Proves:** <integration>

**Demo:** `<demo>`

**Expected:** <expected output>

**Deferred:** <scope exclusions>

### Tasks
2.1. <task>
2.2. <task>
```

### state.json

```json
{
  "feature": "<slug>",
  "status": "planning",
  "created": "<ISO date>",
  "currentTracer": 1,
  "lastReviewedTracer": 0,
  "context": {
    "nonGoals": ["<thing out of scope>"]
  },
  "tracers": [
    {
      "id": 1,
      "name": "<Name>",
      "status": "pending",
      "proves": "<what this tracer validates>",
      "demo": "<exact command>",
      "expected": "<expected output>",
      "deferred": ["<what's out>"],
      "tasks": [
        {
          "id": "1.1",
          "description": "<task>",
          "steps": ["<verification step>"],
          "passes": false,
          "commit": null
        }
      ],
      "learnings": [],
      "completed": null
    }
  ]
}
```

## Review Checklist

- PRD scope is reflected in tracer phases
- First tracer is the thinnest end-to-end slice
- Every tracer has a concrete demo and expected result
- Tasks are atomic with verification steps

## Handoff

When planning is complete, load the `tracer-dev` skill to execute the tracers.
