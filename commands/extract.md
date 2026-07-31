---
description: Reverse-engineer draft PRODUCT, DESIGN, and CODE briefs from an existing codebase
argument-hint: [optional path to scan, defaults to repo root]
allowed-tools: Read, Grep, Glob, Bash(git:*)
---

Invoke the `extract` skill. Scan target: $ARGUMENTS

It owns the full procedure: read-only evidence gathering, mapping evidence to brief
slots, the confirm pass for the high-leverage inferred values, and writing the
drafts with every gap left as an explicit TODO.
