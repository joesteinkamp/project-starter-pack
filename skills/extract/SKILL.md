---
name: extract
description: Reverse-engineers PRODUCT.md, DESIGN.md, CODE.md, AGENT.md from an existing codebase. Audits which briefs are missing or thin, extracts what's inferable from code (manifests, tokens, components, configs), confirms gaps via questionnaire, and ends with a fork-and-iterate review of decisions the codebase left ambiguous. Use when the user asks to extract briefs, reverse-engineer briefs, generate briefs from an existing codebase, audit which briefs are missing, or fill in missing project documentation. Triggers on "extract briefs", "reverse-engineer", "reverse engineer briefs", "briefs from codebase", "audit briefs", "missing PRODUCT.md", "fill in the briefs", "fork the briefs".
---

# Extract Skill

You run the inverse of the rest of the starter pack. Instead of leading with questions and writing briefs, you lead with a codebase scan, derive what's inferable, and only ask the user about what the code can't answer. The flow ends with a **fork review** that exposes the decisions the codebase left ambiguous so the user can accept, override, or branch into iteration.

## Setup

1. Locate the plugin root. You will need:
   - Templates: `templates/PRODUCT.template.md`, `templates/DESIGN.template.md`, `templates/DESIGN.tokens.template.json`, `templates/CODE.template.md`, `templates/AGENT.template.md`, `templates/CLAUDE.template.md`.
   - Questionnaires: `questionnaires/product.questions.md`, `questionnaires/design.questions.md`, `questionnaires/code.questions.md`.
   - Guardrails: `guardrails/{product,ux,design,code}-anti-patterns.md`.
2. Read all templates before scanning — the section list of each template is your **completeness checklist** for that brief.

## Phase 1 — Scan

Walk the project root and collect evidence per brief. Don't ask the user anything yet.

### Existing brief files

Look for and read if present:
- `PRODUCT.md`
- `DESIGN.md`, `DESIGN.json`
- `CODE.md`
- `AGENT.md`, `AGENTS.md`
- `CLAUDE.md`
- `README.md`, `README.*`
- `.cursor/rules/*`, `.github/copilot-instructions.md`, `.aider.conf*`, `GEMINI.md` — useful corroborating evidence

### Code evidence (for `CODE.md`)

- Manifests: `package.json`, `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`.
- Framework / config: `next.config.*`, `vite.config.*`, `nuxt.config.*`, `astro.config.*`, `remix.config.*`, `svelte.config.*`, `angular.json`, `tsconfig.json`, `eslint.config.*` / `.eslintrc*`, `prettier*`, `biome.json`, `.editorconfig`.
- CI / deploy: `.github/workflows/*`, `.gitlab-ci.yml`, `vercel.json`, `netlify.toml`, `wrangler.toml`, `Dockerfile`, `docker-compose.*`, `fly.toml`.
- Tests: presence of `vitest`, `jest`, `playwright`, `cypress`, `pytest`, `cargo test`.
- Repo strategy: top-level `apps/` / `packages/` / workspaces field → monorepo.

### Design evidence (for `DESIGN.md` UI system)

- Token sources: `tailwind.config.*`, `theme.*`, `tokens.*`, CSS files with `:root` custom properties, `*.css` / `*.scss` with named scales, `DESIGN.json`.
- Components: top-level `components/`, `ui/`, `design-system/`, `app/components/`, `src/components/`. Sample 5–10 component filenames to infer the primitive set (Button, Input, Card, etc.).
- Motion: search for `transition`, `animate`, `framer-motion`, `motion/react`, `cubic-bezier(`, `ease-` utilities.
- Color: collect any hex / oklch / hsl values found in token files. If hex, plan to convert to OKLCH on output.
- Type: font imports (`next/font`, `@fontsource/*`, Google Fonts links in `<head>`).

### UX evidence (for `DESIGN.md` UX foundation)

- Route structure: `app/`, `pages/`, `routes/` directory layout → information architecture skeleton.
- Top-level page filenames → navigation surface.
- Empty state / error boundary files (`error.tsx`, `not-found.tsx`, `loading.tsx`) → which flows have edge states wired up.

### Product evidence (for `PRODUCT.md`)

Hardest to infer from code. Pull from:
- `README.md` headline + first paragraph → candidate one-liner.
- `package.json` `description` field.
- Marketing pages (`app/(marketing)/*`, `pages/index.*`) — visible copy.
- `LICENSE`, repo metadata.

Treat all of this as **candidate, unconfirmed**.

## Phase 2 — Audit

For each of the four briefs, classify as:

- `complete` — file exists and every section in the matching template is filled in with non-placeholder content.
- `thin` — file exists but ≥ 1 template section is empty, TODO, or one-line placeholder.
- `missing` — file does not exist.

Render an audit table to the user before writing anything:

