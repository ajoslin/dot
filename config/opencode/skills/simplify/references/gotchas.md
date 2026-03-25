# Simplify Gotchas

Use this when a cleanup looks tempting but you are not sure it is real simplification.

## Rule of Thumb

Real simplification makes the code easier to read at the point of use.

Fake simplification moves complexity around, hides it behind a new layer, or changes ownership while calling it cleanup.

## 1) Wrapper / Forwarder Churn

Avoid:

- helpers that only rename one call
- components or classes that only forward inputs
- tiny adapter layers with no real behavior

Prefer:

- calling the real helper directly
- inlining the wrapper
- deleting the extra name when it adds no clarity

## 2) One-Off Types

Avoid:

- exported prop or option interfaces used once
- local shapes pulled into standalone types just to name them
- type indirection that makes the reader jump around

Prefer:

- inline typing when the shape is local and short
- existing shared types when the shape is truly shared

## 3) Boolean Soup

Avoid:

- multiple booleans that encode an implicit state machine
- branching spread across many tiny flags

Prefer:

- one direct state value when the model is really a mode
- early returns that make the main path obvious

## 4) Effect-Derived State

Avoid:

- effects that copy or derive values already available from inputs, props, query data, or state
- extra state just to mirror another source

Prefer:

- deriving directly at the point of use or in a small local helper
- keeping one source of truth

## 5) Test-Seam Extraction

Avoid:

- tiny one-export functions created only to make tests easier
- dependency injection through type plumbing when production code gets harder to read

Prefer:

- direct production wiring
- local duplication over test-only abstraction when the logic is tiny

## 6) Boundary Drift

Avoid:

- moving code into a more "central" place that is not the real owner
- cleanup that shifts work across module, service, or package boundaries without a product reason
- replacing invariant-enforcing helpers with raw access

Prefer:

- the smallest safe cleanup inside the current canonical home
- convergence toward existing ownership rules

If ownership changes are needed, this is no longer a simple simplify pass.

## 7) Fake Reuse

Avoid:

- extracting a helper for a one-time DRY win that hurts locality
- introducing a new micro-pattern because it feels cleaner in isolation

Prefer:

- repeating a small amount of code when it keeps the flow obvious
- reusing an existing canonical helper when it already fits

## 8) Visible UI Drift

Avoid:

- new style variants or interaction patterns during a cleanup-only pass
- changes that are visibly different but not structurally simpler

Prefer:

- existing product patterns
- visual cleanup only when it is clearly canonical and easy to verify

## 9) Broad Refactor Disguised as Cleanup

Stop when the work becomes:

- a migration
- a redesign
- a system ownership change
- a compatibility decision
- a test harness project

Those are `proposal-only` or a separate task.
