# Claude Code Instructions

@AGENTS.md

> This file is a thin pointer. It imports `AGENTS.md` — the project's entry point, which routes to the briefs (`PRODUCT.md`, `DESIGN.md`, `CODE.md`, `WRITING.md`) — and adds Claude-Code-specific notes below. Shared rules belong in `AGENTS.md` so Codex, Cursor, Antigravity, and every other agent see the same source of truth. This file is derived: edit the briefs, not this file.

## Starter-pack flows in this project

`project-starter-pack` exposes every flow as a skill, so natural language triggers them. Installed as a Claude Code plugin, each flow also has a slash command:

- `/starter:setup` — guided flow through the three briefs, then wires up `AGENTS.md` and this file.
- `/starter:product-brief` — (re)generate `PRODUCT.md`.
- `/starter:design-brief` — (re)generate `DESIGN.md` (UX + UI) and the `WRITING.md` companion.
- `/starter:code-brief` — (re)generate `CODE.md`.
- `/starter:validate` — check the briefs for contradictions and review the repo against them.
- `/starter:extract` — reverse-engineer draft briefs from an existing codebase (brownfield).

The same flows auto-trigger as skills when the user describes the matching work:

- `setup` — fires on "set up this project", "run the starter pack".
- `product-brief` — fires on "set up product context", "write PRODUCT.md", etc.
- `design-brief` — fires on "design system", "UX foundation", "DESIGN.md", "writing rules".
- `code-brief` — fires on "tech stack", "CODE.md", "architecture decisions".
- `validate` — fires on "check the briefs", "review against DESIGN.md", "find anti-patterns in the repo".
- `extract` — fires on "extract the briefs", "brownfield", "reverse engineer the design system".

## Project-specific Claude notes

{{HARNESS_PROJECT_NOTES}}
