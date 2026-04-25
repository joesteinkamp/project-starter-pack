---
description: Walk through the Product Brief and write PRODUCT.md
---

Invoke the `product-brief` skill.

Run the full Product Brief flow:
1. Pre-flight (reuse / merge / overwrite if `PRODUCT.md` exists).
2. Pass 1 — structured questions via `AskUserQuestion`.
3. Pass 2 — open follow-ups in chat.
4. Validate against `guardrails/product-anti-patterns.md`.
5. Apply opinionated defaults (marked `[default — confirm]`).
6. Preview, accept one round of edits, write `PRODUCT.md` at the project root.

End with the one-line summary the skill prescribes.
