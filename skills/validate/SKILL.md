---
name: validate
description: Reviews a project against its own PRODUCT.md, DESIGN.md, DESIGN.json, and CODE.md briefs and the anti-pattern guardrails. Use when the user asks to validate or check the briefs, find contradictions between them, audit the repo or a diff against the design/product/code rules, or hunt for anti-patterns in the codebase. Triggers on "validate the briefs", "check for contradictions", "review against DESIGN.md", "audit the code against the briefs", "find anti-patterns in the repo", "/starter:validate".
---

# Validate Skill

You run a **brief-aware** review. Unlike a generic code review, every finding is justified
against *this project's* briefs (`PRODUCT.md`, `DESIGN.md`, `DESIGN.json`, `CODE.md`) and the
four anti-pattern registries. There are two modes; run both unless the user scopes you to one.

This skill is **read-only**. Report findings; never edit unless the user explicitly asks.

## Setup

1. Locate the plugin root. Guardrails are at `guardrails/{product,ux,design,code}-anti-patterns.md`.
2. Read the four guardrail files so you can cite specific bans by name.
3. Read the project briefs from the project root: `PRODUCT.md`, `DESIGN.md`, `DESIGN.json` (if present), `CODE.md`.

## Inputs

If a brief is missing, say so and name the command that writes it (`/starter:product-brief`,
`/starter:design-brief`, `/starter:code-brief`). Run Mode A on whatever briefs exist; skip a
cross-check whose brief is absent rather than inventing the missing side.

## Mode A — Brief consistency

Read the briefs against *each other* and report contradictions. Check at least this matrix:

| Pair | Contradiction to look for |
|---|---|
| Motion (DESIGN) vs performance budget (CODE) | "expressive" motion or heavy transitions against a strict bundle/INP budget; animations on the critical path the perf budget protects. |
| Brand register & voice (PRODUCT) vs microcopy/UI voice (DESIGN) | a "decisive, no-hedging" voice paired with hedging or gamified copy; register `product` but a marketing-brand visual system (or vice versa). |
| Stack vs hosting (CODE) | runtime/library choices that the chosen host can't run (e.g. a Node-only dependency on an edge/Workers target); database choice vs hosting region/latency claims. |
| Accessibility baseline (PRODUCT) vs color tokens (DESIGN / DESIGN.json) | stated WCAG level vs foreground/background and accent contrast that wouldn't pass it. Compute the contrast, don't eyeball it. |
| Color strategy (DESIGN) vs the actual tokens | "Restrained — one accent on ≤10%" vs a palette that ships several saturated accents. |
| Component primitives (DESIGN) vs the "no nested cards" guardrail | primitives or layouts that imply cards inside cards, or contradict the brief's own stated bans. |
| Success metrics (PRODUCT) vs UX success metrics (DESIGN) | metrics that pull in opposite directions (e.g. "calm, no engagement nudges" vs an engagement/streak metric). |

Output a table: `brief:section — the contradiction — suggested resolution`.

## Mode B — Code / UI vs briefs

Only if the repo contains application code. Use the `git diff` scope from the command when one
is present; otherwise review the whole tree. **Dispatch a parallel review team** — one subagent
per lens, each handed the relevant brief sections and guardrail file:

- **Product / Brand** — user-facing copy vs `PRODUCT.md` register, voice, and `product-anti-patterns.md`.
- **UX** — flows, empty/error/loading states, focus & keyboard reachability vs `DESIGN.md` UX foundation and `ux-anti-patterns.md`.
- **UI / Design** — raw hex where `DESIGN.json` requires OKLCH, banned patterns (nested cards, default shadows, bounce easing, gradient text…), hard-coded spacing vs the token scale, measure cap — vs `DESIGN.md` UI system and `design-anti-patterns.md`.
- **Code** — conventions, error handling, performance budgets, security vs `CODE.md` and `code-anti-patterns.md`.

Each subagent returns concrete findings as `file:line — what's wrong — which brief/guardrail it violates — suggested fix`. Then **dedupe** overlapping findings, **group** by lens, and **sort** by impact (a broken top-flow or a security/accessibility line beats a style nit).

## Done

Print a one-screen summary, contradictions first:

```
Brief consistency (Mode A): {{N}} contradictions
  - …

Code vs briefs (Mode B): {{M}} findings  ·  {{H}} high · {{Me}} medium · {{L}} low
  HIGH
    - path:line — finding — fix
  …

Nothing was changed. Tell me which findings to fix and I'll apply them.
```

## Important

- Read-only. Never edit during a validate run; only report.
- Every finding must cite a brief section or a named guardrail — no generic advice that isn't anchored in this project's rules.
- If the briefs themselves are thin or missing, surface that as the first finding (an agent can't follow rules that were never written).
- This is the project's brief-aware check; the operator's global instructions may also define a generic review pass — they complement, they don't replace this one.
