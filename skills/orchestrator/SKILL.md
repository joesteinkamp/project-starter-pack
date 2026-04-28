---
name: orchestrator
description: Synthesizes PRODUCT.md, DESIGN.md, CODE.md, and PROJECT.md (when present) into AGENT.md (universal agents.md) and CLAUDE.md (Claude-Code-specific) at the project root. Use when the user asks to generate or regenerate AGENT.md, AGENTS.md, or CLAUDE.md, or when the briefs exist and the agent instructions need to be assembled. Triggers on "AGENT.md", "AGENTS.md", "CLAUDE.md", "orchestrate briefs", "generate agent instructions", "assemble project instructions".
---

# Orchestrator Skill

You assemble the briefs into `AGENT.md` (universal agents.md spec) and `CLAUDE.md` (thin file that imports `AGENT.md` and adds Claude-Code-specific addenda).

## Setup

1. Locate the plugin root. Templates are at `templates/AGENT.template.md` and `templates/CLAUDE.template.md`. Anti-pattern guardrails are at `guardrails/{product,ux,design,code}-anti-patterns.md`.
2. Read both templates and all four guardrail files before starting.

## Inputs

Read these briefs from the project root:
- `PRODUCT.md` — required
- `DESIGN.md` — required
- `CODE.md` — required
- `PROJECT.md` — **optional**. Present only when an initiative is actively scoped. If absent, that's fine — the "Current project" section is omitted from `AGENT.md` (do not leave a TODO placeholder for it).

If any of the three required briefs are missing:
- Print which are missing and the command to run for each (`/starter:product-brief`, `/starter:design-brief`, `/starter:code-brief`).
- Ask the user: proceed with placeholders for missing briefs, or stop?
- If they proceed, leave the corresponding sections in `AGENT.md` as `[TODO — run /starter:<brief>]` and continue.

## Pre-flight

Check whether `AGENT.md` and/or `CLAUDE.md` exist:
- If neither exists, proceed.
- If either exists, ask: overwrite (regenerate from briefs) or stop. Do not offer "merge" — these files are derived, not authored.

## Synthesis

### AGENT.md

Populate `templates/AGENT.template.md`:

- `{{PRODUCT_SUMMARY}}` — a 2-3 sentence synthesis of `PRODUCT.md` (one-liner + register + primary user).
- `{{CURRENT_PROJECT}}` — only if `PROJECT.md` exists. Synthesize: title, one-liner, status, goal, top 3 non-goals, success metrics, scope slice (design surfaces + code subsystems). Keep tight — bullets, not prose. If `PROJECT.md` is missing, **remove the entire "Current project" section** from the rendered template (do not leave a TODO; PROJECT.md is optional by design).
- `{{PRODUCT_CONTEXT}}` — bullet summary: register, primary user, jobs-to-be-done, brand personality (3 words), top 3 anti-references.
- `{{UX_LAWS}}` — extract from `DESIGN.md` UX foundation: interaction principles, accessibility commitments, top user flows (one line each).
- `{{DESIGN_LAWS}}` — extract from `DESIGN.md` UI system: color strategy + accent rules, type pairing + measure cap, motion stance, when cards are allowed.
- `{{CODE_CONVENTIONS}}` — extract from `CODE.md`: stack, languages/tooling, naming, comment policy, error handling, performance budgets, security baselines.
- `{{PRODUCT_ANTI_PATTERNS}}` — embed `guardrails/product-anti-patterns.md` headlines (1 line per pattern).
- `{{UX_ANTI_PATTERNS}}` — embed `guardrails/ux-anti-patterns.md` headlines.
- `{{DESIGN_ANTI_PATTERNS}}` — embed `guardrails/design-anti-patterns.md` headlines.
- `{{CODE_ANTI_PATTERNS}}` — embed `guardrails/code-anti-patterns.md` headlines.

Anti-pattern lists must be **embedded inline** (one-line summaries), not just linked. An agent reading `AGENT.md` should see the bans without hopping files.

### CLAUDE.md

Populate `templates/CLAUDE.template.md`. The file is intentionally thin — it imports `AGENT.md` via `@AGENT.md` and adds:
- `{{CLAUDE_PROJECT_NOTES}}` — synthesize 3-5 project-specific Claude-Code notes from the briefs (e.g. "Use the Explore sub-agent for codebase searches; this monorepo has 12 packages", or "Use the Plan sub-agent before any change to the auth flow"). If nothing project-specific stands out, leave a single line: "No project-specific Claude notes yet."

Keep `CLAUDE.md` short. The shared rules belong in `AGENT.md`.

## Preview & write

1. Render both files and show the user (collapse long sections if needed).
2. Ask for one round of edits.
3. Write `AGENT.md` and `CLAUDE.md` to the project root.

## Done

Print a one-screen summary:
```
✓ Wrote AGENT.md ({{N}} sections, {{M}} anti-patterns embedded)
✓ Wrote CLAUDE.md (thin import of AGENT.md + {{K}} Claude-specific notes)

Next steps:
- Test by asking Claude to build something small in this repo. It should
  read AGENT.md before generating UI or code.
- If anything in the briefs changes, edit PRODUCT.md / DESIGN.md / CODE.md
  and re-run /starter:orchestrate.
```

## Important

- Never invent product or design context. If a brief is missing or thin, say so in the output.
- `AGENT.md` and `CLAUDE.md` are derived files. Do not offer to "merge" edits — regenerate from briefs.
- The voice of the synthesized files should match the voice the briefs established. Don't add hedging.
