# Linting and compiler notes

## Linting

- This skill uses the `pinescript-lint` npm package via a wrapper script.
- Linting is intended for hand-authored Pine Script; generated code should be validated in the TradingView editor.
- Install or run on demand:
  - `npx --yes pinescript-lint <path>`
  - Or `node scripts/pinescript_lint.mjs <path>`

### Wrapper configuration

- Override the linter command with `PINESCRIPT_LINT_CMD`.
- Dry-run for scripting and tests with `PINESCRIPT_LINT_DRY_RUN=1`.

Examples:

```bash
node scripts/pinescript_lint.mjs indicators/rsi.pine
PINESCRIPT_LINT_CMD="npx --yes pinescript-lint" node scripts/pinescript_lint.mjs src
```

## Compiler notes

- Pine Script compiles on TradingView servers; no official local compiler is available.
- When verifying compilation, rely on TradingView editor diagnostics and execution logs.
