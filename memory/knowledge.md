# Project Knowledge

Non-obvious facts, decisions, and gotchas that the code alone won't tell you.
Read this before doing substantive work.

---

<!-- Entries are added by the agent (with user approval) when iterative
     discovery surfaces something worth remembering. Group related entries
     under H2 headings as the file grows. -->

## Antigravity has a full skills system (2026-08-17)

**Where they go:** `~/.gemini/config/skills/<name>/SKILL.md` machine-globally — `~/.gemini/config/`
is Antigravity's global customization root. Also `.agents/skills/` per-workspace (or `.agent/`,
`_agents/`, `_agent/`), and `skills.json` to register directories in arbitrary locations. The
format is the same `name` + `description` frontmatter every other tool uses, with the same
progressive disclosure: only names and descriptions sit in context until a skill activates.

Its full customization system is Rules (`AGENTS.md` / `GEMINI.md`), Skills, Plugins
(`plugins/<name>/plugin.json` — a *different* schema from Claude's `.claude-plugin/plugin.json`),
Hooks, and MCP servers.

**Why this is worth writing down:** the pack shipped for two releases describing Antigravity as
having "no skill or command surface" and installing nothing for it. What is true is that it has no
*command* surface; that got conflated with having no surface at all, and the wrong claim
propagated into `README.md`, `INSTALL.md`, `render-ports.sh`, `skills/setup/SKILL.md`, the
`AGENTS.md` template, and the example fixture. Every `test.sh` check passed the whole time,
because they were all string-level. Fixed in #15, which also added installer tests that assert on
the filesystem.

**The lesson that generalizes:** a claim about what a *tool* can do is not verifiable by grepping
this repo. When a target's capabilities are the thing in question, probe the tool. Both behaviors
in #15 were confirmed before being built on, cheaply:

- `agy -p "<trigger>"` with a throwaway skill in `~/.gemini/config/skills/` — it activated from
  its description alone. `agy` is Antigravity's CLI; `agy --help` lists `plugin`, `models`,
  `agents`. There is no `skills` subcommand, so `-p` is the probe.
- `claude -p "/<dir>:<name>"` with a throwaway `~/.claude/commands/<dir>/<name>.md` — confirming
  that Claude Code builds a command's name from its path.

**Authoritative reference:** Antigravity bundles its own docs as a skill —
`~/.gemini/antigravity-cli/builtin/skills/agy-customizations/`, with `docs/skills.md`,
`docs/plugins.md`, `docs/hooks.md`, `docs/json_configs.md`, and `docs/rules.md`. Read that before
assuming anything about what Antigravity supports.
