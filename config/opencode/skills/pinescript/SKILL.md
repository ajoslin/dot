---
name: pinescript
description: Use when creating or reviewing TradingView Pine Script v6 indicators/strategies/libraries, applying non-repainting best practices, generating Pine Script from other languages, or running Pine Script linting.
references:
  - references/pinescript_v6.md
  - references/linting.md
---

# Pine Script

## Overview

Provide Pine Script v6 guidance for indicators, strategies, and libraries. Apply non-repainting and performance best practices. Support generating Pine Script via other languages (TypeScript, Python, etc.) by keeping generated output compliant with v6 guidance. Run linting with the bundled script wrapper around `pinescript-lint`.

## Workflow

1. Determine script type and version
   - Add `//@version=6` and choose `indicator()`, `strategy()`, or `library()`.
2. Apply execution model and repainting safeguards
   - Use `barstate.isconfirmed`, historical offsets, and `request.security()` lookahead guidance.
3. Optimize performance and state
   - Prefer `var`/`varip` for state, limit loops, precompute constants, avoid redundant security calls.
4. Generate Pine Script from other languages when needed
   - Emit Pine Script v6-compliant output and validate by inspection or TradingView editor diagnostics.
5. Lint before delivery (manual Pine Script only)
   - Run `node scripts/pinescript_lint.mjs <path>` to check formatting and basic issues.

## References

- Pine Script v6 concepts and best practices: `references/pinescript_v6.md`
- Linting workflow and linter configuration: `references/linting.md`

## Scripts

- Lint Pine Script files: `scripts/pinescript_lint.mjs`
- Lint script tests: `scripts/pinescript_lint.test.mjs`
