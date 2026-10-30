---
description: Guided setup — pick a scope (everything, or one brief), run it, seed evals/, then wire up AGENTS.md + CLAUDE.md
---

Invoke the `setup` skill, treating $ARGUMENTS as the scope.

Scope words: `product`, `design` (also writes `WRITING.md`), `code`, `evals` (seeds `evals/`
only), `all`. Anything
else — including nothing — means the skill asks which briefs to run.

It owns the rest: the intro and brownfield check, the selected briefs in order, the
always-run evals step and wire-up of `AGENTS.md` + `CLAUDE.md`, the between-step updates, and the
resume instructions if the user stops partway.
