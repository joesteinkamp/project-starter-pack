---
name: project-brief
description: Walks the user through scoping a single active initiative and writes PROJECT.md at the project root. Use when the user asks to start a new initiative, scope a project, write a project brief, define goals and non-goals for a piece of work, or generate PROJECT.md. Triggers on phrases like "project brief", "PROJECT.md", "scope the project", "start a new initiative", "what are we building this sprint", "define goals and non-goals".
---

# Project Brief Skill

You are running the Project Brief flow. Your job is to walk the user through an opinionated questionnaire and produce `PROJECT.md` at the project root using `templates/PROJECT.template.md`.

`PROJECT.md` is **short-lived**: it scopes a single active initiative inside an existing product. The persistent context (`PRODUCT.md`, `DESIGN.md`, `CODE.md`) is the soil; `PROJECT.md` is the slice of work happening right now.

## Setup

1. Locate the plugin root (the directory containing this `skills/` folder). The questionnaire bank is at `questionnaires/project.questions.md`. The template is at `templates/PROJECT.template.md`. The anti-pattern guardrails are at `guardrails/project-anti-patterns.md`.
2. Read all three before starting so you carry the full question list and the bans into the conversation.

## Pre-flight

1. Check whether `PROJECT.md` exists at the project root.
   - **Exists** → ask the user: replace (start fresh — projects are short-lived, merging two initiatives leaks scope) or stop. Use `AskUserQuestion`. Do not offer "merge".
   - **Missing** → proceed.
2. Check whether `PRODUCT.md`, `DESIGN.md`, and `CODE.md` exist. If any are missing, tell the user which and name the matching command (`/starter:product-brief`, `/starter:design-brief`, `/starter:code-brief`). Ask whether to proceed with TODOs in the scope-slice sections or stop and run the missing brief first.

## Pass 1 — Structured questions (AskUserQuestion)

Ask Q1–Q3 from `questionnaires/project.questions.md` using `AskUserQuestion`. Batch them in one call.

## Pass 2 — Open follow-ups

Ask Q4–Q11 from the questionnaire as free-form chat prompts. Ask one or two at a time — don't drown the user. Wait for answers before continuing.

When asking about scope slice (Q8, Q9), reference the actual section headings in `DESIGN.md` and `CODE.md` if they exist — give the user a menu rather than asking them to remember.

## Validation pass

Apply `guardrails/project-anti-patterns.md` to what the user gave you:
- If the goal reads as an output ("ship X"), push back once and ask what changes for users or the business.
- If non-goals are missing or generic ("keep it small"), ask for concrete exclusions — name actual adjacent work being refused.
- If success metrics duplicate `PRODUCT.md` wholesale, ask which subset is realistic inside this project's time horizon.
- If a constraint has no reason behind it, ask for the reason; if there isn't one, drop the constraint.
- If the scope slice names every section of `DESIGN.md` / `CODE.md`, push back — that isn't a project.

Be direct. The starter-pack's voice is opinionated.

## Defaults pass

For any unanswered slot, fill with the defaults table in `questionnaires/project.questions.md`. Mark each defaulted line with ` [default — confirm]` in the output so the user sees what was assumed.

## Preview & write

1. Render the populated `templates/PROJECT.template.md` and show it to the user in the chat.
2. Ask: "Write to `PROJECT.md`, or edit any section first?" Accept one round of edits.
3. Write the final file to `PROJECT.md` at the project root using the `Write` tool.

## Done

Print a one-line summary: "Wrote PROJECT.md ({{TITLE}}, status: {{STATUS}}). Re-run `/starter:orchestrate` so AGENT.md picks up the current scope."

## Important

- Do not invent answers the user didn't give. Defaults are explicit and labeled.
- This is a **replace-only** brief. There is no "merge" — projects are short-lived and merging two initiatives leaks scope.
- The decisions log starts empty. Do not pre-fill it from the conversation; decisions land as the project runs, not at brief time.
- If `PRODUCT.md` / `DESIGN.md` / `CODE.md` are missing, the scope-slice sections will be thin. That's fine — flag it in the output, don't fabricate surfaces.
