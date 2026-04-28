---
name: evaluator
description: Audits the project's actual code, design tokens, route structure, and product copy against AGENT.md and the five anti-pattern guardrails (product, UX, design, code, project). Use when the user asks to evaluate, audit, lint, grade, or check whether the project follows the briefs. Triggers on phrases like "evaluate this project", "audit against the briefs", "is this code following AGENT.md", "design audit", "starter audit", "check the project against the guardrails".
---

# Evaluator Skill

You audit the user's actual project against the rules the starter-pack already encoded for it. The contract is `AGENT.md` plus the five anti-pattern registries. Findings must cite real evidence in the repo — never report a violation you can't point to.

## Setup

1. Locate the plugin root. The five guardrail files are at `guardrails/{product,ux,design,code,project}-anti-patterns.md`. Read them — they're the structured rule set.
2. Read `AGENT.md` from the project root. This is the synthesized contract. If it doesn't exist, stop and tell the user to run `/starter:orchestrate` first.
3. If `PROJECT.md` exists at the project root, read it — it scopes the current initiative (goal, non-goals, scope slice, success metrics) and sharpens "is this in scope?" findings.
4. If `DESIGN.json` exists at the project root, read it — it's the machine-readable design token companion that tightens the design audit.

## Repo discovery

Build a scoped picture of what's actually in the repo. **Skip** `node_modules/`, `.git/`, `dist/`, `build/`, `.next/`, `out/`, `coverage/`, `.venv/`, `__pycache__/`, lockfiles, and binary assets. Bucket the rest:

- **Code surfaces** — `*.{ts,tsx,js,jsx,py,go,rs,rb,java,kt,swift}` and config files like `tsconfig.json`, `eslint.config.*`, `pyproject.toml`. For the Code axis.
- **Design surfaces** — `*.css`, `*.scss`, `tailwind.config.*`, design token files, component files (`*.tsx`, `*.vue`, `*.svelte`), Storybook stories. For the Design axis.
- **IA / route surfaces** — `app/`, `pages/`, `routes/`, `src/routes/`, top-level URL structure. For the UX axis.
- **Product copy** — landing-page files, hero copy, marketing markdown, README.md, in-product strings. For the Product axis.

Note any axis that has no evidence in the repo. Don't fabricate findings for axes you can't see.

## Dispatch — four parallel sub-agents

Use the `Explore` sub-agent to dispatch one investigation per axis in parallel. Each sub-agent receives:

- The relevant slice of `AGENT.md` (Product context / UX laws / Design laws / Code conventions plus its anti-pattern section).
- The full text of the matching `guardrails/<axis>-anti-patterns.md`.
- The list of repo paths in its bucket (not the file contents — the sub-agent reads what it needs).
- A required output schema (see "Finding shape" below).

The four sub-agents:

1. **Product axis** — checks landing copy, README, in-product strings against `product-anti-patterns.md` (vague personas, generic positioning, hedging brand voice, feature-list-as-positioning, ornamental metrics, abstract anti-references, three-buzzword personality). When `PROJECT.md` exists, also evaluates the current initiative against `project-anti-patterns.md` (output-as-goal, missing non-goals, vanity deadlines, "phase 2" placeholders, scope-that-names-everything) — a project finding cites `PROJECT.md` as the evidence file.
2. **UX axis** — checks IA / routes / interactive components against `ux-anti-patterns.md` (confirm-instead-of-undo, modal-first, hidden state, generic errors, dark patterns, lossy navigation, accessibility-as-cleanup).
3. **Design axis** — checks color tokens, type, spacing, motion, component primitives against `design-anti-patterns.md` (purple gradients, neon-on-black, nested cards, gradient text, bounce easing, pure black/white, layout animations) and `DESIGN.json` if present.
4. **Code axis** — checks source files, types, error handling, tests, comments against `code-anti-patterns.md` (premature abstraction, defensive over trust, magic timing, dead code, comment-as-rename, snapshot-as-primary-signal, `--no-verify` / `--force` shortcuts).

## Finding shape

Each sub-agent must return a JSON-shaped list. Each finding:

```
{
  "axis": "product" | "ux" | "design" | "code",
  "rule": "<short anti-pattern name from the guardrail file>",
  "severity": "block" | "warn" | "note",
  "evidence": [{ "file": "<path>", "line": <number|null>, "snippet": "<≤120 chars>" }],
  "explanation": "<one sentence — why this hits the rule>",
  "suggested_fix": "<one or two sentences — what to change>"
}
```

Severity guide:
- `block` — clear, named anti-pattern with direct evidence (e.g. `setTimeout(fn, 100)` next to a race comment, or a CSS variable with a purple gradient on a dark background).
- `warn` — pattern is present but context-dependent (e.g. a single `as any` that might be load-bearing, a card-inside-card that might be a deliberate exception).
- `note` — the brief covers a topic but the repo has no evidence either way (e.g. `AGENT.md` mandates `prefers-reduced-motion` but no motion code exists yet).

Tell each sub-agent: **no finding without evidence**. If the rule is met or not testable from the files in scope, omit it.

## Aggregate

When all four return:

1. Concatenate findings.
2. Dedupe (same rule + same file:line collapses to one finding).
3. Sort by severity (`block` → `warn` → `note`), then by axis, then by file path.
4. Cap at 30. If there are more, keep all `block` findings, then fill with `warn`, then `note`. Note the truncation count in the summary.

## Write the report

Write to `.starter/evaluations/<YYYY-MM-DD-HHMM>.md`. Create `.starter/evaluations/` if it doesn't exist. Report shape:

```markdown
# Project Evaluation — <ISO timestamp>

Audited against `AGENT.md` and the five anti-pattern registries.

## Summary
- {{N_BLOCK}} block, {{N_WARN}} warn, {{N_NOTE}} note ({{N_TRUNCATED}} additional findings truncated)
- Axes covered: {{LIST}}
- Axes skipped (no evidence in repo): {{LIST}}

## Findings

### Code (block)
1. **{{rule}}** — `path/to/file.ts:42`
   > <code snippet>

   {{explanation}}

   **Fix:** {{suggested_fix}}

(... continued, grouped by axis then severity)

## Next steps
- For each `block` finding, run `/starter:feedback` if the brief itself is wrong, or fix the code if the brief is right.
- Re-run `/starter:evaluate` after fixes to confirm.
- If recurring patterns suggest the plugin's templates or guardrails are at fault, run `/starter:report-issue`.
```

## Print to chat

Print only the **Summary** + the top 5 `block` findings (file:line + one-line fix). Tell the user the full report is at `.starter/evaluations/<filename>`.

## Important

- Do not invent evidence. A finding without a `file:line` is not a finding.
- Do not re-state the entire `AGENT.md` back at the user. They wrote it; the report is about deviation, not summary.
- The five anti-pattern lists are the spec — don't add new bans on the fly. If you want a new ban, that's a `/starter:report-issue` against the guardrail.
- Honest scoping: if the repo has a `package.json` and nothing else, say so. A near-empty audit is a real result, not a failure.
- Respect parallelism: the four sub-agents run in a single dispatch, not sequentially.
- Performance: the sub-agents read what they need. Don't pre-load whole-repo file contents into the main thread.
- This skill is read-only by default. It writes one report file under `.starter/evaluations/` and nothing else. Auto-fixes only on explicit follow-up from the user.
