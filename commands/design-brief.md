---
description: Walk through the Design Brief (UX first, then UI) and write or update DESIGN.md (joesteinkamp/design.md format)
---

Invoke the `design-brief` skill.

Run the full Design Brief flow:
1. Pre-flight: if `DESIGN.md` exists, offer **reuse / update sections (merge) / update tokens only / overwrite**. If it exists but is not in the [joesteinkamp/design.md](https://github.com/joesteinkamp/design.md) format, also offer to convert it. Read `PRODUCT.md` if present; recommend running `/starter:product-brief` first if not.
2. **Phase A — UX foundation**: structured + open follow-ups covering user knowledge, IA, flows (with edge cases and empty/error states), interaction principles, accessibility, UX success metrics.
3. **Phase B — UI system**: structured + open follow-ups covering visual register, color (OKLCH), typography, spacing, motion, components.
4. Validate against `guardrails/ux-anti-patterns.md` and `guardrails/design-anti-patterns.md`.
5. Apply opinionated defaults (marked `[default — confirm]`).
6. Embed both anti-pattern lists inline in the **Do's and Don'ts** section.
7. Render `DESIGN.md` with YAML front matter (tokens) and markdown body in the canonical section order: Overview → UX Foundation → Colors → Typography → Layout → Elevation & Depth → Shapes → Components → Do's and Don'ts.
8. In merge modes, preserve untouched sections verbatim.
9. Preview, accept one round of edits, write `DESIGN.md` at the project root.

End with the one-line summary the skill prescribes.
