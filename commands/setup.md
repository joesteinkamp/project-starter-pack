---
description: Guided setup — pick a scope (everything, or one brief), run it, then wire up AGENTS.md + CLAUDE.md
---

Invoke the `setup` skill, treating $ARGUMENTS as the scope.

Scope words: `product`, `design` (also writes `WRITING.md`), `code`, `all`. Anything
else — including nothing — means the skill asks which briefs to run.

It owns the rest: the intro and brownfield check, the selected briefs in order, the
always-run wire-up of `AGENTS.md` + `CLAUDE.md`, the between-step updates, and the
resume instructions if the user stops partway.
