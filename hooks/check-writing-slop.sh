#!/usr/bin/env bash
#
# check-writing-slop.sh — advisory PostToolUse hook (warn-only, never blocks).
#
# Runs every `prose`-scoped detector in guardrails/registry.json against an
# edited prose file. The detectors are compiled by build-guardrails.sh from
# guardrails/writing-anti-patterns.md and its .detect.md sidecar; which bans
# are safe to grep for is recorded there as a `confidence` field rather than in
# a comment here ("robust" and "leverage" stay out of WRT-01 because tech docs
# use them honestly). Exit is always 0.
#
# Wire it on the edit event of whichever tool you run (install-hooks.sh does it
# for Claude Code, Codex, Cursor, and Antigravity).

set -uo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/hook-input.sh"

input="$(cat)"

while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  hook_check_scope "$f" prose
done < <(hook_file_paths "$input")

exit 0
