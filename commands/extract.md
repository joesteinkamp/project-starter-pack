---
description: Reverse-engineer PRODUCT.md, DESIGN.md, CODE.md, AGENT.md from an existing codebase, fill missing briefs, and surface fork points to iterate on
---

Invoke the `extract` skill.

Reverse direction of the rest of the starter pack: instead of questionnaire → briefs, this scans the repo and works backward into the briefs, then fills the gaps, then asks what to fork.

## Sequence

1. **Scan** — walk the repo for evidence per brief: existing `PRODUCT.md`, `DESIGN.md`, `CODE.md`, `AGENT.md` / `AGENTS.md`, `CLAUDE.md`, plus manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`), framework configs, CSS / Tailwind / token files, component directories, README, and any `.cursor/`, `.github/copilot-instructions.md`, etc.
2. **Audit completeness** — for each of the four briefs, classify as `complete`, `thin`, or `missing`, using the matching `templates/*.template.md` as the section checklist. Show the user the audit table before writing anything.
3. **Extract per brief** — for every non-complete brief, derive what's inferable from the codebase. Order by inferability: `CODE.md` first (most code-grounded), then `DESIGN.md` (tokens + components), then `PRODUCT.md` and `AGENT.md` (least inferable from code; lean on README and existing docs).
4. **Confirm gaps** — for each section that can't be inferred, use `AskUserQuestion` from the matching questionnaire. Mark inferred-but-unconfirmed values with ` [inferred — confirm]`; mark defaulted values with ` [default — confirm]` (matches the existing convention).
5. **Validate** — run each generated brief through its anti-pattern guardrails before previewing.
6. **Preview & write** — preview each brief, accept one round of edits, and write only the missing or thin files. Never overwrite a brief the user marked `complete` in step 2 without explicit overwrite confirmation.
7. **Re-orchestrate** — invoke the `orchestrator` skill so `AGENT.md` and `CLAUDE.md` regenerate against the now-complete set.
8. **Fork review** — final step. Surface every inferred decision where the codebase was ambiguous (e.g. "color strategy read as Committed, could also be Restrained"; "auth model inferred as session, JWT also plausible from deps"). Present them as fork points the user can: **accept**, **override** (re-answer here), or **branch** (loop back into the relevant brief command to iterate further).

## Done

End with the one-screen summary the skill prescribes — files written, fork points surfaced, and the next command to run if the user wants to iterate on a fork.
