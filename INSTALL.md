# Install

`project-starter-pack` installs into Claude Code, Codex, Cursor, and Antigravity. Everything is
**symlinked**, so `git pull` in the checkout updates every tool at once.

## Option 1 — `install.sh` (all tools)

```bash
git clone https://github.com/joesteinkamp/project-starter-pack.git ~/code/project-starter-pack
cd ~/code/project-starter-pack
./install.sh
```

```bash
./install.sh --yes          # skip the confirmation prompt
./install.sh codex cursor   # only those tools
./install.sh --uninstall    # remove exactly what was installed
```

A tool whose config directory doesn't exist is skipped cleanly — installing for a tool you don't
have is not an error. Re-running is idempotent, and a real file or directory already sitting at a
destination is never replaced (the installer says so and moves on).

### What lands where

| Tool | Installed | Invoke |
|---|---|---|
| **Claude Code** | `~/.claude/skills/<flow>` and `~/.claude/commands/starter/<verb>.md` | `/starter:setup`, `/starter:extract`, `/starter:validate`, or any flow by name |
| **Codex** | `~/.codex/skills/<flow>` | `$<flow>` — e.g. `$setup`, `$design-brief` |
| **Cursor** | `~/.cursor/skills/<flow>` and `~/.cursor/commands/starter-<flow>.md` | `/starter-setup`, `/starter-extract`, `/starter-validate`, or any skill by name |
| **Antigravity** | `~/.gemini/config/skills/<flow>` (symlink per skill) | by name, or plain language: *"walk me through the product brief"* |

The command surface is three verbs — generate, seed, check. The three brief flows are skills only:
run one through `setup` with a scope word (`/starter:setup design`) or ask for it by name. Codex and
Antigravity are unaffected either way — neither ever had a command surface.

Antigravity's skills go in its **machine-global customization root**, `~/.gemini/config/` — one of
its three discovery locations, and the only one that isn't per-workspace. The format is the same
`skills/<name>/SKILL.md` every other tool uses, with the same progressive disclosure (only the name
and description are in context until the flow is activated), so the pack's skills install verbatim.
On top of that it reads the generated `AGENTS.md` in your projects natively, and that file records
the pack's path in its "Maintaining these files" section — so plain language reaches the same flows
even in a workspace where the skills aren't installed.

Claude's commands install into a `starter/` **subdirectory**, because Claude Code builds a
command's name from its path — `~/.claude/commands/starter/setup.md` is `/starter:setup`. That is
the same invocation the plugin path below produces, on purpose: one tool should not have two
different invocations for the same flow depending on how it was installed. Cursor has no
namespacing, so its ports stay flat, prefixed files (`/starter-setup`).

Claude's command files are symlinked from `commands/*.md` unchanged — they are written in Claude's
dialect. The Cursor ones are **generated** from those same files by `render-ports.sh`, which
`install.sh` runs every time. Never hand-edit a port — edit the canonical command and re-install.

## Option 2 — Claude Code plugin (zero scripts)

Claude-Code-only users can skip `install.sh` entirely and clone the repo as a plugin. It delivers
the same `/starter:*` commands and skills, with no script run and no symlinks — and it can be
scoped to a single project, which `install.sh` cannot:

```bash
# this project only
mkdir -p .claude/plugins
git clone https://github.com/joesteinkamp/project-starter-pack.git .claude/plugins/project-starter-pack

# or every project
mkdir -p ~/.claude/plugins
git clone https://github.com/joesteinkamp/project-starter-pack.git ~/.claude/plugins/project-starter-pack
```

Then `/starter:setup` (optionally `/starter:setup product|design|code|all`), `/starter:extract`,
and `/starter:validate` — plus every flow by name, as a skill.

The two paths coexist and now deliver the same surface, so there is no reason to run both. Pick the
plugin for a project-scoped install or to avoid running a script; pick `install.sh` if you use any
of the other three tools, or want one `git pull` to update them all.

## Optional — advisory hooks

Warn-only nudges when an edit drifts from the design system or the writing rules. Opt-in, never
blocking, and off unless you run this:

```bash
hooks/install-hooks.sh                           # Claude Code, this project
hooks/install-hooks.sh --global                  # Claude Code, all projects
hooks/install-hooks.sh codex cursor antigravity  # the other tools (machine-wide)
hooks/install-hooks.sh --uninstall [targets]     # reverse it
```

Requires `jq`. See [`hooks/README.md`](./hooks/README.md).

## Verify

In your AI tool, ask for the setup flow — `/starter:setup` in Claude Code, `$setup` in Codex,
`/starter-setup` in Cursor, `setup` by name in Antigravity, or "run the project starter pack setup"
anywhere. You should see it ask what to run (everything, or one brief) before the intro.

If nothing happens, check that the symlink exists and resolves:

```bash
ls -l ~/.codex/skills/setup          # should point into your checkout
ls -l ~/.gemini/config/skills/setup  # same, for Antigravity
```

## Update

```bash
cd ~/code/project-starter-pack
git pull
./install.sh --yes    # re-renders the Cursor ports; symlinks need no touching
```

Projects you set up before a given update need no migration. Their `CLAUDE.md` pointer is a
snapshot, so it can advertise a command that has since been retired (the three `/starter:*-brief`
commands were folded into `/starter:setup <scope>`) until the next flow's wire-up rewrites it.
Re-running `setup` refreshes the list.

## Uninstall

```bash
./install.sh --uninstall
hooks/install-hooks.sh --uninstall     # if you enabled the hooks
```

Only symlinks pointing into the checkout are removed; anything you put there yourself is left
alone. For a plugin install, `rm -rf ~/.claude/plugins/project-starter-pack`.

## Requirements

- `bash`, `git`. `jq` only for the optional hooks.
- A git working tree for the project you're setting up, so the briefs can be committed alongside
  the code.
