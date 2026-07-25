#!/usr/bin/env bash
#
# guard-design.sh — advisory PostToolUse hook (warn-only, never blocks).
#
# When DESIGN.json is present in the project, the design system is OKLCH-based
# (see guardrails/design-anti-patterns.md: "No pure black/white" / "Use OKLCH").
# Raw hex colors in style files are usually a slip back to the old palette, so
# this nudges — it does not block. Exit is always 0.
#
# Wire it as a PostToolUse hook on Edit|Write|MultiEdit. It reads the tool-call
# JSON on stdin and inspects the edited file.

set -uo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/hook-input.sh"

input="$(cat)"
file="$(hook_file_path "$input")"

[ -n "${file:-}" ] && [ -f "$file" ] || exit 0
hook_is_style_file "$file" || exit 0

# Only nudge when this project actually committed to a token system.
root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
[ -f "$root/DESIGN.json" ] || exit 0

# Hex color literals in a value position: all four CSS lengths (#rgb, #rgba,
# #rrggbb, #rrggbbaa), and only after a `:` on the line so id selectors
# (`#dad {`) and anchors (`href="#add"`) don't false-positive. Conservative by
# design — a hex outside a declaration (e.g. a Tailwind arbitrary value) is
# missed rather than guessed at.
hits="$(grep -nE ':[[:space:]]*[^;{}]*#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b' "$file" 2>/dev/null | head -5)"
if [ -n "$hits" ]; then
  {
    echo "design-guard: raw hex color(s) in $file — DESIGN.json uses OKLCH (design-anti-patterns.md)."
    echo "$hits" | sed 's/^/  /'
    echo "  Prefer the OKLCH tokens from DESIGN.json. (advisory — nothing was blocked)"
  } >&2
fi

exit 0
