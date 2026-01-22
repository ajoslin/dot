---
name: prd
description: Create a lightweight product requirements document and planning brief before implementation work.
---

# PRD

Create a comprehensive, lightweight planning document that captures the why, what, and how before implementation.

## Philosophy

This codebase will outlive you. Every shortcut becomes someone else's burden. Every hack compounds into technical debt that slows the whole team down.

Patterns established will be copied. Corners cut will be cut again. Fight entropy. Leave the codebase better than it was found.

## When to Use

- User asks for planning or product requirements without committing to tracers yet
- Feature spans multiple components or has unclear scope
- Need alignment on goals, constraints, risks, and success metrics

## Preflight

- Search for existing plans: `docs/prd/**/PRD.md`
- If a plan exists, use the ask question tool to confirm whether to update or create a new slug
- Use the ask question tool to confirm the feature slug (kebab-case) before writing files
- Run any supporting scripts with `python3`

## Planning Questions

Use the ask question tool to gather the minimum needed to write a useful PRD. Keep to 5-7 questions per pass.

### Core

- "What problem does this solve and who feels it?"
- "Why now? What triggered this work?"
- "What does success look like in measurable terms?"
- "What is explicitly out of scope?"
- "What constraints must be respected?" (performance, security, compatibility)

### Situational (ask only when relevant)

- "What parts of the system must this touch?"
- "How will we demonstrate this works end-to-end?"
- "What are the biggest risks or unknowns?"
- "What decisions are still open and could block progress?"
- "Any UI, accessibility, or data model requirements?"

## Workflow

1. Clarify intent and scope using the planning questions.
2. Explore the codebase for similar patterns and key files.
3. Summarize the solution at a system level (not implementation detail).
4. Define success metrics, constraints, risks, and non-goals.
5. Capture integration touchpoints and dependencies.
6. Document the thinnest end-to-end demo path for later tracer planning.

## Output

Create `docs/prd/<feature-slug>/PRD.md` with the following structure.

```markdown
# <Feature Name>

## Problem
<What pain exists and who experiences it?>

### Why Now?
<Trigger, urgency, or cost of inaction>

## Summary
<1-2 sentences describing what the feature does when complete>

## Goals & Success Metrics
| Metric | Current | Target | How Measured |
|--------|---------|--------|--------------|
| <metric> | <baseline> | <goal> | <method> |

## Non-Goals
- <explicitly out of scope>

## Users & Stakeholders
- <primary user>
- <internal owners>

## Scope & Phasing
### Phase 1
- <must-have outcomes>

### Later
- <future work>

## Constraints
- <performance/security/compatibility constraints>

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| <risk> | High/Med/Low | High/Med/Low | <mitigation> |

## Open Questions
| Question | Owner | Status |
|----------|-------|--------|
| <question> | <owner> | Open |

## Dependencies
- <team/system/dependency>

## Integration Touchpoints
- <UI surface>
- <API endpoint>
- <data storage>

## Design & Accessibility (if UI)
- <visual or interaction requirements>
- Accessibility: <WCAG target, screen reader notes>

## Data Model Changes (if applicable)
- Schema changes: <tables, columns, indexes>
- Migrations/backfills: <notes>

## Demo Path (for tracer planning)
<Simplest end-to-end action that proves integration>

## Context
### Patterns to Follow
- <pattern>: `src/path/to/example.ts` - <why relevant>

### Key Files
- `src/relevant/file.ts` - <relevance>
```

## Review Checklist

- Problem and why-now are explicit
- Success metrics are measurable
- Non-goals and constraints are listed
- Integration touchpoints identified
- Demo path is end-to-end and observable
- Open questions documented

