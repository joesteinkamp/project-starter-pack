---
description: Synthesize PRODUCT.md, DESIGN.md, CODE.md, and PROJECT.md (if present) into AGENTS.md (joesteinkamp/agents-md format) and CLAUDE.md
---

Invoke the `orchestrator` skill.

Synthesize the briefs into agent instructions:
1. Read `PRODUCT.md`, `DESIGN.md`, and `CODE.md` from the project root. If any are missing, surface which command writes them; ask the user whether to proceed with TODO placeholders. Also read `PROJECT.md` if it exists — it's optional and folds in as a "Current project" section.
2. Pre-flight: if `AGENTS.md` and/or `CLAUDE.md` exist, offer **regenerate / update sections (merge) / stop**. Always preserve the `<!-- custom:start -->` / `<!-- custom:end -->` block.
3. Populate `templates/AGENTS.template.md` — the universal agents.md spec per [joesteinkamp/agents-md](https://github.com/joesteinkamp/agents-md), with precedence hierarchy, always-on rules (Git, Security, Testing), and project-specific synthesis (product summary, current project from `PROJECT.md` when present, product context, UX laws, design laws, code conventions, **inline-embedded** anti-pattern summaries from all four guardrails). Reference DESIGN.md tokens by `{path.to.token}` syntax.
4. Populate `templates/CLAUDE.template.md` — thin file that imports `@AGENTS.md` and adds 3-5 Claude-Code-specific notes.
5. Preview both files (in merge mode, only show changed sections), accept one round of edits, write to the project root.

End with the one-screen summary the skill prescribes.
