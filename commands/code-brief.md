---
description: Walk through the Technical Brief and write CODE.md
---

Invoke the `code-brief` skill.

Run the full Technical Brief flow:
1. Pre-flight (reuse / merge / overwrite if `CODE.md` exists). Read `PRODUCT.md` and `DESIGN.md` if they exist. Read any manifest file (`package.json`, `pyproject.toml`, `Cargo.toml`) and pre-populate stack answers as suggestions.
2. Pass 1 — structured questions via `AskUserQuestion` covering frontend, backend, database, hosting, auth, repo strategy, type system, testing posture, and performance budget posture.
3. Pass 2 — open follow-ups covering architecture detail, languages and tooling, code conventions, testing detail, deployment and CI, performance budgets, and security baselines.
4. Validate against `guardrails/code-anti-patterns.md` and check stack consistency.
5. Apply opinionated defaults (marked `[default — confirm]`).
6. Embed the code anti-patterns list inline in the output.
7. Preview, accept one round of edits, write `CODE.md` at the project root.

End with the one-line summary the skill prescribes.
