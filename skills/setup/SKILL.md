---
name: setup
description: Guided project setup — runs the starter-pack briefs, then wires up AGENTS.md and CLAUDE.md. Scoped at the start: everything (Product Brief, Design Brief with its WRITING.md companion, Technical Brief) or just the brief(s) the user picks. Use when the user wants to set up a new project, run the whole starter pack, go from an empty repo to a fully-instructed AI, or fill in a brief a set-up project is still missing. Triggers on "set up this project", "run the starter pack", "project setup flow", "set up the briefs", "starter setup", "onboard this repo".
---

# Setup Skill

You are running the project starter pack. At full scope it is the mega-flow: it takes the
user from an empty repo to a fully-instructed AI in one sitting. Scoped to a single brief,
it runs that one flow and still leaves the project wired. Each step honors its own
pre-flight (reuse / merge / overwrite for the briefs; ask-before-overwrite for the wire-up
files).

## Conventions

Read `../../conventions/question-mechanics.md` first. It defines how this flow asks
structured and open questions in whatever tool you are running in, how it writes files,
and how it resolves the resource paths named below.

## Step 0 — Scope

Settle what this run covers before saying anything else.

**If the request that started this flow named a scope**, take it and skip the question:

| Named | Runs |
|---|---|
| `product` | Product Brief |
| `design` | Design Brief — UX + UI, the `WRITING.md` companion, optionally `DESIGN.json` |
| `code` | Technical Brief |
| `all` | all three, in brief order |

Anything else — no scope named, or a word not in that table — falls through to the
question below. Never guess at a synonym.

**Otherwise, ask as a structured question:** *"What should we run?"* First check which
briefs already exist at the project root (`PRODUCT.md`, `DESIGN.md`, `CODE.md`) and
annotate each option with what you found — "`PRODUCT.md` exists; its flow will offer
reuse / merge / overwrite".

- **Everything** — the three briefs, then the wire-up. Recommend this when no brief exists.
- **Product brief** — writes `PRODUCT.md`.
- **Design brief** — writes `DESIGN.md`, the `WRITING.md` companion (always), and
  optionally `DESIGN.json`.
- **Technical brief** — writes `CODE.md`.

Multi-select where the harness supports it, so "product + technical" is one run;
single-select where it doesn't — "Everything" covers the common multi case. When some
briefs exist and others don't, recommend the missing ones rather than Everything.

The wire-up is not one of the options: it runs at the end of every scope.

## Sequence

1. **Intro** — in one short paragraph, tell the user what is about to happen: name only
   the briefs the chosen scope includes, then the quick wire-up of `AGENTS.md` and
   `CLAUDE.md`. Ask whether to proceed.
   - **Brownfield check:** if the repo already contains application code (a
     `package.json`, components, styles) *and* the scope includes a brief that does not
     exist yet, offer to run the `extract` flow first to pre-fill those briefs from the
     existing code, then continue the questionnaires from those drafts instead of from
     blank.
2. **Product Brief** — if in scope, run the `product-brief` flow. Wait for it to complete
   and write `PRODUCT.md`.
3. **Design Brief** — if in scope, run the `design-brief` flow. UX first, then UI. Wait
   for it to complete and write `DESIGN.md` (optionally `DESIGN.json`, the tokens
   companion) and `WRITING.md` (the writing companion — always).
4. **Technical Brief** — if in scope, run the `code-brief` flow. Wait for it to complete
   and write `CODE.md`.
5. **Wire up** — always, whatever the scope. Write `AGENTS.md` and `CLAUDE.md` (see
   below). No harness picker: `AGENTS.md` is read natively by Codex, Cursor, Antigravity,
   and Copilot; `CLAUDE.md` is a thin pointer that connects Claude Code. Both are always
   written. The step is idempotent — it fills two slots and writes two derived files —
   which is what keeps a single-brief run from leaving the router stale.

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
  are reading templates from), how to start a flow per tool, and the natural-language
  phrasing that always works. Name the flows: `setup`, `product-brief`, `design-brief`,
  `code-brief`, `validate`, `extract`. The three brief flows have no command of their own
  in any tool — reach one by name, or through `setup` with its scope word (Claude Code:
  `/starter:setup design`, plus `/starter:extract` and `/starter:validate`; Codex:
  `$<flow>`, which runs any skill directly; Cursor: `/starter-setup design`, or the skill
  by name; Antigravity and anything else: plain language). Keep it under a dozen lines —
  it is a pointer, not documentation.

Populate `../../templates/CLAUDE.template.md`:

- `{{HARNESS_PROJECT_NOTES}}` — 3-5 notes **specific to this repository**, drawn from the
  briefs you just wrote (riskiest surface, hard performance lines, repo layout gotchas).
  Not generic agent advice — that is user-level. If nothing stands out, a single line:
  "No project-specific Claude notes yet."

Render both, take one round of edits, then write them to the project root.

## On interruption

If the user pauses or stops mid-flow, summarize what is done and what is left, and give
the resume path for each remaining brief: run `setup` again and pick it at the scope step
(or run that flow by name — `product-brief`, `design-brief`, `code-brief` — in a tool that
invokes skills directly). The wire-up runs automatically at the end of any brief flow if
`AGENTS.md` is missing (see "Wiring up AGENTS.md" in the conventions file), so stopping
early never strands the project without its router.

## Done

End with a final summary. List only the files this run actually wrote, then every brief
still missing with the way to get it:

```
✓ Wrote PRODUCT.md / DESIGN.md (+ DESIGN.json) / CODE.md — the briefs, with their
  anti-pattern bans embedded
✓ Wrote WRITING.md (voice, terminology, microcopy, long-form + writing bans)
✓ Wrote AGENTS.md — the router; read natively by Codex, Cursor, and Antigravity
✓ Wrote CLAUDE.md — thin pointer connecting Claude Code

Still missing: CODE.md — run setup again and pick the technical brief (or run the
code-brief flow by name, in a tool that invokes skills directly).

Next steps:
- Test by asking an agent to build something small in this repo. It should read
  AGENTS.md, then the brief that owns the work, before generating.
- Run the validate flow to check the briefs for contradictions.
- When a rule changes, edit the brief that owns it (or re-run its flow) —
  AGENTS.md needs no regenerating.
```

## Important

- Do not skip a brief the scope includes because the user seems impatient. Offer to defer
  it instead, and say which brief files will be missing (and left as TODOs in the router's
  summary) if they do. A brief left out by the scope step is a choice, not a skip — report
  it under "Still missing", don't re-litigate it.
- Each sub-flow owns its own questions, guardrails, defaults, and preview. Don't
  re-implement them here — run the flow and let it finish.
- Never invent product or design context. If a brief is missing or thin, say so in the
  output.
