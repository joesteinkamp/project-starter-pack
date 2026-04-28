# Install

`project-starter-pack` is a Claude Code plugin. Pick the install path that matches how you want to use it.

## Option 1 — Use it directly in your project

Clone the repo into your project's `.claude/plugins/` directory:

```bash
mkdir -p .claude/plugins
git clone https://github.com/joesteinkamp/project-starter-pack.git .claude/plugins/project-starter-pack
```

Then in Claude Code, the commands and skills will be available:
- `/starter:setup`
- `/starter:product-brief`
- `/starter:design-brief`
- `/starter:code-brief`
- `/starter:project-brief`
- `/starter:orchestrate`
- `/starter:feedback`
- `/starter:evaluate`
- `/starter:report-issue`

## Option 2 — Install globally for all projects

Clone into your user-level Claude Code plugins directory:

```bash
mkdir -p ~/.claude/plugins
git clone https://github.com/joesteinkamp/project-starter-pack.git ~/.claude/plugins/project-starter-pack
```

The commands and skills become available in every Claude Code session.

## Option 3 — Symlink during development

If you're hacking on the plugin itself:

```bash
git clone https://github.com/joesteinkamp/project-starter-pack.git ~/code/project-starter-pack
ln -s ~/code/project-starter-pack ~/.claude/plugins/project-starter-pack
```

Edits to the source repo are immediately available.

## Verify

Open Claude Code in a project. Run:

```
/starter:setup
```

You should see the intro message describing the four-step flow. If you don't, the plugin isn't being picked up — confirm the directory structure (the `.claude-plugin/plugin.json` file must be at the plugin root, alongside `commands/` and `skills/`).

## Update

```bash
cd ~/.claude/plugins/project-starter-pack    # or wherever you installed it
git pull
```

## Uninstall

```bash
rm -rf ~/.claude/plugins/project-starter-pack
```

## Requirements

- Claude Code with plugin support enabled.
- A git working tree for the project you're setting up (so the briefs can be committed alongside the code).
