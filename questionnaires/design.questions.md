# Design Brief Questionnaire

The `design-brief` skill walks the user through this question set. **UX questions come first**, then UI. Visual decisions answer to UX context.

## Phase A — UX foundation

### Pass 1 — Structured

#### Q1. Research depth

> How much do you know about the users today?

- `deep` — interviews, research, analytics, support data
- `medium` — some research, some assumptions
- `light` — mostly hypotheses, ready to validate
- `none` — pre-research; using personas as a starting hypothesis

→ informs how confident the `{{USER_KNOWLEDGE}}` section can be

#### Q2. Information architecture posture

> How is the product navigated?

- `flat` — single surface, no real navigation
- `sectional` — 2-5 top-level areas
- `hierarchical` — sections with sub-sections
- `search-first` — a corpus the user queries

→ writes to `{{INFORMATION_ARCHITECTURE}}`

#### Q3. Primary interaction modality

> What does the user spend most of their time doing?

- `reading` — content consumption, long-form
- `creating` — generating something (writing, designing, coding)
- `managing` — dashboards, lists, decisions
- `transacting` — short flows ending in a commit

→ informs interaction principles and motion stance

#### Q4. Accessibility specifics

> Beyond the baseline in PRODUCT.md, any UX-specific commitments?

- `keyboard-first` — keyboard can reach every flow
- `screen-reader-first` — tested with VoiceOver/NVDA, not just contrast
- `motion-sensitive` — strict prefers-reduced-motion adherence
- `none-additional` — baseline is enough

→ extends `{{ACCESSIBILITY_UX}}`

### Pass 2 — Open follow-ups (UX)

#### Q5. User knowledge synthesis

> Summarize what you know about the user beyond persona basics: their
> mental model, their vocabulary, their known pain points, the moment
> they decide to use this.

→ `{{USER_KNOWLEDGE}}`

#### Q6. Information architecture detail

> List top-level navigation entries, the primary entities (and their
> relationships), and what URL structure you intend.

→ `{{INFORMATION_ARCHITECTURE}}`

#### Q7. Primary user flows (2-4)

> For each primary flow: trigger → steps → outcome. Then: critical edge
> cases, and what empty / loading / error / offline states look like.

→ `{{USER_FLOWS}}`

#### Q8. Interaction principles

> Which heuristics matter most for this product? Defaults: recognition over
> recall, undo over confirm, progressive disclosure, keyboard-first. Add,
> remove, or replace.

→ `{{INTERACTION_PRINCIPLES}}`

#### Q9. UX success metrics

> How do you know the experience is working? Task success on top flows,
> time-to-first-value, activation, retention, qualitative signals. What
> counts as a regression?

→ `{{UX_SUCCESS_METRICS}}`

## Phase B — UI system

### Pass 1 — Structured

#### Q10. Color strategy

> How saturated is the visual system?

- `Restrained` — neutrals + one accent (≤10% of surface)
- `Committed` — neutrals + a confident accent system
- `Full Palette` — multiple deliberate hues
- `Drenched` — color is the message

→ writes to `{{COLOR_STRATEGY}}`

#### Q11. Typography pairing

> What kind of pairing fits the register?

- `editorial` — serif display + sans body (long-form feel)
- `utilitarian` — single sans family, range of weights
- `geometric` — geometric sans display + neutral body
- `expressive` — display face with personality (variable, custom)
- `custom` — describe in open follow-up

→ informs `{{TYPOGRAPHY}}`

#### Q12. Density

> How dense should screens feel?

- `airy` — lots of whitespace, editorial breathing room
- `balanced` — comfortable for long sessions
- `dense` — power-user, information-rich

→ informs `{{SPACING_LAYOUT}}`

#### Q13. Theme

> What's the default theme?

- `light` — paper-feel light backgrounds
- `dark` — true dark, justified by use scenario
- `both` — light default, dark companion
- `system` — follow OS preference

→ informs color tokens, and decides whether `DESIGN.json` carries a `dark` block
(any answer except `light` means Q16 must collect dark values too)

#### Q14. Motion stance

> How present is motion?

- `minimal` — only state-change cues
- `considered` — purposeful transitions, expo-out default
- `expressive` — motion is part of the brand

→ writes to `{{MOTION}}`, and seeds the `DESIGN.json` motion tokens
`{{MOTION_EASING}}`, `{{MOTION_FAST}}`, `{{MOTION_BASE}}`, `{{MOTION_SLOW}}`

### Pass 2 — Open follow-ups (UI)

