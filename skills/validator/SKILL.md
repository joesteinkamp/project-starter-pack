---
name: validator
description: Cross-checks PRODUCT.md, DESIGN.md, and CODE.md for contradictions and re-applies the four anti-pattern guardrails. Use when the user asks to validate, audit, lint, or sanity-check the briefs, or when the briefs have been hand-edited and need a consistency pass before re-orchestrating. Triggers on "validate briefs", "check briefs", "audit PRODUCT/DESIGN/CODE", "are the briefs consistent", "lint the project briefs".
---

# Validator Skill

You sanity-check the three briefs against each other and against the anti-pattern guardrails. You do not edit the briefs — you produce a report the user (or the next pass of `/starter:product-brief` / `/starter:design-brief` / `/starter:code-brief`) can act on.

## Setup

1. Locate the plugin root. Guardrails live at `guardrails/{product,ux,design,code}-anti-patterns.md`.
2. Read all four guardrail files before starting.

## Inputs

Read all three briefs from the project root:
- `PRODUCT.md`
- `DESIGN.md`
- `CODE.md`

If any are missing:
- Print which are missing and the command to run for each (`/starter:product-brief`, `/starter:design-brief`, `/starter:code-brief`).
- Stop. Do not validate a partial set — half the contradictions can't be detected without all three.

If any brief contains `[TODO — …]` or `[default — confirm]` markers, list them up top under "Unresolved placeholders" — the user should resolve those before trusting the rest of the report.

## Cross-brief checklist

Walk these six checks. For each, return ✓ (consistent), ⚠ (worth a look — soft tension), or ✗ (contradicts).

1. **Motion vs. stack** — Compare the motion stance in `DESIGN.md` (UI system) against the stack and dependencies in `CODE.md`. Examples of contradictions: "minimal motion" + Framer Motion / Lottie / GSAP listed as core dependencies; "expressive animation" + a stack that has no animation library and a strict performance budget that forbids one.

2. **Performance vs. design weight** — Compare the performance budgets in `CODE.md` (LCP, bundle size, etc.) against the design choices in `DESIGN.md` (heavy hero imagery, video backgrounds, custom fonts, complex motion). Flag if the design implies weight the budget can't carry.

3. **Brand register vs. UX microcopy** — Compare the register and brand personality in `PRODUCT.md` against the UX microcopy guidance and tone in `DESIGN.md`. Examples: "playful, irreverent" register + "neutral, professional, no exclamation marks" microcopy; "serious, precise, surgical" register + "fun loading states and emoji-heavy empty states".

4. **Primary user vs. flows** — Compare the primary user and jobs-to-be-done in `PRODUCT.md` against the user-knowledge model and top flows in `DESIGN.md`. Flag if the flows assume a different sophistication level than the persona, or if a stated job-to-be-done has no flow.

5. **Accessibility vs. testing** — Compare the accessibility commitments in `DESIGN.md` against the testing posture in `CODE.md`. Flag if WCAG AA / keyboard-only / screen-reader commitments are made with no automated a11y testing in the test plan.

6. **Anti-references vs. UI patterns** — Compare the anti-references in `PRODUCT.md` (the products this is **not** trying to be) against the UI patterns chosen in `DESIGN.md`. Flag if the chosen patterns are exactly what the anti-references are known for (e.g. anti-reference is "another Linear clone" but the layout is a three-pane Cmd-K-driven Linear-shaped UI).

## Anti-pattern re-application

For each of the four guardrail files, scan the matching brief for hits:
- `guardrails/product-anti-patterns.md` against `PRODUCT.md`
- `guardrails/ux-anti-patterns.md` against the UX foundation half of `DESIGN.md`
- `guardrails/design-anti-patterns.md` against the UI system half of `DESIGN.md`
- `guardrails/code-anti-patterns.md` against `CODE.md`

For each hit, name the anti-pattern, quote (≤12 words) the offending line, and cite the section.

## Output

Render a single report:

```
# Brief validation report

## Unresolved placeholders
- [list, or "None"]

## Cross-brief checks
✓/⚠/✗ Motion vs. stack         — [one-line finding]
✓/⚠/✗ Performance vs. design   — [one-line finding]
✓/⚠/✗ Register vs. microcopy   — [one-line finding]
✓/⚠/✗ User vs. flows           — [one-line finding]
✓/⚠/✗ A11y vs. testing         — [one-line finding]
✓/⚠/✗ Anti-refs vs. UI         — [one-line finding]

## Anti-pattern hits
- PRODUCT.md § <section>: <pattern name> — "<≤12-word quote>"
- ...
- (or "None")

## Fix-it
1. Open <BRIEF.md> § <section>: <one-sentence direction>
2. ...
```

End with one summary line:
```
{{N_PASS}} passed, {{N_WARN}} warnings, {{N_FAIL}} contradictions, {{N_HITS}} anti-pattern hits. Re-run /starter:orchestrate after fixes.
```

## Important

- This skill never edits the briefs. It only reports.
- If a check is genuinely not applicable (e.g. a static-content site has no test plan), mark it ✓ with the note "n/a — no test plan stated" rather than ✗.
- Be specific. "DESIGN.md is too heavy" is useless; "DESIGN.md § Motion calls for parallax hero, but CODE.md § Performance caps JS at 80kb" is actionable.
- Do not invent contradictions to look thorough. If all six checks pass with no anti-pattern hits, say so plainly.
