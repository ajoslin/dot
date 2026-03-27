---
name: plannotator-compound
description: >
  Analyze a user's Plannotator plan archive to extract denial patterns, feedback
  taxonomy, evolution over time, and actionable prompt improvements — then produce
  a polished HTML dashboard report. Use this skill when the user says things like
  "/compound-planning", "analyze my plans", "plan analysis", "what are my denial
  patterns", "why do my plans get denied", "compound planning report", "plan
  insights", or "analyze my planning data". This is a user-invoked skill only —
  do not trigger automatically. The user must explicitly request it.
---

# Compound Planning Analysis

You are conducting a comprehensive research analysis of a user's Plannotator plan
archive. The goal: extract patterns from their denied plans and annotations, reduce
them into actionable insights, and produce an elegant HTML dashboard report.

This is a multi-phase process. Each phase must complete fully before the next begins.
Research integrity is paramount — every file must be read, no skipping.

## Phase 0: Locate the Plans Directory

Check for `~/.plannotator/plans/`. If it exists and contains `.md` files, proceed.

If not found, ask the user:
> "I couldn't find plans at ~/.plannotator/plans/. Where is your plans directory?"

Once you have the path, verify it contains files matching `*-denied.md` and/or
`*.annotations.md`. If neither exist, inform the user there's no denial/annotation
data to analyze and stop.

## Phase 1: Inventory

Count and report the dataset:

```
- *-approved.md files (count)
- *-denied.md files (count)
- *.annotations.md files (count)
- *.diff.md files (count)
- Date range (earliest to latest date found in filenames)
- Total days spanned
- Revision rate: denied / (approved + denied) — this is the "X% of plans
  revised before coding" stat used in dashboard section 1
```

Also run `wc -l` across all `*-approved.md` files to get average lines per
approved plan. This tells the user whether their plans are staying lightweight
or bloating over time. You do not need to read approved plan contents — just
their line counts. If possible, break this down by time period (e.g., monthly)
to show whether plan size changed.

Dates appear in filenames in YYYY-MM-DD format, sometimes as a prefix
(2026-01-07-name-approved.md) and sometimes embedded (name-2026-03-15-approved.md).
Extract dates from all filenames.

Tell the user what you found and that you're beginning the extraction.

## Phase 2: Map — Parallel Extraction

This is the most time-intensive phase. You must read EVERY denied plan and EVERY
annotation file. Do not skip files. Do not summarize early.

**Important:** Do NOT read approved plan files. They are counted in the inventory
for context (total volume, approval rate) but are not analyzed for feedback
patterns. Only `*-denied.md` and `*.annotations.md` files contain the feedback
data this analysis needs.

### Batching Strategy

The approach depends on dataset size:

**Small datasets (< 40 total files):** Read all files directly — no need for
parallel agents. Just read them sequentially and proceed to Phase 3.

**Medium datasets (40-120 files):** Split into 2-4 parallel agents by file type
and/or time period.

**Large datasets (120+ files):** Split into batches of ~40-60 files per agent.
Split by the natural time boundaries in the data (months, quarters, or whatever
groupings produce balanced batches). If one time period dominates (e.g., the most
recent month has 3x the files), split that period into two batches.

Launch all extraction agents in parallel using the Agent tool with
`run_in_background: true`.

### Output Files

Each extraction agent must write its results to a clean output file rather than
relying on the agent task output (which contains interleaved JSONL framework
logs that are difficult to parse). Instruct each agent to write to:

```
/tmp/compound-planning/extraction-{batch-name}.md
```

Create the `/tmp/compound-planning/` directory before launching agents. The
reduce agent in Phase 3 will read these clean files directly.

### Extraction Prompt for Denied Plans

Each agent for denied plans receives this instruction (adapt the time period,
file glob, and output path):

