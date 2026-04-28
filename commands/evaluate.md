---
description: Audit the project's actual code, design, and product surface against AGENT.md + the four guardrail registries
---

Invoke the `evaluator` skill.

Run a four-axis audit (Product, UX, Design, Code) of the user's project against the rules encoded in `AGENT.md` and the anti-pattern guardrails:

1. Read `AGENT.md` (the synthesized contract). If it doesn't exist, stop and tell the user to run `/starter:orchestrate` first. Read `PROJECT.md` and `DESIGN.json` if present.
2. Discover what's actually in the repo — source files, design tokens, route structure, marketing/landing copy. Skip dependencies and build output.
3. Dispatch four parallel sub-agents (Product, UX, Design, Code), each loading only its slice of the spec + the relevant repo subset.
4. Aggregate findings. Each finding is: axis, anti-pattern hit, evidence (`file:line` snippet), severity (`block` / `warn` / `note`), suggested fix. Cap at ~30 to avoid drowning the user.
5. Write the full report to `.starter/evaluations/<YYYY-MM-DD-HHMM>.md` and print a tight summary to chat.
6. Offer follow-ups: `/starter:feedback` if a finding suggests the brief itself is wrong, or apply auto-fixes for clear cases.
