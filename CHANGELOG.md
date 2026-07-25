# Change Log

AI-made changes to this repository: what changed and why.

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