```
You are extracting structured data from denied plan files for a pattern analysis.

Directory: [PLANS DIRECTORY]
Files to read: All *-denied.md files with dates in [TIME PERIOD]
Output: Write your complete results to [OUTPUT FILE PATH]

Read EVERY matching file. For EACH file, extract:
- The plan name/topic
- The denial reason or feedback given (look for reviewer comments, annotations,
  revision requests — capture the actual words used)
- What was specifically asked to change
- The type of feedback (let the content determine the category — don't force-fit
  into predefined types. Common types include things like: scope concerns,
  approach disagreements, missing information, process requirements, quality
  concerns, UX/design issues, naming disputes, clarification requests,
  testing/procedural denials — but the user's actual patterns may differ)
- Any specific phrases or recurring language from the reviewer
- The date

Do NOT skip any files. One entry per file.

Format each entry as:
**[filename]**
- Date: ...
- Topic: ...
- Denial reason: ...
- Feedback type: ...
- Specific asks: ...
- Notable phrases: ...
---

After processing all files, write the complete results to [OUTPUT FILE PATH].
State the total file count at the end of the file.
```

### Extraction Prompt for Annotation Files

Annotation files have a different structure — they contain inline comments,
highlights, and feedback left on specific sections of plans. Each agent for
annotations receives this instruction:

```
You are extracting structured data from annotation files for a pattern analysis.

Directory: [PLANS DIRECTORY]
Files to read: All *.annotations.md files with dates in [TIME PERIOD]
Output: Write your complete results to [OUTPUT FILE PATH]

Read EVERY matching file. For EACH file, extract:
- The plan name/topic it annotates
- Every individual annotation/comment made (there may be multiple per file)
- For each annotation: the quoted text, what type of feedback it is (correction,
  scope concern, design preference, structural request, question, praise,
  process directive, etc.), and what section of the plan was annotated
- The overall tone of the feedback

Do NOT skip any files. One entry per file.

Format each entry as:
**[filename]**
- Plan topic: ...
- Annotations found: [count]
- Annotation 1: "[quote or paraphrase]" — Type: ... — Section: ...
- Annotation 2: "[quote or paraphrase]" — Type: ... — Section: ...
- (continue for all annotations in the file)
- Overall tone: ...
---

After processing all files, write the complete results to [OUTPUT FILE PATH].
State the total file count at the end of the file.
```

### While Agents Run

Track completion. As each agent finishes, note the count of files it processed.
Verify the total matches the inventory from Phase 1. If any agent's count is
short, flag it and consider re-launching for the missing files.

If an agent times out (possible with large batches — a batch of 128 files can
take 8+ minutes), re-launch it for just the unprocessed files. Check the output
file to see how far it got before timing out.

## Phase 3: Reduce — Pattern Analysis

Once ALL extraction agents have completed (or all files have been read for small
datasets), launch a single reduction agent.

The reduction agent reads the clean extraction files from `/tmp/compound-planning/`
(not the agent task output files, which contain noisy JSONL framework logs). It
processes all extraction files together and produces the comprehensive analysis.

Give the reduction agent this prompt (adapt the file paths):

```
You are a data scientist conducting the reduction phase of a map-reduce analysis
across a user's plan denial and annotation archive.

Read ALL extraction files at /tmp/compound-planning/extraction-*.md

These files contain structured extractions from every denied plan and annotation
file. Your job: aggregate everything, find patterns, cluster into a taxonomy,
and produce a comprehensive analysis.

Be exhaustive. Use real counts. Quote real phrases from the data. This is
research — no hand-waving, no fabrication.

Produce the following sections:
[... sections listed below ...]
```

The reduction agent's job is to let the data speak. Do not impose a predetermined
framework — discover what's actually there. The analysis must produce:

### 1. Denial Reason Taxonomy
Categorize every denial into a finite set of types that emerge from the data. Count
occurrences. Show percentages. Include real example quotes for each type. Aim for
8-15 categories — enough to be specific, few enough to be scannable. Let the user's
actual feedback determine what the categories are.

### 2. Top Feedback Patterns (ranked by frequency)
The 5-10 most recurring patterns. For each: what the reviewer consistently asks for,
3+ example quotes from different files, and whether the pattern changed over time.

