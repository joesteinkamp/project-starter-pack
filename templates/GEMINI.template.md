# Gemini Instructions

@AGENT.md

> This file imports `AGENT.md` (the universal agents.md spec) and adds Gemini-CLI-specific notes below. The shared rules live in `AGENT.md` — keep them there so every AI tool sees the same source of truth. Edit `PRODUCT.md`, `DESIGN.md`, or `CODE.md` and re-run `/starter:orchestrate` rather than hand-editing this file.

## Layering — this is the project layer

{{LAYERING_NOTE}}

## Project-specific notes

{{HARNESS_PROJECT_NOTES}}

## Regenerating these instructions

The briefs (`PRODUCT.md`, `DESIGN.md`, `CODE.md`) and this file are maintained with the `project-starter-pack` tooling, whose `/starter:*` commands run in Claude Code — they are not available in this harness. To regenerate: edit the briefs and run `/starter:orchestrate` from Claude Code, or follow the pack's `questionnaires/` and `templates/` by hand.
