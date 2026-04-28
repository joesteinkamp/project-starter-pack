---
description: Cross-check PRODUCT.md, DESIGN.md, and CODE.md for contradictions and anti-pattern hits
---

Invoke the `validator` skill.

Run a consistency pass over the three briefs:
1. Read `PRODUCT.md`, `DESIGN.md`, and `CODE.md` from the project root. If any are missing, surface which command writes them and stop.
2. Walk the cross-brief checklist (motion vs. stack, performance vs. design weight, register vs. microcopy, primary user vs. flows, accessibility vs. testing, anti-references vs. UI patterns).
3. Re-apply the four anti-pattern guardrails against the briefs.
4. Report a checklist with ✓ / ⚠ / ✗ per check, plus a "fix-it" section pointing at the specific brief and section to edit.

End with the one-line summary the skill prescribes.
