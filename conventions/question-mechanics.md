# Question mechanics

How every starter-pack flow asks, answers, and writes — in any AI tool. Each skill
points here instead of naming one harness's tools.

## Structured questions

Where a flow says **ask as a structured question**, offer a small set of options and
let the user pick one (or several, when the flow says multi-select).

- **If the harness has a structured-question tool, use it.** Claude Code has
  `AskUserQuestion`; batch independent questions into a single call.
- **If it doesn't** — Codex, Cursor, and Antigravity have no such tool — print the
  question and its options as a numbered list in chat and accept either a number or
  free text. Batch the same way: two to four related questions at once, labelled
  `1a`, `1b`, … so the user can answer them in one message.

The rules are identical either way: every option carries a one-line note on what it
commits the project to, and the user may always answer with something not on the list.

## Open questions

Free-form prompts in chat. Ask one or two at a time and wait for the answer before
continuing. Never dump the whole list at once.

## Writing files

Where a flow says **write the file**, use whichever file-writing tool the harness
provides. Always render the content in the conversation first and take one round of
edits before writing.

## Resource paths

Paths a skill names — `questionnaires/…`, `templates/…`, `guardrails/…`,
`conventions/…` — are relative to the **pack root**, which is two directories above
the skill's own `SKILL.md`: `../../questionnaires/product.questions.md` from
`skills/product-brief/SKILL.md`.

Resolve them that way rather than hunting for a "plugin root". Installation symlinks
whole skill directories into each tool's skills folder, and `../../` resolves through
the symlink back into the pack checkout.

## Naming a flow

Flows are named, not slash-prefixed: `setup`, `product-brief`, `design-brief`,
`code-brief`, `validate`, `extract`. When telling the user to run the
next one, name the flow — the invocation syntax differs per tool and the pack's README
carries the table.

## Wiring up AGENTS.md

`AGENTS.md` is the project's routing file — near-static, generated once. Every brief flow
ends by making sure it exists, so a single-flow run in a fresh repo never strands the
project without its router. If `AGENTS.md` is **missing** at the project root when a flow
finishes:

1. Write it from `templates/AGENTS.template.md` (resolved per Resource paths above).
   Fill the project summary from `PRODUCT.md`'s one-liner if that file exists, else leave
   `[TODO — run the product-brief flow]`. Fill the maintenance note with the pack's
   absolute path on disk and the per-tool ways to start a flow.
2. Write `CLAUDE.md` from `templates/CLAUDE.template.md` the same way — it is a thin
   pointer importing `AGENTS.md`. Unless something repo-specific stands out, its notes
   slot reads "No project-specific Claude notes yet."

If either file already **exists**, leave it alone here — the `setup` flow's wire-up step
owns regeneration, and it always asks before overwriting.
