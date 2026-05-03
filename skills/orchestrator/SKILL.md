---
name: orchestrator
description: Synthesizes PRODUCT.md, DESIGN.md, CODE.md, and PROJECT.md (when present) into AGENTS.md (universal agents.md spec, joesteinkamp/agents-md format) and CLAUDE.md (Claude-Code-specific) at the project root. Supports updating an existing AGENTS.md by merging only the regenerated sections while preserving hand-edits inside the custom block. Use when the user asks to generate, regenerate, or update AGENTS.md or CLAUDE.md, or when the briefs exist and the agent instructions need to be assembled. Triggers on "AGENTS.md", "CLAUDE.md", "orchestrate briefs", "generate agent instructions", "assemble project instructions", "update agents file".
---

# Orchestrator Skill

You assemble the briefs into `AGENTS.md` (universal agents.md spec, formatted per [joesteinkamp/agents-md](https://github.com/joesteinkamp/agents-md)) and `CLAUDE.md` (thin file that imports `AGENTS.md` and adds Claude-Code-specific addenda).

## Setup

1. Locate the plugin root. Templates are at `templates/AGENTS.template.md` and `templates/CLAUDE.template.md`. Anti-pattern guardrails are at `guardrails/{product,ux,design,code}-anti-patterns.md`.
2. Read both templates and all four guardrail files before starting.

## Inputs

Read the briefs from the project root:
- `PRODUCT.md` — required
- `DESIGN.md` — required (expected: YAML front matter + canonical sections per joesteinkamp/design.md)
- `CODE.md` — required
- `PROJECT.md` — **optional**. Present only when an initiative is actively scoped. If absent, that's fine — the "Current project" section is omitted from `AGENTS.md` (do not leave a TODO placeholder for it).

If any of the three required briefs are missing:
- Print which are missing and the command to run for each (`/starter:product-brief`, `/starter:design-brief`, `/starter:code-brief`).
- Ask: proceed with placeholders, or stop?
- If they proceed, leave the corresponding sections in `AGENTS.md` as `[TODO — run /starter:<brief>]` and continue.

## Pre-flight (existing AGENTS.md / CLAUDE.md)

Check for `AGENTS.md` and `CLAUDE.md`.

- **Either AGENTS.md or CLAUDE.md exists** → ask via `AskUserQuestion`:
  - **regenerate** — overwrite all derived sections, preserve any content inside the `<!-- custom:start -->` / `<!-- custom:end -->` block.
  - **update sections** (merge) — pick which derived sections to refresh (e.g., only `## Design laws`); leave the rest verbatim.
  - **stop**.
- **Neither exists** → proceed.

Always preserve the contents of the `<!-- custom:start -->` … `<!-- custom:end -->` block when regenerating `AGENTS.md`. If the existing file lacks the block, ask the user whether any of its hand-edits should be lifted into the custom block before overwriting.

## Synthesis

### AGENTS.md

Populate `templates/AGENTS.template.md`. The template already includes the agents-md format primitives (precedence hierarchy, always-on rules for Git/Security/Testing, and the `.agents/` extension index). Fill these slots:

- `{{PRODUCT_SUMMARY}}` — 2-3 sentence synthesis of `PRODUCT.md` (one-liner + register + primary user).
- `{{CURRENT_PROJECT}}` — only if `PROJECT.md` exists. Synthesize: title, one-liner, status, goal, top 3 non-goals, success metrics, scope slice (design surfaces + code subsystems). Keep tight — bullets, not prose. If `PROJECT.md` is missing, **remove the entire "Current project" section** from the rendered template (do not leave a TODO; PROJECT.md is optional by design).
- `{{PRODUCT_CONTEXT}}` — bullet summary: register, primary user, jobs-to-be-done, brand personality (3 words), top 3 anti-references.
- `{{UX_LAWS}}` — extract from `DESIGN.md` UX Foundation section: interaction principles, accessibility commitments, top user flows (one line each). UX is the constraint; everything below executes against these.
- `{{DESIGN_LAWS}}` — extract from `DESIGN.md` UI sections (Colors, Typography, Layout, Components, Motion). Reference tokens by their `{path.to.token}` names from the YAML front matter (e.g., "Accent fill = `{colors.accent}`; never use raw hex in code"). These express the UX laws above — if a UI choice would undermine a UX law, it loses.
- `{{CODE_CONVENTIONS}}` — extract from `CODE.md`: stack, languages/tooling, naming, comment policy, error handling, performance budgets, security baselines.
- `{{PRODUCT_ANTI_PATTERNS}}` / `{{UX_ANTI_PATTERNS}}` / `{{DESIGN_ANTI_PATTERNS}}` / `{{CODE_ANTI_PATTERNS}}` — embed headlines from the matching `guardrails/*.md` file (one line per pattern). Embedded inline, not just linked. An agent reading `AGENTS.md` should see the bans without hopping files.
- `{{CUSTOM_NOTES}}` — on a fresh write: leave a single comment line (`<!-- Add project-specific notes here. They survive /starter:orchestrate. -->`). On regenerate: copy the existing custom block verbatim.

### CLAUDE.md

Populate `templates/CLAUDE.template.md`. The file is intentionally thin — it imports `AGENTS.md` via `@AGENTS.md` and adds:

- `{{CLAUDE_PROJECT_NOTES}}` — synthesize 3-5 project-specific Claude-Code notes from the briefs. Walk these categories and pick the ones the briefs actually justify:
  - **Sub-agent steering** — when to dispatch Plan vs. Explore for *this* codebase. Example: "Dispatch Plan before any change to billing flows — they touch Stripe webhooks and migration ordering matters."
  - **Hot-spot files** — paths that need extra care. Example: "`src/auth/session.ts` is custom and load-bearing; read it fully before editing."
  - **Repo shape** — monorepo? package count? language split? Example: "Monorepo with 12 packages under `packages/`; use Explore rather than Grep from the main thread."
  - **Tooling quirks** — non-default test runners, codegen, pre-commit hooks. Example: "Tests run via `pnpm vitest`, not `npm test`. Pre-commit runs `biome` — don't skip it."
  - **Blast-radius rules** — actions that need confirmation. Example: "Never run `pnpm db:migrate:prod` without an explicit user OK; staging is fine."

  **Guardrail:** every note must cite a specific file, flow, package, or tool from one of the briefs. Generic Claude advice ("prefer Edit over Write", "read before editing") belongs in `AGENTS.md`, not here. If nothing project-specific stands out, leave a single line: "No project-specific Claude notes yet."

Keep `CLAUDE.md` short. Shared rules belong in `AGENTS.md`.

## .agents/ scaffolding (optional)

If the user asks to add a project-specific rule or skill, create the file under `.agents/rules/<name>.md` or `.agents/skills/<name>.md` with the correct frontmatter:

- **Rule frontmatter**: `description`, `globs` (array of file patterns), `alwaysApply` (boolean — default `false`).
- **Skill frontmatter**: `description`, `trigger` (the natural-language phrase), `risk` (`low` | `medium` | `high`).

Filenames lowercase-with-hyphens. One concept per file. Lead with the rule statement; rationale later.

## Preview & write

1. Render both files and show the user (collapse long sections if needed).
2. In merge mode, show a diff or the changed sections only.
3. Ask for one round of edits.
4. Write `AGENTS.md` and `CLAUDE.md` to the project root.

## Done

Print a one-screen summary:

```
✓ Wrote AGENTS.md ({{N}} sections, {{M}} anti-patterns embedded, custom block preserved)
✓ Wrote CLAUDE.md (thin import of AGENTS.md + {{K}} Claude-specific notes)

Next steps:
- Test by asking Claude to build something small in this repo. It should
  read AGENTS.md before generating UI or code.
- If anything in the briefs changes, edit PRODUCT.md / DESIGN.md / CODE.md
  and re-run /starter:orchestrate.
- Project-specific rules/skills go under .agents/rules/ and .agents/skills/.
```

## Important

- Never invent product or design context. If a brief is missing or thin, say so in the output.
- Hand-edits inside the `<!-- custom:start -->` / `<!-- custom:end -->` block are sacrosanct — preserve them on every regenerate.
- The voice of the synthesized files should match the voice the briefs established. Don't add hedging.
