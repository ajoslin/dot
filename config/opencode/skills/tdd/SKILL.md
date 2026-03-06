---
name: tdd
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions red-green-refactor, wants integration tests, or asks for test-first development.
---

# Test-Driven Development

## Philosophy

Core principle: tests should verify behavior through public interfaces, not implementation details.

Good tests are integration-style and exercise real code paths through public APIs.
They describe what the system does, not how it does it.

Bad tests are coupled to implementation. They mock internals, test private methods,
or fail on refactors where behavior did not change.

## Anti-Pattern: Horizontal Slices

Do not write all tests first and then all implementation.

Use vertical tracer bullets instead:

RED -> GREEN one behavior at a time.

```text
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED->GREEN: test1->impl1
  RED->GREEN: test2->impl2
  RED->GREEN: test3->impl3
```

## Workflow

### 1. Planning

Before writing code:

- Confirm needed interface changes with the user
- Confirm which behaviors to test (prioritized)
- Identify opportunities for deep modules
- Design interfaces for testability
- List behaviors to test (not implementation steps)
- Get user approval on the plan

### 2. Tracer Bullet

Write one test for one behavior:

RED: test fails
GREEN: minimal code to pass

### 3. Incremental Loop

For each next behavior:

RED: write next failing test
GREEN: write minimal passing code

Rules:

- One test at a time
- Only enough code for the current test
- No speculative features
- Keep tests behavior-focused

### 4. Refactor

After all tests pass:

- Extract duplication
- Deepen modules behind stable interfaces
- Improve design while preserving behavior
- Re-run tests after each refactor step

Never refactor while RED.

## Checklist Per Cycle

- [ ] Test describes behavior, not implementation
- [ ] Test uses public interface only
- [ ] Test survives internal refactor
- [ ] Code is minimal for this test
- [ ] No speculative features added
