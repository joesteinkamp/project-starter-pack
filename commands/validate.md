---
description: Cross-check the briefs (PRODUCT.md, DESIGN.md, DESIGN.json, CODE.md) for contradictions and review the repo against them
argument-hint: [optional focus or path]
allowed-tools: Bash(git:*), Task, Read, Grep, Glob
---

Invoke the `validate` skill.

Scope context (changed files, if any):

!`git diff --stat HEAD 2>/dev/null | tail -20 || echo "no git diff available"`

Run a brief-aware review. Focus: $ARGUMENTS

The skill owns the full procedure: Mode A (brief consistency, always runs) and Mode B
(code/UI vs briefs, only when the repo has application code). This is read-only — report
findings, do not edit anything unless the user explicitly asks.
