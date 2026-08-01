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

#### Q9b. System source

> Are you authoring a visual system, or adopting one that already exists?

- `author` — define it in this brief (continues with Q10–Q19)
- `adopt` — an existing design system is the source of truth
- `adopt-and-extend` — an existing system, plus deliberate overrides

→ writes to `{{SYSTEM_SOURCE}}`. On `adopt` / `adopt-and-extend`, follow up
open-form for: the system's name and version, where it lives (package, docs
URL, token file path, design library), what this project overrides, and what
it deliberately doesn't use. The remaining UI slots are then filled as
references to the adopted system plus the stated overrides — never a
restatement of its values, which would be stale by the system's next release.
Skip Q10–Q14 and Q15–Q19 except where an override needs detail; always ask
Q14b (lock posture).

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

→ informs color tokens, and decides which theme blocks `DESIGN.json` carries.
The `color` block always holds the **default** theme's values (light values for
`light`/`both`/`system`, dark values for `dark`). `both` and `system` add a
`themes.dark` override block — Q16 collects both value sets. A single-theme
answer (`light` **or** `dark`) means no `themes` block at all: the file states
exactly what the design system commits to, symmetrically in both directions.

#### Q14. Motion stance

> How present is motion?

- `minimal` — only state-change cues
- `considered` — purposeful transitions, expo-out default
- `expressive` — motion is part of the brand

→ writes to `{{MOTION}}`, and seeds the `DESIGN.json` motion tokens
`{{MOTION_EASING}}`, `{{MOTION_FAST}}`, `{{MOTION_BASE}}`, `{{MOTION_SLOW}}`

#### Q14b. Lock posture

> When a coding agent builds UI from this brief, how much room does it have?

- `tight` — everything locked; invention only through explicit proposals
- `standard` — tokens, scales, motion vocabulary, and accessibility locked;
  composition, empty states, and new patterns open
- `loose` — only tokens and accessibility locked; everything else open

→ writes to `{{LOCK_LEVELS}}` as a locked/open table plus the gap rule (the
design-brief skill defines both). The anti-pattern bans are **always locked**,
at every posture. If Q9b chose `adopt` / `adopt-and-extend`, the adopted
system is locked wholesale and the overrides section is the open surface.

### Pass 2 — Open follow-ups (UI)

#### Q15. Visual register

> One sentence describing the overall mood, plus 2-3 reference points
> (real publications, products, environments).

→ `{{VISUAL_REGISTER}}`

#### Q16. Color tokens

