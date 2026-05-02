---
description: Guided one-sitting setup — Product Brief, Design Brief, Technical Brief, then orchestration
---

Run the full project starter pack flow end to end.

This is the mega command. It walks the user from an empty repo to a fully-instructed AI in one sitting. Each step honors its own pre-flight (reuse / merge / overwrite for the briefs; overwrite-only for the orchestrator output).

## Sequence

1. **Intro** — In one short paragraph, tell the user what's about to happen: three briefs (Product, Design, Technical), then synthesis into `AGENTS.md` and `CLAUDE.md`. Ask whether to proceed. If existing `PRODUCT.md`, `DESIGN.md`, `CODE.md`, `AGENTS.md`, or `CLAUDE.md` are detected, mention that each step will offer reuse/merge/overwrite for its file.
2. **Product Brief** — invoke the `product-brief` skill. Wait for it to complete and write `PRODUCT.md`.
3. **Design Brief** — invoke the `design-brief` skill. UX first, then UI. Wait for it to complete and write `DESIGN.md` in the [joesteinkamp/design.md](https://github.com/joesteinkamp/design.md) format (YAML token front matter + canonical-order markdown body).
4. **Technical Brief** — invoke the `code-brief` skill. Wait for it to complete and write `CODE.md`.
5. **Orchestrate** — invoke the `orchestrator` skill. Synthesize `AGENTS.md` (per [joesteinkamp/agents-md](https://github.com/joesteinkamp/agents-md)) and `CLAUDE.md`.

Between steps, give the user a one-line update so they always know where they are in the flow.

## On interruption

If the user pauses or stops mid-flow, summarize what's done and what's left, and remind them of the individual commands they can resume with:
- `/starter:product-brief`
- `/starter:design-brief`
- `/starter:code-brief`
- `/starter:orchestrate`

## Done

End with a final summary listing every file written and a "next steps" line: test the AI's output by asking it to build something small in the project — it should now read `AGENTS.md` and `CLAUDE.md` first and respect the briefs.
