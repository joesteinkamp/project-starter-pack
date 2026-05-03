---
name: design-brief
description: Walks the user through a UX-and-UI design brief and writes (or updates) DESIGN.md at the project root, conforming to the joesteinkamp/design.md format (YAML token front matter + markdown rationale, canonical section order). UX foundation comes first (user knowledge, IA, flows, success metrics), then the UI system (color, type, spacing, motion, components). Use when the user asks for a design brief, design system, UX foundation, DESIGN.md, or to define visual language. Triggers on "design brief", "DESIGN.md", "design system", "UX foundation", "user flows", "information architecture", "color strategy", "design tokens", "update design", "modify DESIGN.md".
---

# Design Brief Skill

You are running the Design Brief flow. Output is `DESIGN.md` at the project root, conforming to the [joesteinkamp/design.md](https://github.com/joesteinkamp/design.md) format: YAML front matter for tokens + markdown body in canonical section order (Overview → UX Foundation → Colors → Typography → Layout → Elevation & Depth → Shapes → Components → Do's and Don'ts).

## Setup

1. Locate the plugin root. The questionnaire bank is at `questionnaires/design.questions.md`. Template is at `templates/DESIGN.template.md`. Anti-pattern guardrails are at `guardrails/design-anti-patterns.md` and `guardrails/ux-anti-patterns.md`.
2. Read all of them before starting.
3. If `PRODUCT.md` exists, read it — design choices answer to product context. If it doesn't, recommend the user run `/starter:product-brief` first; offer to continue anyway if they decline.

## Pre-flight (existing DESIGN.md)

Check whether `DESIGN.md` exists at the project root. Use `AskUserQuestion` to choose:

- **reuse** — leave the existing file untouched; exit.
- **update sections** (merge) — pick specific sections to modify; the rest is preserved verbatim. Default for "I just want to change colors" / "update the typography" / "fix the user flows".
- **update tokens only** — modify the YAML front matter without touching the markdown body. Default for "change the accent color" / "swap the body font".
- **overwrite** — start from scratch.

If the existing file does not parse as the design.md format (no YAML front matter, or sections out of canonical order), say so and offer: keep-as-is + skip, or convert-to-spec (preserves content, reorders sections, lifts tokens into front matter).

## Phase A — UX foundation (always first, unless mode is "update tokens only")

### Pass A1 — Structured

Ask Q1–Q4 from the **UX section** of `questionnaires/design.questions.md` using `AskUserQuestion`. In merge mode, only ask for sections the user picked.

### Pass A2 — Open follow-ups

Ask Q5–Q9 (UX) as free-form prompts. One or two at a time. For user flows, prompt for at least one happy path **and** at least one edge case / empty state — apply `guardrails/ux-anti-patterns.md` if they skip them.

## Phase B — UI system

### Pass B1 — Structured

Ask Q10–Q14 (UI) using `AskUserQuestion`.

### Pass B2 — Open follow-ups

Ask Q15–Q19 (UI) as free-form prompts. For color tokens, accept hex from the user but auto-convert to OKLCH in the output (note the conversion). For typography, require a measure cap (default to 65–75ch).

## Validation pass

Apply both guardrails:
- `guardrails/ux-anti-patterns.md` — if user flows lack empty/error states, push back. If "are you sure?" modals are casually proposed, suggest undo instead.
- `guardrails/design-anti-patterns.md` — if the user describes purple gradients, neon-on-black, nested cards, or other entries on the ban list, push back once with the rationale.

Be direct. Don't soften.

## Defaults pass

Apply the defaults table from `questionnaires/design.questions.md`. Mark defaulted lines with ` [default — confirm]`. Always pull anti-pattern lists from `guardrails/design-anti-patterns.md` and `guardrails/ux-anti-patterns.md` into the **Do's and Don'ts** section inline.

## Format compliance (joesteinkamp/design.md spec)

When rendering `DESIGN.md`:

1. **YAML front matter** at the top, fenced by `---`. Required: `name`. Optional and supported: `version` (set to `alpha`), `description`, `colors`, `typography`, `rounded`, `spacing`, `components`. Quote string values that contain colors or units.
2. **Canonical `##` section order** (only include sections that have content; omit empty ones, but never reorder):
   1. Overview
   2. UX Foundation *(project-specific extension; placed here so visual sections stay in canonical order)*
   3. Colors
   4. Typography
   5. Layout
   6. Elevation & Depth
   7. Shapes
   8. Components
   9. Do's and Don'ts
3. **Token references** in the markdown body use `{path.to.token}` syntax (e.g., `{colors.accent}`, `{rounded.md}`) — never repeat literal hex/px values that already live in the front matter.
4. **Component variants** (hover, active, pressed) become separate keys under `components.*` (e.g., `components.button`, `components.button-hover`).

Tokens live in front matter; rationale lives in body. Don't duplicate.

## Merge mode write rules

- Preserve any sections the user did not choose to update — copy them across verbatim from the existing `DESIGN.md`.
- When updating tokens only, rewrite only the YAML front matter and leave the markdown body byte-identical.
- After merge, re-run the canonical-order check; if a hand-edit added a section out of order, surface this and offer to reorder.

## Preview & write

1. Render the populated `DESIGN.md` and show it to the user.
2. Ask for one round of edits.
3. Write `DESIGN.md` to the project root.

## Done

"Wrote DESIGN.md ({{N}} sections, {{T}} tokens in front matter, {{M}} defaults marked for confirmation). Next: `/starter:code-brief`."

## Important

- UX always comes before UI. Do not let the user skip Phase A unless they explicitly say "we already have UX defined elsewhere" — in which case ask where, and reference it in the output.
- Hex values from the user get converted to OKLCH in the front matter; note the conversion in the Colors body.
- If you are running inside `/starter:setup`, hand control back when done.
