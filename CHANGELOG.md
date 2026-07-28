# Change Log

AI-made changes to this repository: what changed and why.

## 2026-07-27 — Claude Opus 5 (portability: four tools, one pack; Gemini retired)

**Ask:** execute `PORTABILITY-PLAN.md` — make the pack install and *run* in Claude Code, Codex,
Cursor, and Antigravity, instead of being a Claude Code plugin whose outputs other tools can
only read. Mid-execution Joe amended one decision: sunset Gemini outright rather than demote it.

**What changed:**

- **Skills became the canonical engine.** Every flow lives once in its `SKILL.md`; the seven
  `commands/*.md` are thin wrappers (6–9 non-blank lines) that name a skill and nothing else.
  Added the missing **`skills/setup/`** — the mega-flow existed only as a command, so it was
  unreachable in a skills-only tool.
- **Harness lock-in removed from the portable layer.** `AskUserQuestion`, the `Write` tool by
  name, Claude's `` !`cmd` `` injection, `$ARGUMENTS`, and "locate the plugin root" are gone
  from skills and questionnaires. New **`conventions/question-mechanics.md`** is the single file
  allowed to name a specific harness's tools ("use `AskUserQuestion` in Claude Code; otherwise
  print numbered options"). Skills address shared resources as `../../…`, which resolves through
  the install symlink back into the checkout — so a skill dir installed alone still finds them.
- **`AGENT.md` → `AGENTS.md`** — the actual [agents.md](https://agents.md) filename, which
  Codex, Cursor, and Antigravity read automatically. Ripples through templates, orchestrator,
  example, and docs; `CLAUDE.md` now imports `@AGENTS.md`. The orchestrator's pre-flight offers
  migration off a legacy `AGENT.md` instead of deleting it silently, and `AGENTS.md` gained a
  `{{REGENERATION_NOTE}}` recording the pack's path on disk plus per-tool invocation — that is
  how a tool with no command surface finds and re-runs the flows.
- **Gemini CLI retired.** `templates/GEMINI.template.md` and the example render are deleted;
  **Antigravity** — its successor, which reads `AGENTS.md` natively — is supported in its place.
  The harness picker now states up front that `AGENTS.md` already covers Codex, Cursor, and
  Antigravity, and only asks about tools wanting a file of their own (Claude Code, default on;
  Cursor scoped rules, opt-in). The orchestrator offers to clean up a stale `GEMINI.md`.
- **`install.sh` + `render-ports.sh`.** Symlinks (never copies, so `git pull` updates every
  tool) skill dirs into `~/.claude`, `~/.codex`, `~/.cursor`, and renders + links Cursor's
  `/starter-*` command ports from the canonical commands. Idempotent, skips a tool whose config
  dir is absent, refuses to replace a real file it did not create, and `--uninstall` removes
  only symlinks resolving into the checkout. Ports are gitignored — generated, never hand-edited.
- **Hooks across all four tools** behind `HOOK_PLATFORM`, which selects the payload dialect:
  Claude's `tool_input.file_path`, Cursor's top-level `file_path`, Antigravity's JSON-encoded
  `toolCall.args.TargetFile`, and Codex's `apply_patch` envelope (paths live in the patch text,
  not a field — so the hooks now loop over every file a call touched). A bare
  `install-hooks.sh` still targets Claude Code project-scope only, deliberately: it is the one
  tool with a per-project config, so the default never reaches into `$HOME` for tools you
  didn't name.
- **`test.sh` gained a portability contract** (~45 checks): every flow has a skill and every
  skill a wrapper, wrappers stay thin, a grep ban-list for harness tool names and dialect,
  `../../` resource paths, `/starter:` confined to Claude-surface files, an idempotent port
  renderer with one port per command, every `install.sh` target branch present, and the Gemini
  sunset enforced. Multi-tool install fixtures run under a sandboxed `HOME` so a test run can
  never touch the developer's real config (verified: `~/.codex` and `~/.cursor` untouched).

**Why this approach:** skills are the one surface three of the four tools run natively, so
inverting the commands-primary/skills-mirror relationship makes portability structural instead
of duplicated. The `AGENTS.md` rename is what buys Codex, Cursor, and Antigravity output support
for free — it is the filename they already look for. Symlinks over copies so one `git pull`
updates every tool at once.

