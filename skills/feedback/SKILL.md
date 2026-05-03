---
name: feedback
description: Takes corrective feedback on a generated brief (PRODUCT.md, DESIGN.md, CODE.md, PROJECT.md, AGENTS.md, CLAUDE.md) and proposes a focused edit to the affected md file(s). Use when the user says a generated file is wrong, missing detail, contradicts reality, has the wrong tone, or contains a stale anti-pattern. Triggers on phrases like "fix PRODUCT.md", "this brief is wrong", "give feedback on DESIGN.md", "PROJECT.md scope is off", "AGENTS.md is missing X", "the generated CLAUDE.md got Y wrong".
---

# Feedback Skill

You take corrective feedback on a brief that the starter-pack already generated and turn it into a focused edit on the affected file(s). You do **not** journal feedback for later — every run ends in either an applied edit or a clear reason it wasn't applied.

## Setup

1. Locate the plugin root. The templates are at `templates/{PRODUCT,DESIGN,CODE,PROJECT,AGENT,CLAUDE}.template.md` and the guardrails are at `guardrails/{product,ux,design,code,project}-anti-patterns.md`. You may need to read them later to ground a proposed edit in the same voice the generator used.
2. Identify which generated briefs exist at the project root: `PRODUCT.md`, `DESIGN.md`, `CODE.md`, `PROJECT.md`, `AGENTS.md`, `CLAUDE.md`. If none exist, stop and tell the user to run `/starter:setup` first.

## Pass 1 — Locate the problem (AskUserQuestion)

Ask both questions in a single `AskUserQuestion` call.

**Q1. Which file is the feedback about?**
Choices: `PRODUCT.md`, `DESIGN.md`, `CODE.md`, `PROJECT.md`, `AGENTS.md`, `CLAUDE.md`, `Multiple / not sure`.
- Allow multi-select.
- If the user picks `Multiple / not sure`, you'll narrow it down in Pass 2 from the symptom.

**Q2. What's the issue?**
Choices:
- `Missing — a section or detail that should be there isn't`
- `Wrong — contradicts reality, the stack, or another brief`
- `Vague — technically present but useless as guidance`
- `Wrong tone or voice — hedges, generic, off-brand`
- `Wrong stance — the opinion encoded is the wrong one for this project`
- `Stale anti-pattern — a ban that doesn't apply, or a missing one that should`
- `Other`

## Pass 2 — Pin it down (open chat)

Ask, in order, only the prompts that are still open:

1. **Where in the file?** A section heading, a quoted line, or "general / structural" if the issue spans the whole file.
2. **What would correct look like?** One to three sentences. If the user is uncertain, ask for the symptom in their actual code or product instead — that's enough to draft a fix.

If the user picked `Multiple / not sure` in Q1, use the location + symptom to narrow to one or two files. Confirm the narrowed set before continuing.

## Diagnose — derived vs source

`AGENTS.md` and `CLAUDE.md` are **derived** from `PRODUCT.md`, `DESIGN.md`, `CODE.md`, and (when present) `PROJECT.md`. If the affected file is one of those:

- Read the relevant source brief(s).
- Decide whether the root cause is in the derived file or in the source brief:
  - If the source brief already has the right content and the derived file dropped it or distorted it → edit the derived file directly and note that the source brief was correct.
  - If the source brief is itself wrong → edit the source brief, then offer to re-run `/starter:orchestrate` to regenerate `AGENTS.md` and `CLAUDE.md`.
  - If both are wrong → edit both, source first.

`PROJECT.md` is itself a source brief (per-initiative). Feedback that's actually about scope, non-goals, success metrics for the current initiative, or the decisions log usually points there — even if the user reported it against `AGENTS.md`.

State the diagnosis to the user in one line before drafting the edit.

## Draft the edit

1. Read the target file(s) you'll be editing.
2. Locate the smallest section that needs to change. Section-scoped edits beat whole-file rewrites.
3. Draft a replacement for that section in the same voice as the rest of the file (opinionated, specific, no hedging). Match the existing heading style and bullet density.
4. If the user's "correct" answer was thin, fill the rest from the relevant template + guardrail file rather than inventing.
5. If the fix touches an anti-pattern list, ground each line in the matching `guardrails/*.md` file — don't invent new bans.

## Preview & apply

1. Show the user the diff (old section → new section, per file). Cap each side at ~25 lines per section; truncate with a note if longer.
2. Ask: "Apply this edit, edit further first, or cancel?"
3. On apply, use the `Edit` tool against the target file(s). Use `replace_all: false` and pass enough surrounding context that the match is unique.
4. If a derived file was edited but the source brief was the actual cause, finish with: "Run `/starter:orchestrate` to regenerate `AGENTS.md` and `CLAUDE.md` from the updated source brief?" and act on the answer.

## Done

Print a one-screen summary:

```
✓ Edited {{FILE}} ({{SECTION}})
{{IF_DERIVED_BUT_SOURCE_FIXED}}
✓ Edited source brief {{SOURCE_FILE}} ({{SOURCE_SECTION}})
↻ Re-ran /starter:orchestrate to regenerate AGENTS.md and CLAUDE.md
{{END_IF}}

Diagnosis: {{ONE_LINE}}

If this looks like a recurring pattern in the plugin's templates,
questionnaires, or guardrails, run /starter:report-issue to send the
feedback upstream so the generator gets better.
```

## Important

- Never silently rewrite a section the user didn't flag. Stay scoped to what they reported.
- Never invent product or stack facts. If the "correct" answer requires information you don't have, ask one targeted question rather than guessing.
- If the user describes a problem that isn't actually in the file (you read it and the section already covers what they're asking for), say so — quote the line and ask whether the issue is elsewhere.
- Don't lecture about anti-patterns. The user already ran the brief; the goal here is repair, not re-education.
- If the user is running this inside another flow (e.g. `/starter:setup`), still complete the edit — the briefs are independent files and an in-flight setup doesn't block fixes to ones already written.
