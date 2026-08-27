#!/usr/bin/env bash
#
# guard-design.sh — advisory PostToolUse hook (warn-only, never blocks).
#
# When DESIGN.json is present in the project, the design system is OKLCH-based,
# so a raw hex in a style file is usually a slip back to the old palette. This
# enforces guardrails/design-anti-patterns.md: "No raw hex where a token system
# applies". Note the neighbouring ban is "No pure black (#000)" only — the
# registry permits pure white, so do not widen this to a black/white claim.
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

check_one() {
  local file="$1"
  [ -n "$file" ] && [ -f "$file" ] || return 0
  hook_is_style_file "$file" || return 0

  # Hex color literals in a value position: all four CSS lengths (#rgb, #rgba,
  # #rrggbb, #rrggbbaa), and only after a `:` on the line so id selectors
  # (`#dad {`) and anchors (`href="#add"`) don't false-positive. Conservative by
  # design — a hex outside a declaration (e.g. a Tailwind arbitrary value) is
  # missed rather than guessed at.
  local hits
  hits="$(grep -nE ':[[:space:]]*[^;{}]*#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b' "$file" 2>/dev/null | head -5)"
  if [ -n "$hits" ]; then
    {
      echo "design-guard: raw hex color(s) in $file — DESIGN.json uses OKLCH (design-anti-patterns.md)."
      echo "$hits" | sed 's/^/  /'
      echo "  Prefer the OKLCH tokens from DESIGN.json. (advisory — nothing was blocked)"
    } >&2
  fi
}

while IFS= read -r f; do check_one "$f"; done < <(hook_file_paths "$input")

exit 0
