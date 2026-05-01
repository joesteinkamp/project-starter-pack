# Claude Code Instructions

@AGENT.md

> This file imports `AGENT.md` (the universal agents.md spec) and adds Claude-Code-specific guidance below. The shared rules live in `AGENT.md` — keep them there so other AI tools see the same source of truth. Edit `PRODUCT.md`, `DESIGN.md`, or `CODE.md` and re-run `/starter:orchestrate` rather than hand-editing this file.

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
- `/starter:orchestrate` — regenerate `AGENT.md` and `CLAUDE.md` from the briefs (folds in `PROJECT.md` when present).
- `/starter:validate` — cross-check the persistent briefs for contradictions and anti-pattern hits.
- `/starter:feedback` — apply corrective feedback to a generated brief.
- `/starter:evaluate` — audit the project against `AGENT.md` and the four anti-pattern guardrails.
- `/starter:report-issue` — file an upstream issue at `joesteinkamp/project-starter-pack`.

### Skills available

The plugin also exposes skills that auto-trigger when the user describes the matching work:

- `product-brief` — fires on "set up product context", "write PRODUCT.md", etc.
- `design-brief` — fires on "design system", "UX foundation", "DESIGN.md".
- `code-brief` — fires on "tech stack", "CODE.md", "architecture decisions".
- `project-brief` — fires on "scope this project", "PROJECT.md", "what are we building this sprint".
- `orchestrator` — fires when `AGENT.md` or `CLAUDE.md` needs to be regenerated.
- `validator` — fires on "validate briefs", "check briefs", "are the briefs consistent".
- `feedback` — fires on "fix PRODUCT.md", "this brief is wrong", "AGENT.md is missing X".
- `evaluator` — fires on "audit this project", "evaluate against the briefs", "design audit".
- `report-issue` — fires on "report this upstream", "file an issue against the starter pack".

## Project-specific Claude notes

- **Sub-agent steering**: dispatch **Plan** before any change to `app/lib/retro/service.ts` or the meeting-surface route (`app/routes/teams.$team.retros.$retro.tsx`) — these touch real-time state via LiveKit data-channels and timing edge cases land here. Use **Explore** for searches across `app/lib/` instead of grepping from the main thread.
- **Hot-spot file**: `app/db/schema.ts` is load-bearing for the carryover relationship between `Retro` → `Action` → next `Retro`. Read the whole file before modifying any of those tables; migrations are forward-only.
- **Tooling quirks**: tests run via `pnpm vitest` (not `npm test`) and E2E via `pnpm playwright test`. Pre-commit runs Biome — don't skip it. Migrations are applied via `pnpm db:migrate`; never edit a migration that has shipped.
- **Blast-radius rule**: never run `pnpm db:migrate:prod` or `gh workflow run deploy-prod` without an explicit user OK. Staging deploys auto-trigger from `main` and are fine.
- **Performance gate**: any change that touches `app/routes/teams.$team.retros.$retro.write.tsx` (the writing surface, the most-visited route) must be checked against the LCP ≤1.5s budget before merge. Bundle additions to that route get scrutiny first.
