---
name: setup
description: Guided end-to-end project setup — walks the Product Brief, Design Brief, and Technical Brief in one sitting, then synthesizes AGENTS.md, WRITING.md, and the selected harness files. Use when the user wants to set up a new project, run the whole starter pack, or go from an empty repo to a fully-instructed AI. Triggers on "set up this project", "run the starter pack", "project setup flow", "set up the briefs", "starter setup", "onboard this repo".
---

# Setup Skill

You are running the full project starter pack, end to end. This is the mega-flow: it
takes the user from an empty repo to a fully-instructed AI in one sitting. Each step
honors its own pre-flight (reuse / merge / overwrite for the briefs; overwrite-only for
the orchestrator's derived output).

## Conventions

Read `../../conventions/question-mechanics.md` first. It defines how this flow asks
structured and open questions in whatever tool you are running in, how it writes files,
and how it resolves the resource paths named below.

## Sequence

1. **Intro** — in one short paragraph, tell the user what is about to happen: three
   briefs (Product, Design, Technical), then synthesis into `AGENTS.md`, `WRITING.md`,
   and the harness files they select. Ask whether to proceed.
   - **Brownfield check:** if the repo already contains application code (a
     `package.json`, components, styles), offer to run the `extract` flow first to
     pre-fill the briefs from the existing code, then continue the questionnaires from
     those drafts instead of from blank.
2. **Product Brief** — run the `product-brief` flow. Wait for it to complete and write
   `PRODUCT.md`.
3. **Design Brief** — run the `design-brief` flow. UX first, then UI. Wait for it to
   complete and write `DESIGN.md` (and optionally `DESIGN.json`, the tokens companion).
4. **Technical Brief** — run the `code-brief` flow. Wait for it to complete and write
   `CODE.md`.
5. **Orchestrate** — run the `orchestrator` flow. Synthesize `AGENTS.md`, `WRITING.md`,
   and the selected harness files.

If the harness can invoke skills directly, invoke each one by name. If it cannot, read
the corresponding `../<flow>/SKILL.md` and execute it inline — the flow is the same
either way.

Between steps, give the user a one-line update so they always know where they are.

## On interruption

If the user pauses or stops mid-flow, summarize what is done and what is left, and name
the individual flows they can resume with: `product-brief`, `design-brief`, `code-brief`,
`orchestrator`.

## Done

End with a final summary listing every file written, then a next-steps line: test the
AI's output by asking it to build something small in the project — it should now read
`AGENTS.md` (and its harness file) first and respect the briefs.

## Important

- Do not skip a brief because the user seems impatient. Offer to defer it instead, and
  say which sections of `AGENTS.md` will be left as TODOs if they do.
- Each sub-flow owns its own questions, guardrails, defaults, and preview. Don't
  re-implement them here — run the flow and let it finish.