**Considered and rejected:** *vendoring* questionnaires/templates into each skill dir to make
skills self-contained — seven skills share them, copies drift, and the slot↔question contract
would have to police every copy; relative paths through the symlink achieve the same isolation.
*Writing both* `AGENT.md` and `AGENTS.md` during migration — two sources of truth, which is the
drift this pack exists to prevent. *Keeping* `AGENT.md` — fails the whole point, since no tool
auto-reads it. *Codex command ports* — Codex has no command surface; its skills answer to
`$<flow>`. **Supersedes** the plan's own recommendation to demote Gemini to a legacy opt-in:
Joe called it mid-session, and he is right that a template nothing regenerates is a drift
machine — the CLI is retired and Antigravity needs no file at all.

Also committed: `PORTABILITY-PLAN.md` and `AGENTS-ROUTER-PLAN.md` (the latter a *follow-on*
plan to replace the orchestrator with a routing `AGENTS.md`; its baseline is now satisfied but
it is deliberately unexecuted).

6 new files, 1 renamed, 2 deleted, 36 edited; +1056/−525. 306/306 checks pass (was 256);
shellcheck clean. Five of the new portability checks were mutation-verified.

## 2026-07-25 — Claude Fable 5 (writing layer: WRITING.md + fifth guardrail + writing hook)

**Ask:** the pack guarded product, UX, design, and code slop but had no rules for prose — UI
labels through long-form copy. Joe asked for a `WRITING.md` that teaches agents how not to
write AI slop, grounded in [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop)
(MIT; credited in README Attribution).

**What changed:**

- **`guardrails/writing-anti-patterns.md`** — fifth ban registry in the grouped-bullet
  dialect: flagship vocabulary, empty adverbs/phrases, sentence patterns (binary contrasts,
  colon reveals, negative listing…), openers/framing, puffery, endings, formatting slop, and
  a Microcopy group written for the UI-label side (cutesy errors, blame-the-user copy, vague
  button verbs), closing with the slop test.
- **`templates/WRITING.template.md`** — a *synthesized* template, not a brief:
  Voice / Vocabulary & terminology / Microcopy / Long-form / anti-patterns. The orchestrator
  now always writes `WRITING.md` alongside `AGENT.md`, filling voice from `PRODUCT.md` and
  microcopy context from `DESIGN.md` — deferring upward, never duplicating the briefs.
- **`hooks/check-writing-slop.sh`** — third advisory hook (warn-only, exit 0) on prose files:
  flagship words, empty framing phrases, em-dash clusters (>5/file). Wired into the installer,
  snippet, and hooks README; `hook_is_prose_file` added to the shared lib.
- **Wiring:** orchestrator + validate skills (new Writing/Copy review lens; Mode A voice row
  now cross-checks WRITING.md), `AGENT.template.md` (`### Writing` ban block + a writing item
  in the AI Slop self-check), `examples/saga-reader/WRITING.md` render + example AGENT.md,
  `test.sh` (`SYNTH_TEMPLATES`, required render check, `check_link` generalized to take the
  guardrail file; the installer-idempotence fixture now derives its expected entry count from
  `HOOK_SCRIPTS` instead of a hardcoded 2), README/orchestrate docs.

**Why this approach:** guardrail + orchestrator-synthesized template instead of a fourth
brief — writing rules derive from decisions `PRODUCT.md` and `DESIGN.md` already capture, so
a dedicated questionnaire would mostly re-ask answered questions. *Rejected:* a full fourth
brief (questionnaire/skill/command, ~25 files) — Joe chose the lighter shape; hook checks for
"robust"/"leverage" — too many legitimate uses in tech docs, the hook keeps only
near-zero-false-positive tells.

4 new files + 12 edited; 256/256 checks pass.

## 2026-07-25 — Claude Fable 5 (cross-vendor review + fixes)

**Ask:** `/improve` on the two post-merge commits, then "fix all." Six review lenses ran —
three local Claude subagents (architect, back-end, design-systems; the first two verified
findings empirically in throwaway repo copies) plus Cursor (two runs) and Gemini as
cross-vendor refuters. Codex was dropped mid-review to an OpenAI 503 outage; its shell lens
was redistributed to Cursor.

**What changed and why:**

