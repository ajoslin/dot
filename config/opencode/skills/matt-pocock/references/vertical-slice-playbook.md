# Vertical Slice Playbook

## Definition

A vertical slice delivers one user-observable behavior end-to-end, touching all necessary layers in one bounded unit.

## Slice Checklist

- Problem statement and user-visible outcome
- Data/API/UI changes for this behavior only
- Acceptance criteria and failure modes
- Tests for behavior (not implementation internals)
- Manual QA steps for final confirmation

## Good Slice Signals

- Can be implemented and verified independently
- Integrates early across boundaries
- Easy to roll back if needed

## Anti-Patterns

- Horizontal phase work (all db, then all api, then all ui)
- Multiple unrelated behaviors in one issue
- Unverifiable completion criteria
