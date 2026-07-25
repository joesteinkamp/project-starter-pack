---
name: orchestrator
description: Synthesizes PRODUCT.md, DESIGN.md, and CODE.md into AGENT.md (universal agents.md) plus the selected harness files (CLAUDE.md, GEMINI.md, Cursor rules) at the project root. Use when the user asks to generate or regenerate AGENT.md, AGENTS.md, CLAUDE.md, GEMINI.md, or the Cursor rules, or when all three briefs exist and the agent instructions need to be assembled. Triggers on "AGENT.md", "AGENTS.md", "CLAUDE.md", "GEMINI.md", "Cursor rules", "orchestrate briefs", "generate agent instructions", "assemble project instructions".
---

# Orchestrator Skill

You assemble the three briefs into `AGENT.md` (universal agents.md spec) plus the harness files the user selects — `CLAUDE.md`, `GEMINI.md`, and/or a Cursor file — each a thin import of `AGENT.md` with harness-specific addenda.

## Setup

1. Locate the plugin root. Templates are at `templates/AGENT.template.md`, `templates/CLAUDE.template.md`, `templates/GEMINI.template.md`, and `templates/cursor-rules.template.mdc`. Anti-pattern guardrails are at `guardrails/{product,ux,design,code}-anti-patterns.md`.
2. Read `AGENT.template.md`, the templates for the harnesses in play, and all four guardrail files before starting.

## Inputs

Read all three briefs from the project root:
- `PRODUCT.md`
- `DESIGN.md`
- `CODE.md`

If any are missing:
- Print which are missing and the command to run for each (`/starter:product-brief`, `/starter:design-brief`, `/starter:code-brief`).
- Ask the user: proceed with placeholders for missing briefs, or stop?
- If they proceed, leave the corresponding sections in `AGENT.md` as `[TODO — run /starter:<brief>]` and continue.

## Pre-flight

