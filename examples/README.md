# Examples

A complete, no-personal-data render of every file `project-starter-pack` produces, for a
fictional product so you can see the depth and voice each brief expects before you run the
flow on your own project.

## `saga-reader/`

**Saga** — a local-first reading app for long-form nonfiction. Deliberately *not* an AI
product, so the example shows the opinionated, cliché-free output the guardrails are meant
to produce (no purple gradients, no hero-metric landing, no gamification).

| File | What it is |
|---|---|
| `PRODUCT.md` | The product brief — register, users, jobs, personality, anti-references, principles. |
| `DESIGN.md` | The design brief — UX foundation (users, IA, flows) **and** UI system (OKLCH color, editorial type, spacing, motion, components). |
| `DESIGN.json` | The machine-readable token companion (real OKLCH values, matches the Impeccable filename convention). |
| `CODE.md` | The technical brief — stack, architecture, conventions, testing, performance budgets, security. |
| `AGENT.md` | The **generated** universal agents.md spec, synthesized from the three briefs with all five anti-pattern lists embedded inline. Always written. |
| `WRITING.md` | The **generated** writing rules — voice, terminology, microcopy, and long-form, with the writing ban list embedded. Always written. |
| `CLAUDE.md` | The **generated** thin Claude Code file — imports `@AGENT.md` and adds project-specific notes. |
| `GEMINI.md` | The **generated** Gemini CLI file (thin import of `@AGENT.md`). Written only if Gemini is a selected harness. |
| `.cursor/rules/project.mdc` | The **generated** Cursor rules file (scoped, `alwaysApply`). Written only if Cursor's scoped option is selected. |

The first four files are what *you* fill in (via the questionnaires); the rest are what the
orchestrator generates. `AGENT.md` and `WRITING.md` are always written; the harness-specific files
(`CLAUDE.md`, `GEMINI.md`, and a Cursor file) are emitted only for the harnesses you select —
this example shows all of them so you can see each shape. Read `AGENT.md` to see how the
briefs collapse into a single source of truth an agent reads before it writes any code or UI.
