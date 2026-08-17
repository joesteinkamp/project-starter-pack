# Agent Instructions

> This file is the entry point for any AI coding agent working in this repository. It follows the [agents.md](https://agents.md) convention, so Codex, Cursor, Antigravity, Copilot, and anything else that honors the spec read it automatically; Claude Code reaches it through `CLAUDE.md`. It is generated once by `project-starter-pack` and then routes to the briefs — when a rule changes, edit the brief that owns it; this file does not need regenerating.

> **Layering:** This is the **project / codebase** layer — rules that are true of *this repository*. It intentionally omits user/global concerns — tool preferences, autonomy level, memory, sub-agent strategy, and output conventions — which live in the operator's own global instructions. The two layers compose; where they conflict for work in this repo, the project layer wins.

## Project Summary

Saga is a local-first reading app for long-form nonfiction, built for committed readers who want to *finish* what they start and get value back out of what they highlight. It is a product surface (earned familiarity over novelty): the interface recedes so the text can do the work. The core loop is read → capture in one gesture → return to your marks.

## What to read before you build

This repository's rules live in the brief files at the project root. This file does not
duplicate them; it tells you which one to read **before** starting the matching kind of work:

| Doing this? | Read this first | Skipping it means |
|---|---|---|
| Building or changing **UI or UX** — layout, components, flows, states, motion | `DESIGN.md` (UX foundation + UI system); `DESIGN.json` for exact token values | Inventing spacing, color, and patterns the system already fixed |
| Writing **any user-facing words** — labels, buttons, errors, empty states, docs, marketing | `WRITING.md` (voice, terminology, microcopy, long-form) | Copy in generic AI voice, against terminology already chosen |
| Making **product or brand decisions** — scope, positioning, personas, tone | `PRODUCT.md` (who it's for, why it exists, personality, anti-references) | Re-deciding scope and audience the product already settled |
| Writing **code** — stack, architecture, conventions, testing, performance, security | `CODE.md` | Stack and architecture choices that contradict the repo |

**Design and writing have a hard trigger:** read `DESIGN.md` before your first edit to a
component, stylesheet, or token file, and `WRITING.md` before your first edit to any string a
user will see — including a one-line tweak. Drift in these two is invisible; the output looks
fine and is only wrong against a standard nobody re-reads. `CODE.md` needs no such trigger,
because tests, lint, and review already catch stack and architecture divergence.

Each brief carries its own **anti-pattern ban list embedded inline** — reading the file is
also reading the bans. The bans are non-negotiable: if the user asks for one anyway, push back
once with a concrete alternative; if they insist, comply but flag the trade-off.

**Accessibility** spans two briefs: the WCAG commitment lives in `PRODUCT.md`; the keyboard,
focus, reduced-motion, and target-size rules live in `DESIGN.md`. Read both before shipping UI.

## Ground rules

- Read the routed brief **before** generating, not after. A non-trivial change usually touches
  more than one — when in doubt, skim all four.
- Do not invent product context, design tokens, or stack decisions the briefs don't support.
- If a request is ambiguous or contradicts a brief, ask the user before assuming.
- The briefs are the source of truth. If reality has outgrown one, update the brief — don't
  quietly diverge from it.

## AI Slop self-check

Before showing any UI to the user, run this check:

- [ ] Does this look like a stranger could tell an AI made it? If yes, redesign.
- [ ] Are the color choices a category reflex (purple-for-AI, neon-for-crypto, blue-for-banking)? If yes, reconsider.
- [ ] Is every element earning its place, or is there ornament-for-ornament's-sake?
- [ ] Did I default to a hero-metric layout, identical-card grid, or modal-first thinking? If yes, see `DESIGN.md` for the chosen pattern.
- [ ] Does the copy hedge ("might", "could", "consider") instead of taking a stance?
- [ ] Would a reader who has skimmed a thousand AI-written pages flag this copy ("delve", "It's not X. It's Y.", em-dash clusters)? See `WRITING.md`.

## When to ask the user

- The request contradicts one of the briefs.
- The request requires a decision the briefs don't cover (new section, new flow, new dependency).
- The request would cross a performance / security / accessibility line in `CODE.md` or `DESIGN.md`.
- You are about to take a destructive or hard-to-reverse action.

## Maintaining these files

`project-starter-pack` lives at `~/code/project-starter-pack`. The briefs are the source of
truth — edit them directly, or re-run the flow that owns one: `setup`, `product-brief`,
`design-brief` (also regenerates `WRITING.md`), `code-brief`, `validate`, `extract`.

The three brief flows have no command of their own — reach one by name, or through `setup`
with its scope word (`product`, `design`, `code`, `all`).

- **Claude Code** — `/starter:setup design`, plus `/starter:extract` and `/starter:validate`.
- **Codex** — `$<flow>`, e.g. `$design-brief`; it runs any skill directly.
- **Cursor** — `/starter-setup design`, or ask for the skill by name.
- **Antigravity** — ask for the skill by name, e.g. `design-brief`.
- **Anything else** — plain language works: "walk me through the design brief
  using the project-starter-pack questionnaire at `~/code/project-starter-pack`".
