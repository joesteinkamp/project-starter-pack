---
description: Cross-check the three briefs for contradictions and review the repo against the briefs and guardrails
argument-hint: [optional focus or path]
allowed-tools: Bash(git:*), Task, Read, Grep, Glob
---

Invoke the `validate` skill.

Scope context (changed files, if any):

!`git diff --stat HEAD 2>/dev/null | tail -20 || echo "no git diff available"`

Run a brief-aware review. Focus: $ARGUMENTS

1. **Mode A — Brief consistency.** Read `PRODUCT.md`, `DESIGN.md`, `DESIGN.json`, and `CODE.md` and check them against each other for contradictions (the matrix the skill prescribes). Always runs; needs no code.
2. **Mode B — Code/UI vs briefs.** If there is application code in the repo, dispatch the review team (one lens per brief) to find `file:line` violations of the briefs and the anti-pattern guardrails.

This is read-only. Report findings — do not edit anything unless the user explicitly asks. End with the summary the skill prescribes (contradictions first, then code findings by severity).
