# Contributing

Thanks for looking. This pack is markdown and bash — no build step, no dependencies beyond
`bash`, `grep`, `sed`, and `jq` — so the loop is short: edit, run `./test.sh`, commit.

## The one gate

```bash
./test.sh
```

It must be green before any commit. It runs in seconds and enforces the contracts that rot
silently otherwise:

- **Slot ↔ question ↔ skill ↔ template.** Every `{{SLOT}}` a template defines has a question (or
  a default) that feeds it, and a skill that fills it. Add a slot without its question and the
  pack stays "working" while the output has a hole.
- **The portability contract.** Skills are the engine; every flow exists as a skill, because
  Codex has no command surface. Harness-specific names (`AskUserQuestion`, the `Write` tool,
  `$ARGUMENTS`, Claude's shell-injection dialect, "plugin root") are banned in `skills/`,
  `questionnaires/`, `conventions/`, and `guardrails/`. `conventions/question-mechanics.md` is
  the single exempt file.
- **Guardrail wiring.** Every anti-pattern registry is embedded by the brief that owns it, so
  reading a brief is also reading its bans.
- **Manifest validity.** `claude plugin validate` parses the plugin and marketplace manifests
  when the Claude Code CLI is on `PATH`. A manifest that another program has to parse is checked
  by that program, not by grep.
- **The example is a fixture.** `examples/saga-reader/` must be a complete, placeholder-free
  render whose structure matches the templates. Change a template heading, re-render the example.

If a change requires relaxing a check, retarget the check — don't delete it.

## Where things live

| Directory | What it is |
|---|---|
| `skills/` | The flows. One `SKILL.md` each, and the source of truth. |
| `commands/` | Thin wrappers over skills, under 12 non-blank lines. Never flow logic. |
| `templates/` | The markdown and JSON the flows render. |
| `questionnaires/` | Source-of-truth question banks per brief. |
| `guardrails/` | Anti-pattern registries, embedded by the owning brief. |
| `conventions/` | Shared skill mechanics (how questions get asked per tool). |
| `examples/saga-reader/` | A complete worked render, treated as a test fixture. |
| `hooks/` | Opt-in, warn-only advisory hooks. Not installed by default. |

Two files have a blast radius worth naming. `test.sh` fails open when edited wrongly — the
checks pass while enforcing nothing. `render-ports.sh` runs on every install, so a
non-deterministic change there churns every user's `~/.cursor/commands`. Both carry section
comments explaining what each check defends against. Read them before editing.

Never hand-edit `commands/cursor/`. It is generated from `commands/*.md` by `render-ports.sh`
and gitignored. Edit the canonical command and re-render.

## Things that need a conversation first

Open an issue before a PR when the change would:

- grow the command surface, or add a slot, question, or guardrail;
- require relaxing a `test.sh` check;
- make one tool's experience diverge from the others'.

The command surface is three verbs — `setup`, `extract`, `validate`: generate, seed, check. A
new command needs a reason that survives "is this a verb, or a namespace?".

## Adding a tool target

Add one row to `targets_table()` in `install.sh`, then run `./test.sh`. It installs the new
target into a throwaway `HOME`, once per presence marker, and names every doc that doesn't
mention the tool yet: the two README tables, the `INSTALL.md` table and its paths, and the hook
installer. Each needs a hand-written cell, since what a tool *reads* and how it *invokes* a flow
differ per tool.

Before the row, probe the tool. A skills directory you have not watched a tool load from is a
guess, and the next section is about what a guess costs.

## Claims about other tools

A claim about what Claude Code, Codex, Cursor, or Antigravity can do is not verifiable by
grepping this repo. Probe the tool. `memory/knowledge.md` records how, and what it cost the last
time someone assumed instead — a shipped flow was silently absent in one tool of four for two
releases while every check passed.

For anything another program parses, assert on the parse. Ask the tool what it sees; don't ask
the filesystem what was written.

## Branches and commits

```bash
git checkout -b feat/short-description   # or fix/, docs/
```

Commit messages say what changed and why. The repo uses conventional prefixes (`feat:`, `fix:`,
`docs:`, `test:`, `chore:`) but does not enforce them.

## The change log

`CHANGELOG.md` records changes as **decisions, not diffs**: what changed, the ask that prompted
it, why this approach, and what was considered and rejected. When an entry supersedes an earlier
one, name it and say what new information changed the call.

A human maintainer approves every entry. Propose it in the PR description rather than committing
it unasked.
