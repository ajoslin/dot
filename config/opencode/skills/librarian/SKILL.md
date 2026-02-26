---
name: librarian
description: Multi-repository codebase exploration for library internals, architecture understanding, and implementation comparisons.
---

# Librarian Skill

Use this skill when you need deep understanding of external codebases.

Best-use cases:
- Explain how a third-party library works internally.
- Find real implementation patterns in public code.
- Compare two libraries/frameworks for a specific capability.
- Trace architecture and execution flow across a repository.

Tool routing:
- Official docs/API questions: use documentation lookup first.
- Real-world code usage patterns: search public repositories.
- Internal implementation details: fetch source and read targeted files.

Execution pattern:
1. Identify target library/repo and scope the question.
2. Collect high-signal files (README, package metadata, entry points).
3. Inspect implementation files for the asked behavior.
4. Synthesize findings with concrete file evidence.

Output style:
- Give direct answer first.
- Support with precise file references.
- Use a diagram if system flow is non-trivial.
