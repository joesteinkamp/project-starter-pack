# Claude Code Instructions

@AGENT.md

> This file imports `AGENT.md` (the universal agents.md spec) and adds Claude-Code-specific guidance below. The shared rules live in `AGENT.md` — keep them there so other AI tools see the same source of truth. Edit `PRODUCT.md`, `DESIGN.md`, or `CODE.md` and re-run `/starter:orchestrate` rather than hand-editing this file.

## Layering — this is the project layer

{{LAYERING_NOTE}}

## Claude Code preferences

### Slash commands available in this project

This project ships the `project-starter-pack` plugin. The following commands are available:

- `/starter:setup` — guided flow through all three briefs and orchestration.
- `/starter:product-brief` — (re)generate `PRODUCT.md`.
- `/starter:design-brief` — (re)generate `DESIGN.md` (UX + UI).
- `/starter:code-brief` — (re)generate `CODE.md`.
- `/starter:orchestrate` — regenerate `AGENT.md` and the selected harness files from the three briefs.
- `/starter:validate` — check the briefs for contradictions and review the repo against them.
- `/starter:extract` — reverse-engineer draft briefs from an existing codebase (brownfield).

### Skills available

The plugin also exposes skills that auto-trigger when the user describes the matching work:

- `product-brief` — fires on "set up product context", "write PRODUCT.md", etc.
- `design-brief` — fires on "design system", "UX foundation", "DESIGN.md".
- `code-brief` — fires on "tech stack", "CODE.md", "architecture decisions".
- `orchestrator` — fires when `AGENT.md` or any harness file (`CLAUDE.md`, `GEMINI.md`, Cursor rules) needs to be regenerated.
- `validate` — fires on "check the briefs", "review against DESIGN.md", "find anti-patterns in the repo".
- `extract` — fires on "extract the briefs", "brownfield", "reverse engineer the design system".

## Project-specific Claude notes

{{HARNESS_PROJECT_NOTES}}
