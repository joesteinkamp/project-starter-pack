# CLAUDE.md

Agent instructions for this repository.

## Compatibility

This file is plain Markdown so it works in both Codex (`AGENTS.md`) and Claude Code (`CLAUDE.md`). `AGENTS.md` points here — maintain this file only.

## Canonical Docs

The following files govern agent behavior in this repo. Treat them as authoritative.

- `CLAUDE.md` — this file; agent instructions and the memory protocol
- `memory/knowledge.md` — non-obvious project knowledge captured during AI conversations
- `memory/changelog.md` — dated log of edits to governing docs, used to diagnose behavior drift

## Knowledge Capture

Read `memory/knowledge.md` before doing substantive work in this repo.

When a conversation requires iterative discovery — e.g., the initial answer was wrong, missed context, or only became correct after back-and-forth — ask the user: **"Should I add this to `memory/knowledge.md`?"** before moving on. If the user agrees, update `memory/knowledge.md` and append a dated entry to `memory/changelog.md`.

The trigger is *discovery*, not chat volume. Only ask when something surprised you or required exploration to get right — not after every routine Q&A. Never auto-save; the user is the editor.

## Guardrails

- When you modify any file listed under Canonical Docs (including this file), append a dated entry to `memory/changelog.md` describing what changed and why.
- Changelog entries are dated and explain the *why*, not just the *what*. One-line entries are fine; the audit value is the date plus the reason.
- Keep `memory/knowledge.md` lightly structured. Group related entries under H2 headings as the file grows. No categories, tags, or schemas.
