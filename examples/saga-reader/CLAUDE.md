# Claude Code Instructions

@AGENTS.md

> This file imports `AGENTS.md` (the universal agents.md spec) and adds Claude-Code-specific guidance below. The shared rules live in `AGENTS.md` — keep them there so Codex, Cursor, Antigravity, and every other agent see the same source of truth. Edit `PRODUCT.md`, `DESIGN.md`, or `CODE.md` and re-run the pack's `orchestrator` flow rather than hand-editing this file.

## Layering — this is the project layer

This is the **project / codebase** layer — rules that are true of *this repository*. It
intentionally omits user/global concerns — tool preferences, autonomy level, memory, sub-agent
strategy, and output conventions — which live in your user/global layer (`~/.claude/CLAUDE.md`).
The two layers compose; where they conflict for work in this repo, the project layer wins.

## Claude Code preferences

### Starter-pack flows in this project

`project-starter-pack` exposes every flow as a skill, so natural language triggers them. Installed as a Claude Code plugin, each flow also has a slash command:

- `/starter:setup` — guided flow through all three briefs and orchestration.
- `/starter:product-brief` — (re)generate `PRODUCT.md`.
- `/starter:design-brief` — (re)generate `DESIGN.md` (UX + UI).
- `/starter:code-brief` — (re)generate `CODE.md`.
- `/starter:orchestrate` — regenerate `AGENTS.md`, `WRITING.md`, and the selected harness files from the three briefs.
- `/starter:validate` — check the briefs for contradictions and review the repo against them.
- `/starter:extract` — reverse-engineer draft briefs from an existing codebase (brownfield).

### Skills available

The same flows auto-trigger as skills when the user describes the matching work:

- `setup` — fires on "set up this project", "run the starter pack".
- `product-brief` — fires on "set up product context", "write PRODUCT.md", etc.
- `design-brief` — fires on "design system", "UX foundation", "DESIGN.md".
- `code-brief` — fires on "tech stack", "CODE.md", "architecture decisions".
- `orchestrator` — fires when `AGENTS.md` or `CLAUDE.md` needs to be regenerated.
- `validate` — fires on "check the briefs", "review against DESIGN.md", "find anti-patterns in the repo".
- `extract` — fires on "extract the briefs", "brownfield", "reverse engineer the design system".

## Project-specific Claude notes

- The **import pipeline** (`import/`, EPUB.js + pdf.js) is the riskiest surface — dispatch the **Plan** sub-agent before changing it, and never run parsers with network access.
- The **highlight anchor-matcher** and **sync merge** logic must keep their tests green; treat a dropped highlight anchor on re-import as a release blocker.
- Reading-path performance is a hard limit: keep parsers lazy-loaded, never import EPUB.js/pdf.js on the Reader route.
- The codebase is grouped by feature (`library/`, `reader/`, `marks/`, `import/`, `sync/`) — scope changes to the relevant feature folder.
