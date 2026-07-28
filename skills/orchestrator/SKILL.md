---
name: orchestrator
description: Synthesizes PRODUCT.md, DESIGN.md, and CODE.md into AGENTS.md (universal agents.md) plus WRITING.md (the project's writing rules) and the optional harness files (CLAUDE.md, Cursor scoped rules) at the project root. Use when the user asks to generate or regenerate AGENTS.md, WRITING.md, CLAUDE.md, or the Cursor rules, or when all three briefs exist and the agent instructions need to be assembled. Triggers on "AGENTS.md", "AGENT.md", "WRITING.md", "CLAUDE.md", "Cursor rules", "orchestrate briefs", "generate agent instructions", "assemble project instructions".
---

# Orchestrator Skill

You assemble the three briefs into `AGENTS.md` (the [agents.md](https://agents.md) spec file) and `WRITING.md` (the project's writing rules), plus the harness files the user selects — `CLAUDE.md` and/or a scoped Cursor rule — each a thin import of `AGENTS.md` with harness-specific addenda.

## Conventions

Read `../../conventions/question-mechanics.md` first. It defines how this flow asks structured questions in whatever tool you are running in, how it writes files, and how it resolves the resource paths below.

## Setup

1. Templates are at `../../templates/AGENTS.template.md`, `../../templates/WRITING.template.md`, `../../templates/CLAUDE.template.md`, and `../../templates/cursor-rules.template.mdc`. Anti-pattern guardrails are at `../../guardrails/{product,ux,design,writing,code}-anti-patterns.md`.
2. Read `AGENTS.template.md`, `WRITING.template.md`, the templates for the harnesses in play, and all five guardrail files before starting.
3. Note the pack's own absolute path on disk — you need it for `{{REGENERATION_NOTE}}` below.

## Inputs

Read all three briefs from the project root:
- `PRODUCT.md`
- `DESIGN.md`
- `CODE.md`

If any are missing:
- Print which are missing and the flow that writes each (`product-brief`, `design-brief`, `code-brief`).
- Ask the user: proceed with placeholders for missing briefs, or stop?
- If they proceed, leave the corresponding sections in `AGENTS.md` as `[TODO — run the <brief> flow]` and continue.

## Pre-flight

Check every file this run could write: `AGENTS.md` and `WRITING.md`, plus — per the harness selection below — `CLAUDE.md` and `.cursor/rules/project.mdc`:
- If none exist, proceed.
- If any exists, list which and ask: overwrite (regenerate from briefs) or stop. A hand-written `AGENTS.md` gets the same gate as `CLAUDE.md` — never overwrite silently. Do not offer "merge" — these files are derived, not authored.

### Legacy files

Two filenames this pack used to write are now retired. Handle both in pre-flight, and never delete anything the user didn't choose to delete.

**`AGENT.md`** — the singular name earlier versions wrote. No tool auto-reads it. If it exists at the project root:

- Tell the user that `AGENTS.md` — the actual agents.md spec filename — is what Codex, Cursor, and Antigravity read automatically, and `AGENT.md` is not.
- Offer, as a structured question: regenerate as `AGENTS.md` and delete `AGENT.md` (recommended), regenerate as `AGENTS.md` and leave the old file in place, or stop.
- If they keep it, say plainly that two files will now describe the project and only one is generated.

**`GEMINI.md`** — written for the Gemini CLI, which is retired. Its successor, Antigravity, reads `AGENTS.md` natively and needs no file of its own. This pack no longer generates `GEMINI.md` or ships its template. If the file exists:

- Say why it is stale: the tool it was written for is gone, and nothing regenerates it, so it will drift from the briefs.
- Offer: delete it (recommended), or leave it and accept that it is now hand-maintained.

## Harness targets

`AGENTS.md` and `WRITING.md` are **always written**. `AGENTS.md` is the universal source of truth every harness file imports or copies; `WRITING.md` is the writing companion it points to for user-facing copy. Say so before asking, and say what it already buys the user:

> `AGENTS.md` is read automatically by **Codex, Cursor, and Antigravity** — those three are already covered and need no file of their own. The picker below is only for tools that want one.

Then ask which additional harnesses they target, as a structured multi-select question:

- **Claude Code** (default on) — writes `CLAUDE.md`, a thin `@AGENTS.md` import plus Claude-specific notes. Claude Code does not auto-read `AGENTS.md`, so this file is what connects it.
- **Cursor scoped rules** (opt-in) — writes `.cursor/rules/project.mdc` from `../../templates/cursor-rules.template.mdc`: glob-scoped and `alwaysApply`, the idiomatic Cursor form. Cursor already reads `AGENTS.md`, so this is an upgrade, not a requirement.

If the user asks about Codex or Antigravity, confirm they are supported and already done — `AGENTS.md` is their instruction file. Do not offer a Gemini CLI target; that tool is retired.

Only emit the harness files the user selects.

## Synthesis

### The Layering note — one source of truth

`{{LAYERING_NOTE}}` appears in both `AGENTS.template.md` and `CLAUDE.template.md`, so the note is
defined once, here, instead of hand-maintained per harness. Fill every occurrence with exactly this
text, swapping only the `<global layer>` pointer:

> This is the **project / codebase** layer — rules that are true of *this repository*. It
> intentionally omits user/global concerns — tool preferences, autonomy level, memory,
> sub-agent strategy, and output conventions — which live in `<global layer>`. The two layers
> compose; where they conflict for work in this repo, the project layer wins.

`<global layer>` is: "the operator's own global instructions" in `AGENTS.md`, and "your user/global
layer (`~/.claude/CLAUDE.md`)" in `CLAUDE.md`. The Cursor rule file carries the note via
`{{AGENT_BODY}}` and needs no separate copy.

### AGENTS.md

Populate `../../templates/AGENTS.template.md`:

- `{{PROJECT_SUMMARY}}` — a 2-3 sentence synthesis of `PRODUCT.md` (one-liner + register + primary user).
- `{{PRODUCT_CONTEXT}}` — bullet summary: register, primary user, jobs-to-be-done, brand personality (3 words), top 3 anti-references.
- `{{UX_LAWS}}` — extract from `DESIGN.md` UX foundation: interaction principles and top user flows (one line each). Accessibility belongs in `{{ACCESSIBILITY_LAWS}}` below — don't duplicate it here beyond a pointer.
- `{{DESIGN_LAWS}}` — extract from `DESIGN.md` UI system: color strategy + accent rules, type pairing + measure cap, motion stance, when cards are allowed.
- `{{ACCESSIBILITY_LAWS}}` — synthesize `PRODUCT.md`'s accessibility commitment (the WCAG level) with `DESIGN.md`'s UX-specific additions (keyboard, focus, reduced-motion, target sizes, reading level) into one bulleted commitment block. This is the one file every agent reads — the commitment must be visible here, not only in the briefs.
- `{{CODE_CONVENTIONS}}` — extract from `CODE.md`: stack, languages/tooling, naming, comment policy, error handling, performance budgets, security baselines.
- `{{PRODUCT_ANTI_PATTERNS}}` — embed `../../guardrails/product-anti-patterns.md` headlines (1 line per pattern).
- `{{UX_ANTI_PATTERNS}}` — embed `../../guardrails/ux-anti-patterns.md` headlines.
- `{{DESIGN_ANTI_PATTERNS}}` — embed `../../guardrails/design-anti-patterns.md` headlines.
- `{{WRITING_ANTI_PATTERNS}}` — embed `../../guardrails/writing-anti-patterns.md` headlines.
- `{{CODE_ANTI_PATTERNS}}` — embed `../../guardrails/code-anti-patterns.md` headlines.
- `{{REGENERATION_NOTE}}` — see below.

Anti-pattern lists must be **embedded inline** (one-line summaries), not just linked. An agent reading `AGENTS.md` should see the bans without hopping files.

### The regeneration note

`{{REGENERATION_NOTE}}` is what lets an agent in a harness with no command surface still run the
pack. Write it as a short block that states three things:

1. **Where the pack lives** — the absolute path of the `project-starter-pack` checkout you are
   reading templates from.
2. **How to start a flow, per tool** — Claude Code: `/starter:<flow>`; Codex: `$<flow>`; Cursor:
   `/starter-<flow>` or the skill by name; Antigravity and anything else: plain natural language.
3. **The natural-language phrasing that always works**, e.g. *"walk me through the product brief
   using the project-starter-pack questionnaire at `<path>`"* and *"re-run the project-starter-pack
   orchestrator flow at `<path>` to regenerate AGENTS.md from the briefs."*

Name the flows: `setup`, `product-brief`, `design-brief`, `code-brief`, `orchestrator`, `validate`,
`extract`. Keep it under a dozen lines — it is a pointer, not documentation.

### WRITING.md

Populate `../../templates/WRITING.template.md`. `WRITING.md` owns how words get written in the repo — button labels to long-form prose. It **defers upward** to `PRODUCT.md` for personality and register: restate them as writing directives, never duplicate the prose.

- `{{WRITING_VOICE}}` — from `PRODUCT.md`'s register and brand personality, as directives about how sentences behave (person, tense, where wit is allowed, what the voice never does).
- `{{WRITING_TERMINOLOGY}}` — the product's nouns and their exact casing (from `PRODUCT.md`'s one-liner and `DESIGN.md`'s components and flows), plus words the product never uses.
- `{{WRITING_MICROCOPY}}` — rules for labels, buttons, empty/error/loading states, confirmations — grounded in `DESIGN.md`'s component primitives and user flows. Include the casing convention and the button verb rule.
- `{{WRITING_LONGFORM}}` — structure and evidence rules for docs, onboarding, and marketing copy, consistent with the register.
- `{{WRITING_ANTI_PATTERNS}}` — embed `../../guardrails/writing-anti-patterns.md` headlines (1 line per pattern); the same embed fills the matching slot in `AGENTS.md`.

### CLAUDE.md (if Claude Code selected)

Populate `../../templates/CLAUDE.template.md`. The file is intentionally thin — it imports `AGENTS.md` via `@AGENTS.md`, carries the Layering note (see above), the available flows, and:
- `{{HARNESS_PROJECT_NOTES}}` — synthesize 3-5 notes that are **specific to this repository**, not generic agent advice. Good: "Dispatch the Plan sub-agent before touching the import pipeline — it's the riskiest surface" or "This monorepo has 12 packages; scope searches to the changed one." Bad: restating Edit-over-Write or general sub-agent strategy (that's user-level). If nothing project-specific stands out, leave a single line: "No project-specific Claude notes yet."

Keep `CLAUDE.md` short. Shared rules belong in `AGENTS.md`; user-level rules belong in the operator's global layer, never here.

### Cursor scoped rules (if selected)

Populate `../../templates/cursor-rules.template.mdc` and write it to `.cursor/rules/project.mdc`. Fill `{{AGENT_BODY}}` with the full body of the generated `AGENTS.md` (everything below its title), and `{{HARNESS_PROJECT_NOTES}}` with the project-specific notes. Never symlink — write a copy and tell the user to re-run this flow to refresh it.

## Preview & write

1. Render `AGENTS.md` and `WRITING.md` plus each selected harness file and show the user (collapse long sections if needed).
2. Ask for one round of edits.
3. Write `AGENTS.md`, `WRITING.md`, and every selected harness file (`CLAUDE.md` and/or `.cursor/rules/project.mdc`) to the project root.

## Done

Print a one-screen summary listing every file written (only the selected harnesses):
```
✓ Wrote AGENTS.md ({{N}} sections, {{M}} anti-patterns embedded)
    — read automatically by Codex, Cursor, and Antigravity
✓ Wrote WRITING.md (voice, terminology, microcopy, long-form + writing bans)
✓ Wrote CLAUDE.md (thin import of AGENTS.md + {{K}} project-specific notes)
✓ Wrote .cursor/rules/project.mdc   ← only if selected

Next steps:
- Test by asking an agent to build something small in this repo. It should
  read AGENTS.md before generating UI or code.
- Run the validate flow to check the briefs for contradictions and review
  any existing code against them.
- If anything in the briefs changes, edit PRODUCT.md / DESIGN.md / CODE.md
  and re-run this orchestrator flow.
```

## Important

- Never invent product or design context. If a brief is missing or thin, say so in the output.
- `AGENTS.md`, `WRITING.md`, and every harness file (`CLAUDE.md`, the Cursor rule) are derived files. Do not offer to "merge" edits — regenerate from briefs.
- The voice of the synthesized files should match the voice the briefs established. Don't add hedging.
