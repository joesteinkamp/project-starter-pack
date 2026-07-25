# Gemini Instructions

@AGENT.md

> This file imports `AGENT.md` (the universal agents.md spec) and adds Gemini-CLI-specific notes below. The shared rules live in `AGENT.md` — keep them there so every AI tool sees the same source of truth. Edit `PRODUCT.md`, `DESIGN.md`, or `CODE.md` and re-run `/starter:orchestrate` rather than hand-editing this file.

## Layering — this is the project layer

This is the **project / codebase** layer — rules that are true of *this repository*. It
intentionally omits user/global concerns — tool preferences, autonomy level, memory, sub-agent
strategy, and output conventions — which live in your user/global layer (your personal Gemini
context / global instructions). The two layers compose; where they conflict for work in this
repo, the project layer wins.

## Project-specific notes

- The **import pipeline** (`import/`, EPUB.js + pdf.js) is the riskiest surface — plan before changing it, and never run parsers with network access.
- The **highlight anchor-matcher** and **sync merge** logic must keep their tests green; treat a dropped highlight anchor on re-import as a release blocker.
- Reading-path performance is a hard limit: keep parsers lazy-loaded, never import EPUB.js/pdf.js on the Reader route.
- The codebase is grouped by feature (`library/`, `reader/`, `marks/`, `import/`, `sync/`) — scope changes to the relevant feature folder.

## Regenerating these instructions

The briefs (`PRODUCT.md`, `DESIGN.md`, `CODE.md`) and this file are maintained with the `project-starter-pack` tooling, whose `/starter:*` commands run in Claude Code — they are not available in this harness. To regenerate: edit the briefs and run `/starter:orchestrate` from Claude Code, or follow the pack's `questionnaires/` and `templates/` by hand.
