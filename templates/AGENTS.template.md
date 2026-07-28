# Agent Instructions

> This file is the entry point for any AI coding agent working in this repository. It follows the [agents.md](https://agents.md) convention, so Codex, Cursor, Antigravity, Copilot, and anything else that honors the spec read it automatically; Claude Code reaches it through `CLAUDE.md`. It is generated once by `project-starter-pack` and then routes to the briefs — when a rule changes, edit the brief that owns it; this file does not need regenerating.

> **Layering:** This is the **project / codebase** layer — rules that are true of *this repository*. It intentionally omits user/global concerns — tool preferences, autonomy level, memory, sub-agent strategy, and output conventions — which live in the operator's own global instructions. The two layers compose; where they conflict for work in this repo, the project layer wins.

## Project Summary

{{PROJECT_SUMMARY}}

## What to read before you build

This repository's rules live in the brief files at the project root. This file does not
duplicate them; it tells you which one to read **before** starting the matching kind of work:

| Doing this? | Read this first |
|---|---|
| Building or changing **UI or UX** — layout, components, flows, states, motion | `DESIGN.md` (UX foundation + UI system), plus `DESIGN.json` for exact token values when present |
| Writing **any user-facing words** — labels, buttons, errors, empty states, docs, marketing | `WRITING.md` (voice, terminology, microcopy, long-form) |
| Making **product or brand decisions** — scope, positioning, personas, tone | `PRODUCT.md` (who it's for, why it exists, personality, anti-references) |
| Writing **code** — stack, architecture, conventions, testing, performance, security | `CODE.md` |

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

<!-- Filled at wire-up with the pack's location on disk and how to start each
flow in this repo's tools — so an agent in a harness without slash commands
(Antigravity, Codex) can still run the pack by name. To regenerate one brief,
re-run `setup` and pick the matching brief at its scope step, or run that flow
by name in a tool that invokes skills directly. -->

{{REGENERATION_NOTE}}
