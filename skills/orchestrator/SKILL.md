---
name: orchestrator
description: Synthesizes PRODUCT.md, DESIGN.md, and CODE.md into AGENTS.md (universal agents.md spec, joesteinkamp/agents-md format) and CLAUDE.md (Claude-Code-specific) at the project root. Supports updating an existing AGENTS.md by merging only the regenerated sections while preserving hand-edits inside the custom block. Use when the user asks to generate, regenerate, or update AGENTS.md / AGENT.md / CLAUDE.md, or when all three briefs exist and the agent instructions need to be assembled. Triggers on "AGENTS.md", "AGENT.md", "CLAUDE.md", "orchestrate briefs", "generate agent instructions", "assemble project instructions", "update agents file".
---

# Orchestrator Skill

You assemble the three briefs into `AGENTS.md` (universal agents.md spec, formatted per [joesteinkamp/agents-md](https://github.com/joesteinkamp/agents-md)) and `CLAUDE.md` (thin file that imports `AGENTS.md` and adds Claude-Code-specific addenda).

## Setup

1. Locate the plugin root. Templates are at `templates/AGENTS.template.md` and `templates/CLAUDE.template.md`. Anti-pattern guardrails are at `guardrails/{product,ux,design,code}-anti-patterns.md`.
2. Read both templates and all four guardrail files before starting.

## Inputs

Read the three briefs from the project root:
- `PRODUCT.md`
- `DESIGN.md` (expected: YAML front matter + canonical sections per joesteinkamp/design.md)
- `CODE.md`

If any are missing:
- Print which are missing and the command to run for each (`/starter:product-brief`, `/starter:design-brief`, `/starter:code-brief`).
- Ask: proceed with placeholders, or stop?
- If they proceed, leave the corresponding sections in `AGENTS.md` as `[TODO — run /starter:<brief>]` and continue.

## Pre-flight (existing AGENTS.md / AGENT.md / CLAUDE.md)

Check for `AGENTS.md`, legacy `AGENT.md` (singular), and `CLAUDE.md`.

- **Legacy `AGENT.md` only** → offer: rename to `AGENTS.md` (recommended) or write `AGENTS.md` alongside.
- **Either AGENTS.md or CLAUDE.md exists** → ask via `AskUserQuestion`:
  - **regenerate** — overwrite all derived sections, preserve any content inside the `<!-- custom:start -->` / `<!-- custom:end -->` block.
  - **update sections** (merge) — pick which derived sections to refresh (e.g., only `## Design laws`); leave the rest verbatim.
  - **stop**.
- **Neither exists** → proceed.

Always preserve the contents of the `<!-- custom:start -->` … `<!-- custom:end -->` block when regenerating `AGENTS.md`. If the existing file lacks the block, ask the user whether any of its hand-edits should be lifted into the custom block before overwriting.

## Synthesis

### AGENTS.md

Populate `templates/AGENTS.template.md`. The template already includes the agents-md format primitives (precedence hierarchy, always-on rules for Git/Security/Testing, and the `.agents/` extension index). Fill these slots:

- `{{PROJECT_SUMMARY}}` — 2-3 sentence synthesis of `PRODUCT.md` (one-liner + register + primary user).
- `{{PRODUCT_CONTEXT}}` — bullet summary: register, primary user, jobs-to-be-done, brand personality (3 words), top 3 anti-references.
- `{{UX_LAWS}}` — extracted from `DESIGN.md` UX Foundation section: interaction principles, accessibility commitments, top user flows (one line each).
- `{{DESIGN_LAWS}}` — extracted from `DESIGN.md` UI sections (Colors, Typography, Layout, Components, Motion). Reference tokens by their `{path.to.token}` names from the YAML front matter (e.g., "Accent fill = `{colors.accent}`; never use raw hex in code").
- `{{CODE_CONVENTIONS}}` — extracted from `CODE.md`: stack, languages/tooling, naming, comment policy, error handling, performance budgets, security baselines.
- `{{PRODUCT_ANTI_PATTERNS}}` / `{{UX_ANTI_PATTERNS}}` / `{{DESIGN_ANTI_PATTERNS}}` / `{{CODE_ANTI_PATTERNS}}` — embed headlines from the matching `guardrails/*.md` file (one line per pattern). Embedded inline, not just linked.
- `{{CUSTOM_NOTES}}` — on a fresh write: leave a single comment line (`<!-- Add project-specific notes here. They survive /starter:orchestrate. -->`). On regenerate: copy the existing custom block verbatim.

### CLAUDE.md

Populate `templates/CLAUDE.template.md` (it imports `@AGENTS.md`):
- `{{CLAUDE_PROJECT_NOTES}}` — 3-5 project-specific Claude-Code notes synthesized from the briefs (e.g. "Use the Explore sub-agent for codebase searches; this monorepo has 12 packages", or "Use the Plan sub-agent before any change to the auth flow"). If nothing project-specific stands out, write a single line: "No project-specific Claude notes yet."

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
4. Write `AGENTS.md` and `CLAUDE.md` to the project root. If a legacy `AGENT.md` was renamed, also delete the singular file.

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
