# project-starter-pack

An AI project starter for product designers, portable across the tools you actually use. It walks
you through three opinionated briefs — Product, Design (UX + UI), Technical — and synthesizes them
into `AGENTS.md` plus `WRITING.md`, so every AI coding agent in your repo designs and codes with the
same rigor a senior team would apply.

Runs in **Claude Code, Codex, Cursor, and Antigravity** — same flows, same outputs.

Inspired by [pbakaus/impeccable](https://github.com/pbakaus/impeccable). Patterns reused: the brand-vs-product register, OKLCH color strategies, the anti-pattern registry shape, and the AI slop self-check. No prose vendored.

## What you get

After running the `setup` flow (or each flow individually), your project root will contain:

| File | Owner | What it is |
|---|---|---|
| `PRODUCT.md` | Product Brief | Who, what, why, brand personality, anti-references, principles |
| `DESIGN.md` | Design Brief | UX foundation (user knowledge, IA, flows, success metrics) **and** UI system (color, type, spacing, motion, components) |
| `DESIGN.json` | Design Brief (optional) | Machine-readable token companion (filename matches Impeccable's convention for interop) |
| `CODE.md` | Technical Brief | Stack, architecture, conventions, testing, performance, security |
| `AGENTS.md` | Orchestrator | The [agents.md](https://agents.md) spec file — single source of truth (always written) |
| `WRITING.md` | Orchestrator | Voice, terminology, microcopy, and long-form rules — the anti-slop writing layer (always written) |
| `CLAUDE.md` | Orchestrator | Thin file: imports `@AGENTS.md` + Claude-Code-specific notes (written if Claude Code is selected) |

`AGENTS.md` and `WRITING.md` are always written. Harness-specific files are emitted only for the
harnesses you pick at orchestration time — see [Tool support](#tool-support).

## Tool support

| | Claude Code | Codex | Cursor | Antigravity |
|---|---|---|---|---|
| **Reads the output** | via `CLAUDE.md` (`@AGENTS.md`) | `AGENTS.md` natively | `AGENTS.md` natively | `AGENTS.md` natively |
| **Runs the flows** | skills + `/starter:*` commands | skills (`$<flow>`) | skills + `/starter-*` commands | natural language |
| **Advisory hooks** | ✅ | ✅ | ✅ | ✅ |

Skills are the portable engine — three of the four tools run them natively, and the fourth reaches
the same flows through plain language. Commands are a convenience layer on top.

### Invoking a flow

| Flow | Claude Code | Codex | Cursor | Antigravity |
|---|---|---|---|---|
| `setup` | `/starter:setup` | `$setup` | `/starter-setup` | "run the project starter pack setup" |
| `product-brief` | `/starter:product-brief` | `$product-brief` | `/starter-product-brief` | "walk me through the product brief" |
| `design-brief` | `/starter:design-brief` | `$design-brief` | `/starter-design-brief` | "walk me through the design brief" |
| `code-brief` | `/starter:code-brief` | `$code-brief` | `/starter-code-brief` | "walk me through the technical brief" |
| `orchestrator` | `/starter:orchestrate` | `$orchestrator` | `/starter-orchestrate` | "regenerate AGENTS.md from the briefs" |
| `validate` | `/starter:validate` | `$validate` | `/starter-validate` | "check the briefs for contradictions" |
| `extract` | `/starter:extract` | `$extract` | `/starter-extract` | "extract briefs from this codebase" |

In every tool, describing the work in your own words also triggers the matching flow — "let's define
the design system", "set up product context". The generated `AGENTS.md` carries a
"Regenerating these instructions" section recording where the pack lives on disk, so an agent in a
tool with no command surface can still find and run it.

## Harness files at orchestration time

The `orchestrator` flow always writes `AGENTS.md` and `WRITING.md` — that alone covers Codex,
Cursor, and Antigravity. Then it asks which tools want a file of their own:

- **Claude Code** (default on) → `CLAUDE.md`, a thin `@AGENTS.md` import plus project-specific notes.
  Claude Code doesn't auto-read `AGENTS.md`, so this file is the connection.
- **Cursor scoped rules** (opt-in) → `.cursor/rules/project.mdc` (glob-scoped, `alwaysApply`). An
  upgrade over the native `AGENTS.md` read, not a requirement.

**Gemini CLI is no longer a target.** The tool is retired, and its successor Antigravity reads
`AGENTS.md` natively. The pack no longer generates `GEMINI.md` or ships its template; the
orchestrator's pre-flight offers to clean up an existing one.

## Questionnaire shape

Hybrid: structured multiple-choice for high-leverage decisions (register, color strategy, framework),
open follow-ups for the things that need a designer's voice (brand personality, anti-references,
principles, user knowledge, flows). Structured questions use the harness's own question tool where
one exists and fall back to numbered options in chat where it doesn't — see
[`conventions/question-mechanics.md`](./conventions/question-mechanics.md). Opinionated defaults fill
any gaps and are marked `[default — confirm]` in the output.

## Opinionation

Each brief carries its own anti-pattern guardrails embedded inline in the output, and `AGENTS.md` collects all five ban lists in one place so any agent reading it sees the bans without hopping files:

- `guardrails/product-anti-patterns.md` — vague personas, generic positioning, hedging brand voice
- `guardrails/ux-anti-patterns.md` — confirm-instead-of-undo, modal-first, hidden state, dark patterns
- `guardrails/design-anti-patterns.md` — purple gradients, neon-on-black, nested cards, gradient text, bounce easing
- `guardrails/writing-anti-patterns.md` — AI-flagship vocabulary ("delve", "seamless"), binary contrasts, throat-clearing, cutesy error messages
- `guardrails/code-anti-patterns.md` — premature abstraction, defensive on internal boundaries, magic timing

## Brownfield projects

Already have a codebase? Run the `extract` flow first. It reads `package.json` / `pyproject.toml`,
your CSS / token / theme files, the components directory, CI config, and the README, then writes
*draft* `PRODUCT.md`, `DESIGN.md`, `DESIGN.json`, and `CODE.md` — filling what the code proves and
marking everything it can't (`[TODO — confirm]`). It never invents brand or product intent: code
shows *what*, not *why*. Review the drafts, run `validate` to check them against the code, then
`orchestrator`.

## Relationship to your global instructions

`project-starter-pack` produces the **project / codebase layer** — `AGENTS.md`, the selected
harness files, and the briefs — which describes *this repository*: its product, its design system, its stack and
conventions. It is the companion to a **user / global layer** (your own `~/.claude/CLAUDE.md`,
e.g. generated by something like [`agent-global-instructions`](https://github.com/joesteinkamp/agent-global-instructions))
that describes *you* across every project: your autonomy level, memory, tool/MCP preferences,
sub-agent strategy, and output/serving conventions.

The two layers compose and **must not duplicate each other**. So the files this pack generates
deliberately *defer upward*: they don't restate Edit-over-Write, parallel tool calls, when to
dispatch a sub-agent, or how you like artifacts served — that's all user-level. They keep only
what's true of the repo. The generated `AGENTS.md` and every harness file carry a short "Layering"
note saying exactly this, so any agent reading them knows where each kind of rule lives.

## Examples

[`examples/saga-reader/`](./examples/saga-reader/) is a complete, no-personal-data render of
every file the pack produces — the three briefs (`PRODUCT.md`, `DESIGN.md`, `CODE.md`), the
`DESIGN.json` token companion, and the generated `AGENTS.md` + `WRITING.md` plus both harness
renders (`CLAUDE.md`, `.cursor/rules/project.mdc`) — for a fictional
reading app. It's deliberately *not* an AI product, so it shows the cliché-free output the
guardrails are meant to produce. Read it before running the flow to see the depth and voice
each brief expects.

## Install

```bash
./install.sh              # all four tools (symlinks; --yes skips the prompt)
./install.sh codex cursor # a subset
./install.sh --uninstall  # remove exactly what was installed
```

See [INSTALL.md](./INSTALL.md) for per-tool detail and the Claude-plugin alternative.

## Development

Run the integrity linter before committing changes to the templates, questionnaires, skills, or
orchestrator:

```
./test.sh
```

It verifies the **slot ↔ question ↔ orchestrator ↔ template** contract — every template
`{{SLOT}}` has a question (or default) that feeds it, every `DESIGN.json` token is traceable
to the design questionnaire, every guardrail is wired into a skill and the orchestrator, and
the shipped example is a complete, placeholder-free render whose structure matches the
templates. It also enforces the **portability contract**: every flow exists as a skill, every
command is a thin wrapper naming a real skill, no harness-specific tool names leak into skills or
questionnaires, and the port renderer is idempotent. It needs only `bash`, `grep`, `sed`, and
(for the behavioral fixtures) `jq`.

### Optional design hooks

`hooks/` holds **opt-in, warn-only** hooks that nudge when an edited file drifts from the design
system (raw hex where OKLCH applies, glassmorphism, animating layout properties) or the writing
rules (AI-flagship vocabulary, empty framing phrases, em-dash clusters in prose files). They are
not installed by default and never block. One set of scripts serves all four tools. Run
`hooks/install-hooks.sh` to enable them; see [`hooks/README.md`](./hooks/README.md) for the per-tool
wiring and why enforcement stays advisory.

## Repo layout

```
.
├── install.sh                    # Multi-tool installer (symlinks; --uninstall reverses)
├── render-ports.sh               # Generates the Cursor command ports from commands/
├── .claude-plugin/plugin.json    # Claude Code plugin manifest (the zero-script path)
├── commands/                     # Slash command entry points — thin wrappers over skills
├── skills/                       # The flows themselves: one SKILL.md each, the source of truth
├── conventions/                  # Shared skill mechanics (how questions get asked per tool)
├── templates/                    # Markdown + JSON templates for outputs
├── guardrails/                   # Anti-pattern registries
├── questionnaires/               # Source-of-truth question banks per brief
├── examples/                     # Worked example renders (no personal data)
├── hooks/                        # Optional, opt-in, warn-only advisory hooks
└── test.sh                       # Integrity + portability linter
```

## Out of scope

- Deep visual auditing of rendered UI (use [Impeccable](https://github.com/pbakaus/impeccable) for that). The `validate` flow reviews code and tokens against the briefs, but not pixels.
- A standalone CLI. `install.sh` is an installer, not a runtime — the flows run inside your AI tool.

## Attribution

Concepts adapted from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (Apache 2.0). The writing anti-patterns are adapted from [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop) (MIT). The agents.md convention follows [agents.md](https://agents.md).

## License

MIT.
