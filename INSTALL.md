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
| **Claude Code** | `~/.claude/skills/<flow>` (symlink per skill) | by name, or `/starter:setup` / `/starter:extract` / `/starter:validate` if you use the plugin path below |
| **Codex** | `~/.codex/skills/<flow>` | `$<flow>` — e.g. `$setup`, `$design-brief` |
| **Cursor** | `~/.cursor/skills/<flow>` and `~/.cursor/commands/starter-<flow>.md` | `/starter-setup`, `/starter-extract`, `/starter-validate`, or any skill by name |
| **Antigravity** | nothing — it has no skill or command surface | plain language: *"walk me through the product brief using the project-starter-pack questionnaire at `<path>`"* |

The command surface is three verbs — generate, seed, check. The three brief flows are skills only:
run one through `setup` with a scope word (`/starter:setup design`) or ask for it by name. Codex and
Antigravity are unaffected either way — neither ever had a command surface.

Antigravity is still fully supported: it reads the generated `AGENTS.md` in your projects natively,
and `install.sh` prints the exact phrasing to start a flow. The generated `AGENTS.md` also records
the pack's path in its "Maintaining these files" section, so an agent can find it later
without you.

The Cursor command files are **generated** from `commands/*.md` by `render-ports.sh`, which
`install.sh` runs every time. Never hand-edit them — edit the canonical command and re-install.

## Option 2 — Claude Code plugin (zero scripts)

Claude-Code-only users can skip `install.sh` entirely and clone the repo as a plugin. This gets the
`/starter:*` commands and the skills together:

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

The two paths coexist, but there is no reason to run both for Claude Code — pick the plugin if
Claude Code is the only tool you use, and `install.sh` if it isn't.

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
`/starter-setup` in Cursor, or "run the project starter pack setup" anywhere. You should see it ask
what to run (everything, or one brief) before the intro.

If nothing happens, check that the symlink exists and resolves:

```bash
ls -l ~/.codex/skills/setup      # should point into your checkout
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
