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

## Stock macOS runs bash 3.2, and only a Mac can test for it (2026-10-25)

**The fact:** on an out-of-the-box Mac, `#!/usr/bin/env bash` finds `/bin/bash` 3.2.57, with BSD
`sed`/`grep`/`readlink` alongside it. Any Mac user who runs the hooks or the installer without
having installed a newer bash gets that interpreter.

**What it cost:** from 2026-08-27 until CI first ran on macOS, every advisory hook enforced
nothing on a Mac. The hooks split registry records with `IFS=$'\x01' read`. bash 3.2 uses `\001`
internally as its quoting byte (CTLESC) and never splits on it, so each record arrived as one
field and every detector was skipped. The hook still exited 0, which looks identical to "nothing
to report." `\x1f` works everywhere. In the same run, BSD `sed` read `sed -i "$expr" file` as a
backup suffix plus a script, so ten `test.sh` probes mutated nothing and passed anyway. The suite
had been 336/336 green on Linux the whole time.

Two constructs to avoid, both banned at the source by `test.sh` check 10i:

- splitting with `read` on `\001` or `\177` (bash 3.2's CTLESC and CTLNUL). `${var//…/…}`
  substitution with those bytes does work in 3.2, which is why `build-guardrails.sh` is fine;
- `sed -i` in any form. GNU and BSD disagree on its argument, so redirect to a file instead.

**The generalizable rule:** the interpreter is part of the target set, and the strictest one
decides what is portable, just as the strictest YAML parser did. A suite that has only run on one
OS has only proven that OS. Grepping for known-bad constructs is a backstop; it catches what is
already known and nothing new.

**The probe:** the `test (macos-latest)` CI job. bash 3.2 cannot be built in the cloud sandboxes
these sessions run in: `ftp.gnu.org`, its mirrors, and GitHub's source archives are all blocked.
For a portability question about a shell construct, push and read the macOS job's log; that log
is a real Mac. A Linux run cannot reproduce the bash 3.2 bug, but one useful local check exists:
making a reader's separator disagree with its writer's reproduces the same failure signature,
because both mean records arriving unsplit.

## Probing Claude Code plugin questions (2026-10-25)

The `claude` CLI answers plugin questions directly, and none of these probes needs to touch a real
config:

- `claude plugin validate .` parses `.claude-plugin/plugin.json` against the real schema, and
  `claude plugin validate .claude-plugin/marketplace.json` does the same for the marketplace. It
  caught `author` declared as a string, which the schema rejects and every string-level check in
  `test.sh` let through. Plain `validate` fails on errors only. `--strict` also fails on the
  warning that a root `CLAUDE.md` isn't loaded as plugin context, which is expected here, since
  that file is this repo's own instructions.
- For an end-to-end install, set `HOME` and `CLAUDE_CONFIG_DIR` to a scratch directory, then run
  `claude plugin marketplace add <path>`, `claude plugin install <name>@<marketplace>`,
  `claude plugin list`, `claude plugin details <name>@<marketplace>`, and
  `claude plugin uninstall <name>@<marketplace>`.
- `details` lists what Claude Code actually loaded. That is how we learned the plugin path
  surfaces each of `commands/setup.md`, `extract.md`, and `validate.md` as a skill with the same
  name as the real skill, so nine are listed for six flows. Tracked in #21, which also asks
  whether the plugin path's invocation is really `/starter:` as `INSTALL.md` claims.
