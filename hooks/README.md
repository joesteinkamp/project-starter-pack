# Hooks (optional, advisory)

These hooks are **opt-in, warn-only, and not installed by default.** They print nudges when an
edited file drifts from the design system or the writing rules; they never block a tool call and
never edit anything.

## Why advisory, not enforcing

`project-starter-pack` is AI-driven: each brief embeds its anti-pattern bans inline and
`AGENTS.md` routes the agent to the owning brief, so the agent self-checks before it writes. Hard blocking on something like "raw hex" produces false
positives (third-party CSS, generated files) and fights the designer. And genuine hard enforcement
— protected paths, dangerous-bash guards, a tool-call audit log — is a **user / global-layer**
concern (it belongs with your global instructions), not something a per-project starter pack should
duplicate. So these hooks stay advisory and optional. If you want project-specific reminders, opt
in; otherwise the guardrails embedded in the briefs are the enforcement.

## What they check

The bans are **not written in these scripts.** They live as prose in
`guardrails/*-anti-patterns.md`, with their detectors in the matching `.detect.md` sidecars;
`build-guardrails.sh` compiles both into `guardrails/registry.json`, and the hooks execute that.
Adding a ban to the prose arms its detector in the same edit — no hook is touched. See
`guardrails/_format.md`.

Each hook runs the detectors of one **scope**:

| Hook | Scope it runs | Fires on |
|---|---|---|
| `check-anti-patterns.sh` | `style` | an edit to a style/component file |
| `guard-design.sh` | `tokens` | the same, but only when the project has a `DESIGN.json` — the bans that apply once a project has committed to the OKLCH token system |
| `check-writing-slop.sh` | `prose` | an edit to a `.md`, `.mdx`, or `.txt` file |

All three read the tool-call JSON on stdin, inspect every file the call edited, print to stderr,
and **exit 0**. A warning names the ban by ID (`DES-18`), so it can be looked up in the registry
or in the brief that embeds it.

Which bans are safe to grep for is recorded in the registry as a `confidence` field rather than
argued in a comment here. `certain` warns wherever its scope applies; `scoped` needs a scope or a
threshold to stay useful — `robust` and `leverage` stay out of `WRT-01` because tech docs use them
honestly, and that judgment is now data. Of 89 bans, 10 have a live detector today; 39 more are
marked `unwritten` (detectable, not yet written) and the rest need a rendered page, a token file,
or a human.

If `registry.json` is missing or `jq` is absent, the hooks say so on stderr and check nothing —
they still exit 0, but they never enforce nothing *silently*.

## One set of scripts, four tools

Claude Code, Codex, Cursor, and Antigravity each put the edited file's path somewhere different in
the event payload — and Codex doesn't put it in a field at all, it lists the files inside an
`apply_patch` envelope. Rather than fork the scripts, `install-hooks.sh` wires each command with
`HOOK_PLATFORM=<tool>` and `lib/hook-input.sh` normalizes all four shapes into a list of paths.
A hook wired by hand without the variable still works: the normalizer falls back to trying every
shape.

| Tool | Config it merges into | Event |
|---|---|---|
| Claude Code | `./.claude/settings.json`, or `~/.claude/settings.json` with `--global` | `PostToolUse` on `Edit\|Write\|MultiEdit` |
| Codex | `~/.codex/hooks.json` | `PostToolUse` on `apply_patch\|Edit\|Write` |
| Cursor | `~/.cursor/hooks.json` | `afterFileEdit` (flat entries, top-level `version`) |
| Antigravity | `~/.gemini/antigravity-cli/hooks.json` | a named `psp-advisory` hook, `PostToolUse` on the file-write tools. Wrapper scripts under `hooks/` set `HOOK_PLATFORM`, because Antigravity invokes hooks by absolute path with no environment of ours. The `~/.gemini/` path is historical — Antigravity is not the retired Gemini CLI. |

## Install / uninstall

```
hooks/install-hooks.sh                          # Claude Code, this project (./.claude/settings.json)
hooks/install-hooks.sh --global                 # Claude Code, all projects (~/.claude/settings.json)
hooks/install-hooks.sh codex cursor antigravity # the other tools (machine-wide — they have no per-project hook config)
hooks/install-hooks.sh --uninstall [targets]    # remove exactly what the installer added
```

A bare run targets **Claude Code only**, on purpose: it is the one tool with a project-scoped
config, so the default stays inside the repo you are standing in and never reaches into `$HOME` for
tools you didn't name. A target whose config directory doesn't exist is skipped cleanly.

Requires `jq`. The installer preserves any existing hooks (ours are matched by exact command
string, so a same-named script of your own is never touched), and the **first run** writes a `.bak`
beside each config it changes — your pre-install state; later runs never overwrite it, so it always
restores the original. `--uninstall` removes only this pack's entries, and cleans up the empty
scaffolding it added. `settings.snippet.json` shows the exact Claude config if you prefer to merge
it by hand. If the install is project-local, add `.claude/settings.json.bak` to your `.gitignore`
(this repo's does).
