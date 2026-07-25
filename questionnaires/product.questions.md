# Product Brief Questionnaire

The `product-brief` skill walks the user through this question set. **Structured** questions use `AskUserQuestion` (multi-choice). **Open** questions are asked in chat as free-form prompts.

## Pass 1 — Structured

### Q1. Register

> Is this product primarily a brand surface (marketing, distinctiveness wins) or a product surface (tool, earned familiarity wins)?

- `brand` — marketing site, landing page, campaign, content surface
- `product` — application, tool, dashboard, daily-use surface
- `hybrid` — meaningful both, with a leaning

→ writes to `{{REGISTER}}`

### Q2. Audience awareness

> When users land on this product, what do they already know?

- `aware` — they know they have the problem and are evaluating solutions
- `curious` — they sense the problem but haven't named it
- `unaware` — they need education before they'll consider this

→ informs voice and onboarding strategy in `{{PRODUCT_PURPOSE}}`

### Q3. Voice posture

> How opinionated is the brand voice?

- `decisive` — takes a stance, no hedging
- `friendly` — warm, welcoming, but still confident
- `expert` — authoritative, technical, no-frills
- `playful` — irreverent, surprising, human

→ informs `{{PERSONALITY_DETAIL}}`

### Q4. Accessibility commitment

> What's the accessibility baseline?

- `WCAG 2.1 AA` (the long-standing floor)
- `WCAG 2.2 AA` (recommended default — adds focus-not-obscured, 24px target size, redundant-entry)
- `WCAG 2.1 AAA` (regulated industries, public sector)
- `Custom` — describe in open follow-up

→ writes to `{{ACCESSIBILITY}}`

## Pass 2 — Open follow-ups

### Q5. One-liner

> In one sentence a stranger could repeat back to you, what is this product?
> No hype words. No "the best". Just the promise.

→ `{{ONE_LINER}}`

### Q6. Primary (and secondary) user, in their context

> Describe the primary user with enough specificity that you could pick them
> out of a coffee shop. Role, seniority, environment, what they tried before
> this, what made them stop trying. If there's a meaningful secondary
> audience, name them too (one or two sentences).

→ `{{PRIMARY_USERS}}` + `{{SECONDARY_USERS}}` (leave secondary blank with a
TODO if there isn't a distinct one)

### Q7. Jobs-to-be-done

> What is the user hiring this product to do? Lead with a verb. 1-3 jobs.

→ `{{JOBS_TO_BE_DONE}}`

### Q8. Brand personality, three words + the proof

> Three adjectives that describe the voice — then 2-3 sentences explaining
> how those adjectives show up in real copy or behavior.

→ `{{PERSONALITY_THREE_WORDS}}` + `{{PERSONALITY_DETAIL}}`

### Q9. Anti-references

> Name 3-5 specific products, sites, or patterns this should NOT resemble.
> Be concrete: real names, real aesthetics. Vague anti-refs ("not boring")
> don't constrain anything.

→ `{{ANTI_REFERENCES}}`

### Q10. Design principles (4-6)

> What principles should bias every design decision in this product? Each
> should be quotable in a review.

→ `{{DESIGN_PRINCIPLES}}`

### Q11. Success metrics

> What numbers (or qualitative signals) tell you this product is working?
> Avoid ornamental metrics ("engagement"). Prefer "7-day retention", "task
> success rate", "median time to first value".

→ `{{SUCCESS_METRICS}}`

## Defaults applied if unanswered

| Slot | Default | Mark |
|---|---|---|
| `{{ACCESSIBILITY}}` | WCAG 2.2 AA, keyboard reachability, prefers-reduced-motion respected, semantic HTML first | `[default — confirm]` |
| `{{DESIGN_PRINCIPLES}}` | Practice what you preach; show, don't tell; purposeful restraint; expert confidence | `[default — confirm]` |
| `{{ANTI_REFERENCES}}` | (skipped — too project-specific to default) | leave blank with TODO |

## Pre-flight checks before writing

- If `PRODUCT.md` exists, ask: **reuse / merge / overwrite**.
- Validate that personas aren't generic (the `product-anti-patterns.md` rules) — flag and re-prompt if they are.
- Validate that anti-references name actual things, not abstract qualities.

## Extraction hints (brownfield)

When `/starter:extract` runs against existing code, the README, landing/marketing copy, and the
package `description` can seed `{{ONE_LINER}}`, `{{PRODUCT_PURPOSE}}`, and (low-confidence)
`{{REGISTER}}`. Everything else here — users, jobs, personality, anti-references, principles,
metrics — code cannot prove; extract leaves those as `[TODO — confirm]` for this questionnaire.
