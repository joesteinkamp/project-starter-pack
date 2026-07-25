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

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/hook-input.sh"

input="$(cat)"
file="$(hook_file_path "$input")"

[ -n "${file:-}" ] && [ -f "$file" ] || exit 0
hook_is_style_file "$file" || exit 0

warn() { echo "anti-pattern: $1 in $file — $2 (design-anti-patterns.md, advisory)" >&2; }

# Animating layout properties (banned: "No animations on layout properties").
# Two anchored patterns instead of a whole-line sweep, so `transition-colors`,
# `var(--all-fast)`, and prose mentions of "all" don't false-positive:
#  1. a CSS transition/transition-property declaration whose *value list* names
#     a layout property (`transition: all`, `transition: margin-top 0.2s`, ...)
#  2. a Tailwind layout-transition utility class (`transition-all`, ...)
layout_props='all|width|height|top|left|right|bottom|margin(-[a-z]+)?|padding(-[a-z]+)?|gap|inset|flex-basis'
if grep -qE "(^|[^[:alnum:]-])transition(-property)?[[:space:]]*:[[:space:]]*([^;}]*[[:space:],])?(${layout_props})([[:space:],;}]|\$)" "$file" 2>/dev/null \
   || grep -qE "(^|[\"'[:space:]])transition-(all|width|height)([\"'[:space:]]|\$)" "$file" 2>/dev/null; then
  warn "transition on a layout property" "animate transform/opacity instead"
fi

# Glassmorphism by default (banned: "No glassmorphism by default").
grep -qE 'backdrop-filter[[:space:]]*:[[:space:]]*blur' "$file" 2>/dev/null \
  && warn "backdrop-filter: blur (glassmorphism)" "use deliberately or not at all"

# Gradient text (banned: "No gradient text").
grep -qE '(-webkit-)?background-clip[[:space:]]*:[[:space:]]*text' "$file" 2>/dev/null \
  && warn "gradient/clipped text" "rarely meets contrast and reads as dated"

exit 0
