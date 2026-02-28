# Pass 1 - System Summary

## Objective

Build a two-layer system where Spacebot is the single conversational interface and strategic orchestrator, while Middleman V2 is the deterministic execution kernel for irreversible and order-sensitive operations.

Initial project scope:
- `~/dev/realworld/monorepo`
- `~/dev/crypto-challenge-manager`

Machine policy:
- MBP is default execution machine.
- Studio is opt-in by explicit override.

## Core Principle

Spacebot should own intent, prioritization, and explanation.
Middleman V2 should own guarantees, ordering, retries, idempotency, and execution safety.

## High-Level Architecture

```text
User (Discord/Telegram)
        |
        v
Spacebot (LLM layer + Hands)
  - Cross-project watcher
  - Priority engine
  - Requirement shaping
  - Reporting + operator UX
        |
        | Commands / Queries / Events
        v
Middleman V2 (deterministic layer)
  - PR queue engine (FIFO)
  - Worktree lifecycle manager
  - Retry/idempotency kernel
  - Branch/push policy enforcement
  - Crash recovery + audit log
        |
        v
Git + GitHub + Local worktrees + CI signals
```

## Responsibility Split

- Spacebot:
  - What to do next
  - Which queue key to process first
  - Which items can be grouped by root cause
  - What to tell the user
- Middleman V2:
  - How to do it safely
  - In what exact order it runs
  - How retries/backoff happen
  - What is allowed to push/modify

## Why This Split

- Preserves one-message UX (you talk to Spacebot only).
- Keeps deterministic guarantees out of prompt logic.
- Makes failures debuggable with strict event history.
- Supports 24/7 execution without depending on model behavior for correctness.

## Required Guarantees

- Per-queue FIFO order for PR work.
- Exactly one active item per queue key.
- Bounded retries with deterministic stop conditions.
- Idempotent replay-safe processing after restarts.
- Protected branch policy never bypassed.
- Full action and evidence ledger for auditability.
