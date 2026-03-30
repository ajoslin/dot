---
name: skill-creator
description: Create new skills, modify and improve existing skills, and measure skill quality for OpenCode agents. Load FIRST before writing any SKILL.md. Use when creating a skill from scratch, editing or optimizing an existing skill, scaffolding skill structure, testing skill quality with evals, improving skill triggering accuracy, or debugging skill issues. Provides required format, naming conventions, progressive disclosure patterns, evaluation workflows, and validation. Use this skill whenever the user mentions making a skill, writing a skill, skill development, skill improvement, or skill debugging, even if they don't explicitly say "skill-creator".
---

# Skill Creator

A skill for creating new skills and iteratively improving them in OpenCode.

The process at a high level:

- Decide what the skill should do and roughly how it should work
- Write a draft of the skill
- Create a few test prompts and run them via Task subagents
- Help the user evaluate the results (qualitatively, and quantitatively if applicable)
- Rewrite the skill based on feedback
- Repeat until satisfied
- Expand the test set and try again at larger scale

Your job is to figure out where the user is in this process and help them progress. Maybe they want to create a skill from scratch — help narrow scope, draft it, write test cases, run them, iterate. Maybe they already have a draft — jump straight to evaluation. Be flexible: if the user says "just vibe with me," skip the formal eval loop.

## Communicating with the User

Pay attention to context cues about the user's technical familiarity. There's a growing trend where people across all backgrounds are using AI coding tools. In the default case:

- "evaluation" and "benchmark" are borderline, but OK
- For "JSON" and "assertion," see cues from the user before using them without explanation

Briefly explain terms if in doubt. Clarify with a short definition if unsure the user will follow.

---

## Creating a Skill

### Capture Intent

Start by understanding the user's intent. The conversation might already contain a workflow the user wants to capture (e.g., "turn this into a skill"). If so, extract answers from conversation history first — tools used, step sequences, corrections made, input/output formats observed. The user fills gaps and confirms before proceeding.

1. What should this skill enable the agent to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases? Skills with objectively verifiable outputs (file transforms, data extraction, code generation) benefit from test cases. Subjective skills (writing style, creative work) often don't. Suggest the appropriate default, but let the user decide.

### Interview and Research

Proactively ask about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until this part is ironed out.

Check available MCPs — if useful for research (searching docs, finding similar skills), research in parallel via Task subagents. Come prepared with context to reduce burden on the user.

### Write the SKILL.md

Based on the interview, fill in these components:

- **name**: Skill identifier (lowercase, hyphens, matches directory name)
- **description**: When to trigger, what it does. This is the primary triggering mechanism — include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body. Make descriptions slightly "pushy" to combat under-triggering. For example, instead of "Build dashboards for internal data," write "Build dashboards for internal data. Use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of data, even if they don't explicitly ask for a 'dashboard.'"
- **compatibility**: Required tools, dependencies (optional, rarely needed)
- **the rest of the skill**

### Skill Writing Guide

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

For detailed anatomy patterns, see [anatomy.md](./references/anatomy.md).
For YAML frontmatter spec, see [frontmatter.md](./references/frontmatter.md).
For bundled resource details, see [bundled-resources.md](./references/bundled-resources.md).

#### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) — Always in context (~100 words)
2. **SKILL.md body** — Loaded when skill triggers (<500 lines ideal)
3. **Bundled resources** — Loaded on demand (unlimited, scripts execute without loading)

Word counts are approximate; go longer if needed.

**Key patterns:**
- Keep SKILL.md under 500 lines; approaching the limit, add hierarchy with clear pointers
- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents

For more, see [progressive-disclosure.md](./references/progressive-disclosure.md).

**Domain organization** — when a skill supports multiple domains/frameworks, organize by variant:
```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```
The agent reads only the relevant reference file.

#### Principle of Lack of Surprise

Skills must not contain malware, exploit code, or content that could compromise security. A skill's contents should not surprise the user in their intent if described. Don't create misleading skills or skills designed for unauthorized access or data exfiltration. Roleplay-style skills are fine.

#### Writing Patterns

Prefer the imperative form in instructions.

**Defining output formats:**
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern:**
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Writing Style

Explain to the model why things are important rather than piling on heavy-handed MUSTs. Use theory of mind and make the skill general, not narrow to specific examples. Write a draft, look at it with fresh eyes, and improve.

### Test Cases

After writing the draft, come up with 2-3 realistic test prompts — things a real user would actually say. Share them: "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?"

Save test cases to `evals/evals.json`:

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

---

## Running and Evaluating Test Cases

