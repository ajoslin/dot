---
name: plan-tracers
description: Break a feature into tracer bullets - thin end-to-end slices with defined demos and validation. Creates PROGRESS.md and state.json for tracking.
---

# Plan Tracers

Break a large feature into **tracer bullets** - thin, end-to-end slices that can be built, demoed, and refined incrementally.

## Philosophy

> "Tracer bullets let you home in on your target by trying things and seeing how close they land." — The Pragmatic Programmer

> "Tracer code is not disposable: you write it for keeps. It contains all the error checking, structuring, documentation, and self-checking that any piece of production code has."

This codebase will outlive you. Every shortcut becomes someone else's burden. The patterns you establish will be copied. Fight entropy.

### Tracer Code vs Prototyping

CRITICAL: Tracers are NOT throwaway prototypes!

| Tracer Code | Prototyping |
|-------------|-------------|
| Production code - kept forever | Disposable - thrown away |
| Lean but complete skeleton | Incomplete, ignores robustness |
| Framework of final system | Answers specific questions |

If you need to explore unknowns BEFORE planning tracers, prototype first (whiteboard, throwaway code), THEN plan tracers.

## When to Use

- Starting a feature that touches multiple system components
- User describes work spanning UI, API, database, etc.
- You need to establish "how the application hangs together as a whole"

## Preflight

- Search for existing plans: `docs/tracers/**/PROGRESS.md`
- If a plan exists for this feature, ask whether to update it or create a new slug
- Confirm the feature slug (kebab-case) before writing files

## Decision Tree

```
Has user described the feature?
├─ No → Ask: "What should this feature do when it's done?"
├─ Vague → Run questionnaire to clarify
└─ Clear → Proceed to tracer decomposition
```

## Questionnaire

Ask questions across these domains. Keep concise - 5-7 questions max per session.

### 1. Problem & Motivation

Ask:
- **"What problem does this solve? Who experiences it?"**
- **"What's the cost of NOT solving this?"** (user pain, tech debt, revenue)
- **"Why now? What triggered this work?"**

### 2. Define "Working"

Ask: **"What's the simplest thing we could build that proves the system hangs together?"**

NOT the riskiest thing. The simplest END-TO-END path.

Examples:
- "User clicks button, data appears" (not "...with proper caching and error handling")
- "API returns hardcoded data" before "API returns database data"

### 3. Map the Integration Path

Ask: **"What components does this feature touch?"**

The first tracer should connect ALL touched components, even if trivially.

### 4. Define the Demo

Ask: **"How will we DEMONSTRATE this works?"**

A demo must be:
- **Observable** - user can see/verify it
- **Repeatable** - same result each time
- **Fast** - seconds, not minutes

Capture the expected output so the demo can be verified.

### 5. Constraints

Ask: **"What constraints must this feature respect?"** (performance, security, compatibility, etc.)

### 6. Risks & Non-Goals

Ask:
- **"What could go wrong? Technical risks?"**
- **"What's explicitly OUT of scope?"**
- **"Are there adjacent features that must NOT be affected?"**

### 7. Success Metrics

Ask: **"How will we know this feature succeeded?"** (measurable targets)

### 8. Open Questions

Ask: **"What decisions are still unresolved that could block work?"**

### 9. Design & Data (conditional)

**For UI features:** Ask about visual/interaction and accessibility requirements.

**For database features:** Ask about schema changes and migrations.

Skip if not applicable.

## Codebase Exploration

Before decomposing tracers, explore the codebase to understand:

1. **Existing patterns** - How similar features are built
2. **Key files** - Entry points, schemas, routes the feature will touch
3. **Conventions** - Naming, structure, error handling patterns

Capture findings in the context block (see Output section).

## Tracer Decomposition

### Ordering Principle

First tracer = **simplest end-to-end path connecting all components**

