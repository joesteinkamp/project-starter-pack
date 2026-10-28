---
name: setup
description: Guided project setup — runs the starter-pack briefs, then wires up AGENTS.md and CLAUDE.md. Scoped at the start to everything (Product Brief, Design Brief with its WRITING.md companion, Technical Brief) or just the brief(s) the user picks. Use when the user wants to set up a new project, run the whole starter pack, go from an empty repo to a fully-instructed AI, or fill in a brief a set-up project is still missing. Triggers on "set up this project", "run the starter pack", "project setup flow", "set up the briefs", "starter setup", "onboard this repo".
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
| `evals` | Evals only — seeds `evals/` from the briefs that already exist |
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

- **Evals only** — seeds or refreshes `evals/` from whichever briefs exist, without
  re-running any questionnaire. Recommend it when at least one brief exists but
  `evals/cases.md` does not: it is how a project set up before evals existed gets them.

The evals and wire-up steps are not options: they run at the end of every scope.

## Sequence

1. **Intro** — in one short paragraph, tell the user what is about to happen: name only
   the briefs the chosen scope includes, then seeding `evals/` from them and the quick
   wire-up of `AGENTS.md` and `CLAUDE.md`. Ask whether to proceed.
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
5. **Evals** — always, whatever the scope. Seed `evals/` from the briefs that exist (see
   "The evals step" below).
6. **Wire up** — always, whatever the scope. Write `AGENTS.md` and `CLAUDE.md` (see
   below). No harness picker: `AGENTS.md` is read natively by Codex, Cursor, Antigravity,
   and Copilot; `CLAUDE.md` is a thin pointer that connects Claude Code. Both are always
   written. The step is idempotent — it fills two slots and writes two derived files —
   which is what keeps a single-brief run from leaving the router stale.

If the harness can invoke skills directly, invoke each one by name. If it cannot, read
the corresponding `../<flow>/SKILL.md` and execute it inline — the flow is the same
either way.

Between steps, give the user a one-line update so they always know where they are.

## The evals step

`evals/` is how this project checks that agents working in it follow its briefs. Each case
is one brief rule, a prompt that tests it, and a pass/fail pair of examples (goldens). The
runner is a script that lives in the project, so its CI needs nothing from this pack.

### Pre-flight

- **No `evals/` yet:** copy `../../templates/evals/` (`run.sh`, `cases.md`, `README.md`,
  `config`, `.gitignore`) into the project's `evals/`, keep `run.sh` executable, and put
  the project's name in the `cases.md` heading.
- **`evals/` exists:** ask merge (recommended), keep, or overwrite. Merge refreshes `run.sh`
  and `README.md` from the templates, keeps every existing case and golden exactly as it is
  — confirmed ones and ones added from corrections above all — and adds only new seeds, as
  `unconfirmed`, under the next unused IDs. Never overwrite a case without an explicit yes.

### Seed

Seed **up to 12 cases**, ranked by how much damage breaking the rule would do. More than
that never gets reviewed. Draw them only from briefs that exist on disk, and only from
confirmed text: never from a `[TODO — confirm]` line an `extract` draft left behind.

1. **Bans with a detector.** A ban the briefs embed whose entry in
   `../../guardrails/registry.json` has `kind` `regex`, `regexi` or `count` and
   `confidence` `certain` can grade itself for free, so it is a strong candidate. It still
   competes with the rules below for the 12 places, by damage. Copy the detector
   **inline**: `check: regex:<pattern>`, `check: regexi:<pattern>`, or
   `check: count:<threshold>:<pattern>`. Read the pattern decoded (`jq -r
   '."DES-03".pattern'`), never from the raw JSON text: JSON escapes `\b` as `\\b`, and
   a doubled backslash silently breaks the detector. The registry does not ship into the
   project, so a bare ban ID would not resolve in its CI.
2. **Rules that say what an agent must do,** such as DESIGN.md's interaction principles
   and component primitives, WRITING.md's terminology, PRODUCT.md's principles and
   anti-references, and CODE.md's conventions and lines it must not cross. These become
   `check: none` cases graded by their `judge:` question.

Each case follows the schema in `../../examples/saga-reader/evals/cases.md`:

- `anchor:` must be text copied exactly from `file:`, short enough to survive a light edit.
- `prompt:` is a realistic task in this project's own terms (its components, routes,
  nouns), not a generic one.
- `judge:` is one yes/no question about the outcome, never about the steps.
- `goldens/EV-NN/fail.*` shows what breaking the rule looks like in this project, and
  `pass.*` a near miss that keeps it. Use the extension of the real surface (`.css`,
  `.tsx`, `.md`).
- `status: unconfirmed` and `origin: seeded by setup <today> from <brief> (<section>)`.

**Product AI suite.** When `PRODUCT.md` or `CODE.md` describes AI the product itself
ships, also seed up to 3 `kind: product` cases for those behaviours (grounding, refusing,
the output contract the brief states). When neither does, seed none, and don't ask.

Set `agent:` in `evals/config` to the CLI this flow is running in (`claude`, `codex`,
`agy`, or `agent`), so live runs test the tool the project is actually built with.

### Confirm — one round

Show every seeded case as a numbered list: its headline, the rule it came from, and its
fail/pass pair in one line each. Ask once, as a single structured question per the
conventions file: confirm all, or name the numbers to edit or drop. Apply the answers,
flip the confirmed ones to `status: confirmed`, then run `./evals/run.sh` and fix anything
it reports before moving on. A case the user cannot judge stays `unconfirmed`: drafts
never gate.

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
  by name; Antigravity: the skill by name; anything else: plain language). List the scope
  words, `evals` included. Keep it under a
  dozen lines — it is a pointer, not documentation.

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
✓ Wrote evals/ — N cases (M confirmed); ./evals/run.sh passes

Still missing: CODE.md — run setup again and pick the technical brief (or run the
code-brief flow by name, in a tool that invokes skills directly).

Next steps:
- Test by asking an agent to build something small in this repo. It should read
  AGENTS.md, then the brief that owns the work, before generating.
- Run the validate flow to check the briefs for contradictions.
- When an agent gets something wrong here, add it to `evals/cases.md` with its fail/pass
  pair. `./evals/run.sh --live` runs the suite against a real agent (opt-in, spends tokens).
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
