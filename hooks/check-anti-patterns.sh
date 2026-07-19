#!/usr/bin/env bash
#
# check-anti-patterns.sh — advisory PostToolUse hook (warn-only, never blocks).
#
# Greps an edited style/component file for a few high-signal, reliably-detectable
# bans from guardrails/design-anti-patterns.md and flags them. It is intentionally
# conservative: only patterns that are almost always a real tell, to keep false
# positives low. Exit is always 0.
#
# Wire it as a PostToolUse hook on Edit|Write|MultiEdit.

set -uo pipefail

input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
else
  file="$(printf '%s' "$input" | grep -oE '"(file_path|path)"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"(file_path|path)"[[:space:]]*:[[:space:]]*"([^"]+)".*/\2/')"
fi

[ -n "${file:-}" ] && [ -f "$file" ] || exit 0
case "$file" in
  *.css|*.scss|*.sass|*.less|*.tsx|*.jsx|*.svelte|*.vue|*.astro) ;;
  *) exit 0 ;;
esac

warn() { echo "anti-pattern: $1 in $file — $2 (design-anti-patterns.md, advisory)" >&2; }

# Animating layout properties (banned: "No animations on layout properties").
# `transition: all` animates them too, so it counts.
grep -qE 'transition[^;]*\b(all|width|height|top|left)\b' "$file" 2>/dev/null \
  && warn "transition on a layout property" "animate transform/opacity instead"

# Glassmorphism by default (banned: "No glassmorphism by default").
grep -qE 'backdrop-filter[[:space:]]*:[[:space:]]*blur' "$file" 2>/dev/null \
  && warn "backdrop-filter: blur (glassmorphism)" "use deliberately or not at all"

# Gradient text (banned: "No gradient text").
grep -qE '(-webkit-)?background-clip[[:space:]]*:[[:space:]]*text' "$file" 2>/dev/null \
  && warn "gradient/clipped text" "rarely meets contrast and reads as dated"

exit 0
