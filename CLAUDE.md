# Claude Code Instructions

@AGENTS.md

> Thin pointer. It imports `AGENTS.md` — this repository's entry point — and adds
> Claude-Code-specific notes below. Shared rules belong in `AGENTS.md` so Codex, Cursor, and
> Antigravity see the same source of truth. This is the same pattern the pack generates for the
> projects it sets up, dogfooded here.

## Project-specific Claude notes

- **`./test.sh` before every commit.** It is the only build step this repo has; a red run means
  the slot, portability, or guardrail contract is broken, not that a check is being fussy.
- **`test.sh` and `render-ports.sh` are the blast-radius files.** A wrong edit there fails open —
  the checks pass while enforcing nothing, or every user's `~/.cursor/commands` churns on each
  install. Read the section comments before touching either; they explain what each check is
  defending against.
- **The plugin path and the `install.sh` path must stay in sync.** `.claude-plugin/plugin.json`
  points Claude Code at `commands/` and `skills/`; `install.sh` symlinks the same dirs into three
  other tools. A change that only works under one path is a portability regression.
- **Verify a flow change by reading it as the other tools would.** Claude Code is the only target
  with both commands and a structured-question tool — Codex has neither. If a step only makes
  sense with `AskUserQuestion`, it is broken in three tools out of four.
