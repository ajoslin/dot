# TRW Adaptation Notes

## Alignment With TRW Standards

- Keep strict typing discipline (`no any` intent, additive contract changes).
- Preserve service boundaries (eden-first for new backend domains).
- Avoid barrel files and direct collection access when helpers exist.
- Keep handlers orchestration-focused; move heavy logic into contexts/services.

## Reliability Priorities

1. Enforce net-new type debt ratchet.
2. Require ready-for-execution issue fields (acceptance, dependencies, QA).
3. Default to vertical slices for implementation.
4. Require behavior-first evidence for bugfixes and medium+ changes.

## Suggested PRD-to-Issue Fields

- Story and expected behavior
- Scope boundaries and affected modules
- Dependency edges (`blocked-by`)
- Test strategy and manual QA checklist

## Practical Invocation Examples

- "Use matt-pocock flow for this feature from PRD to issues."
- "Route this bug through Matt style TDD and vertical slices."
- "Apply Matt planning philosophy before we refactor this module."
