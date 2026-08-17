# Changelog

Tracks edits to the documents that govern this repo's agent behavior.
Use this to diagnose issues — if agent behavior changes or guidance starts
conflicting, check what was modified and when.

Does **not** track routine code changes (git history covers those). Only
tracks edits to the governing docs listed in `AGENTS.md`.

---

<!-- Entries appear below as the agent edits governing docs. -->

## 2026-08-17 — `memory/knowledge.md`: YAML frontmatter validity

Added "Frontmatter must be valid YAML, not YAML-ish". A `": "` in an unquoted description is a
syntax error; Claude Code, Codex, and Cursor tolerated it while Antigravity silently dropped the
`setup` skill, leaving the pack's front door missing in one tool of four from the moment
Antigravity support merged.

Recorded because two lessons generalize past this bug: the strictest parser in the target set
decides what is portable ("three of four tools accept it" means three lenient parsers and one
correct one), and a check that a file is *present* is not a check that it *works* — the installer
tests from the session before asserted symlinks landed and passed the whole time the skill was
failing to load.

## 2026-08-17 — `memory/knowledge.md`: first entry, on Antigravity's skills system

Added "Antigravity has a full skills system" — where its skills live, its five customization
types, and the CLI probes that verify them. Written because the pack spent two releases asserting
Antigravity had no skill surface and installing nothing for it (corrected in #15): the claim was
wrong in `README.md`, `INSTALL.md`, `render-ports.sh`, `skills/setup/SKILL.md`, the `AGENTS.md`
template, and the example fixture, while every `test.sh` check stayed green because all of them
were string-level.

The entry records the generalizable part, not just the fact: a claim about what a *tool* supports
cannot be verified by grepping this repo, so probe the tool. It names the two one-line probes used
(`agy -p`, `claude -p "/<dir>:<name>"`) and points at Antigravity's own bundled
`agy-customizations` skill as the authority.

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
