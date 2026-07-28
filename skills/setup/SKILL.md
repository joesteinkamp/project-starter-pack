---
name: setup
description: Guided end-to-end project setup — walks the Product Brief, Design Brief (with its WRITING.md companion), and Technical Brief in one sitting, then wires up AGENTS.md and CLAUDE.md. Use when the user wants to set up a new project, run the whole starter pack, or go from an empty repo to a fully-instructed AI. Triggers on "set up this project", "run the starter pack", "project setup flow", "set up the briefs", "starter setup", "onboard this repo".
---

# Setup Skill

You are running the full project starter pack, end to end. This is the mega-flow: it
takes the user from an empty repo to a fully-instructed AI in one sitting. Each step
honors its own pre-flight (reuse / merge / overwrite for the briefs; ask-before-overwrite
for the wire-up files).

## Conventions

Read `../../conventions/question-mechanics.md` first. It defines how this flow asks
structured and open questions in whatever tool you are running in, how it writes files,
and how it resolves the resource paths named below.

## Sequence

1. **Intro** — in one short paragraph, tell the user what is about to happen: three
   briefs (Product, Design + Writing, Technical), then a quick wire-up of `AGENTS.md`
   and `CLAUDE.md`. Ask whether to proceed.
   - **Brownfield check:** if the repo already contains application code (a
     `package.json`, components, styles), offer to run the `extract` flow first to
     pre-fill the briefs from the existing code, then continue the questionnaires from
     those drafts instead of from blank.
2. **Product Brief** — run the `product-brief` flow. Wait for it to complete and write
   `PRODUCT.md`.
3. **Design Brief** — run the `design-brief` flow. UX first, then UI. Wait for it to
   complete and write `DESIGN.md` (optionally `DESIGN.json`, the tokens companion) and
   `WRITING.md` (the writing companion — always).
4. **Technical Brief** — run the `code-brief` flow. Wait for it to complete and write
   `CODE.md`.
5. **Wire up** — write `AGENTS.md` and `CLAUDE.md` (see below). No harness picker:
   `AGENTS.md` is read natively by Codex, Cursor, Antigravity, and Copilot; `CLAUDE.md`
   is a thin pointer that connects Claude Code. Both are always written.

If the harness can invoke skills directly, invoke each one by name. If it cannot, read
the corresponding `../<flow>/SKILL.md` and execute it inline — the flow is the same
either way.

Between steps, give the user a one-line update so they always know where they are.

## The wire-up step

`AGENTS.md` is a **router**, not a synthesis: it points agents at the brief that owns each
kind of work (UI/UX → `DESIGN.md`, user-facing words → `WRITING.md`, product/brand →
`PRODUCT.md`, code → `CODE.md`). Because it carries no brief content, it never goes stale
and never needs regenerating when a brief changes.

### Pre-flight

- If `AGENTS.md` or `CLAUDE.md` already exists, list which and ask: overwrite or keep.
  Never overwrite silently; do not offer "merge" — these files are derived furniture.
  An `AGENTS.md` with synthesized-brief headings (`## UX laws`, `## Design laws`) is a
  legacy render from an earlier pack version — say the content it carried now lives in
  the briefs, and recommend replacing it with the router.
- **Legacy `AGENT.md`** (singular): no tool auto-reads it. Offer: replace with
  `AGENTS.md` and delete the old file (recommended), write `AGENTS.md` and leave it, or
  skip. Never delete anything the user didn't choose to delete.
- **Legacy `GEMINI.md`**: written for the retired Gemini CLI; nothing regenerates it.
  Offer: delete it (recommended), or leave it as hand-maintained.

### Fill and write

Populate `../../templates/AGENTS.template.md`:

- `{{PROJECT_SUMMARY}}` — a 2-3 sentence synthesis of `PRODUCT.md` (one-liner + register
  + primary user). If `PRODUCT.md` was deferred, leave `[TODO — run the product-brief flow]`.
- `{{REGENERATION_NOTE}}` — where the pack lives (the absolute path of the checkout you
  are reading templates from), how to start a flow per tool (Claude Code:
  `/starter:<flow>`; Codex: `$<flow>`; Cursor: `/starter-<flow>` or the skill by name;
  Antigravity and anything else: plain language), and the natural-language phrasing that
  always works. Name the flows: `setup`, `product-brief`, `design-brief`, `code-brief`,
  `validate`, `extract`. Keep it under a dozen lines — it is a pointer, not documentation.

Populate `../../templates/CLAUDE.template.md`:

- `{{HARNESS_PROJECT_NOTES}}` — 3-5 notes **specific to this repository**, drawn from the
  briefs you just wrote (riskiest surface, hard performance lines, repo layout gotchas).
  Not generic agent advice — that is user-level. If nothing stands out, a single line:
  "No project-specific Claude notes yet."

Render both, take one round of edits, then write them to the project root.

## On interruption

If the user pauses or stops mid-flow, summarize what is done and what is left, and name
the individual flows they can resume with: `product-brief`, `design-brief`, `code-brief`.
The wire-up runs automatically at the end of any brief flow if `AGENTS.md` is missing
(see "Wiring up AGENTS.md" in the conventions file), so stopping early never strands the
project without its router.

## Done

End with a final summary:

```
✓ Wrote PRODUCT.md / DESIGN.md (+ DESIGN.json) / CODE.md — the briefs, with their
  anti-pattern bans embedded
✓ Wrote WRITING.md (voice, terminology, microcopy, long-form + writing bans)
✓ Wrote AGENTS.md — the router; read natively by Codex, Cursor, and Antigravity
✓ Wrote CLAUDE.md — thin pointer connecting Claude Code

Next steps:
- Test by asking an agent to build something small in this repo. It should read
  AGENTS.md, then the brief that owns the work, before generating.
- Run the validate flow to check the briefs for contradictions.
- When a rule changes, edit the brief that owns it (or re-run its flow) —
  AGENTS.md needs no regenerating.
```

## Important

- Do not skip a brief because the user seems impatient. Offer to defer it instead, and
  say which brief files will be missing (and left as TODOs in the router's summary) if
  they do.
- Each sub-flow owns its own questions, guardrails, defaults, and preview. Don't
  re-implement them here — run the flow and let it finish.
- Never invent product or design context. If a brief is missing or thin, say so in the
  output.
