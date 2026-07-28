#!/usr/bin/env bash
#
# check-writing-slop.sh — advisory PostToolUse hook (warn-only, never blocks).
#
# Greps an edited prose file for a few high-signal, reliably-detectable bans
# from guardrails/writing-anti-patterns.md. It is intentionally conservative:
# only tells that are almost never legitimate — "robust" and "leverage" are
# excluded because tech docs use them honestly. Exit is always 0.
#
# Wire it on the edit event of whichever tool you run (install-hooks.sh does it
# for Claude Code, Codex, Cursor, and Antigravity).

set -uo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/hook-input.sh"

input="$(cat)"

check_one() {
  local file="$1"
  [ -n "$file" ] && [ -f "$file" ] || return 0
  hook_is_prose_file "$file" || return 0

  warn() { echo "writing-slop: $1 in $file — $2 (writing-anti-patterns.md, advisory)" >&2; }

  # AI-flagship vocabulary (banned: "No AI-flagship words"). Word-bounded and
  # case-insensitive; only the near-zero-false-positive subset of the ban list.
  if grep -qiwE "delve|delves|delving|tapestry|paradigm shift|game.changer" "$file" 2>/dev/null \
     || grep -qiF "let's dive in" "$file" 2>/dev/null; then
    warn "AI-flagship vocabulary (delve / tapestry / paradigm shift / game changer)" "use the plainer word"
  fi

  # Empty framing phrases (banned: "No empty phrases", "No throat-clearing",
  # "No summary-recap endings").
  if grep -qiE "it'?s worth noting|in conclusion|here'?s the thing|what nobody tells you" "$file" 2>/dev/null; then
    warn "empty framing phrase (worth noting / in conclusion / here's the thing)" "cut it and lead (or end) with the point"
  fi

  # Em-dash clusters (banned: "No em-dash clusters"). A density check, not a ban
  # on the character: a handful across a long doc is fine, a pile is a tell.
  local dashes
  dashes="$(grep -o '—' "$file" 2>/dev/null | wc -l | tr -d '[:space:]')"
  if [ "${dashes:-0}" -gt 5 ] 2>/dev/null; then
    warn "em-dash cluster ($dashes in one file)" "keep 1-2 per piece; prefer commas or periods"
  fi

  return 0
}

while IFS= read -r f; do check_one "$f"; done < <(hook_file_paths "$input")

exit 0
