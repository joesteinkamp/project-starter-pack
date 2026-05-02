# project-starter-pack

A Claude Code plugin for product designers. Walks you through three opinionated briefs — Product, Design (UX + UI), Technical — and synthesizes them into `AGENTS.md` and `CLAUDE.md` so any AI coding agent in your repo designs and codes with the same rigor a senior team would apply.

Output formats:
- `DESIGN.md` follows [joesteinkamp/design.md](https://github.com/joesteinkamp/design.md) — YAML token front matter + canonical-order markdown body (Overview → Colors → Typography → Layout → Elevation & Depth → Shapes → Components → Do's and Don'ts).
- `AGENTS.md` follows [joesteinkamp/agents-md](https://github.com/joesteinkamp/agents-md) — precedence hierarchy, always-on rules (Git / Security / Testing), and a `.agents/` extension index for project-specific rules and skills.

Both formats support **modifying existing files**: every flow detects an existing `DESIGN.md` / `AGENTS.md` and offers reuse, section-level merge, token-only update (DESIGN.md), or overwrite. Hand-edits inside the `<!-- custom:start -->` block in `AGENTS.md` are preserved across regenerations.

Inspired by [pbakaus/impeccable](https://github.com/pbakaus/impeccable). Patterns reused: the brand-vs-product register, OKLCH color strategies, the anti-pattern registry shape, and the AI slop self-check. No prose vendored.

## What you get

After running `/starter:setup` (or each command individually), your project root will contain:

| File | Owner | What it is |
|---|---|---|
| `PRODUCT.md` | Product Brief | Who, what, why, brand personality, anti-references, principles |
| `DESIGN.md` | Design Brief | YAML token front matter + canonical-order body covering UX foundation **and** UI system (per [joesteinkamp/design.md](https://github.com/joesteinkamp/design.md)) |
| `DESIGN.json` | Design Brief (optional) | DTCG-format token companion. Mostly redundant now that tokens live in `DESIGN.md`'s front matter — kept for Impeccable interop |
| `CODE.md` | Technical Brief | Stack, architecture, conventions, testing, performance, security |
| `AGENTS.md` | Orchestrator | Universal [agents.md](https://agents.md) spec — single source of truth, formatted per [joesteinkamp/agents-md](https://github.com/joesteinkamp/agents-md) |
| `CLAUDE.md` | Orchestrator | Thin file: imports `@AGENTS.md` + Claude-Code-specific notes |

## Commands

- `/starter:setup` — guided one-sitting flow through all four steps
- `/starter:product-brief` — (re)generate `PRODUCT.md`
- `/starter:design-brief` — (re)generate `DESIGN.md` (UX + UI)
- `/starter:code-brief` — (re)generate `CODE.md`
- `/starter:orchestrate` — regenerate (or merge-update) `AGENTS.md` + `CLAUDE.md`

Each brief is also exposed as a Skill, so natural-language phrases like "set up the product brief" or "let's define the design system" auto-trigger the matching flow.

## Questionnaire shape

Hybrid: structured `AskUserQuestion` choices for high-leverage decisions (register, color strategy, framework), open follow-ups for the things that need a designer's voice (brand personality, anti-references, principles, user knowledge, flows). Opinionated defaults fill any gaps and are marked `[default — confirm]` in the output.

## Opinionation

Each brief carries its own anti-pattern guardrails embedded inline in the output, and `AGENTS.md` collects all four ban lists in one place so any agent reading it sees the bans without hopping files:

- `guardrails/product-anti-patterns.md` — vague personas, generic positioning, hedging brand voice
- `guardrails/ux-anti-patterns.md` — confirm-instead-of-undo, modal-first, hidden state, dark patterns
- `guardrails/design-anti-patterns.md` — purple gradients, neon-on-black, nested cards, gradient text, bounce easing
- `guardrails/code-anti-patterns.md` — premature abstraction, defensive on internal boundaries, magic timing

## Install

See [INSTALL.md](./INSTALL.md).

## Repo layout

```
.
├── .claude-plugin/plugin.json    # Plugin manifest
├── commands/                     # Slash command entry points
├── skills/                       # Skill definitions (auto-trigger logic)
├── templates/                    # Markdown + JSON templates for outputs
├── guardrails/                   # Anti-pattern registries
└── questionnaires/               # Source-of-truth question banks per brief
```

## Out of scope (v1)

- Multi-harness distributions (Cursor, Codex, Gemini, Copilot). `AGENTS.md` is the universal hook.
- Live design auditing of existing code (use Impeccable for that).
- A standalone CLI.

## Attribution

Concepts adapted from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (Apache 2.0). The agents.md convention follows [agents.md](https://agents.md).

## License

MIT.
