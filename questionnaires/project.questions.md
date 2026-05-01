# Project Brief Questionnaire

The `project-brief` skill walks the user through this question set. **Structured** questions use `AskUserQuestion` (multi-choice). **Open** questions are asked in chat as free-form prompts.

This brief assumes `PRODUCT.md`, `DESIGN.md`, and `CODE.md` already exist. If they don't, the skill should warn and offer to run the missing briefs first — `PROJECT.md` is a slice of those, and slicing what isn't there yet doesn't work.

## Pass 1 — Structured

### Q1. Project type

> What kind of initiative is this?

- `feature` — new capability for users
- `migration` — moving from one stack/library/pattern to another
- `redesign` — reworking an existing surface
- `fix` — addressing a known problem (perf, bug class, debt)
- `spike` — time-boxed exploration to answer a question
- `infra` — internal-facing platform / tooling work

→ informs voice and shape of `{{GOAL}}`

### Q2. Time horizon

> What's the rough shape of the timeline?

- `sprint` — under 2 weeks
- `weeks` — 2–6 weeks
- `quarter` — single quarter
- `open-ended` — no fixed end date

→ informs `{{CONSTRAINTS}}` and the realism check on `{{SUCCESS_METRICS}}`

### Q3. Status

> Where is this initiative right now?

- `active` (default — recommended for a new brief)
- `shipped` — capturing context after the fact
- `parked` — paused with a reason

→ `{{STATUS}}`

## Pass 2 — Open follow-ups

### Q4. Title and one-liner

> Give the project a short title (2–5 words) and a one-sentence description
> a teammate could repeat back. Avoid hype words. The one-liner should make
> shipping this initiative concrete.

→ `{{TITLE}}` + `{{ONE_LINER}}`

### Q5. Goal — the outcome, not the output

> What outcome are we chasing? Lead with what changes for the user or the
> business, not with what we're building. If the goal sounds like a feature
> spec, rewrite it as a result.

→ `{{GOAL}}`

### Q6. Non-goals

> List 3–6 things this initiative will NOT do. Adjacent work, tempting
> add-ons, scope-creep magnets. Be specific: "not in scope: account settings
> redesign, mobile-app parity, i18n" beats "keep it small".

→ `{{NON_GOALS}}`

### Q7. Success metrics for THIS project

> What measurable signals tell us the initiative worked? These should be
> sliced from `PRODUCT.md` success metrics, not copied wholesale. Each
> should be observable within the project's time horizon.

→ `{{SUCCESS_METRICS}}`

### Q8. Scope slice — design surfaces

> Which sections of `DESIGN.md` does this project touch? Name them by their
> heading. Anything not listed is out of scope for this initiative.

→ `{{DESIGN_SURFACES}}`

### Q9. Scope slice — code subsystems

> Which sections of `CODE.md` does this project touch? Same convention —
> name them by heading. Treat anything unlisted as off-limits unless a new
> decision opens it up.

→ `{{CODE_SUBSYSTEMS}}`

### Q10. Constraints

> Deadlines, hard dependencies, accepted tech debt. For each, give the
> reason — a constraint without a reason is a vanity deadline.

→ `{{CONSTRAINTS}}`

### Q11. Open questions

> What don't we know yet that could change the plan? Note an owner where
> there is one. Resolved questions later move to the decisions log.

→ `{{OPEN_QUESTIONS}}`

## Defaults applied if unanswered

| Slot | Default | Mark |
|---|---|---|
| `{{STATUS}}` | active | `[default — confirm]` |
| `{{NON_GOALS}}` | (skipped — too project-specific to default) | leave blank with TODO |
| `{{DECISIONS_LOG}}` | _(empty — append as decisions land)_ | always included |
| `{{OPEN_QUESTIONS}}` | _(none captured)_ | leave blank with TODO |

## Pre-flight checks before writing

- If `PROJECT.md` exists, ask: **replace** (write a new one — option 1 of the architecture) or **stop**. Do not offer "merge" — projects are short-lived; merging two initiatives' scope is a guaranteed scope leak.
- If `PRODUCT.md`, `DESIGN.md`, or `CODE.md` is missing, surface which and suggest the matching `/starter:<brief>` command. Offer to proceed with TODOs in the scope-slice sections.
- Validate against `guardrails/project-anti-patterns.md`:
  - If the goal reads as an output, push back once with a "what changes for users?" prompt.
  - If non-goals are missing or generic ("keep it small"), ask for concrete exclusions.
  - If success metrics duplicate `PRODUCT.md` wholesale, ask for the slice.
