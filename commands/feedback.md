---
description: Give corrective feedback on a generated brief and apply the fix to the affected md file(s)
---

Invoke the `feedback` skill.

Run the corrective feedback flow on one of the project's generated briefs (`PRODUCT.md`, `DESIGN.md`, `CODE.md`, `AGENTS.md`, `CLAUDE.md`):

1. Ask which file the feedback is about and what category of problem it is.
2. Ask where in the file and what "correct" would look like.
3. Read the affected file. If the file is derived (`AGENTS.md` / `CLAUDE.md`), also read the source brief(s) and prefer a source-brief fix.
4. Draft a focused, section-scoped edit. Preview the diff.
5. On confirmation, apply the edit. If a derived file was the symptom but a source brief was the cause, offer to re-run `/starter:orchestrate`.
6. If the same problem looks like an upstream template / questionnaire / guardrail flaw, suggest `/starter:report-issue` so the plugin gets better at generating files in the first place.
