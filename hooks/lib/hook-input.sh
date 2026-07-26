# hook-input.sh — shared tool-call JSON parsing for the advisory hooks.
# Sourced by guard-design.sh, check-anti-patterns.sh, and check-writing-slop.sh;
# not executable on its own.

# Print the edited file's path from the tool-call JSON passed as $1 (may be empty).
hook_file_path() {
  local input="$1" p=""
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null
    return
  fi
  # No jq: try "file_path" first and fall back to "path" only when it is absent,
  # so a nested decoy "path" key can't shadow the real target.
  p="$(printf '%s' "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
       | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
  [ -n "$p" ] || p="$(printf '%s' "$input" | grep -oE '"path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
       | sed -E 's/.*"path"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
  printf '%s' "$p"
}

# Is $1 a style-bearing file these hooks should look at?
hook_is_style_file() {
  case "$1" in
    *.css|*.scss|*.sass|*.less|*.tsx|*.jsx|*.svelte|*.vue|*.astro) return 0 ;;
    *) return 1 ;;
  esac
}

# Is $1 a prose-bearing file the writing hook should look at?
hook_is_prose_file() {
  case "$1" in
    *.md|*.mdx|*.markdown|*.txt) return 0 ;;
    *) return 1 ;;
  esac
}
