# Change Log

AI-made changes to this repository: what changed and why.

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
