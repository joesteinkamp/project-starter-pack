#!/usr/bin/env bash
#
# guard-design.sh — advisory PostToolUse hook (warn-only, never blocks).
#
# Runs the `tokens`-scoped detectors in guardrails/registry.json — the bans
# that only apply once a project has committed to the OKLCH token system, so
# this hook is gated on DESIGN.json existing. Today that is DES-03 ("No raw hex
# where a token system applies"); it is compiled from the prose by
# build-guardrails.sh, not written here.
#
# Note the neighbouring ban is "No pure black (#000)" only — the registry
# permits pure white, so do not widen this into a black/white claim.
# It nudges; it does not block. Exit is always 0.
#
# Wire it on the edit event of whichever tool you run (install-hooks.sh does it
# for Claude Code, Codex, Cursor, and Antigravity). It reads the tool-call JSON
# on stdin and inspects every file that call edited.

set -uo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/hook-input.sh"

input="$(cat)"

# Only nudge when this project actually committed to a token system.
root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
[ -f "$root/DESIGN.json" ] || exit 0

while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  hook_check_scope "$f" tokens
done < <(hook_file_paths "$input")

exit 0
