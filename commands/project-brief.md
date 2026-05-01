---
description: Walk through the Project Brief and write PROJECT.md
---

Invoke the `project-brief` skill.

Run the full Project Brief flow:
1. Pre-flight (replace-only if `PROJECT.md` exists; warn if `PRODUCT.md` / `DESIGN.md` / `CODE.md` are missing).
2. Pass 1 — structured questions via `AskUserQuestion`.
3. Pass 2 — open follow-ups in chat.
4. Validate against `guardrails/project-anti-patterns.md`.
5. Apply opinionated defaults (marked `[default — confirm]`).
6. Preview, accept one round of edits, write `PROJECT.md` at the project root.

End with the one-line summary the skill prescribes.
