# Changelog

Tracks edits to the documents that govern this repo's agent behavior.
Use this to diagnose issues — if agent behavior changes or guidance starts
conflicting, check what was modified and when.

Does **not** track routine code changes (git history covers those). Only
tracks edits to the governing docs listed in `AGENTS.md`.

---

<!-- Entries appear below as the agent edits governing docs. -->

## 2026-07-30 — `AGENTS.md` and `CLAUDE.md` rewritten; pointer direction flipped

`AGENTS.md` was a one-line stub pointing at `CLAUDE.md`, which carried all the content. That is
backwards from the convention this pack now generates for every project it sets up — `AGENTS.md`
is the entry point that all four tools read natively, and `CLAUDE.md` is the thin pointer that
imports it. Flipped them, so the repo dogfoods its own router pattern instead of contradicting it.

`AGENTS.md` gained the contracts that were previously only enforced by `test.sh` and discoverable
by reading it: the portability ban list, commands-stay-thin, `../../` resource paths, the rule
confining Claude's slash-command syntax to Claude-surface files, and "don't reintroduce
synthesis". The memory protocol moved over from `CLAUDE.md` unchanged in substance. `CLAUDE.md`
keeps only Claude-Code-specific notes.

Why now: the merge of `main` into the setup-options branch brought these two files in for the
first time, and `main`'s copies described the retired orchestrator architecture.
