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

input="$(cat)"

# Extract the edited file path (jq if available, else a tolerant grep).
if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
else
  file="$(printf '%s' "$input" | grep -oE '"(file_path|path)"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"(file_path|path)"[[:space:]]*:[[:space:]]*"([^"]+)".*/\2/')"
fi

[ -n "${file:-}" ] && [ -f "$file" ] || exit 0

# Only style-bearing files.
case "$file" in
  *.css|*.scss|*.sass|*.less|*.tsx|*.jsx|*.svelte|*.vue|*.astro) ;;
  *) exit 0 ;;
esac

# Only nudge when this project actually committed to a token system.
root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
[ -f "$root/DESIGN.json" ] || exit 0

# Raw hex literals like #fff or #aabbcc (skip 8-digit hashes that aren't colors).
hits="$(grep -nE '#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?\b' "$file" 2>/dev/null | head -5)"
if [ -n "$hits" ]; then
  {
    echo "design-guard: raw hex color(s) in $file — DESIGN.json uses OKLCH (design-anti-patterns.md)."
    echo "$hits" | sed 's/^/  /'
    echo "  Prefer the OKLCH tokens from DESIGN.json. (advisory — nothing was blocked)"
  } >&2
fi

exit 0
