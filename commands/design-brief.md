---
description: Walk through the Design Brief (UX first, then UI) and write DESIGN.md
---

Invoke the `design-brief` skill.

Run the full Design Brief flow:
1. Pre-flight (reuse / merge / overwrite if `DESIGN.md` exists). Read `PRODUCT.md` if it exists; recommend running `/starter:product-brief` first if it doesn't.
2. **Phase A — UX foundation** first: structured questions, then open follow-ups covering user knowledge, information architecture, user flows (with edge cases and empty/error states), interaction principles, accessibility, and UX success metrics.
3. **Phase B — UI system** second: structured questions, then open follow-ups covering visual register, color (OKLCH), typography, spacing, motion, and component primitives.
4. Validate against `guardrails/ux-anti-patterns.md` and `guardrails/design-anti-patterns.md`.
5. Apply opinionated defaults (marked `[default — confirm]`).
6. Embed both anti-pattern lists inline in the output.
7. Optionally write `DESIGN.json` (the tokens companion, named to match Impeccable's convention) if concrete tokens were collected.
8. Preview, accept one round of edits, write `DESIGN.md` at the project root.

End with the one-line summary the skill prescribes.
