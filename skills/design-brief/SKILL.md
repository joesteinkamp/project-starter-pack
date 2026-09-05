---
name: design-brief
description: Walks the user through a UX-and-UI design brief and writes DESIGN.md (and optional DESIGN.json tokens companion) at the project root. UX foundation comes first (user knowledge, IA, flows, success metrics), then the UI system (color, type, spacing, motion, components). Use when the user asks for a design brief, design system, UX foundation, DESIGN.md, or to define visual language. Triggers on "design brief", "DESIGN.md", "design system", "UX foundation", "user flows", "information architecture", "color strategy", "design tokens".
---

# Design Brief Skill

You are running the Design Brief flow. Your job is to walk the user through UX questions first, then UI questions, and produce `DESIGN.md` (and optionally `DESIGN.json` — the tokens companion) at the project root.

## Conventions

Read `../../conventions/question-mechanics.md` first. It defines how this flow asks structured and open questions in whatever tool you are running in, how it writes files, and how it resolves the resource paths below.

## Setup

1. The questionnaire bank is at `../../questionnaires/design.questions.md`. Templates are at `../../templates/DESIGN.template.md`, `../../templates/DESIGN.tokens.template.json`, and `../../templates/WRITING.template.md` (the writing companion this flow also produces). The anti-pattern guardrails are at `../../guardrails/design-anti-patterns.md`, `../../guardrails/ux-anti-patterns.md`, and `../../guardrails/writing-anti-patterns.md`.
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

Ask Q9b (system source) first, as a structured question.

- **`author`** → ask Q10–Q14b as structured questions, then continue to Pass B2.
- **`adopt` / `adopt-and-extend`** → collect Q9b's open follow-up (system name and version, where
  it lives, overrides, deliberately unused parts), then ask only Q14b (lock posture). Fill the
  remaining UI slots as references to the adopted system plus the stated overrides — never a
  restatement of its values. Skip Pass B2 except where an override needs detail.

### Pass B2 — Open follow-ups

Ask Q15–Q19 (UI) as free-form prompts. For color tokens, accept hex from the user but auto-convert to OKLCH in the output and note the conversion. For typography, require a measure cap (default to 65–75ch if the user shrugs).

## Validation pass

Apply both guardrails:
- `../../guardrails/ux-anti-patterns.md` — if user flows lack empty/error states, push back and ask. If "are you sure?" modals are casually proposed, suggest undo instead.
- `../../guardrails/design-anti-patterns.md` — if the user describes purple gradients, neon-on-black, nested cards, or other entries on the ban list, push back once with the rationale.

Be direct. Don't soften.

## Defaults pass

Apply the defaults table from `../../questionnaires/design.questions.md`. Mark defaulted lines with ` [default — confirm]`. Always pull the anti-pattern lists from `../../guardrails/design-anti-patterns.md` and `../../guardrails/ux-anti-patterns.md` into the relevant sections of the output — embedded inline, not just linked. **Keep each ban's ID** (`DES-18`, `UX-07`) in the rendered line: it is what lets a later review cite the ban by name. Render the prose only — the `.detect.md` sidecars are machine state and never go into a brief.

## Lock levels rendering

Render `{{LOCK_LEVELS}}` from Q14b's posture as a two-column Area / Level table (color tokens &
strategy, type scale & families, spacing scale & breakpoints, motion vocabulary, accessibility
commitments, anti-pattern bans, composition within a screen, empty/error/loading state design,
patterns not in Component primitives), followed by the gap rule:

> Open means invention is welcome — built from locked primitives, held to the interaction
> principles. When no component primitive fits, don't force one and don't invent silently:
> design from locked tokens and flag the result in the handoff as a **proposed pattern** — the
> gap it fills and what it's built from. A proposed pattern used in two real places gets
> promoted into Component primitives.

The anti-pattern bans row reads `always locked` at every posture. On the adopt path, the table
locks the adopted system wholesale and marks the overrides section as the open surface.

