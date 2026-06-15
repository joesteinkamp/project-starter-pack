---
description: Synthesize PRODUCT.md, DESIGN.md, and CODE.md into AGENT.md and CLAUDE.md
---

Invoke the `orchestrator` skill.

Synthesize the three briefs into agent instructions:
1. Read `PRODUCT.md`, `DESIGN.md`, and `CODE.md` from the project root. If any are missing, surface which command writes them; ask the user whether to proceed with TODO placeholders.
2. Pre-flight (overwrite-only — do not offer "merge" since these files are derived).
3. Populate `templates/AGENT.template.md` — the universal agents.md spec — with synthesized project summary, product context, UX laws, design laws, code conventions, and **inline-embedded** anti-pattern summaries from all four guardrail files.
4. Ask which AI harnesses to target (Claude Code / Gemini CLI / Cursor — multi-select). `AGENT.md` is always written; only the selected harness files are emitted.
5. Populate `templates/CLAUDE.template.md` — a thin file that imports `@AGENT.md`, carries the "Layering" note (this is the project layer; user-level tool/autonomy/memory rules stay in the operator's global instructions), lists the available commands/skills, and adds 3-5 notes specific to *this* repository. If selected, also write `GEMINI.md` (thin import) and a Cursor file — `AGENTS.md` (simple copy) or `.cursor/rules/project.mdc` (scoped).
6. Preview the files, accept one round of edits, write to the project root.

End with the one-screen summary the skill prescribes.