This section is one continuous sequence — don't stop partway through.

Put results in a `-workspace/` directory as a sibling to the skill directory. Organize by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Create directories as you go.

### Step 1: Spawn All Runs in the Same Turn

For each test case, launch two Task subagents in the same turn — one with the skill, one without. Launch everything at once so it finishes around the same time.

**With-skill run** — use the `general` subagent type:

```
Task(subagent_type="general", prompt="""
Execute this task using the skill instructions found at <path-to-skill/SKILL.md>.
Read the SKILL.md first, then follow its guidance to complete:
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save all outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Return: summary of what was produced, any issues encountered
""")
```

**Baseline run** — same prompt, no skill reference:
- **New skill**: No skill at all. Same prompt, save to `without_skill/outputs/`.
- **Improving existing skill**: The old version. Snapshot the skill before editing (`cp -r`), point the baseline at the snapshot. Save to `old_skill/outputs/`.

Write an `eval_metadata.json` for each test case. Give each eval a descriptive name:

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: While Runs Are in Progress, Draft Assertions

Use this time productively. Draft quantitative assertions for each test case and explain them to the user. Good assertions are objectively verifiable with descriptive names that read clearly at a glance.

Subjective skills (writing style, design quality) are better evaluated qualitatively — don't force assertions onto things that need human judgment.

Update `eval_metadata.json` and `evals/evals.json` with the assertions once drafted.

### Step 3: Grade and Review

Once all runs are done:

1. **Grade each run** — evaluate assertions against outputs, either inline or via a `thrifty` Task subagent. Save results to `grading.json` in each run directory with this format:
   ```json
   {
     "expectations": [
       {"text": "Output contains valid JSON", "passed": true, "evidence": "File output.json parsed successfully"},
       {"text": "Response under 200 lines", "passed": false, "evidence": "Output was 247 lines"}
     ]
   }
   ```
   For assertions that can be checked programmatically, write and run a script — scripts are faster, more reliable, and reusable across iterations.

2. **Launch the eval viewer** to let the user review outputs in their browser:
   ```bash
   nohup python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   If no display is available, use `--static <path>.html` to write a standalone HTML file instead of starting a server.

   The viewer has two tabs:
   - **Outputs** — navigate test cases, see prompts/outputs/grading, leave feedback per case
   - **Benchmark** — quantitative comparison (pass rates, timing, tokens)

   Tell the user: "I've opened the results in your browser. Review each test case and leave feedback, then come back and tell me you're done."

3. **Analyze patterns** — surface things aggregate stats might hide: assertions that always pass regardless of skill (non-discriminating), high-variance evals, time/token tradeoffs.

### Step 4: Collect Feedback

When the user says they're done, read `feedback.json` from the workspace:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback means the user thought it was fine. Focus improvements on test cases with specific complaints.

Kill the viewer server when done:

```bash
kill $VIEWER_PID 2>/dev/null
```

---

## Improving the Skill

This is the heart of the loop. You've run test cases, the user has reviewed results, now make it better.

### How to Think About Improvements

1. **Generalize from feedback.** The skill will be used many times across many different prompts. You and the user are iterating on a few examples because it's fast. But if the skill only works for those examples, it's useless. Rather than fiddly, overfitting changes or oppressive MUSTs, if something is stubborn, try different metaphors or recommend different working patterns. It's cheap to experiment.

2. **Keep the prompt lean.** Remove things that aren't pulling their weight. Read the transcripts, not just final outputs — if the skill makes the agent waste time on unproductive tangents, remove those instructions.

3. **Explain the why.** Try hard to explain the **why** behind everything. LLMs are smart. They have good theory of mind and when given a good harness can go beyond rote instructions. Even if user feedback is terse, understand the task and transmit that understanding into the instructions. If you're writing ALWAYS or NEVER in caps or using rigid structures, that's a yellow flag — reframe and explain reasoning so the model understands importance. That's more effective.

4. **Look for repeated work across test cases.** Read transcripts and notice if agents independently wrote similar helper scripts or took the same multi-step approach. If all test cases produce similar boilerplate, bundle that script in `scripts/` and tell the skill to use it. Save every future invocation from reinventing the wheel.

This task matters. Take your time and mull things over. Write a draft revision, look at it fresh, and improve. Get into the user's head and understand what they need.

### The Iteration Loop

After improving the skill:

1. Apply improvements
2. Rerun all test cases into a new `iteration-<N>/` directory, including baselines
3. Present results with comparison to previous iteration
4. Wait for user review
5. Read new feedback, improve again, repeat

Keep going until:
- The user says they're happy
- Feedback is all empty (everything looks good)
- You're not making meaningful progress

---

## Description Optimization

The description field in SKILL.md frontmatter is the primary mechanism that determines whether the agent invokes a skill. After creating or improving a skill, offer to optimize the description for better triggering accuracy.

### Step 1: Generate Trigger Eval Queries

Create 20 eval queries — a mix of should-trigger and should-not-trigger. Queries must be realistic, specific, and detailed. Include file paths, personal context, column names, URLs, backstory. Mix lengths and focus on edge cases.

Bad: `"Format this data"`, `"Extract text from PDF"`, `"Create a chart"`

Good: `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage. The revenue is in column C and costs are in column D i think"`