### 3. Recurring Phrases
Exact phrases the reviewer uses repeatedly, with counts and what they signal. These
are the reviewer's vocabulary — their shorthand for what they care about.

### 4. What the Reviewer Values (implicit preferences)
Derived from patterns — what does this specific person care about most? Quality?
Speed? Narrative? Architecture? Process? Simplicity? Rank by evidence strength.
This section should feel like a personality profile of the reviewer's standards.

### 5. What Agents Consistently Get Wrong
The flip side — what recurring mistakes trigger denials? What should agents stop
doing for this reviewer?

### 6. Structural Requests
What plan structure does the reviewer consistently demand? Required sections,
ordering, format preferences, level of detail expected.

### 7. Evolution Over Time
How feedback patterns changed across the time span. Group by whatever natural time
boundaries exist in the data (weeks for short spans, months for longer ones). Did
expectations mature? Did new patterns emerge? What shifted? If the dataset spans
less than a month, note that evolution analysis is limited but still look for any
progression from early to late files.

### 8. Actionable Prompt Instructions
The most important output. Based on all patterns: specific numbered instructions
that could be embedded in a planning prompt to prevent the most common denial
reasons. Write these as actual directives an agent could follow. Be specific to
this user's patterns — generic advice like "write good plans" is worthless. Each
instruction should trace back to a real, frequent denial pattern.

After writing the instructions, calculate what percentage of denials they would
address (count how many denials fall into categories covered by the instructions
vs total denials). Report this percentage — it will be different for every user.

## Phase 4: Generate the HTML Dashboard

Build a single, self-contained HTML file as the final deliverable. Save it to
the user's plans directory as `compound-planning-report.html`.

Read the template at `assets/report-template.html` for the **design language
only**. The template contains example data from a previous analysis — ignore all
data values, quotes, and percentages in the template. Use only its visual design:
colors, typography, spacing, component styles, and layout patterns.

### Design Language (from template)

