# project-starter-pack

A Claude Code plugin for product designers. Walks you through three opinionated briefs — Product, Design (UX + UI), Technical — and synthesizes them into `AGENT.md` and `CLAUDE.md` so any AI coding agent in your repo designs and codes with the same rigor a senior team would apply.

Inspired by [pbakaus/impeccable](https://github.com/pbakaus/impeccable). Patterns reused: the brand-vs-product register, OKLCH color strategies, the anti-pattern registry shape, and the AI slop self-check. No prose vendored.

## What you get

After running `/starter:setup` (or each command individually), your project root will contain:

| File | Owner | What it is |
|---|---|---|
| `PRODUCT.md` | Product Brief | Who, what, why, brand personality, anti-references, principles |
| `DESIGN.md` | Design Brief | UX foundation (user knowledge, IA, flows, success metrics) **and** UI system (color, type, spacing, motion, components) |
| `DESIGN.json` | Design Brief (optional) | Machine-readable token companion (filename matches Impeccable's convention for interop) |
| `CODE.md` | Technical Brief | Stack, architecture, conventions, testing, performance, security |
| `AGENT.md` | Orchestrator | Universal [agents.md](https://agents.md) spec — single source of truth |
| `CLAUDE.md` | Orchestrator | Thin file: imports `@AGENT.md` + Claude-Code-specific notes |

## Commands

- `/starter:setup` — guided one-sitting flow through all four steps
- `/starter:product-brief` — (re)generate `PRODUCT.md`
- `/starter:design-brief` — (re)generate `DESIGN.md` (UX + UI)
- `/starter:code-brief` — (re)generate `CODE.md`
- `/starter:orchestrate` — regenerate `AGENT.md` + `CLAUDE.md`
- `/starter:extract` — reverse direction: scan an existing codebase, audit which briefs are missing or thin, fill the gaps, and end with a fork review of decisions the codebase left ambiguous

Each brief is also exposed as a Skill, so natural-language phrases like "set up the product brief", "let's define the design system", or "reverse-engineer the briefs from this repo" auto-trigger the matching flow.

## Questionnaire shape

Hybrid: structured `AskUserQuestion` choices for high-leverage decisions (register, color strategy, framework), open follow-ups for the things that need a designer's voice (brand personality, anti-references, principles, user knowledge, flows). Opinionated defaults fill any gaps and are marked `[default — confirm]` in the output.

## Opinionation

Each brief carries its own anti-pattern guardrails embedded inline in the output, and `AGENT.md` collects all four ban lists in one place so any agent reading it sees the bans without hopping files:

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

- Multi-harness distributions (Cursor, Codex, Gemini, Copilot). `AGENT.md` is the universal hook.
- Live design auditing of existing code (use Impeccable for that).
- A standalone CLI.

## Attribution

Concepts adapted from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (Apache 2.0). The agents.md convention follows [agents.md](https://agents.md).

## License

MIT.
