---
description: Synthesize PRODUCT.md, DESIGN.md, CODE.md, and PROJECT.md (if present) into AGENT.md and CLAUDE.md
---

Invoke the `orchestrator` skill.

Synthesize the briefs into agent instructions:
1. Read `PRODUCT.md`, `DESIGN.md`, and `CODE.md` from the project root. If any are missing, surface which command writes them; ask the user whether to proceed with TODO placeholders. Also read `PROJECT.md` if it exists — it's optional and folds in as a "Current project" section.
2. Pre-flight (overwrite-only — do not offer "merge" since these files are derived).
3. Populate `templates/AGENT.template.md` — the universal agents.md spec — with synthesized product summary, current project (if `PROJECT.md` exists), product context, UX laws, design laws, code conventions, and **inline-embedded** anti-pattern summaries from all four guardrail files.
4. Populate `templates/CLAUDE.template.md` — a thin file that imports `@AGENT.md` and adds Claude-Code-specific notes (preferred tools, sub-agents, slash commands, skills, plus 3-5 project-specific notes).
5. Preview both files, accept one round of edits, write to the project root.

End with the one-screen summary the skill prescribes.