- **Installer correctness** (`hooks/install-hooks.sh`): the `jq … && mv` merge swallowed
  failures and printed success with exit 0; hook ownership matched by basename suffix and
  could delete a user's own same-named script; the rolling `.bak` destroyed the pristine
  original on the second run. Now: loud failure path, exact-path ownership derived from
  `HOOK_SCRIPTS` (killing a duplicated hardcoded list), first-run-only backup (gitignored),
  deep shape guard, zero-byte/`mktemp`/file-mode fixes, and an `--uninstall` flag. Shared
  stdin parsing moved to `hooks/lib/hook-input.sh`. *Rejected:* marker-field tagging of our
  entries — exact path matching is simpler; the trade-off (stale entries if the repo moves)
  is documented instead.
- **Hook precision:** the transition regex spanned semicolon-less JSX lines and flagged
  `transition-colors`; the hex matcher missed `#rgba`/`#rrggbbaa` while firing on id
  selectors and anchors. Both are now declaration-anchored, verified against 17 live cases.
- **Token schema** (breaking shape change, supersedes the 2026-07-19 light/dark nesting):
  `color.light.*`/`color.dark.*` made the theme part of the token path, so Style Dictionary
  emitted `--color-light-background` and Tailwind `bg-light-background` — every consumer
  needed a hand-written remap. Now flat `color.*` holds the default theme and `themes.dark`
  overrides it; single-theme systems (light *or* dark) delete `themes` entirely, symmetric in
  both directions. Added `accentForeground` and `borderStrong`: text-on-accent measured
  2.4–2.6:1 and borders 1.27:1 while `DESIGN.md` claimed "contrast verified" — all meaningful
  pairs now compute AA-clean and the claim is a measured audit table. Numeric tokens emit
  bare numbers; spacing scale is a real array; the misleading DTCG `$schema` claim became an
  honest format description. *Rejected:* per-theme slot renames (`COLOR_*_LIGHT`) —
  questionnaire slots stay stable; the default-theme convention is documented instead.
- **Test soundness** (`test.sh`): the JSON check was presence-only (deleting `spacing.scale`
  passed), the guardrail check never looked at the hooks, and nothing bound the layering
  note or the advertised command/skill inventory to their sources. Now a bidirectional jq
  path diff, two-way guardrail↔hook linkage, layering/inventory binding, fence hygiene, and
  digit-safe parity — all mutation-verified (7 planted regressions caught; a legitimate
  light-only token file passes). Fixed a self-inflicted SIGPIPE-under-pipefail false negative
  the 2026-07-19 entry had warned about in another spot.
- **Multi-harness completion:** the orchestrator body still taught the two-file world and its
  overwrite gate missed `GEMINI.md`/`AGENTS.md`; README lede and plugin.json had the same
  stale copy. Questionnaires now collect breakpoints (Q18b), route line-height/measure into
  tokens, and inherit the WCAG level from `PRODUCT.md` (default raised to 2.2 AA);
  `AGENT.md` gains an `## Accessibility` section since it is the one file every agent reads.

25 files, +452/−182; 220/220 checks pass (was 177). Not applied (taste calls, flagged only):
dark foreground halation trim, light/dark hue-drift alignment, splitting `test.sh` into
per-section files.

## 2026-07-20 — Claude Fable 5 (follow-up polish)

Hook installer: preserve user PostToolUse blocks that lack a `hooks` array; reject malformed
`.hooks` shapes with a clear error instead of a raw jq crash. Documented two intentional
constraints in `test.sh` (section 7 lowercase-token rule, JSON key check is presence-only).
2 files, +24/−7; 177/177 checks pass.

## 2026-07-19 — Claude Fable 5 (multi-role review + fixes)

Hardened the integrity linter (`test.sh`): template↔example structural parity, robust
skill-invocation checks, code-fence-aware slot matching; fixed a latent pipefail/SIGPIPE
false-negative. Added light/dark structure to the DESIGN.json token schema and dark values
to the saga-reader fixture. Hook installer now preserves user hooks, validates JSON, keeps
a rolling backup; anti-pattern hook catches `transition: all`. Unified
`{{HARNESS_PROJECT_NOTES}}`, single-sourced the Layering note via `{{LAYERING_NOTE}}`,
thinned `orchestrate`/`validate` commands, and refreshed README/questionnaire copy.
21 files, +250/−133; 177/177 checks pass.
