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
| `WRITING.md` | The **generated** writing rules (a design-brief companion) — voice, terminology, microcopy, and long-form, with the writing ban list embedded. Always written. |
| `AGENTS.md` | The **generated** router — points agents at the brief that owns each kind of work. Always written; Codex, Cursor, and Antigravity read it natively. |
| `CLAUDE.md` | The **generated** thin pointer — imports `@AGENTS.md` and adds project-specific notes. Always written; connects Claude Code. |

The briefs are what *you* fill in (via the questionnaires); `WRITING.md` is derived from them,
and the wire-up writes `AGENTS.md` + `CLAUDE.md`. Read `AGENTS.md` to see the routing an agent
follows before it writes any code or UI — the rules themselves stay in the briefs, each with its
own ban list embedded.
