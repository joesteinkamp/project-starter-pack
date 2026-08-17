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

## Frontmatter must be valid YAML, not YAML-ish (2026-08-17)

A plain (unquoted) YAML scalar **cannot contain `": "`** — colon-space is the key/value separator,
so `description: Guided setup. Scoped at the start: everything` is a syntax error, not a style
quibble (`mapping values are not allowed in this context`).

`skills/setup/SKILL.md` shipped exactly that. Claude Code, Codex, and Cursor all parsed it anyway.
Antigravity rejected the file and dropped the skill **silently** — no error, no warning, no entry
in the skill list. The pack's front-door flow was simply absent in one tool of four, and stayed
that way from the moment Antigravity support merged until the next session happened to look at a
real skill list. `test.sh` now fails on the pattern.

**The generalizable rule:** the strictest parser in the target set decides what is portable.
"Three of four tools accept it" is not evidence of correctness — it is three lenient parsers and
one that follows the spec. When output feeds several tools, validate against the spec, not against
whichever tool you happen to be running in.

**And the testing lesson, which is the more expensive one:** a check that a file is *present* is
not a check that it *works*. The installer tests written one session earlier asserted that
symlinks landed in the right place, and passed the entire time the flagship skill was failing to
load. For anything that another program has to parse, assert on the parse — ask the tool what it
sees, do not ask the filesystem what was written. Both probes for that live in the entry above.
