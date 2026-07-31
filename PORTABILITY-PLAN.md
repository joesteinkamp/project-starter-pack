# Portability plan — make project-starter-pack agent-agnostic

**Goal:** the pack installs and runs in **Claude Code, Codex, Cursor (agent), and Antigravity**
— same flows, same outputs — instead of being a Claude Code plugin that other tools can only
read the outputs of.

**Inspiration:** [`~/projects/agent-global-instructions`](../agent-global-instructions) — its
proven patterns: one canonical source + generated per-tool ports, skills as the portable
engine, a multi-target `install.sh`, platform-adapter hooks, and a `test.sh` that enforces
render parity. This plan reuses those patterns at the project-pack level.

---

## Where the pack is Claude-coupled today

| # | Coupling | Where |
|---|----------|-------|
| 1 | Runtime is a Claude Code plugin only | `.claude-plugin/plugin.json`, `commands/` (`/starter:*`) |
| 2 | `setup` exists **only** as a slash command — no skill | `commands/setup.md` (no `skills/setup/`) — in a skills-only tool (Codex) the mega-flow is unreachable |
| 3 | Claude-only tool names baked into flows | `AskUserQuestion` in every brief skill + `questionnaires/product.questions.md`; `Write` tool named in skills |
| 4 | `/starter:*` invocations sprinkled everywhere | commands, skills, templates, examples, README, INSTALL — meaningless in Codex (`$name`), Cursor (`/name`), Antigravity (no commands) |
| 5 | Skills locate resources via "the plugin root" | every `SKILL.md` — breaks when a skill dir is installed alone into `~/.codex/skills/` |
| 6 | Claude command dialect in two commands | `` !`git diff …` `` shell-injection in `commands/validate.md`; `$ARGUMENTS` in `extract.md`/`validate.md` |
| 7 | Hooks install only into Claude settings | `hooks/install-hooks.sh` → `.claude/settings.json` (`PostToolUse`) |
| 8 | Output side: canonical file is `AGENT.md`, not spec-named `AGENTS.md` | orchestrator, templates, examples — Codex/Cursor/Antigravity auto-read **`AGENTS.md`** (the actual [agents.md](https://agents.md) filename); `AGENT.md` they do not |
| 9 | `GEMINI.md` harness targets a retired tool | Gemini CLI is retired; Antigravity replaced it **and reads `AGENTS.md` natively** (per agent-global-instructions) |
| 10 | Docs assume Claude Code | README ("this is a Claude Code plugin"), INSTALL (plugin paths only) |

## What each target tool supports

Facts as encoded in `agent-global-instructions` (the working reference on this machine):

| Capability | Claude Code | Codex | Cursor | Antigravity |
|---|---|---|---|---|
| Slash commands | ✅ `/starter:*` (plugin) | ❌ | ✅ `~/.cursor/commands/*.md` (plain md, no frontmatter, no `!` injection) | ❌ (command install not supported) |
| Skills (`SKILL.md`) | ✅ plugin `skills/` or `~/.claude/skills/` | ✅ `~/.codex/skills/<name>/SKILL.md`, invoked `$<name>` | ✅ `~/.cursor/skills/` | ❌ — natural-language + `AGENTS.md` pointer only |
| Project instructions | `CLAUDE.md` (`@import`) | `AGENTS.md` natively | `AGENTS.md` natively (+ `.cursor/rules/*.mdc` scoped) | `AGENTS.md` natively |
| Hooks | ✅ `settings.json` | ✅ (adapter) | ✅ (adapter) | ✅ `~/.gemini/antigravity-cli/hooks.json` (own schema, `HOOK_PLATFORM` wrappers) |
| Structured question tool | ✅ `AskUserQuestion` | ❌ | ❌ | ❌ |

**Consequence:** skills are the portable engine (3 of 4 tools run them natively); commands are
a Claude/Cursor convenience layer; Antigravity is reached through `AGENTS.md` + natural-language
triggers; and renaming the canonical output to `AGENTS.md` makes Codex/Cursor/Antigravity
output support free.

---

## Phase 1 — Skills become the canonical engine

The pack inverts: today commands are primary and skills mirror them. After this phase, **each
flow lives once, in its skill**, and commands are thin wrappers.

1. **Add `skills/setup/SKILL.md`** — the guided end-to-end flow, currently command-only.
   Trigger phrases: "set up this project", "run the starter pack", "project setup flow".
   With it, all seven flows exist as skills: setup, product-brief, design-brief, code-brief,
   orchestrator, validate, extract.
2. **Slim `commands/*.md` to wrappers**: frontmatter + "Invoke the `<name>` skill. Pass any
   typed focus as context." Flow logic lives only in the skill (single source of truth — the
   same rule agent-global-instructions applies to its command ports).
3. **Neutralize tool names** in skills and questionnaires:
   - `AskUserQuestion` → capability language: *"Ask as a structured multiple-choice question.
     Use the harness's structured-question tool if it has one (`AskUserQuestion` in Claude
     Code); otherwise present numbered options in chat and accept a number or free text."*
     One shared "Question mechanics" paragraph, referenced from each skill, instead of
     repeating the fallback seven times.
   - `Write` tool → just "write the file".
