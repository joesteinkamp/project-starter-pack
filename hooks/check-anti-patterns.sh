#!/usr/bin/env bash
#
# check-anti-patterns.sh — advisory PostToolUse hook (warn-only, never blocks).
#
# Runs every `style`-scoped detector in guardrails/registry.json against an
# edited style/component file. The detectors are not written here: they are
# compiled by build-guardrails.sh from guardrails/design-anti-patterns.md and
# its .detect.md sidecar, so adding a ban to the prose arms it here with no
# edit to this file. Exit is always 0.
#
# Wire it on the edit event of whichever tool you run (install-hooks.sh does it
# for Claude Code, Codex, Cursor, and Antigravity).

set -uo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/hook-input.sh"

input="$(cat)"

while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  hook_check_scope "$f" style
done < <(hook_file_paths "$input")

exit 0