## DESIGN.json (optional tokens companion)

On the `adopt` path, skip `DESIGN.json` — the adopted system's own token source is the
machine-readable truth, and a copy of it would drift. On `adopt-and-extend`, offer it only if
the overrides amount to a full core-token set; otherwise the overrides live in `DESIGN.md` alone.

If the user provided concrete color/typography/spacing values, also populate `../../templates/DESIGN.tokens.template.json` and offer to write it to `DESIGN.json` at the project root. The filename matches the convention used by Impeccable so the two tools can share the file. If the user declined to specify tokens, skip the JSON file.

Theme blocks are symmetric: the top-level `color` block always holds the **default** theme's values — light values when Q13 chose `light`/`both`/`system`, dark values when it chose `dark`. When Q13 chose `both` or `system`, also fill the `themes.dark` override block (the dark column of the DESIGN.md color table). For a single-theme answer — `light` **or** `dark` — delete the whole `themes` block rather than leaving placeholders or fabricating values for a theme that doesn't exist: DESIGN.json must state exactly what the design system commits to.

Rendering rules: numeric slots (`{{TYPE_SCALE_RATIO}}`, `{{TYPE_LINE_HEIGHT}}`) are unquoted in the template — emit bare numbers (`1.25`, not `"1.25"`). `{{SPACING_SCALE}}` renders inside array brackets — emit the bare comma-separated numbers. Before writing, verify the result parses as JSON, and compute the contrast pairs from the questionnaire's pre-flight checklist — a token file whose pairs fail the committed WCAG level does not ship.

## WRITING.md (the writing companion — always written)

This flow also produces `WRITING.md`: the rules for how words get written in the repo, from a
button label to long-form prose. Both of its sources exist by now — `PRODUCT.md` decides
personality and register; the design answers you just collected supply the components and flows.
`WRITING.md` **defers upward** to `PRODUCT.md`: restate personality and register as writing
directives, never duplicate the prose.

Populate `../../templates/WRITING.template.md`:

- `{{WRITING_VOICE}}` — from `PRODUCT.md`'s register and brand personality, as directives about how sentences behave (person, tense, where wit is allowed, what the voice never does).
- `{{WRITING_TERMINOLOGY}}` — the product's nouns and their exact casing (from `PRODUCT.md`'s one-liner and this brief's components and flows), plus words the product never uses.
- `{{WRITING_MICROCOPY}}` — rules for labels, buttons, empty/error/loading states, confirmations — grounded in this brief's component primitives and user flows. Include the casing convention and the button verb rule.
- `{{WRITING_LONGFORM}}` — structure and evidence rules for docs, onboarding, and marketing copy, consistent with the register.
- `{{WRITING_ANTI_PATTERNS}}` — embed `../../guardrails/writing-anti-patterns.md` headlines (1 line per pattern, each keeping its `WRT-nn` ID) — embedded inline, not just linked.

If `PRODUCT.md` is missing, fill the voice section from the register the user gave this flow and
mark it `[TODO — confirm after the product-brief flow]`.

## Preview & write

1. Render populated `DESIGN.md` and show it to the user.
2. If tokens were collected, also render `DESIGN.json`.
3. Render `WRITING.md`.
4. Ask for one round of edits, then write the files to the project root.

## Done

"Wrote DESIGN.md ({{N}} sections, {{M}} defaults marked for confirmation){{tokens_clause}} and WRITING.md (voice, terminology, microcopy, long-form + writing bans). Next: the `code-brief` flow."

Then, if `AGENTS.md` is missing at the project root, follow "Wiring up AGENTS.md" in
`../../conventions/question-mechanics.md` so the routing file exists even outside the `setup` flow.

## Important

- UX always comes before UI. Do not let the user skip Phase A unless they explicitly say "we already have UX defined elsewhere" — in which case ask where, and reference it in the output.
- If you are running inside the `setup` flow, hand control back when done.
