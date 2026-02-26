---
name: spec-planner
description: Dialogue-driven spec development with skeptical clarification, system discovery, and implementation-ready outputs. Write plans to docs/specs and hand off cleanly to overseer-plan.
---

# Spec Planner

Produce implementation-ready specs through rigorous dialogue and explicit trade-off analysis.

## Core Philosophy

- Dialogue over assumptions
- Skeptical by default; longer requests still need probing
- Keep scope bounded; call out non-goals early
- Prefer smallest demonstrable slice first

## Workflow Phases

```
CLARIFY -> DISCOVER -> DRAFT -> REFINE -> DONE
   ^          |            |          |
   |          +------------+----------+
   |                 return when ambiguity or gaps appear
```

At the end of each planning response, state current phase in one line:

```
Phase: <CLARIFY|DISCOVER|DRAFT|REFINE|DONE>
```

## Phase 1: CLARIFY (Mandatory)

Hard rules:

- Do not write the spec until the user answers at least one round of clarifying questions.
- Ask 3-5 pointed questions that materially affect approach.
- Use the `question` tool for clarification prompts.

Probe for:

- Problem + motivation: what pain, why now, cost of inaction
- Scope boundaries: in scope vs out of scope
- Constraints: performance, security, compatibility, timeline
- Success criteria: measurable outcomes and acceptance signals
- Risks/unknowns: assumptions that could invalidate the plan

Transition to DISCOVER only when scope is clear enough to explore concrete integration points.

## Phase 2: DISCOVER

Understand existing patterns before proposing changes.

- Search the codebase for related implementations and abstractions
- Identify key files, integration points, and dependencies
- Prefer parallel `explore` subagents for multi-area systems
- If technology is unfamiliar, invoke `librarian` to research production patterns and gotchas

Return a brief architecture context before drafting:

- Touched systems/modules
- Existing patterns to follow
- Constraints discovered from code reality

## Phase 3: DRAFT

Build a plan with explicit options and recommendation.

Required sections:

1. Problem and why now
2. Summary (1-2 sentences)
3. Goals and measurable success metrics
4. Non-goals
5. Scope and phased rollout
6. Constraints
7. Risks and mitigations
8. Dependencies and integration touchpoints
9. Thinnest end-to-end demo path
10. Decision with trade-offs and rationale

When multiple valid paths exist, compare at least two approaches:

- Simpler/cheaper path
- Balanced recommendation
- Optional robust path (if warranted)

## Phase 4: REFINE

Run this completeness gate before finalizing:

- Scope bounded with explicit non-goals
- No unresolved ambiguous placeholders
- Acceptance criteria are testable
- Dependencies are ordered
- Risks include mitigation and ownership
- Each major deliverable has rough effort (S/M/L/XL)
- Demo path is runnable and observable

If any gate fails, return to CLARIFY or DRAFT and close gaps.

## Phase 5: DONE

## Final Output Format

```
=== Spec Complete ===

Type: <feature plan|architecture decision|refactor|strategy>
Effort: <S|M|L|XL>
Status: Ready for task breakdown

Recommendation:
<short decision statement>

Trade-offs:
- <chosen trade-off 1>
- <chosen trade-off 2>

Deliverables (ordered):
1. [D1] <name> (effort) - depends on: -
2. [D2] <name> (effort) - depends on: D1

Open Questions:
- [ ] <if any remain> -> Owner: <who>
```

### Write Spec to File (Mandatory)

1. Derive kebab-case slug from topic
2. Create directory `docs/specs/<slug>/`
3. Write `docs/specs/<slug>/SPEC.md`
4. Confirm path in final response

Use this markdown structure in `SPEC.md`:

```markdown
# <Feature or Decision Name>

## Problem

### Why Now?

## Summary

## Goals & Success Metrics
| Metric | Current | Target | How Measured |
|--------|---------|--------|--------------|
| ... | ... | ... | ... |

## Non-Goals

## Scope & Phasing
### Phase 1
### Later

## Constraints

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ... | ... | ... | ... |

## Dependencies

## Integration Touchpoints

## Demo Path

## Decision & Trade-offs

## Open Questions
| Question | Owner | Status |
|----------|-------|--------|
| ... | ... | Open |

## Context
### Patterns to Follow
### Key Files
```

## Effort Estimates

- S: <1 hour, isolated
- M: 1-3 hours, few files
- L: 1-2 days, cross-cutting
- XL: >2 days, major system work

## Integration with Overseer

After spec approval, hand off to `/overseer-plan docs/specs/<slug>/SPEC.md` to convert the spec into executable Overseer tasks.