- **Palette:** Light mode, warm off-white (#FDFCFB), text in slate scale, amber
  for highlights/accents, emerald for positive, rose for negative, indigo for
  action elements
- **Typography:** Playfair Display (serif, for narrative headings), Inter (sans,
  for body/data), JetBrains Mono (mono, for code/phrases) — Google Fonts CDN
- **Layout:** Single-column, max-width 1024px, generous vertical whitespace (128px
  between major sections), editorial/narrative-first aesthetic
- **Tone:** Calm, reflective, authoritative. Like a personal retrospective journal,
  not a monitoring dashboard.

### Page Frame (header + footer)

Before the 7 sections, the page has:

- **Header:** Report title on the left (Playfair Display, ~36px), project name +
  date range below it in light meta text. On the right: file counts in mono
  (e.g., "202 denials · 168 annotations · 71 days"). Separated from content by
  a bottom border. Generous bottom padding before section 1.

- **Footer:** After section 7. Top border, centered italic Playfair Display tagline
  summarizing the corpus (e.g., "Analysis of X denied plans and Y annotation files
  from the Plannotator archive.").

### Dashboard Section Order (7 sections)

The report follows this exact section order. Each section builds on the previous
one — the flow moves from "what happened" through "why" to "what to do about it":

1. **The story in the data** — An editorial narrative paragraph (Playfair Display
   serif, ~26px) that tells the headline finding in prose. Not bullet points — a
   real paragraph that reads like the opening of an article. Alongside it, a KPI
   sidebar with 3 key metrics (the top denial percentage, the overall revision
   rate, and the number of distinct denial categories found). Use an amber inline
   highlight on the most striking number in the narrative.

2. **Why plans get denied** — The taxonomy as a ranked list. Each row: rank number
   (mono), category label, a thin 4px progress bar (top item in amber-500, rest
   in slate-300), percentage (mono), and for the top entries, a real italic quote
   from the data below the label. Show the top 10 categories or however many the
   data supports (minimum 5).

3. **How expectations evolved** — One card per natural time period. Each card has:
   the period name in serif, a theme phrase in colored uppercase (different color
   per period to show progression), a description paragraph, and a stat line at
   the bottom (e.g., "X denials · Y narrative requests"). If the data spans less
   than 3 distinct periods, use 2 cards or even a single card with internal
   progression noted.

4. **What works vs what doesn't** — Two side-by-side cards. Left: green-tinted
   (emerald-50/50 bg, emerald-100 border) with traits of plans that succeed for
   this reviewer. Right: red-tinted (rose-50/50 bg, rose-100 border) with what
   agents keep getting wrong. Both derived from the reduction analysis. Bulleted
   with small colored dots. 5-8 items per card.

5. **The actionable output** — The diagnostic payoff. Opens with a Playfair
   Display narrative sentence stating how many prompt instructions were derived
   and what estimated percentage of denials they address (use the real calculated
   percentage from Phase 3, not a generic number). Then the top 3 most impactful
   improvements as numbered items, each with an amber number, bold title, and
   one-line description. This section bridges the analysis and the full prompt
   that follows.

6. **Your most-used phrases** — Grid of chips (2-col mobile, 3-col desktop). Each
   chip: monospace quoted phrase on the left, frequency count on the right. White
   bg, slate-200 border, rounded-12px. Show 9-12 of the most recurring phrases
   found. These should be the reviewer's actual words — their verbal fingerprint.

7. **The corrective prompt** — Dark panel (slate-900 bg, white text, rounded-3xl,
   shadow-xl). Opens with a Playfair intro sentence about the instructions. Then
   a dark code block (slate-800/80 bg, amber-200 monospace text) containing the
   full numbered prompt instructions from Phase 3. Include a copy-to-clipboard
   button that works (JS included). Below the code block: a gradient glow card
   (indigo-to-purple blurred halo behind a white card) with a closing message
   that these instructions are personal — derived from the user's own feedback,
   their own language, their own standards.

### Adaptation Rules

- If the user has < 3 months of data, reduce the evolution section to fewer cards
- If the user has no annotation files (only denials), note this in the narrative
  and skip annotation-specific insights
- If fewer than 5 denial categories emerge, combine the taxonomy and patterns
  sections into one
- If the dataset is very small (< 20 files), the narrative should acknowledge the
  limited sample size and frame findings as preliminary
- The number of prompt instructions will vary per user — could be 8 or 20. Don't
  force exactly 17. Let the data determine the count.
- The top 3 actionable items in section 5 must be the 3 that cover the largest
  share of denials, not the 3 that sound most impressive

### Key Rules

1. Every number must come from the real analysis — no fabricated data
2. Every quote must be a real quote from a real file
3. The taxonomy percentages must be calculated from real counts
4. The prompt instructions must trace back to actual denial patterns
5. The copy button on the prompt block must work (include the JS)

After generating, open the file in the user's browser.

## Phase 5: Summary

Tell the user:
- How many total files were analyzed (denials + annotations)
- The top 3 denial patterns found
- The estimated percentage of denials the prompt instructions would address
- The single most impactful prompt improvement
- Where the report was saved

## Important Notes

- **Research integrity:** Every file must be read. The value of this analysis comes
  from completeness. Sampling or skipping undermines the findings.
- **Real data only:** Never fabricate quotes, percentages, or patterns. If the data
  doesn't show a clear pattern, say so honestly rather than inventing one.
- **Let the data lead:** The taxonomy, patterns, and instructions should emerge from
  what's actually in the files. Different users will have completely different
  denial patterns. A user building mobile apps will have different feedback than
  one building APIs. Don't assume what the patterns will be.
- **Agent parallelization:** For large datasets, maximize parallel agents to reduce
  wall-clock time. The bottleneck is the largest batch — split it.
- **Structured extraction format:** Ask extraction agents to return structured text
  with consistent delimiters so the reduce agent can parse reliably.
- **The report is the artifact:** The HTML dashboard is what the user keeps. It
  should be beautiful, honest, and useful. Every section should feel like it was
  written about them specifically, because it was.
