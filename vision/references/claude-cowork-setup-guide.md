# How to set up Claude Cowork the right way (source post)

Source type: user-provided reference post

---

The people who are "getting" AI in 2026 aren’t the ones writing the cleverest prompts.
They’re the ones who figured out Cowork.

I started using Claude Cowork the week it launched in January 2026. Within a month it became the first thing I open every morning — before email, before Notion, before anything else. Not because someone told me to. Because it kept finishing work I used to spend hours doing myself.

I’ve spent the last three years building AI workflows for my work. Thousands of prompts tested. Dozens of tools tried. So when I tell you Cowork changed how I operate, I’m not saying it lightly.

This is the guide I wish someone had handed me before I wasted time figuring it out alone. Every feature. Every setup step. Every first prompt. And the honest version of where it falls short.

1. Save this guide and spend 30 minutes this weekend to set up Cowork properly.
2. Send it to anyone asking you, “I keep hearing about Claude but I’ve never tried it.”

Cowork is not a chatbot. It’s something else entirely.

Most people think Claude is like ChatGPT. A text box. You type, it responds. That’s claude.ai — the browser version.

Claude Cowork is different. It lives on your desktop. It reads and writes to folders on your actual computer. It creates Word documents. It builds spreadsheets with working formulas. It installs specialist plugins for your exact job. And when it doesn’t have enough information to do something well, it asks you — instead of guessing and giving you polished garbage.

Cowork is what happened when Anthropic took the power of Claude Code — their agentic developer tool — and rebuilt it for the rest of us. No terminal. No command line. No code. Just: describe the outcome you want, point it at your files, and step away.

I describe what I need. Cowork asks me three questions. I answer them. I come back 20 minutes later to a finished document. That loop now covers about 60% of my knowledge work.

Cowork is not one feature. It’s five.

- File System Access — Claude reads and writes to your actual computer
- AskUserQuestion — it forces clarity instead of guessing
- Plugins — specialist packs for your exact role
- Instructions — permanent memory that loads every session
- Connectors — live integrations with Slack, Drive, Notion, and 50+ tools

I ranked them by how much they changed how I work. Start at the top.

## 1) File System Access

What it is (in 10 words): Claude reads and writes files in a folder on your computer.

Why it matters

Every other AI tool runs on uploads. You export a file. You drag it into the chat. You wait. You get an output. You download it. You put it back wherever it came from.

Cowork eliminates that entire loop. You select a folder on your computer. Claude reads everything inside it. When it creates something — a document, a spreadsheet, a summary — it saves directly to that folder. No manual steps.

This sounds like a small thing. It isn’t. It’s the difference between AI as a tool you go to and AI as a collaborator that works in your environment.

Cowork can read your old reports to match your formatting. It can pull data from last month’s spreadsheet to build this month’s. It can reference your brand guidelines mid-task without you mentioning them. All because you pointed it at the right folder.

How to set it up

- Go to `claude.com/download`. Download the desktop app.
- You need a paid plan. Pro is $20/month. Max starts at $100/month.
- Open the app and switch to the Cowork tab.
- Click Select Folder and choose a local folder.
- Everything in that folder is now readable for the session.

Pro tip: The context files strategy

Create a dedicated folder called Claude Context. Inside it, build three files:

- `about-me.md` — who you are, role, and what success looks like
- `brand-voice.md` — communication style and examples
- `working-style.md` — how you want Claude to behave

The more quality context in these files, the less prompting you need.

Your first prompt

Read all the files in this folder completely. Then give me a summary of what you know about me, how I work, and what context you have access to.

## 2) AskUserQuestion

What it is (in 10 words): Cowork asks YOU questions instead of guessing and getting it wrong.

Why it matters

Most AI tools guess when tasks are underspecified. Cowork asks structured clarifying questions (forms/options) before execution.

Suggested usage line:

DO NOT start working yet. First, ask me clarifying questions so we can define the approach together. Only begin once we’ve aligned.

Default opener template:

I want to [YOUR TASK] so that [WHAT GOOD LOOKS LIKE]. First, read all uploaded files completely before responding. DO NOT start executing yet. Ask me clarifying questions (use AskUserQuestion) to refine the approach. Only begin work once we’ve aligned.

Mindset shift: better context beats clever prompts.

## 3) Plugins

What they are (in 10 words): Pre-built specialist packs that make Claude an expert instantly.

Why they matter

Without plugins, Cowork is a strong generalist. Plugins add role-specific commands/workflows.

Official plugin categories listed in post:

- Productivity
- Marketing
- Sales
- Finance
- Data Analysis
- Legal
- Product Management
- Customer Support
- Enterprise Search
- Biology Research

How to install

- Open Cowork
- Click + then Plugins
- Install plugin
- Type `/` to see slash commands

Example prompts in post include `/productivity:start`, `/marketing:draft-content`, `/data:explore`.

## 4) Instructions (Global and Folder)

What they are (in 10 words): Permanent memory that loads automatically at session start.

Why they matter

Cowork does not retain cross-session memory by default. Instructions are the workaround: standing context loaded each session.

Setup:

- Settings > Cowork > Global Instructions
- Add identity, communication style, output defaults, working style, and avoid-list
- Add folder-specific instructions for project/client-specific context

Validation prompt:

Before we start any work, tell me what you know about me, how I like to work, and any standing preferences you’re aware of.

## 5) Connectors

What they are (in 10 words): Live integrations with Slack, Drive, Notion, and other tools.

Why they matter

They reduce copy-paste workflows by allowing live data pull from connected systems.

Setup:

- Settings > Connectors
- Add integration and authenticate once
- Reuse in all sessions

Example prompts:

- Search my Slack messages from the last 7 days and summarize follow-ups by urgency.
- Find the most recent Drive doc for [project], read it, and give top 3 takeaways.

## Known limitations in post

- No cross-session memory (workaround: context files + instructions)
- Tasks stop if app is closed
- Usage burns faster on complex tasks
- Desktop-only, no mobile sync experience
- No image generation
- Marked as research preview; use caution on sensitive files

## 30-minute setup flow in post

- 0-5: install app and enable Cowork
- 5-10: create `about-me.md`, `brand-voice.md`, `working-style.md`
- 10-15: set global instructions
- 15-20: run first task with clarifying questions
- 20-25: install one plugin
- 25-30: connect one external tool

Core thesis: stop optimizing prompts in isolation; build compounding context systems.
