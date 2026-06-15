# Gemini Instructions

@AGENT.md

> This file imports `AGENT.md` (the universal agents.md spec) and adds Gemini-CLI-specific notes below. The shared rules live in `AGENT.md` — keep them there so every AI tool sees the same source of truth. Edit `PRODUCT.md`, `DESIGN.md`, or `CODE.md` and re-run `/starter:orchestrate` rather than hand-editing this file.

## Layering — this is the project layer

This file (and `AGENT.md`) is the **project / codebase** layer: rules true of *this repository*.
Your **user / global** layer (your personal Gemini context / global instructions) owns everything
true of *you* across every project — tool preferences, autonomy level, memory, and output
conventions. This file does **not** restate any of that; the two layers compose. Where a project
rule conflicts with a personal one, the project rule wins for work in this repo.

## Project-specific notes

{{HARNESS_PROJECT_NOTES}}
