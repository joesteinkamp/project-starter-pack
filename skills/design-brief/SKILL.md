---
name: design-brief
description: Walks the user through a UX-and-UI design brief and writes DESIGN.md (and optional DESIGN.json tokens companion) at the project root. UX foundation comes first (user knowledge, IA, flows, success metrics), then the UI system (color, type, spacing, motion, components). Use when the user asks for a design brief, design system, UX foundation, DESIGN.md, or to define visual language. Triggers on "design brief", "DESIGN.md", "design system", "UX foundation", "user flows", "information architecture", "color strategy", "design tokens".
---

# Design Brief Skill

You are running the Design Brief flow. Your job is to walk the user through UX questions first, then UI questions, and produce `DESIGN.md` (and optionally `DESIGN.json` — the tokens companion) at the project root.

## Conventions

Read `../../conventions/question-mechanics.md` first. It defines how this flow asks structured and open questions in whatever tool you are running in, how it writes files, and how it resolves the resource paths below.

## Setup

1. The questionnaire bank is at `../../questionnaires/design.questions.md`. Templates are at `../../templates/DESIGN.template.md` and `../../templates/DESIGN.tokens.template.json`. The anti-pattern guardrails are at `../../guardrails/design-anti-patterns.md` and `../../guardrails/ux-anti-patterns.md`.
2. Read all of them before starting.
3. If `PRODUCT.md` exists, read it — design choices answer to product context. If it doesn't, recommend the user run the `product-brief` flow first; offer to continue anyway if they decline.

## Pre-flight

Check whether `DESIGN.md` exists at the project root.
- **Exists** → reuse / merge / overwrite, asked as a structured question.
- **Missing** → proceed.

## Phase A — UX foundation (always first)

### Pass A1 — Structured

Ask Q1–Q4 from the **UX section** of `../../questionnaires/design.questions.md` as structured questions.

### Pass A2 — Open follow-ups

Ask Q5–Q9 (UX) as free-form prompts. Ask one or two at a time. For user flows specifically, prompt the user to describe at least one happy path **and** at least one edge case / empty state — apply `../../guardrails/ux-anti-patterns.md` if they skip them.

## Phase B — UI system

### Pass B1 — Structured

Ask Q10–Q14 (UI) as structured questions.

### Pass B2 — Open follow-ups

Ask Q15–Q19 (UI) as free-form prompts. For color tokens, accept hex from the user but auto-convert to OKLCH in the output and note the conversion. For typography, require a measure cap (default to 65–75ch if the user shrugs).

## Validation pass

Apply both guardrails:
- `../../guardrails/ux-anti-patterns.md` — if user flows lack empty/error states, push back and ask. If "are you sure?" modals are casually proposed, suggest undo instead.
- `../../guardrails/design-anti-patterns.md` — if the user describes purple gradients, neon-on-black, nested cards, or other entries on the ban list, push back once with the rationale.

Be direct. Don't soften.

## Defaults pass

Apply the defaults table from `../../questionnaires/design.questions.md`. Mark defaulted lines with ` [default — confirm]`. Always pull the anti-pattern lists from `../../guardrails/design-anti-patterns.md` and `../../guardrails/ux-anti-patterns.md` into the relevant sections of the output — embedded inline, not just linked.

## DESIGN.json (optional tokens companion)

If the user provided concrete color/typography/spacing values, also populate `../../templates/DESIGN.tokens.template.json` and offer to write it to `DESIGN.json` at the project root. The filename matches the convention used by Impeccable so the two tools can share the file. If the user declined to specify tokens, skip the JSON file.

Theme blocks are symmetric: the top-level `color` block always holds the **default** theme's values — light values when Q13 chose `light`/`both`/`system`, dark values when it chose `dark`. When Q13 chose `both` or `system`, also fill the `themes.dark` override block (the dark column of the DESIGN.md color table). For a single-theme answer — `light` **or** `dark` — delete the whole `themes` block rather than leaving placeholders or fabricating values for a theme that doesn't exist: DESIGN.json must state exactly what the design system commits to.

Rendering rules: numeric slots (`{{TYPE_SCALE_RATIO}}`, `{{TYPE_LINE_HEIGHT}}`) are unquoted in the template — emit bare numbers (`1.25`, not `"1.25"`). `{{SPACING_SCALE}}` renders inside array brackets — emit the bare comma-separated numbers. Before writing, verify the result parses as JSON, and compute the contrast pairs from the questionnaire's pre-flight checklist — a token file whose pairs fail the committed WCAG level does not ship.

## Preview & write

1. Render populated `DESIGN.md` and show it to the user.
2. If tokens were collected, also render `DESIGN.json`.
3. Ask for one round of edits, then write both files to the project root.

## Done

"Wrote DESIGN.md ({{N}} sections, {{M}} defaults marked for confirmation){{tokens_clause}}. Next: the `code-brief` flow."

## Important

- UX always comes before UI. Do not let the user skip Phase A unless they explicitly say "we already have UX defined elsewhere" — in which case ask where, and reference it in the output.
- If you are running inside the `setup` flow, hand control back when done.
