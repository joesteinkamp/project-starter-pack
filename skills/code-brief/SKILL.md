---
name: code-brief
description: Walks the user through a technical brief and writes CODE.md at the project root. Covers stack, architecture, conventions, testing, deployment, performance, and security. Use when the user asks for a technical brief, tech stack decisions, CODE.md, architecture documentation, or engineering conventions. Triggers on "code brief", "CODE.md", "tech stack", "architecture", "engineering conventions", "code conventions", "performance budget", "security baseline".
---

# Code Brief Skill

You are running the Technical Brief flow. Your job is to walk the user through technical questions and produce `CODE.md` at the project root.

## Setup

1. Locate the plugin root. The questionnaire bank is at `questionnaires/code.questions.md`. The template is at `templates/CODE.template.md`. The anti-pattern guardrails are at `guardrails/code-anti-patterns.md`.
2. Read all of them before starting.
3. If `PRODUCT.md` and/or `DESIGN.md` exist, read them — technical choices should serve product and design constraints (e.g. a strict performance budget if the design relies on motion that must stay smooth).

## Pre-flight

Check whether `CODE.md` exists at the project root.
- **Exists** → reuse / merge / overwrite via `AskUserQuestion`.
- **Missing** → proceed.

If a `package.json`, `pyproject.toml`, `Cargo.toml`, or similar exists at the project root, read it and pre-populate stack answers as suggestions to the user — don't make them retype what's already declared.

## Pass 1 — Structured

Ask Q1–Q9 from `questionnaires/code.questions.md` using `AskUserQuestion`. Batch where possible.

## Pass 2 — Open follow-ups

Ask Q10–Q16 as free-form prompts.

## Validation pass

Apply `guardrails/code-anti-patterns.md`:
- If the user describes premature abstraction layers ("we'll have a service layer that wraps a repository layer that wraps an ORM"), push back once and ask whether the abstraction is earned.
- If they request defensive programming on internal boundaries, push back.
- If they want `--no-verify` or disabled checks as a baseline, push back hard.

Also sanity-check the stack for internal consistency (e.g. Cloudflare Pages + Node-only library = mismatch).

## Defaults pass

Apply the defaults table from `questionnaires/code.questions.md`. Mark defaulted lines with ` [default — confirm]`. Always pull the anti-pattern list from `guardrails/code-anti-patterns.md` into `{{CODE_ANTI_PATTERNS}}` — embedded inline, not just linked.

## Preview & write

1. Render populated `CODE.md` and show it to the user.
2. Ask for one round of edits, then write to `CODE.md` at the project root.

## Done

"Wrote CODE.md ({{N}} sections, {{M}} defaults marked for confirmation). Next: `/starter:orchestrate` to generate AGENTS.md and CLAUDE.md."

## Important

- If a manifest file exists (`package.json` etc.), use it as ground truth for stack questions — don't ignore it.
- If you are running inside `/starter:setup`, hand control back when done.
