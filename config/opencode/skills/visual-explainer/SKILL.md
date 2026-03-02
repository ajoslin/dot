---
name: visual-explainer
description: Use when assembling rich, readable report HTML from normalized council payloads, chart specs, and chart assets before print optimization.
---

# Visual Explainer

## Purpose

Convert structured council report data into high-readability HTML that is suitable for executive review and downstream PDF rendering.

## Inputs

- `report_payload` JSON from `council-output-report`
- `chart_spec` and optional `chart_asset` outputs from `chart-visualization`
- optional `supporting_metrics` JSON

## Workflow

1. Build HTML sections in this order:
- executive headline + narrative
- top findings table
- chart blocks with captions (window + source)
- action board
- open questions + appendix

2. Wire charts:
- use chart assets when available
- if assets are unavailable, embed deterministic chart spec snippets as placeholders

3. Produce semantic, print-friendly markup:
- use section wrappers and explicit heading hierarchy
- avoid dense single-page layouts
- keep table columns concise and stable

## Output Contract

Return:
- `report_html` (full HTML string or path)
- `layout_notes` array (important structure decisions)
- `render_warnings` array
