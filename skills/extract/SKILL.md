---
name: extract
description: Reverse-engineers draft PRODUCT.md, DESIGN.md, DESIGN.json, and CODE.md briefs from an existing codebase, so the starter pack works on brownfield projects, not just greenfield ones. Use when the user wants to bootstrap briefs from code that already exists, infer the stack or design system, or onboard an existing repo into project-starter-pack. Triggers on "extract the briefs", "brownfield", "reverse engineer the design system", "infer the stack from the code", "generate briefs from existing code", "/starter:extract".
---

# Extract Skill

You fill the same brief slots the questionnaires fill — but from **evidence in the codebase**
instead of from questions. The output is *drafts with confidence markers*, not finished briefs;
you seed the flow, you don't replace the designer's judgment.

This skill is **read-only** during evidence gathering. Only the final write step creates files.

## Setup

1. Locate the plugin root. Templates are in `templates/`; the slot list each draft must fill is
   defined by `templates/PRODUCT.template.md`, `templates/DESIGN.template.md`,
   `templates/DESIGN.tokens.template.json`, and `templates/CODE.template.md`.
2. Determine the scan target (a path argument, else the repo root).

## Evidence gathering (read-only)

- **CODE evidence** — `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` (framework, runtime, deps, scripts, package manager), `tsconfig.json` (strictness), lockfiles, CI config (`.github/workflows`), Dockerfile / host config.
- **DESIGN evidence** — global CSS, Tailwind/UnoCSS config, any `tokens.*` / theme files (colors — **flag raw hex vs OKLCH**), `@font-face` / font imports, spacing/scale variables, and the components directory (the primitive inventory).
- **PRODUCT evidence** — `README`, landing/marketing copy, the package `description`, and any docs that state who it's for.

## Mapping evidence to slots

Fill each slot from evidence; anything not provable from the code stays
`[TODO — confirm via /starter:<brief>]`. **Never invent** product voice, personas, or design
intent — code can prove a stack, it cannot prove a brand.

| Evidence | Slots it seeds |
|---|---|
| `package.json` deps / framework | `{{STACK_FRONTEND}}`, `{{STACK_BACKEND}}`, `{{STACK_OTHER}}` |
| DB driver / ORM / host config | `{{STACK_DATABASE}}`, `{{STACK_HOSTING}}`, `{{STACK_AUTH}}` |
| package manager, tsconfig, linter config | `{{LANGUAGES_TOOLING}}` |
| repo shape, folder boundaries | `{{ARCHITECTURE}}`, `{{CODE_CONVENTIONS}}` |
| test runner + test dirs | `{{TESTING}}` |
| CI workflow, deploy config | `{{DEPLOYMENT}}` |
| bundle/perf config, image pipeline | `{{PERFORMANCE}}` |
| auth, CSP/headers, secrets handling | `{{SECURITY}}` |
| color tokens / theme files | `{{COLOR_STRATEGY}}`, `{{COLOR_TOKENS}}`, and `DESIGN.json` (`{{COLOR_BACKGROUND}}`, `{{COLOR_FOREGROUND}}`, `{{COLOR_MUTED}}`, `{{COLOR_ACCENT}}`, `{{COLOR_BORDER}}` — plus their `_DARK` counterparts when the code ships a dark theme) |
| font imports / scale variables | `{{TYPOGRAPHY}}`, `{{FONT_DISPLAY}}`, `{{FONT_BODY}}`, `{{FONT_MONO}}`, `{{TYPE_SCALE_RATIO}}`, `{{TYPE_BASE_SIZE}}` |
| spacing variables | `{{SPACING_LAYOUT}}`, `{{SPACING_UNIT}}`, `{{SPACING_SCALE}}` |
| transition/animation tokens | `{{MOTION}}`, `{{MOTION_EASING}}`, `{{MOTION_FAST}}`, `{{MOTION_BASE}}`, `{{MOTION_SLOW}}` |
| components directory | `{{COMPONENTS}}` |
| routes / nav structure | `{{INFORMATION_ARCHITECTURE}}` |
| README / landing copy | `{{ONE_LINER}}`, `{{PRODUCT_PURPOSE}}`, `{{REGISTER}}` (low confidence — confirm) |

Slots that code can rarely prove — `{{PRIMARY_USERS}}`, `{{SECONDARY_USERS}}`,
`{{JOBS_TO_BE_DONE}}`, `{{PERSONALITY_THREE_WORDS}}`, `{{PERSONALITY_DETAIL}}`,
`{{ANTI_REFERENCES}}`, `{{DESIGN_PRINCIPLES}}`, `{{SUCCESS_METRICS}}`, `{{USER_KNOWLEDGE}}`,
`{{USER_FLOWS}}`, `{{UX_SUCCESS_METRICS}}`, `{{VISUAL_REGISTER}}`, `{{INTERACTION_PRINCIPLES}}`,
`{{ACCESSIBILITY}}`, `{{ACCESSIBILITY_UX}}` — default to a `[TODO — confirm]` unless the docs
state them outright. The anti-pattern slots (`{{DESIGN_ANTI_PATTERNS}}`, `{{CODE_ANTI_PATTERNS}}`)
are still pulled from the guardrails verbatim.

## Confirm pass

Use `AskUserQuestion` for the few high-leverage values that change everything downstream and that
the code can only hint at: **register** (brand / product / hybrid), **color strategy**
(Restrained / Committed / Full Palette / Drenched — pre-filled from the detected token count),
and **primary framework** (pre-filled from `package.json`, ask to confirm). This converges extract
with the questionnaire flow rather than bypassing it.

## Write

Honor the same pre-flight as the brief skills: if `PRODUCT.md` / `DESIGN.md` / `CODE.md` already
exist, ask **reuse / merge / overwrite**. Write the drafts (plus `DESIGN.json` if real tokens were
found) with every inferred-but-unconfirmed value marked, and every gap left as an explicit TODO.

## Done

```
✓ Extracted drafts: PRODUCT.md, DESIGN.md, CODE.md{{, DESIGN.json}}
  {{X}} slots filled from evidence · {{Y}} left as [TODO — confirm]

Next steps:
- Review the drafts — extract seeds, it doesn't decide. Fix the TODOs.
- Run /starter:validate to check the extracted briefs against the code.
- Run /starter:orchestrate to generate AGENT.md and the harness files.
```

## Important

- Read-only until the write step. Never modify application code.
- Never invent product or brand context. A draft slot is either evidence-backed or a marked TODO.
- Confidence is part of the output: say which slots are inferred and which are confirmed.