#### Q15. Visual register

> One sentence describing the overall mood, plus 2-3 reference points
> (real publications, products, environments).

→ `{{VISUAL_REGISTER}}`

#### Q16. Color tokens

> Provide OKLCH values (or describe and the skill will propose) for:
> background, foreground, muted, accent, border. If Q13 chose `dark`, `both`,
> or `system`, provide the dark-theme value for each as well. Any system
> colors (success, warning, danger) go in the `DESIGN.md` prose table only —
> `DESIGN.json` carries the five core tokens per theme.

→ `{{COLOR_TOKENS}}` (the prose table in `DESIGN.md`) and the `DESIGN.json`
token slots `{{COLOR_BACKGROUND}}`, `{{COLOR_FOREGROUND}}`, `{{COLOR_MUTED}}`,
`{{COLOR_ACCENT}}`, `{{COLOR_BORDER}}` — plus, when a dark theme exists,
`{{COLOR_BACKGROUND_DARK}}`, `{{COLOR_FOREGROUND_DARK}}`, `{{COLOR_MUTED_DARK}}`,
`{{COLOR_ACCENT_DARK}}`, `{{COLOR_BORDER_DARK}}` (drop the `dark` block from
`DESIGN.json` when Q13 chose `light`)

#### Q17. Typography specifics

> Display family, body family, mono family. Base size. Scale ratio (≥1.25).
> Line height for body (≥1.4). Measure cap (default 65-75ch).

→ `{{TYPOGRAPHY}}` (the prose section in `DESIGN.md`) and the `DESIGN.json`
token slots `{{FONT_DISPLAY}}`, `{{FONT_BODY}}`, `{{FONT_MONO}}`,
`{{TYPE_SCALE_RATIO}}`, `{{TYPE_BASE_SIZE}}`

#### Q18. Spacing & layout

> Spacing unit and scale. Grid system (or none). When are cards allowed,
> when are they not?

→ `{{SPACING_LAYOUT}}` (the prose section in `DESIGN.md`) and the `DESIGN.json`
token slots `{{SPACING_UNIT}}`, `{{SPACING_SCALE}}`

#### Q19. Component primitives (8-12)

> List the primitives that define the system: button, input, card, surface,
> link, etc. Note any unusual choices (sharp corners, no shadow at rest, etc.).

→ `{{COMPONENTS}}`

## Defaults applied if unanswered

| Slot | Default | Mark |
|---|---|---|
| `{{INTERACTION_PRINCIPLES}}` | Recognition over recall, undo over confirm, progressive disclosure, keyboard-first | `[default — confirm]` |
| `{{ACCESSIBILITY_UX}}` | WCAG 2.1 AA, keyboard reachability, visible focus, prefers-reduced-motion, 8th-grade reading level | `[default — confirm]` |
| `{{COLOR_STRATEGY}}` | Restrained — neutrals + one accent | `[default — confirm]` |
| `{{MOTION}}` | expo-out easing, durations 120/200/320ms, prefers-reduced-motion respected, never animate layout | `[default — confirm]` |
| `{{DESIGN_ANTI_PATTERNS}}` | Pull from `guardrails/design-anti-patterns.md` verbatim | always included |

## Pre-flight checks before writing

- If `DESIGN.md` exists, ask: **reuse / merge / overwrite**.
- Validate user flows have at least one edge case and at least one empty/error state listed.
- Validate color tokens use OKLCH (not hex/HSL) — auto-convert with a note if the user provides hex.
- Validate typography includes a measure cap.
- Always pull anti-patterns from `guardrails/design-anti-patterns.md` and `guardrails/ux-anti-patterns.md` so the brief carries the bans inline.

## Extraction hints (brownfield)

When `/starter:extract` runs against existing code: theme/token files and CSS seed
`{{COLOR_STRATEGY}}`, `{{COLOR_TOKENS}}`, and the `DESIGN.json` color tokens (flagging raw hex
for OKLCH conversion); font imports and scale variables seed `{{TYPOGRAPHY}}` and the type tokens;
spacing variables seed `{{SPACING_LAYOUT}}` and the spacing tokens; transition tokens seed
`{{MOTION}}`; the components directory seeds `{{COMPONENTS}}`; routes/nav seed
`{{INFORMATION_ARCHITECTURE}}`. UX intent (`{{USER_FLOWS}}`, `{{USER_KNOWLEDGE}}`,
`{{VISUAL_REGISTER}}`) is left as `[TODO — confirm]` — code shows *what*, not *why*.