```
Brief         Status      Notes
PRODUCT.md    missing     no file; README has a one-liner candidate
DESIGN.md     thin        UI tokens present, UX foundation empty
CODE.md       complete    all 9 sections present
AGENT.md      missing     will regenerate after briefs are filled
```

Ask the user which briefs to (re)generate. Default to all `missing` and `thin`. Never modify `complete` briefs without explicit overwrite confirmation.

## Phase 3 — Extract per brief

Process the briefs in order of inferability so the user sees the easy wins first and answers the hardest questions last.

### Order

1. `CODE.md` — most evidence, fewest questions.
2. `DESIGN.md` — UI from tokens / components, UX from routes + user input.
3. `PRODUCT.md` — mostly user input, README-seeded.
4. `AGENT.md` + `CLAUDE.md` — handled by the `orchestrator` skill in Phase 6.

### For each non-complete brief

1. **Pre-fill** every template slot you can from the scan.
2. **Mark provenance** for every pre-filled value:
   - ` [inferred — confirm]` — derived from the codebase, user hasn't confirmed.
   - ` [default — confirm]` — fell back to the questionnaire's defaults table.
   - (no marker) — read directly from an existing `complete` section the user opted to keep.
3. **Ask only what's left** — for any slot still empty after inference and defaults, ask the matching questions from the corresponding `questionnaires/*.questions.md` using `AskUserQuestion` (structured) and chat (open follow-ups). Skip questions the scan already answered.
4. **Validate** against the brief's guardrails (`guardrails/code-anti-patterns.md`, `guardrails/{ux,design}-anti-patterns.md`, `guardrails/product-anti-patterns.md`). Push back once on anti-pattern smells, same as the forward-direction skills.
5. **Embed anti-pattern lists inline** in the relevant template slots (`{{CODE_ANTI_PATTERNS}}`, `{{DESIGN_ANTI_PATTERNS}}`, etc.) — same as the forward skills.
6. **Preview** the populated brief, accept one round of edits, then **write** to the project root.

If `DESIGN.json` exists in the repo, read its tokens into `DESIGN.md` color/type/spacing slots; if it doesn't but the user supplied concrete tokens during the gap-confirmation step, offer to write `DESIGN.json` using `templates/DESIGN.tokens.template.json`.

## Phase 4 — Re-orchestrate

Once the three briefs exist (whether freshly written or carried forward), invoke the `orchestrator` skill to regenerate `AGENT.md` and `CLAUDE.md`. Do not hand-write these — they are derived.

## Phase 5 — Fork review

This is the new bit, and the reason the user asked for `extract` instead of running the four forward commands.

For every value you marked ` [inferred — confirm]`, present it as a **fork point**: a place the codebase was ambiguous and you made a call. Group fork points by brief.

Format each fork point as:

```
[brief: section]
  Inferred: <what you wrote>
  Evidence: <what in the codebase pointed here>
  Alternatives: <1–2 plausible other reads>
  Action: accept | override | branch
```

After listing all fork points, ask the user — using `AskUserQuestion` where the choice is bounded — what to do with each:

- **accept** — strip the `[inferred — confirm]` marker, move on.
- **override** — capture the user's correction inline and rewrite the affected brief section.
- **branch** — exit `extract` and recommend the relevant brief command (`/starter:product-brief`, `/starter:design-brief`, `/starter:code-brief`) to iterate further. Print the command and stop; the user resumes it themselves.

If the user **branches** on any brief, do not re-run `orchestrator` after the fork review — the brief is now in flight, and `AGENT.md` should be regenerated only after the user finishes iterating.

## Done

Print a one-screen summary:

```
✓ Audited 4 briefs ({{N_complete}} complete, {{N_thin}} thin, {{N_missing}} missing)
✓ Wrote {{LIST_OF_FILES}}
✓ Surfaced {{N}} fork points ({{N_accepted}} accepted, {{N_overridden}} overridden, {{N_branched}} branched)

Next:
- If you branched on any brief, run the matching /starter:<brief> command to iterate.
- If everything was accepted or overridden, AGENT.md and CLAUDE.md are up to date.
- Edit any brief by hand and re-run /starter:orchestrate to refresh AGENT.md.
```

## Important

- **Never invent product context.** Inference from a README headline is candidate, not truth. Mark it ` [inferred — confirm]` and let the fork review handle it.
- **Code-grounded values are not free passes either.** A `package.json` says what's installed, not what's intentional. The user might be carrying a dependency they want to drop. Surface stack reads as fork points if the README or other signals hint at a transition.
- **Respect `complete` briefs.** If the user keeps a brief, do not silently rewrite its sections during `orchestrate` either — the orchestrator should consume the kept file as-is.
- **Don't overuse fork review.** If the codebase was unambiguous on a slot, don't manufacture an alternative just to fill the table. Fork points are real ambiguities, not formality.
- **Voice matches the rest of the pack** — direct, opinionated, no hedging. Same anti-patterns enforced.
