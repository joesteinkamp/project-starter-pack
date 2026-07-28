---
description: Cross-check the briefs (PRODUCT.md, DESIGN.md, DESIGN.json, CODE.md) for contradictions and review the repo against them
argument-hint: [optional focus or path]
allowed-tools: Bash(git:*), Task, Read, Grep, Glob
---

Invoke the `validate` skill. Focus: $ARGUMENTS

It owns the full procedure: Mode A (brief consistency, always runs) and Mode B
(code/UI vs briefs, only when the repo has application code). This is read-only —
report findings, do not edit anything unless the user explicitly asks.
