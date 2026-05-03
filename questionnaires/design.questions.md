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

→ informs color tokens

#### Q14. Motion stance

> How present is motion?

- `minimal` — only state-change cues
- `considered` — purposeful transitions, expo-out default
- `expressive` — motion is part of the brand

→ writes to `{{MOTION}}`

### Pass 2 — Open follow-ups (UI)

#### Q15. Visual register

> One sentence describing the overall mood, plus 2-3 reference points
> (real publications, products, environments).

→ `{{VISUAL_REGISTER}}`

#### Q16. Color tokens

> Provide OKLCH values (or describe and the skill will propose) for:
> background, foreground, muted, accent, border, plus any system colors
> (success, warning, danger).

→ `{{COLOR_TOKENS}}` (rationale in body) and the `colors:` block in DESIGN.md's YAML front matter

#### Q17. Typography specifics

> Display family, body family, mono family. Base size. Scale ratio (≥1.25).
> Line height for body (≥1.4). Measure cap (default 65-75ch).

→ `{{TYPOGRAPHY}}`

#### Q18. Spacing & layout

> Spacing unit and scale. Grid system (or none). When are cards allowed,
> when are they not?

→ `{{SPACING_LAYOUT}}`

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
