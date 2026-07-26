# project-starter-pack

A Claude Code plugin for product designers. Walks you through three opinionated briefs — Product, Design (UX + UI), Technical — and synthesizes them into `AGENT.md` plus the harness files you select (`CLAUDE.md`, `GEMINI.md`, Cursor rules) so any AI coding agent in your repo designs and codes with the same rigor a senior team would apply.

Inspired by [pbakaus/impeccable](https://github.com/pbakaus/impeccable). Patterns reused: the brand-vs-product register, OKLCH color strategies, the anti-pattern registry shape, and the AI slop self-check. No prose vendored.

## What you get

After running `/starter:setup` (or each command individually), your project root will contain:

| File | Owner | What it is |
|---|---|---|
| `PRODUCT.md` | Product Brief | Who, what, why, brand personality, anti-references, principles |
| `DESIGN.md` | Design Brief | UX foundation (user knowledge, IA, flows, success metrics) **and** UI system (color, type, spacing, motion, components) |
| `DESIGN.json` | Design Brief (optional) | Machine-readable token companion (filename matches Impeccable's convention for interop) |
| `CODE.md` | Technical Brief | Stack, architecture, conventions, testing, performance, security |
| `AGENT.md` | Orchestrator | Universal [agents.md](https://agents.md) spec — single source of truth (always written) |
| `WRITING.md` | Orchestrator | Voice, terminology, microcopy, and long-form rules — the anti-slop writing layer (always written) |
| `CLAUDE.md` | Orchestrator | Thin file: imports `@AGENT.md` + Claude-Code-specific notes (written if Claude Code is selected) |

`AGENT.md` and `WRITING.md` are always written. The harness-specific files — `CLAUDE.md`, and
optionally `GEMINI.md` or a Cursor file — are emitted only for the harnesses you pick at
orchestration time (see [Harness support](#harness-support)).

## Commands

- `/starter:setup` — guided one-sitting flow through the three briefs and orchestration
- `/starter:product-brief` — (re)generate `PRODUCT.md`
- `/starter:design-brief` — (re)generate `DESIGN.md` (UX + UI)
- `/starter:code-brief` — (re)generate `CODE.md`
- `/starter:orchestrate` — regenerate `AGENT.md` + `WRITING.md` + the selected harness files
- `/starter:validate` — check the briefs for contradictions and review the repo against them
- `/starter:extract` — reverse-engineer draft briefs from an existing codebase (brownfield)

Each brief is also exposed as a Skill, so natural-language phrases like "set up the product brief" or "let's define the design system" auto-trigger the matching flow.

## Harness support

`/starter:orchestrate` always writes `AGENT.md` (the universal [agents.md](https://agents.md) hook)
and `WRITING.md` (the writing rules), then emits a file for each harness you select:

- **Claude Code** (default on) → `CLAUDE.md`
- **Gemini CLI** → `GEMINI.md`
- **Cursor** → either `AGENTS.md` (a simple copy Cursor reads natively — the default) **or**
  `.cursor/rules/project.mdc` (glob-scoped, `alwaysApply`)

Codex, Copilot, and other agents read `AGENT.md`/`AGENTS.md` directly.

## Questionnaire shape

Hybrid: structured `AskUserQuestion` choices for high-leverage decisions (register, color strategy, framework), open follow-ups for the things that need a designer's voice (brand personality, anti-references, principles, user knowledge, flows). Opinionated defaults fill any gaps and are marked `[default — confirm]` in the output.

## Opinionation

Each brief carries its own anti-pattern guardrails embedded inline in the output, and `AGENT.md` collects all five ban lists in one place so any agent reading it sees the bans without hopping files:

- `guardrails/product-anti-patterns.md` — vague personas, generic positioning, hedging brand voice
- `guardrails/ux-anti-patterns.md` — confirm-instead-of-undo, modal-first, hidden state, dark patterns
- `guardrails/design-anti-patterns.md` — purple gradients, neon-on-black, nested cards, gradient text, bounce easing
- `guardrails/writing-anti-patterns.md` — AI-flagship vocabulary ("delve", "seamless"), binary contrasts, throat-clearing, cutesy error messages
- `guardrails/code-anti-patterns.md` — premature abstraction, defensive on internal boundaries, magic timing

## Brownfield projects

Already have a codebase? Run `/starter:extract` first. It reads `package.json` / `pyproject.toml`,
your CSS / token / theme files, the components directory, CI config, and the README, then writes
*draft* `PRODUCT.md`, `DESIGN.md`, `DESIGN.json`, and `CODE.md` — filling what the code proves and
marking everything it can't (`[TODO — confirm]`). It never invents brand or product intent: code
shows *what*, not *why*. Review the drafts, run `/starter:validate` to check them against the code,
then `/starter:orchestrate`.

## Relationship to your global instructions

`project-starter-pack` produces the **project / codebase layer** — `AGENT.md`, the selected
harness files, and the briefs — which describes *this repository*: its product, its design system, its stack and
conventions. It is the companion to a **user / global layer** (your own `~/.claude/CLAUDE.md`,
e.g. generated by something like [`agent-global-instructions`](https://github.com/joesteinkamp/agent-global-instructions))
that describes *you* across every project: your autonomy level, memory, tool/MCP preferences,
sub-agent strategy, and output/serving conventions.

The two layers compose and **must not duplicate each other**. So the files this pack generates
deliberately *defer upward*: they don't restate Edit-over-Write, parallel tool calls, when to
dispatch a sub-agent, or how you like artifacts served — that's all user-level. They keep only
what's true of the repo. The generated `AGENT.md` and every harness file carry a short "Layering"
note saying exactly this, so any agent reading them knows where each kind of rule lives.

## Examples

[`examples/saga-reader/`](./examples/saga-reader/) is a complete, no-personal-data render of
every file the pack produces — the three briefs (`PRODUCT.md`, `DESIGN.md`, `CODE.md`), the
`DESIGN.json` token companion, and the generated `AGENT.md` + `WRITING.md` plus all three harness
renders (`CLAUDE.md`, `GEMINI.md`, `.cursor/rules/project.mdc`) — for a fictional
reading app. It's deliberately *not* an AI product, so it shows the cliché-free output the
guardrails are meant to produce. Read it before running the flow to see the depth and voice
each brief expects.

## Install

See [INSTALL.md](./INSTALL.md).

## Development

Run the integrity linter before committing changes to the templates, questionnaires, or
orchestrator:

```
./test.sh
```

It verifies the **slot ↔ question ↔ orchestrator ↔ template** contract — every template
`{{SLOT}}` has a question (or default) that feeds it, every `DESIGN.json` token is traceable
to the design questionnaire, every guardrail is wired into a skill and the orchestrator, and
the shipped example is a complete, placeholder-free render whose structure matches the
templates (every template heading and token key appears in the example). It needs only
`bash`, `grep`, and `sed`.

### Optional design hooks

`hooks/` holds **opt-in, warn-only** hooks that nudge when an edited file drifts from the design
system (raw hex where OKLCH applies, glassmorphism, animating layout properties) or the writing
rules (AI-flagship vocabulary, empty framing phrases, em-dash clusters in prose files). They are
not installed by default and never block. Run `hooks/install-hooks.sh` to enable them; see
[`hooks/README.md`](./hooks/README.md) for why enforcement stays advisory and lives here rather
than in your global layer.

## Repo layout

```
.
├── .claude-plugin/plugin.json    # Plugin manifest
├── commands/                     # Slash command entry points
├── skills/                       # Skill definitions (auto-trigger logic)
├── templates/                    # Markdown + JSON templates for outputs
├── guardrails/                   # Anti-pattern registries
├── questionnaires/               # Source-of-truth question banks per brief
├── examples/                     # Worked example renders (no personal data)
├── hooks/                        # Optional, opt-in, warn-only design hooks
└── test.sh                       # Integrity linter for the slot/question contract
```

## Out of scope

- Deep visual auditing of rendered UI (use [Impeccable](https://github.com/pbakaus/impeccable) for that). `/starter:validate` reviews code and tokens against the briefs, but not pixels.
- A standalone CLI — this is a Claude Code plugin.

## Attribution

Concepts adapted from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (Apache 2.0). The writing anti-patterns are adapted from [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop) (MIT). The agents.md convention follows [agents.md](https://agents.md).

## License

MIT.
