---
description: Guided one-sitting setup — Product Brief, Design Brief, Technical Brief, then orchestration
---

Run the full project starter pack flow end to end.

This is the mega command. It walks the user from an empty repo to a fully-instructed AI in one sitting. Each step honors its own pre-flight (reuse / merge / overwrite for the briefs; overwrite-only for the orchestrator output).

## Sequence

1. **Intro** — In one short paragraph, tell the user what's about to happen: three briefs (Product, Design, Technical), then synthesis into `AGENT.md` and `CLAUDE.md`. Ask whether to proceed.
2. **Product Brief** — invoke the `product-brief` skill. Wait for it to complete and write `PRODUCT.md`.
3. **Design Brief** — invoke the `design-brief` skill. UX first, then UI. Wait for it to complete and write `DESIGN.md` (and optionally `DESIGN.json` as the tokens companion).
4. **Technical Brief** — invoke the `code-brief` skill. Wait for it to complete and write `CODE.md`.
5. **Orchestrate** — invoke the `orchestrator` skill. Synthesize `AGENT.md` and `CLAUDE.md`.
6. **Validate (optional)** — once `AGENT.md` and `CLAUDE.md` are written, ask the user once: "Run `/starter:validate` to cross-check the briefs for contradictions and anti-pattern hits?" Default: yes. If they accept, invoke the `validator` skill. If they decline, skip and remind them they can run it later.

Between steps, give the user a one-line update so they always know where they are in the flow.

## On interruption

If the user pauses or stops mid-flow, summarize what's done and what's left, and remind them of the individual commands they can resume with:
- `/starter:product-brief`
- `/starter:design-brief`
- `/starter:code-brief`
- `/starter:orchestrate`
- `/starter:validate`

## Done

End with a final summary listing every file written and a "next steps" line: test the AI's output by asking it to build something small in the project — it should now read `AGENT.md` and `CLAUDE.md` first and respect the briefs.