> Provide OKLCH values (or describe and the skill will propose) for the seven
> core tokens: background, foreground, muted, accent, **accentForeground**
> (text/icons on an accent fill — must clear 4.5:1 on accent), **border**
> (decorative hairlines/dividers only), and **borderStrong** (any border that
> is a control's sole boundary — must clear 3:1 on background, WCAG 1.4.11).
> If Q13 chose `both` or `system`, provide values for both themes and label the
> columns Light / Dark, marking which is default. Any system colors (success,
> warning, danger) go in the `DESIGN.md` prose table only — `DESIGN.json`
> carries the seven core tokens per theme.

→ `{{COLOR_TOKENS}}` (the prose table in `DESIGN.md`) and the `DESIGN.json`
token slots `{{COLOR_BACKGROUND}}`, `{{COLOR_FOREGROUND}}`, `{{COLOR_MUTED}}`,
`{{COLOR_ACCENT}}`, `{{COLOR_ACCENT_FOREGROUND}}`, `{{COLOR_BORDER}}`,
`{{COLOR_BORDER_STRONG}}` (the **default** theme, per Q13) — plus, when Q13
chose `both` or `system`, the `themes.dark` slots `{{COLOR_BACKGROUND_DARK}}`,
`{{COLOR_FOREGROUND_DARK}}`, `{{COLOR_MUTED_DARK}}`, `{{COLOR_ACCENT_DARK}}`,
`{{COLOR_ACCENT_FOREGROUND_DARK}}`, `{{COLOR_BORDER_DARK}}`,
`{{COLOR_BORDER_STRONG_DARK}}` (delete the whole `themes` block for a
single-theme answer, `light` or `dark` alike)

#### Q17. Typography specifics

> Display family, body family, mono family. Base size. Scale ratio (≥1.25).
> Line height for body (≥1.4). Measure cap (default 65-75ch).

→ `{{TYPOGRAPHY}}` (the prose section in `DESIGN.md`) and the `DESIGN.json`
token slots `{{FONT_DISPLAY}}`, `{{FONT_BODY}}`, `{{FONT_MONO}}`,
`{{TYPE_SCALE_RATIO}}`, `{{TYPE_BASE_SIZE}}`, `{{TYPE_LINE_HEIGHT}}`,
`{{TYPE_MEASURE}}` — line height and measure are tokens, not just prose, so
The `validate` flow and the guardrails can check them mechanically

#### Q18. Spacing & layout

> Spacing unit and scale. Grid system (or none). When are cards allowed,
> when are they not?

→ `{{SPACING_LAYOUT}}` (the prose section in `DESIGN.md`) and the `DESIGN.json`
token slots `{{SPACING_UNIT}}`, `{{SPACING_SCALE}}`

#### Q18b. Breakpoints & responsive strategy

> Container-query-first, or named viewport breakpoints? If breakpoints: list
> each one and what changes there. Without this, every coding agent invents
> its own — the one-off-values problem the token file exists to prevent.

→ `{{BREAKPOINTS}}` (in `DESIGN.md`)

#### Q19. Component primitives (8-12)

> List the primitives that define the system: button, input, card, surface,
> link, etc. Note any unusual choices (sharp corners, no shadow at rest, etc.).

→ `{{COMPONENTS}}`

## Defaults applied if unanswered

| Slot | Default | Mark |
|---|---|---|
| `{{INTERACTION_PRINCIPLES}}` | Recognition over recall, undo over confirm, progressive disclosure, keyboard-first | `[default — confirm]` |
| `{{ACCESSIBILITY_UX}}` | Inherit the WCAG level `PRODUCT.md` committed to (its own default is 2.2 AA — never restate a different level here), keyboard reachability, visible focus, prefers-reduced-motion, 8th-grade reading level | `[default — confirm]` |
| `{{BREAKPOINTS}}` | Container-query-first; no named viewport breakpoints unless a layout genuinely changes shape | `[default — confirm]` |
| `{{SYSTEM_SOURCE}}` | Authored in this brief — no external design system | `[default — confirm]` |
| `{{COLOR_STRATEGY}}` | Restrained — neutrals + one accent | `[default — confirm]` |
| `{{LOCK_LEVELS}}` | `standard` posture, rendered as the locked/open table + gap rule | `[default — confirm]` |
| `{{MOTION}}` | expo-out easing, durations 120/200/320ms, prefers-reduced-motion respected, never animate layout | `[default — confirm]` |
| `{{DESIGN_ANTI_PATTERNS}}` | Pull from `guardrails/design-anti-patterns.md` verbatim | always included |

## Pre-flight checks before writing

- If `DESIGN.md` exists, ask: **reuse / merge / overwrite**.
- Validate user flows have at least one edge case and at least one empty/error state listed.
- Validate color tokens use OKLCH (not hex/HSL) — auto-convert with a note if the user provides hex.
- **Compute contrast, don't eyeball it** — for every theme: foreground/background,
  muted/background, and accent/background (as text) must clear 4.5:1;
  accentForeground/accent must clear 4.5:1; borderStrong/background must clear
  3:1 (WCAG 1.4.11) — all against the level `PRODUCT.md` committed to. Fix or
  flag any failing pair before writing, and record the measured ratios in the
  `DESIGN.md` color table.
- Validate typography includes a measure cap.
- Always pull anti-patterns from `guardrails/design-anti-patterns.md` and `guardrails/ux-anti-patterns.md` so the brief carries the bans inline.

## Extraction hints (brownfield)

When the `extract` flow runs against existing code: theme/token files and CSS seed
`{{COLOR_STRATEGY}}`, `{{COLOR_TOKENS}}`, and the `DESIGN.json` color tokens — including the
`_DARK` counterparts under `themes.dark` when the code ships a dark theme (flagging raw hex
for OKLCH conversion); font imports and scale variables seed `{{TYPOGRAPHY}}` and the type tokens;
spacing variables seed `{{SPACING_LAYOUT}}` and the spacing tokens; media/container queries seed
`{{BREAKPOINTS}}`; transition tokens seed
`{{MOTION}}`; the components directory seeds `{{COMPONENTS}}` — and, when present, generates
`component-registry.json` at the project root (shadcn registry format), which the
`{{COMPONENTS}}` draft references as the full inventory; routes/nav seed
`{{INFORMATION_ARCHITECTURE}}`. A design-system dependency in the manifest (a
component or token package) seeds `{{SYSTEM_SOURCE}}` as `adopt` — with local
theme files read as its overrides — otherwise `{{SYSTEM_SOURCE}}` is seeded as
authored. `{{LOCK_LEVELS}}` is seeded at the `standard` posture as
`[default — confirm]` — lock posture is intent, and code can't show intent. UX intent (`{{USER_FLOWS}}`, `{{USER_KNOWLEDGE}}`,
`{{VISUAL_REGISTER}}`) is left as `[TODO — confirm]` — code shows *what*, not *why*.