Check every file this run could write: `AGENT.md`, plus — per the harness selection below — `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, and `.cursor/rules/project.mdc`:
- If none exist, proceed.
- If any exists, list which and ask: overwrite (regenerate from briefs) or stop. A hand-written `AGENTS.md` or `GEMINI.md` gets the same gate as `CLAUDE.md` — never overwrite silently. Do not offer "merge" — these files are derived, not authored.

## Harness targets

Before writing, ask the user which AI harnesses they target, via `AskUserQuestion` (multi-select):

- **Claude Code** — writes `CLAUDE.md` (default on).
- **Gemini CLI** — writes `GEMINI.md` from `templates/GEMINI.template.md`.
- **Cursor** — writes either `AGENTS.md` (a copy of `AGENT.md`; Cursor reads it natively — the simple default) **or** `.cursor/rules/project.mdc` from `templates/cursor-rules.template.mdc` (glob-scoped, `alwaysApply` — the idiomatic, scoped option). Ask which when Cursor is selected.

`AGENT.md` is always written — it is the universal source of truth every harness file imports or copies. Only emit the harness files the user selects.

## Synthesis

### The Layering note — one source of truth

`{{LAYERING_NOTE}}` appears in `AGENT.template.md`, `CLAUDE.template.md`, and
`GEMINI.template.md` so the note is defined once, here, instead of hand-maintained per harness.
Fill every occurrence with exactly this text, swapping only the `<global layer>` pointer:

> This is the **project / codebase** layer — rules that are true of *this repository*. It
> intentionally omits user/global concerns — tool preferences, autonomy level, memory,
> sub-agent strategy, and output conventions — which live in `<global layer>`. The two layers
> compose; where they conflict for work in this repo, the project layer wins.

`<global layer>` is: "the operator's own global instructions" in `AGENT.md`; "your user/global
layer (`~/.claude/CLAUDE.md`)" in `CLAUDE.md`; "your user/global layer (your personal Gemini
context / global instructions)" in `GEMINI.md`. The Cursor rule file carries the note via
`{{AGENT_BODY}}` and needs no separate copy.

### AGENT.md

Populate `templates/AGENT.template.md`:

- `{{PROJECT_SUMMARY}}` — a 2-3 sentence synthesis of `PRODUCT.md` (one-liner + register + primary user).
- `{{PRODUCT_CONTEXT}}` — bullet summary: register, primary user, jobs-to-be-done, brand personality (3 words), top 3 anti-references.
- `{{UX_LAWS}}` — extract from `DESIGN.md` UX foundation: interaction principles, accessibility commitments, top user flows (one line each).
- `{{DESIGN_LAWS}}` — extract from `DESIGN.md` UI system: color strategy + accent rules, type pairing + measure cap, motion stance, when cards are allowed.
- `{{ACCESSIBILITY_LAWS}}` — synthesize `PRODUCT.md`'s accessibility commitment (the WCAG level) with `DESIGN.md`'s UX-specific additions (keyboard, focus, reduced-motion, target sizes, reading level) into one bulleted commitment block. This is the one file every agent reads — the commitment must be visible here, not only in the briefs.
- `{{CODE_CONVENTIONS}}` — extract from `CODE.md`: stack, languages/tooling, naming, comment policy, error handling, performance budgets, security baselines.
- `{{PRODUCT_ANTI_PATTERNS}}` — embed `guardrails/product-anti-patterns.md` headlines (1 line per pattern).
- `{{UX_ANTI_PATTERNS}}` — embed `guardrails/ux-anti-patterns.md` headlines.
- `{{DESIGN_ANTI_PATTERNS}}` — embed `guardrails/design-anti-patterns.md` headlines.
- `{{CODE_ANTI_PATTERNS}}` — embed `guardrails/code-anti-patterns.md` headlines.

Anti-pattern lists must be **embedded inline** (one-line summaries), not just linked. An agent reading `AGENT.md` should see the bans without hopping files.

### CLAUDE.md

Populate `templates/CLAUDE.template.md`. The file is intentionally thin — it imports `AGENT.md` via `@AGENT.md`, carries the Layering note (see above), the available commands/skills, and:
- `{{HARNESS_PROJECT_NOTES}}` — synthesize 3-5 notes that are **specific to this repository**, not generic agent advice. Good: "Dispatch the Plan sub-agent before touching the import pipeline — it's the riskiest surface" or "This monorepo has 12 packages; scope searches to the changed one." Bad: restating Edit-over-Write or general sub-agent strategy (that's user-level). If nothing project-specific stands out, leave a single line: "No project-specific Claude notes yet."

Keep `CLAUDE.md` short. Shared rules belong in `AGENT.md`; user-level rules belong in the operator's global layer, never here.

### GEMINI.md (if Gemini CLI selected)

Populate `templates/GEMINI.template.md`. Like `CLAUDE.md` it imports `@AGENT.md` and carries the Layering note (see above). Fill `{{HARNESS_PROJECT_NOTES}}` with the same project-specific notes you wrote for `CLAUDE.md` (re-voiced for Gemini if needed). No tool/sub-agent prefs — those are user-level.

### Cursor (if Cursor selected)

- **Simple (default):** write `AGENTS.md` to the project root — a verbatim copy of `AGENT.md` with a one-line header noting it is derived; Cursor reads `AGENTS.md` natively.
- **Scoped (opt-in):** populate `templates/cursor-rules.template.mdc` and write it to `.cursor/rules/project.mdc`. Fill `{{AGENT_BODY}}` with the full body of the generated `AGENT.md` (everything below its title), and `{{HARNESS_PROJECT_NOTES}}` with the project-specific notes. Never symlink — write a copy and tell the user to re-run `/starter:orchestrate` to refresh.

## Preview & write

1. Render `AGENT.md` plus each selected harness file and show the user (collapse long sections if needed).
2. Ask for one round of edits.
3. Write `AGENT.md` and every selected harness file (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md` and/or `.cursor/rules/project.mdc`) to the project root.

## Done

Print a one-screen summary listing every file written (only the selected harnesses):
```
✓ Wrote AGENT.md ({{N}} sections, {{M}} anti-patterns embedded)
✓ Wrote CLAUDE.md (thin import of AGENT.md + {{K}} project-specific notes)
✓ Wrote GEMINI.md / AGENTS.md / .cursor/rules/project.mdc   ← only those selected

Next steps:
- Test by asking Claude to build something small in this repo. It should
  read AGENT.md before generating UI or code.
- Run /starter:validate to check the briefs for contradictions and review
  any existing code against them.
- If anything in the briefs changes, edit PRODUCT.md / DESIGN.md / CODE.md
  and re-run /starter:orchestrate.
```

## Important

- Never invent product or design context. If a brief is missing or thin, say so in the output.
- `AGENT.md` and every harness file (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, the Cursor rule) are derived files. Do not offer to "merge" edits — regenerate from briefs.
- The voice of the synthesized files should match the voice the briefs established. Don't add hedging.
