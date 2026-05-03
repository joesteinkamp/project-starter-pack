# Example: good-saas (Bramble)

A complete, internally consistent set of briefs for a fictional B2B engineering-retro tool called Bramble. Use this as a reference when running `/starter:setup` — it shows what filled-out briefs look like and how the orchestrator turns them into `AGENTS.md` and `CLAUDE.md`.

## Files

- `PRODUCT.md` — register, users, jobs-to-be-done, brand personality, anti-references, principles
- `DESIGN.md` — UX foundation (knowledge, IA, flows, principles, a11y, metrics) + UI system (color, type, spacing, motion, components)
- `DESIGN.json` — token companion, machine-readable
- `CODE.md` — stack, architecture, conventions, testing, deployment, performance, security
- `AGENTS.md` — synthesized universal agents.md
- `CLAUDE.md` — thin import of `AGENTS.md` + Claude-Code-specific notes

## What to notice

- **Register choice (PRODUCT.md)**: hybrid leaning product. The brief states explicitly which side wins when they pull — that single sentence prevents a category of arguments downstream.
- **Anti-references are real products** (EasyRetro, Confluence, Miro, Notion, Slack stand-up bots), not abstractions like "boring" or "corporate". Concrete anti-references constrain decisions; abstract ones don't.
- **OKLCH accent rationale (DESIGN.md → Color)**: a single deep-evergreen accent at ≤8% of surface, picked specifically *not* to be a category reflex (no purple, no neon).
- **Cards are scoped (DESIGN.md → Spacing & layout)**: cards are allowed only on the writing and meeting surfaces. Lists use hairline borders. This is a deliberate choice tied to the "quiet defaults" principle in PRODUCT.md.
- **Performance budget is a hard limit (CODE.md)**: LCP ≤1.5s on the writing surface, not "we'll try". The motion stance in DESIGN.md (no animation library) makes this budget defensible.
- **CLAUDE.md notes all cite specific files or commands** — `app/lib/retro/service.ts`, `pnpm db:migrate:prod`, the writing-surface route. None of them are generic Claude advice; that lives in `AGENTS.md`.

## How this was assembled

The three source briefs (`PRODUCT.md`, `DESIGN.md`, `CODE.md`) were authored first by walking the questionnaires under `/questionnaires/`. The orchestrator then synthesized `AGENTS.md` and `CLAUDE.md` from the three. Running `/starter:validate` against this set returns zero cross-brief contradictions and zero anti-pattern hits — it's a regression fixture for the validator skill.