4. **Kill "plugin root" path discovery.** Every skill references its resources **relative to
   its own `SKILL.md`** (`../../questionnaires/…`, `../../templates/…`, `../../guardrails/…`).
   Installation symlinks whole skill dirs (Phase 3), so relative paths resolve through the
   symlink into the repo checkout.
   - *Considered and rejected:* vendoring copies of questionnaires/templates into each skill
     dir (self-contained skills). Rejected because seven skills share the same templates and
     guardrails — copies drift, and `test.sh`'s slot↔question↔template contract would have to
     police every copy.
5. **Replace `/starter:*` cross-references** with tool-neutral phrasing ("run the
   `design-brief` skill") plus one **invocation table** in README (Phase 6) that maps each
   flow to its syntax per tool. Skills' "Next:" lines point at flow names, not slash syntax.

## Phase 2 — Per-tool invocation surfaces

- **Claude Code** — unchanged: the plugin manifest keeps `/starter:*` and auto-triggering
  skills. `.claude-plugin/plugin.json` stays.
- **Codex** — install each skill at `~/.codex/skills/<name>/` (symlink); invoked as `$<name>`
  or by natural language. Skill frontmatter (`name`, `description`) already matches. No
  command port — Codex has none.
- **Cursor** — install skills at `~/.cursor/skills/` (symlink) **and** render optional command
  ports to `~/.cursor/commands/starter-<name>.md` (plain markdown, generated, gitignored).
- **Antigravity** — no installable surface. It participates two ways:
  1. It reads the generated `AGENTS.md` in target projects (output side — free after Phase 4).
  2. To *run the pack's flows* in Antigravity, the generated `AGENTS.md` (and the pack's own
     README) carries a short pointer: where the pack lives on disk and the natural-language
     phrases that start each flow ("walk me through the product brief using the
     project-starter-pack questionnaire at <path>"). Hooks wire separately (Phase 5).
- **Dialect fixes** (only two files use Claude-specific syntax):
  - `commands/validate.md` `` !`git diff --stat HEAD …` `` → move into the skill as an
    instruction: *"Run `git diff --stat HEAD` first and use the output."* Works everywhere;
    Claude merely loses the pre-injection (negligible — one extra tool call).
  - `$ARGUMENTS` in `extract.md`/`validate.md` → stays in the Claude command wrappers only;
    skills phrase it as "any focus supplied in the request."

## Phase 3 — `install.sh` (modeled on agent-global-instructions)

```
./install.sh                    # all four tools, asks once; --yes skips
./install.sh codex cursor       # subset
./install.sh --uninstall        # remove exactly what was installed
```

- **Symlink, don't copy** (dev-friendly, `git pull` = instant update): repo skill dirs →
  `~/.claude/skills/` (for non-plugin installs), `~/.codex/skills/`, `~/.cursor/skills/`;
  rendered command ports → `~/.cursor/commands/`.
- **Renderer** (`render-ports.sh`): generates the Cursor command ports from the canonical
  commands with the same transforms as agent-global-instructions' `render-commands.sh`
  (strip frontmatter, `` !`cmd` `` → ``run `cmd` ``, `$ARGUMENTS` note). Ports are
  **generated, gitignored, never hand-edited**; install re-renders every run; atomic writes
  (temp + `mv`), prune-after-success — steal those hardening details, they were earned.
- Idempotent; skips a tool cleanly when its config dir is absent (the agent-global-instructions
  "clean no-op" behavior).
- Claude plugin install path (clone into `.claude/plugins/`) remains supported and documented
  as the zero-script option for Claude-only users.

## Phase 4 — Output-side agnosticism (the orchestrator)

1. **Rename the canonical output `AGENT.md` → `AGENTS.md`** — the actual agents.md spec
   filename. Codex, Cursor, and Antigravity all auto-read it; nothing extra to emit for any
   of them. Ripples: `templates/AGENT.template.md` → `AGENTS.template.md`; `CLAUDE.md`
   imports `@AGENTS.md`; orchestrator/README/examples updated.
   - *Migration:* orchestrator's pre-flight detects a legacy `AGENT.md`, offers to regenerate
     as `AGENTS.md` and delete the old file.
   - *Considered and rejected:* writing both files (drift risk, two sources of truth) or
     keeping `AGENT.md` (fails the whole point — tools don't auto-read it).
2. **Rework the harness picker** in the orchestrator skill:
   - Always written: `AGENTS.md` + `WRITING.md` — and the picker now *says* this covers
     **Codex, Cursor, and Antigravity natively**, so users see those tools are supported,
     not absent.
   - **Claude Code** (default on) → `CLAUDE.md` (thin `@AGENTS.md` import).
   - **Cursor scoped rules** (opt-in) → `.cursor/rules/project.mdc`. The old "simple copy to
     `AGENTS.md`" option disappears — it's now the always-on default for everyone.
   - **Gemini CLI** → demote to a legacy opt-in ("retired tool — only if you still run it"),
     or drop the template entirely. **Recommendation: demote now, drop in the release after.**
3. **Fix regeneration notes** in templates (e.g. `GEMINI.template.md` says the pack "runs in
   Claude Code — not available in this harness"): reword to "re-run the pack's `orchestrator`
   flow from any tool it's installed in (Claude Code, Codex, Cursor)."

## Phase 5 — Hooks: multi-tool adapters

Keep the hooks **opt-in and warn-only** (unchanged philosophy). Port the adapter pattern from
agent-global-instructions' `install-hooks.sh`:

- `hooks/lib/hook-input.sh` (already exists) grows a `HOOK_PLATFORM` switch that normalizes
  each tool's hook payload (file path in, JSON out per that tool's schema).
- `hooks/install-hooks.sh [claude|codex|cursor|antigravity]` — default all present; per-tool
  merge into: Claude `settings.json` `PostToolUse` (as today), Cursor's hooks config, Codex's
  hook mechanism, Antigravity's `~/.gemini/antigravity-cli/hooks.json` via thin
  `HOOK_PLATFORM=antigravity` wrapper scripts. Copy the exact merge/backup/uninstall behavior
  already proven in agent-global-instructions rather than reinventing it.
- Lowest-priority phase: hooks are advisory nudges; the pack is fully usable without them.

## Phase 6 — Docs, example, tests

- **README** — drop "this is a Claude Code plugin"; add the support matrix and a per-tool
  **invocation table** (`/starter:setup` · `$setup` · `/starter-setup` in Cursor · "run the
  starter setup" in Antigravity). "Out of scope: a standalone CLI" stays true — `install.sh`
  is an installer, not a runtime.
- **INSTALL.md** — rewrite around `install.sh` with per-tool sections; keep the Claude plugin
  clone path as Option 1 for Claude-only users.
- **examples/saga-reader** — `AGENT.md` → `AGENTS.md`; mark `GEMINI.md` legacy (or remove
  with the template); update every cross-reference inside the example files.
- **test.sh** — extend the contract:
  - every flow has a skill; every command is a thin wrapper naming an existing skill;
  - no `AskUserQuestion` / `Write`-tool / `` !`cmd` `` / "plugin root" strings in skills or
    questionnaires (grep-able ban list, same style as the existing checks);
  - `/starter:` appears only in Claude-surface files (commands/, README's invocation table,
    CLAUDE.template);
  - `render-ports.sh` is idempotent and yields a port per canonical command;
  - example structure still matches templates after the `AGENTS.md` rename.

---

## Sequencing and effort

| Order | Phase | Size | Risk |
|---|---|---|---|
| 1 | Phase 1 (skills canonical) + Phase 2 (dialect fixes) | M | Low — internal refactor, Claude behavior unchanged |
| 2 | Phase 4 (AGENTS.md rename + picker) | M | Medium — breaking rename for existing users; migration note required |
| 3 | Phase 3 (install.sh + renderer) | M | Low — additive; steal hardened script patterns |
| 4 | Phase 6 (docs, example, test.sh) | M | Low — but do test.sh checks *with* each phase, not after |
| 5 | Phase 5 (hooks adapters) | S–M | Low — optional layer |

Each phase lands as its own commit(s) with `./test.sh` green; the test additions in Phase 6
should actually be written alongside the phase they guard.

## Open decisions (for Joe)

1. **Gemini CLI target:** demote to legacy opt-in (recommended) or drop `GEMINI.template.md`
   immediately?
2. **`AGENT.md` → `AGENTS.md`:** confirm the breaking rename (recommended — it's the spec
   filename and what makes Codex/Antigravity support free). Migration is a pre-flight offer,
   not silent.
3. **Cursor command ports:** ship them (`/starter-setup` etc. in Cursor) or rely on skills
   alone there? Recommendation: ship — the renderer is small and the pattern already exists.
