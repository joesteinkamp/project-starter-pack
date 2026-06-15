---
description: Reverse-engineer draft PRODUCT, DESIGN, and CODE briefs from an existing codebase
argument-hint: [optional path to scan, defaults to repo root]
allowed-tools: Read, Grep, Glob, Bash(git:*)
---

Invoke the `extract` skill.

Scan target: $ARGUMENTS (default: the repository root).

Reverse-engineer first-draft briefs from the existing code, read-only:

1. **Gather evidence** — read `package.json` / `pyproject.toml` / `go.mod`, tsconfig, CI config, CSS / Tailwind config / token files, the components directory, and the README / landing copy.
2. **Map evidence to brief slots** — fill what the code proves; leave anything not inferable as `[TODO — confirm via /starter:<brief>]`. Never invent product voice or design intent.
3. **Confirm pass** — use `AskUserQuestion` for the high-leverage inferred values (register, color strategy, framework).
4. **Write** drafts of `PRODUCT.md`, `DESIGN.md` (+ `DESIGN.json` if real tokens were found), and `CODE.md`, honoring reuse / merge / overwrite if they already exist.

End by telling the user to review the drafts, then run `/starter:validate` (to check the extracted briefs against the code) and `/starter:orchestrate`.
