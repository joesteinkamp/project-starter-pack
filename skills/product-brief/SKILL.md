---
name: product-brief
description: Walks the user through a product positioning brief and writes PRODUCT.md at the project root. Use when the user asks to set up product context, write a product brief, define brand or positioning, or generate PRODUCT.md. Triggers on phrases like "product brief", "PRODUCT.md", "set up product context", "brand positioning", "who is this product for".
---

# Product Brief Skill

You are running the Product Brief flow. Your job is to walk the user through an opinionated questionnaire and produce `PRODUCT.md` at the project root using `../../templates/PRODUCT.template.md`.

## Conventions

Read `../../conventions/question-mechanics.md` first. It defines how this flow asks structured and open questions in whatever tool you are running in, how it writes files, and how it resolves the resource paths below.

## Setup

1. The questionnaire bank is at `../../questionnaires/product.questions.md`. The template is at `../../templates/PRODUCT.template.md`. The anti-pattern guardrails are at `../../guardrails/product-anti-patterns.md`.
2. Read all three before starting so you carry the full question list and the bans into the conversation.

## Pre-flight

Check whether `PRODUCT.md` exists at the project root.
- **Exists** → ask the user: reuse (skip the flow), merge (run the questionnaire and merge new answers into existing sections), or overwrite (start fresh). Ask this as a structured question.
- **Missing** → proceed.

## Pass 1 — Structured questions

Ask Q1–Q4 from `../../questionnaires/product.questions.md` as structured questions. Batch them where the questions are independent.

## Pass 2 — Open follow-ups

Ask Q5–Q11 from the questionnaire as free-form chat prompts. Ask one or two at a time — don't drown the user. Wait for answers before continuing.

## Validation pass

Apply `../../guardrails/product-anti-patterns.md` to what the user gave you:
- If the persona is generic ("developers who want better tools"), push back once and ask for specificity.
- If anti-references are abstract ("not boring"), ask for real product/site names.
- If brand personality is three buzzwords ("modern, clean, friendly"), ask for the proof — how does it show up in copy?

Be direct. The starter-pack's voice is opinionated.

## Defaults pass

For any unanswered slot, fill with the defaults table in `../../questionnaires/product.questions.md`. Mark each defaulted line with ` [default — confirm]` in the output so the user sees what was assumed. Always pull the anti-pattern list from `../../guardrails/product-anti-patterns.md` into `{{PRODUCT_ANTI_PATTERNS}}` — embedded inline, not just linked. **Keep each ban's ID** (`PRD-03`) in the rendered line: it is what lets a later review cite the ban by name. Render the prose only — the `.detect.md` sidecar is machine state and never goes into a brief.

## Preview & write

1. Render the populated `../../templates/PRODUCT.template.md` and show it to the user in the chat.
2. Ask: "Write to `PRODUCT.md`, or edit any section first?" Accept one round of edits.
3. Write the final file to `PRODUCT.md` at the project root.

## Done

Print a one-line summary: "Wrote PRODUCT.md ({{N}} sections, {{M}} defaults marked for confirmation). Next: the `design-brief` flow."

Then, if `AGENTS.md` is missing at the project root, follow "Wiring up AGENTS.md" in
`../../conventions/question-mechanics.md` so the routing file exists even outside the `setup` flow.

## Important

- Do not invent answers the user didn't give. Defaults are explicit and labeled.
- Do not vendor prose from the inspiration repo. The voice and structure are ours.
- If you are running inside the `setup` flow, hand control back to it when done — do not invoke the next brief yourself.