**Should-trigger (8-10):** Different phrasings of the same intent — formal, casual. Cases where the user doesn't name the skill but clearly needs it. Uncommon use cases. Cases where this skill competes with another but should win.

**Should-not-trigger (8-10):** Near-misses sharing keywords but needing something different. Adjacent domains, ambiguous phrasing where naive keyword match would trigger but shouldn't. Don't make them obviously irrelevant — they should be genuinely tricky.

Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

### Step 2: Review with User

Present the eval set. Let them edit queries, toggle should-trigger, add/remove entries. This step matters — bad eval queries lead to bad descriptions.

### Step 3: Iterate on the Description

For each query, assess whether the current description would trigger correctly. For failures, analyze why and propose improvements. Re-test. Iterate until triggering accuracy is high on both should-trigger and should-not-trigger cases.

Focus on held-out test performance (not just the queries you tuned against) to avoid overfitting.

### Step 4: Apply the Result

Update the skill's SKILL.md frontmatter with the improved description. Show the user before/after and report accuracy.

### How Skill Triggering Works

Skills appear in the agent's `available_skills` list with name + description. The agent decides whether to load a skill based on that description. The agent only consults skills for tasks it can't easily handle on its own — simple one-step queries may not trigger even if the description matches, because the agent handles them directly. Complex, multi-step, or specialized queries reliably trigger when the description matches.

Eval queries should be substantive enough that the agent would benefit from consulting a skill.

---

## Updating an Existing Skill

If the user is updating an existing skill (not creating new):

- **Preserve the original name.** Note the directory name and `name` frontmatter field — use them unchanged.
- **Copy to a writable location before editing** if the installed path is read-only. Copy to `/tmp/skill-name/`, edit there, then copy back.

---

## Skill Locations in OpenCode

| Priority | Location |
|----------|----------|
| 1 | `.opencode/skills/<name>/` (project-level) |
| 2 | `~/.config/opencode/skills/<name>/` (global) |

Discovery walks up from CWD to git root. First match wins for duplicate names.

## Reference Files

| File | Purpose |
|------|---------|
| [anatomy.md](./references/anatomy.md) | Skill directory structures |
| [frontmatter.md](./references/frontmatter.md) | YAML spec, naming, validation |
| [progressive-disclosure.md](./references/progressive-disclosure.md) | Token-efficient design |
| [bundled-resources.md](./references/bundled-resources.md) | scripts/, references/, assets/ |
| [patterns.md](./references/patterns.md) | Real-world skill patterns |
| [gotchas.md](./references/gotchas.md) | Common mistakes + fixes |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/init_skill.sh` | Scaffold new skill directory |
| `scripts/validate_skill.sh` | Validate skill structure and frontmatter |
| `scripts/package_skill.sh` | Create distributable zip |

## Pre-Flight Checklist

Before finalizing a skill:

- [ ] SKILL.md starts with `---` (line 1, no blank lines)
- [ ] `name:` field present, matches directory name
- [ ] `description:` includes what + when to use (slightly pushy)
- [ ] Closing `---` after frontmatter
- [ ] SKILL.md under 500 lines (use references/ for more)
- [ ] All internal links resolve
- [ ] Description tested against realistic trigger queries

Run: `./scripts/validate_skill.sh ./my-skill`

---

## Core Loop Summary

1. Figure out what the skill is about
2. Draft or edit the skill
3. Run test prompts via Task subagents (with-skill + baseline, in parallel)
4. Evaluate outputs with the user (qualitative review + quantitative evals if applicable)
5. Improve the skill based on feedback
6. Repeat until satisfied
7. Optimize the description for triggering accuracy
8. Validate and package

Track progress through this loop via TodoWrite to make sure steps don't get skipped.

## See Also

- [Cloudflare Skill](https://github.com/dmmulroy/cloudflare-skill) — Reference implementation of a large platform skill