NOT: The riskiest unknown (prototype first), the most valuable feature (may be complex), or the easiest isolated piece (doesn't prove integration).

YES: Thinnest slice through ALL layers. Demoable in days, not weeks.

### For Each Tracer Define:

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Short title | "End-to-end data flow" |
| **Demo** | Exact command/action | `curl localhost:5262/api/metrics` |
| **Expected** | Observable output | "JSON array with 3 rows" |
| **Proves** | Integration validated | "UI→API→DB roundtrip works" |
| **Deferred** | Explicitly OUT | "Real queries" |

### Task Decomposition

Each task must be:
- Independently committable
- Have verification steps (how to prove it works)
- Build on previous tasks (no orphan work)

## Output

Create two files in `docs/tracers/<feature-slug>/`:

### PROGRESS.md (Human-readable)

```markdown
# <Feature Name>

## Problem

<What problem are we solving? Who experiences it?>

### Why Now?

<What triggered this work? Cost of inaction?>

## Summary

<1-2 sentences: what this feature does when complete>

## Constraints

- <constraint>
- <constraint>

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| <risk> | High/Med/Low | High/Med/Low | <mitigation> |

## Non-Goals

- <thing explicitly out of scope> - <why deferred>

## Adjacent Features (Do Not Affect)

- <feature/system that must remain unchanged>

## Success Metrics

| Metric | Current | Target | How Measured |
|--------|---------|--------|--------------|
| <metric> | <baseline> | <goal> | <method> |

## Open Questions

| Question | Owner | Status |
|----------|-------|--------|
| <question> | <owner> | Open |

## Design Considerations (if UI feature)

- Visual/interaction requirements
- Accessibility: <WCAG level, screen reader notes>

## Data Model Changes (if applicable)

- Schema changes: <tables, columns, indexes>
- Migrations: <backfill requirements>

## Context

### Patterns to Follow

- <pattern>: `src/path/to/example.ts` - <why relevant>

### Key Files

- `src/relevant/file.ts` - <description of relevance>

---

## Tracer 1: <Name>

**Proves:** <what integration this validates>

**Demo:** `<exact command or action>`

**Expected:** <what user should see>

**Deferred:** <what's explicitly NOT in this tracer>

### Tasks

1.1. <task>
1.2. <task>

### Learnings

(filled in during review)

---

## Tracer 2: <Name>

**Proves:** <integration>

**Demo:** `<demo>`

**Expected:** <expected output>

**Deferred:** <scope exclusions>

### Tasks

2.1. <task>
2.2. <task>

### Learnings

(filled in during review)
```

### state.json (Machine-readable)

```json
{
  "feature": "<slug>",
  "status": "planning",
  "created": "<ISO date>",
  "currentTracer": 1,
  "lastReviewedTracer": 0,
  "context": {
    "patterns": [
      "<pattern>: src/path/to/example.ts"
    ],
    "keyFiles": [
      "src/relevant/file.ts"
    ],
    "nonGoals": [
      "<thing out of scope>"
    ]
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
          "steps": [
            "<verification step 1>",
            "<verification step 2>"
          ],
          "passes": false,
          "commit": null
        },
        {
          "id": "1.2",
          "description": "<task>",
          "steps": [
            "<verification step>"
          ],
          "passes": false,
          "commit": null
        }
      ],
      "learnings": [],
      "completed": null
    },
    {
      "id": 2,
      "name": "<Name>",
      "status": "pending",
      "proves": "<integration>",
      "demo": "<demo>",
      "expected": "<expected output>",
      "deferred": ["<scope exclusions>"],
      "tasks": [
        {
          "id": "2.1",
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

### Schema Details

#### Task Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Task identifier, e.g. "1.1", "2.3" |
| `description` | string | What the task accomplishes |
| `steps` | string[] | Verification steps - how to prove it works |
| `passes` | boolean | `true` when ALL steps pass (set by tracer-dev) |
| `commit` | string\|null | Commit hash or "uncommitted" (set by tracer-dev) |

#### Tracer Object

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | "pending", "in_progress", "complete" |
| `proves` | string | The integration claim this tracer validates |
| `learnings` | string[] | Discoveries made during implementation (set by tracer-dev) |
| `completed` | string\|null | ISO date when tracer was reviewed and passed |

### Field Rules

**READ-ONLY during execution (tracer-dev):**
- `id`, `description`, `steps`, `proves`, `deferred` - defined at planning time

**WRITABLE during execution:**
- `passes` - set to `true` when ALL verification steps pass
- `commit` - set to commit hash or "uncommitted"
- `status` - updated as work progresses
- `learnings` - appended during tracer review

**NEVER delete tasks** - This could lead to missing functionality. If a task is wrong, mark it as a learning and add corrected tasks.

## Review Checklist

Before marking planning complete, verify:

- [ ] Problem statement is clear and compelling
- [ ] Success metrics defined with measurable targets
- [ ] Open questions identified (even if unresolved)
- [ ] Non-goals explicitly listed
- [ ] Adjacent features that must not be affected identified
- [ ] First tracer is the thinnest end-to-end slice (not easiest piece)
- [ ] Each tracer has a concrete, runnable demo
- [ ] Tasks are atomic and independently committable
- [ ] Context block has patterns and key files from codebase exploration

**Conditional checks:**
- [ ] Design considerations captured (if UI feature)
- [ ] Data model changes documented (if touching database)

## Bad vs Good Examples

### Bad: No Problem Statement

```markdown
## Summary
Add user favorites feature.

## Tracer 1: Database
1.1. Create favorites table
1.2. Add indexes
```

Missing: Why? Who needs this? What's the cost of not doing it? Success metrics?

### Bad: Tracer is Isolated Piece (Not End-to-End)

```markdown
## Tracer 1: Database Schema
Proves: "Database can store favorites"

## Tracer 2: API Endpoints
Proves: "API can CRUD favorites"

## Tracer 3: UI Components
Proves: "UI can display favorites"
```

Wrong: Each tracer only proves one layer. No integration validated until Tracer 3.

### Good: Thin End-to-End Slice

```markdown
## Problem

Users lose their place when returning to the app. 47% abandon after 
re-finding content. Costs ~$30k/month in lost conversions.

### Why Now?
Competitor launched favorites last month. Q4 retention initiative.

## Success Metrics

| Metric | Current | Target | How Measured |
|--------|---------|--------|--------------|
| Return user drop-off | 47% | 20% | Analytics funnel |
| "Lost content" support tickets | 200/week | 50/week | Zendesk tag |

## Non-Goals
- Favorite folders/organization - future iteration
- Sharing favorites - separate feature
- Offline favorites - requires sync infrastructure

## Tracer 1: End-to-End Favorite Toggle

**Proves:** User can favorite an item and see it persisted across sessions

**Demo:** `curl -X POST localhost:3000/api/favorites/item-123 -H "Auth: token"`
         then `curl localhost:3000/api/favorites` returns the item

**Expected:** POST returns 201, GET returns array containing item-123

**Deferred:** UI, unfavorite, duplicate handling, pagination

### Tasks
1.1. Add favorites table with userId, itemId, createdAt
1.2. POST /api/favorites/:itemId endpoint (hardcoded user)
1.3. GET /api/favorites endpoint returning user's favorites

## Tracer 2: UI Integration

**Proves:** User can favorite from UI and see favorites list

**Demo:** Click heart icon on item, navigate to /favorites, see item listed

**Deferred:** Unfavorite, optimistic updates, empty state
```

Key differences:
- Problem quantified with business impact
- Success metrics are measurable
- First tracer connects DB → API (integration, not isolation)
- Deferred items explicit per tracer

## Completion

When planning is complete:

```bash
afplay /System/Library/Sounds/Glass.aiff
```

Inform user:
```
Planning complete.

Created:
  docs/tracers/<feature>/PROGRESS.md (human-readable plan)
  docs/tracers/<feature>/state.json (machine state)

Feature: <name>
Tracers: N total
Tasks: M total

To begin development:
  Load the tracer-dev skill
```
