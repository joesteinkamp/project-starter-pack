# Claude Code Instructions

@AGENTS.md

> This file imports `AGENTS.md` (the universal agents.md spec) and adds Claude-Code-specific guidance below. The shared rules live in `AGENTS.md` — keep them there so other AI tools see the same source of truth. Edit `PRODUCT.md`, `DESIGN.md`, or `CODE.md` and re-run `/starter:orchestrate` rather than hand-editing this file.

## Claude Code preferences

### Tool use

- Prefer `Edit` over `Write` when modifying existing files.
- Read files before editing — never edit blind.
- Use `Grep` / `Glob` over shell `find` / `grep` when searching the codebase.
- Run independent tool calls in parallel.

### Sub-agents

- For broad codebase exploration, dispatch the **Explore** sub-agent rather than searching from the main thread — it protects context.
- For non-trivial implementation planning, dispatch the **Plan** sub-agent before coding.
- Don't dispatch sub-agents for trivial lookups; use direct tools instead.

### Slash commands available in this project

This project ships the `project-starter-pack` plugin. The following commands are available:

- `/starter:setup` — guided flow through all three briefs and orchestration.
- `/starter:product-brief` — (re)generate `PRODUCT.md`.
- `/starter:design-brief` — (re)generate `DESIGN.md` (UX + UI).
- `/starter:code-brief` — (re)generate `CODE.md`.
- `/starter:project-brief` — scope the current initiative and write `PROJECT.md` (run per initiative).
- `/starter:orchestrate` — regenerate `AGENTS.md` and `CLAUDE.md` from the briefs (folds in `PROJECT.md` when present).
- `/starter:validate` — cross-check the persistent briefs for contradictions and anti-pattern hits.
- `/starter:feedback` — apply corrective feedback to a generated brief (`PRODUCT.md`, `DESIGN.md`, `CODE.md`, `PROJECT.md`, `AGENTS.md`, `CLAUDE.md`).
- `/starter:evaluate` — audit the project against `AGENTS.md` and the four anti-pattern guardrails; report at `.starter/evaluations/`.
- `/starter:report-issue` — file an upstream issue at `joesteinkamp/project-starter-pack` so the generator improves.

### Skills available

The plugin also exposes skills that auto-trigger when the user describes the matching work:

- `product-brief` — fires on "set up product context", "write PRODUCT.md", etc.
- `design-brief` — fires on "design system", "UX foundation", "DESIGN.md".
- `code-brief` — fires on "tech stack", "CODE.md", "architecture decisions".
- `project-brief` — fires on "scope this project", "PROJECT.md", "what are we building this sprint".
- `orchestrator` — fires when `AGENTS.md` or `CLAUDE.md` needs to be regenerated.
- `validator` — fires on "validate briefs", "check briefs", "are the briefs consistent".
- `feedback` — fires on "fix PRODUCT.md", "this brief is wrong", "AGENTS.md is missing X".
- `evaluator` — fires on "audit this project", "evaluate against the briefs", "design audit".
- `report-issue` — fires on "report this upstream", "file an issue against the starter pack".

## Project-specific Claude notes

{{CLAUDE_PROJECT_NOTES}}
