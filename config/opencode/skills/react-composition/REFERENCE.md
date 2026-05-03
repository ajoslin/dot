# React Composition Reference

This reference distills Fernando Rojo's "Composition Is All You Need" talk into reusable engineering guidance.

## Talk thesis

A component starts clean, then product reality arrives: create vs update forms, partial edit forms, welcome text, terms, redirect behavior, attachments, thread replies, forwarding, editing, submit buttons outside the frame, synced drafts, ephemeral drafts. The easy response is another boolean or render prop. Over time the component interface becomes almost as complex as the implementation.

The alternative is to treat the feature as a component family:

- Lift shared state into a provider.
- Expose named internal parts.
- Let callers assemble variants in JSX.
- Keep provider implementations swappable behind the same context contract.

## Key examples from the talk

### User form boolean creep

A generic `UserForm` begins as a create form. Update mode adds `isUpdateUser`. Differences add `renderWelcome`, `renderTerms`, `redirectToOnboarding`, `onlyEditName`, `isSlugRequired`. The interface becomes a hidden state matrix.

Correction: split the use cases or expose internal parts so the caller renders exactly the fields/messages/actions needed.

### Slack composer variants

The Slack composer has channel, thread, edit, and forward variants. They share concepts but not all internals:

- Some have drag/drop attachments; edit does not.
- Some show common actions; edit only needs formatting/emoji.
- Thread has `AlsoSendToChannel`.
- Forward has actions outside the composer frame.
- Some state is ephemeral; channel draft state syncs across devices.

Correction: `Composer.Provider` plus `Composer.Frame`, `Header`, `Input`, `Footer`, `CommonActions`, and variant-specific parts.

### Context as interface, provider as adapter

Children depend on a context interface: value, update, submit, refs/meta. They do not know whether state comes from `useState`, server-synced draft hooks, or edit-message persistence. Each provider adapts its implementation to the same interface.

This is the architecture deepening move: a small interface hides meaningful implementation variety.

## Decision guide

Use compound composition when at least two are true:

- There are multiple real variants, not hypothetical variants.
- Variants share state/actions but differ in visible children.
- Parent conditionals decide large subtrees.
- State needs to be accessed by components outside the visual box.
- Existing config arrays are accumulating UI-specific exceptions.
- A provider can hide more than one state implementation.

Do not use it when:

- A component has one simple use case.
- Differences are purely styling and fit an explicit `variant` enum.
- The API would introduce more concepts than it removes.
- There is only one adapter and no credible second implementation.

## Naming guidance

Name parts after user-visible or domain concepts, not implementation mechanics:

- Good: `Composer.AlsoSendToChannel`, `Composer.CommonActions`, `Composer.Dropzone`.
- Weak: `Composer.LeftSlot`, `Composer.ModeRenderer`, `Composer.CustomSection`.

A generic `Slot` is acceptable for primitive libraries, but product features usually benefit from named parts.

## Testing guidance

Test representative composed variants:

- Channel composer renders dropzone, common actions, submit, and uses synced draft adapter.
- Thread composer renders `AlsoSendToChannel` and no extra mode prop is required.
- Edit composer omits dropzone and renders cancel/save behavior directly.
- Forward composer has external actions that can submit through context while outside the frame.

Avoid tests that only assert helper functions for config arrays. The wiring is the behavior.

## Migration sequence

1. Freeze the old component API; do not add more booleans.
2. Extract context interface from what children actually need.
3. Build provider and one internal part at a time.
4. Recreate one variant as a composed call site.
5. Add adapter tests for the provider implementation.
6. Migrate the next variant only after the first is behavior-equivalent.
7. Delete old props when all callers have moved.
