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
| **Claude Code** | `~/.claude/skills/<flow>` (symlink per skill) | by name, or `/starter:<flow>` if you use the plugin path below |
| **Codex** | `~/.codex/skills/<flow>` | `$<flow>` — e.g. `$setup` |
| **Cursor** | `~/.cursor/skills/<flow>` and `~/.cursor/commands/starter-<flow>.md` | `/starter-<flow>`, or the skill by name |
| **Antigravity** | nothing — it has no skill or command surface | plain language: *"walk me through the product brief using the project-starter-pack questionnaire at `<path>`"* |

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

Then `/starter:setup`, `/starter:product-brief`, `/starter:design-brief`, `/starter:code-brief`,
`/starter:validate`, `/starter:extract`.

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
`/starter-setup` in Cursor, or "run the project starter pack setup" anywhere. You should see the
intro describing the flow: three briefs, then the `AGENTS.md` wire-up.

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
