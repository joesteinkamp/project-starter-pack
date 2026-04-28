# TODO

Follow-up opportunities for `project-starter-pack`. Captured from a v0.1.0 audit on 2026-04-28.

---

## High

### Add `/starter:validate` to catch cross-brief contradictions
After briefs exist, nothing checks they agree (e.g. "minimal motion" in `DESIGN.md` vs. an animation-heavy stack in `CODE.md`; product success metrics vs. UX KPIs). A validator command + skill should run a fixed cross-brief checklist and re-apply the four anti-pattern guardrails against the briefs.
**Files:** new `commands/validate.md`, new `skills/validator/SKILL.md`; touch `README.md`, `templates/CLAUDE.template.md`, `commands/setup.md`.

### Enrich `{{CLAUDE_PROJECT_NOTES}}` guidance
`skills/orchestrator/SKILL.md:54` tells the orchestrator to "synthesize 3-5 project-specific Claude-Code notes" with one example. Result: filler. Need named note categories (sub-agent steering, hot-spot files, repo shape, tooling quirks, blast-radius rules) each with an example, plus a guardrail that every note must cite a specific file/flow/tool from the briefs.
**Files:** `skills/orchestrator/SKILL.md:51-56`.

### Ship a fully-filled example
Repo has templates but zero filled examples. Users can't preview the output before running `/starter:setup`. Add `examples/good-saas/` with realistic `PRODUCT.md` / `DESIGN.md` / `DESIGN.json` / `CODE.md` / `AGENT.md` / `CLAUDE.md` plus a one-paragraph `README.md` framing what to notice. Also doubles as a regression fixture for the validator above.
**Files:** new `examples/good-saas/*`; touch `README.md`.

### Surface UX-first hierarchy in `AGENT.md`
`templates/AGENT.template.md:23-33` lists `## UX laws` and `## Design laws` as peers, so a downstream agent can lean UI-first. The questionnaire and `commands/setup.md:13` already establish UX-then-UI; the synthesized output drops the relationship. Add a one-line lead-in under each heading making UX the constraint and UI the expression.
**Files:** `templates/AGENT.template.md:23-33`, `skills/orchestrator/SKILL.md:41-42`.

---

## Medium

### Document downstream agent integration
`README.md:61` lists Cursor/Codex/Gemini/Copilot as out of scope (v1), but `AGENT.md` is the universal hook. A short doc — "exporting AGENT.md to Cursor rules / Codex prompts / Copilot context" — would make good on the README's pitch.
**Files:** new `INTEGRATIONS.md` (or section in `README.md`).

### Extend `DESIGN.tokens.template.json`
Currently only color, type, and motion. No spacing scale, shadows, or border-radius — weak for the Figma/Impeccable interop the README mentions.
**Files:** `templates/DESIGN.tokens.template.json`; questions Q15-Q19 in `questionnaires/design.questions.md`.

### Re-orchestration / sync detection
Edit `PRODUCT.md` by hand, re-run `/starter:orchestrate`, and stale briefs get baked into `AGENT.md` silently. A timestamp/hash header in `AGENT.md` would let the orchestrator warn on drift.
**Files:** `templates/AGENT.template.md`, `skills/orchestrator/SKILL.md`.

### Team-shape questions in product brief
No "team size / iteration velocity / ownership model" prompts. These shape sensible defaults for testing depth and design-token granularity.
**Files:** `questionnaires/product.questions.md`.

---

## Low

### Pause between `/starter:setup` steps
Setup runs the four steps back-to-back. A "Continue to design brief?" gate would help users who want to break it up.
**Files:** `commands/setup.md`.

### Rendering strategy for large `AGENT.md`
20+ anti-patterns can overwhelm the preview. Document a collapse/summary approach in the orchestrator skill.
**Files:** `skills/orchestrator/SKILL.md:58-62`.

### Greenfield fallback in code-brief
Code brief assumes a manifest file (`package.json`, `pyproject.toml`, etc.) exists. Documented but worth a clearer prompt for greenfield projects with no manifest yet.
**Files:** `skills/code-brief/SKILL.md`.
