# Pine Script v6 quick reference

## Script structure

- Start every script with `//@version=6`. Omitting it defaults to v1.
- Declare exactly one of:
  - `indicator("Name", overlay=true|false)`
  - `strategy("Name", overlay=true|false)`
  - `library("Name")`
- Declare inputs early (`input.*`) so UI grouping is consistent.

## Execution model and state

- Scripts run once per bar update; realtime bars can update multiple times.
- Use `var` for one-time initialization and persistent state.
- Use `varip` when tracking realtime updates within a bar.
- Prefer `:=` for reassignment to preserve type stability.

## Repainting and lookahead safety

- Use confirmed data for signals:
  - `barstate.isconfirmed` for close-only logic.
  - Use `[1]` offsets for confirmed values (ex: `close[1]`).
- When requesting higher timeframe data, avoid future leakage:
  - `request.security(symbol, tf, series[1], lookahead=barmerge.lookahead_on)`
  - Or `request.security(symbol, tf, series, lookahead=barmerge.lookahead_off)`
- Keep order logic free of repainting values when writing strategies.

## Performance tips

- Cache expensive series in variables; avoid repeated `request.security()` calls.
- Limit loops and array sizes; Pine runs per bar on TradingView servers.
- Precompute constants and use `var` for objects created once (labels, lines).
- Use `barstate.islast` for heavy debug output.

## Common pitfalls

- Mixing realtime and historical data without confirmation.
- Using `request.security()` without offsets or lookahead controls.
- Recreating drawing objects every bar instead of reusing references.
- Assuming arrays are fast for unbounded growth; cap size explicitly.

## Minimal template

```pine
//@version=6
indicator("Template", overlay=true)

len = input.int(14, "Length")
rsiValue = ta.rsi(close, len)

plot(rsiValue, "RSI")
```

## Pine Script generation guidance

- When generating Pine Script from another language (TypeScript, Python, etc.), keep the output valid v6 syntax and include `//@version=6` at the top.
- Emit consistent indentation (4 spaces) and prefer explicit types for inputs (`input.int`, `input.float`, `input.bool`) to avoid ambiguity.
- Generate deterministic names for plots, lines, labels so code is easy to trace back to the generator source.
- When building higher timeframe logic, include safe `request.security()` defaults and provide an option to override lookahead behavior.
