---
name: react-composition
description: Designs and refactors React component APIs toward compound composition: fewer boolean mode props, clearer seams, context-backed internals, and JSX-first variant assembly. Use when building or reviewing React components with many props, conditional render branches, render props/slots, shared form/composer/card/table internals, or when the user mentions composition, compound components, Radix-style APIs, prop drilling, boolean props, or "composition is all you need".
---

# React Composition

## Purpose

Apply the "Composition Is All You Need" pattern: replace shallow, prop-configured React modules with deeper component families whose interface is small, explicit, and composable.

Core rule:

> Lift shared state, compose internals.

## Vocabulary to use

- **Module** — component, hook, provider, compound component family, or utility with an interface and implementation.
- **Interface** — props, children shape, context contract, valid combinations, ordering, side effects, error modes.
- **Implementation** — rendering, state management, effects, data sync, and styling behind the interface.
- **Depth** — leverage behind a small interface.
- **Seam** — where behavior can vary without editing in place; often a provider, context contract, child component, or JSX composition point.
- **Adapter** — concrete provider/hook/state source satisfying the same interface.
- **Leverage** — reusable internals, fewer invalid prop combinations, flexible layout.
- **Locality** — variant behavior lives where the variant is rendered.

## Trigger signals

Load this skill when you see:

- Boolean mode props: `isEditing`, `isThread`, `isForwarding`, `hideFooter`, `renderTerms`, `onlyEditName`.
- One parent deciding which component tree children render.
- Repeated conditions spread through the same component.
- UI config arrays gaining exceptions: `divider`, `isMenu`, `render`, `variant`, `hiddenWhen`.
- Render props used mainly to escape an over-controlling parent.
- Prop drilling of form state, refs, submit handlers, focus handlers, or mutation behavior.
- Several related UI variants sharing structure but requiring different internal pieces.

## Diagnostic tests

- **Boolean tree test** — if a prop determines which component tree renders from the parent, prefer composition.
- **Deletion test** — if deleting the abstraction makes complexity vanish, it was shallow; if complexity spreads across callers, it was earning its keep.
- **Interface test surface** — test the public component family interface, not extracted helper trivia.
- **Adapter reality check** — one provider/state implementation is a hypothetical seam; two implementations make the seam real.

## Preferred shape

```tsx
<Composer.Provider value={composerState}>
  <Composer.Dropzone />
  <Composer.Frame>
    <Composer.Header />
    <Composer.Input />
    <Composer.Footer>
      <Composer.CommonActions />
      <Composer.Submit />
    </Composer.Footer>
  </Composer.Frame>
</Composer.Provider>
```

Variant-specific features become rendered components, not flags:

```tsx
<Composer.Provider value={threadComposerState}>
  <Composer.Frame>
    <Composer.Header />
    <Composer.AlsoSendToChannel />
    <Composer.Input />
    <Composer.Footer>
      <Composer.CommonActions />
      <Composer.Submit />
    </Composer.Footer>
  </Composer.Frame>
</Composer.Provider>
```

## Workflow

1. Map real variants and what differs: state source, layout, actions, validation, submit behavior, persistence.
2. Name shared internals: `Provider`, `Frame`, `Header`, `Input`, `Footer`, `CommonActions`, `Submit`, domain-specific toggles.
3. Define a context interface containing only what children need.
4. Create adapters: each variant provider translates its state source into the same interface.
5. Compose call sites with exact JSX. Prefer omission over `showX={false}`.
6. Abstract only after repetition; keep escape hatches to individual parts.
7. Test representative composed variants and provider adapters through the public interface.

## Output format

When advising, return: current interface problem, proposed seam, composed JSX shape, adapter plan, tests, and migration path.

See [REFERENCE.md](REFERENCE.md) for examples, decision guide, naming, testing, and migration details.
