# shellcheck shell=bash
# hook-input.sh — shared tool-call parsing for the advisory hooks.
# Sourced by guard-design.sh, check-anti-patterns.sh, and check-writing-slop.sh;
# not executable on its own.
#
# One set of hook scripts serves Claude Code, Codex, Cursor, and Antigravity.
# They disagree about where the edited file's path lives in the event payload, so
# install-hooks.sh sets HOOK_PLATFORM in each wired command and the normalizer
# below turns any of the four shapes into a plain list of paths.
#
#   claude       .tool_input.file_path            (Edit|Write|MultiEdit)
#   codex        .tool_input.file_path, or an apply_patch envelope in
#                .tool_input.command listing several files
#   cursor       .file_path at the top level of the afterFileEdit event
#   antigravity  .toolCall.args.TargetFile — args arrive JSON-encoded, so the
#                value comes back wrapped in its own quote pair
#
# Unknown or unset HOOK_PLATFORM falls back to trying every shape, which is what
# makes a hand-wired hook work without the env var.

# Print every edited file path in the tool-call JSON passed as $1, one per line.
hook_file_paths() {
  local input="$1" platform="${HOOK_PLATFORM:-}" p=""

  if command -v jq >/dev/null 2>&1; then
    p="$(printf '%s' "$input" | jq -r '
      [ .tool_input.file_path?, .tool_input.path?, .tool_input.filePath?,
        .tool_input.notebook_path?, .file_path?, .toolCall.args.TargetFile? ]
      | map(select(type == "string" and . != "")) | .[]' 2>/dev/null)"
  else
    # No jq: try "file_path" first and fall back to "path" only when it is
    # absent, so a nested decoy "path" key can't shadow the real target.
    p="$(printf '%s' "$input" | grep -oE '"(file_path|TargetFile)"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
         | sed -E 's/.*:[[:space:]]*"([^"]+)".*/\1/')"
    [ -n "$p" ] || p="$(printf '%s' "$input" | grep -oE '"path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
         | sed -E 's/.*"path"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
  fi

  # Antigravity encodes each arg as a JSON string inside the args object, so the
  # extracted value still carries its own quote pair. Strip one level.
  if [ "$platform" = antigravity ] && [ -n "$p" ]; then
    p="$(printf '%s\n' "$p" | sed -e 's/^"//' -e 's/"$//')"
  fi

  [ -n "$p" ] && printf '%s\n' "$p"

  # Codex routes file edits through apply_patch; the paths live in the patch
  # text, not in a field. Adds/updates/moves only — a delete has nothing to lint.
  if [ -z "$p" ] && { [ "$platform" = codex ] || [ -z "$platform" ]; }; then
    local cmdtext
    if command -v jq >/dev/null 2>&1; then
      cmdtext="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    fi
    [ -n "${cmdtext:-}" ] || return 0
    printf '%s\n' "$cmdtext" \
      | sed -nE 's/^\*\*\* (Add File|Update File|Move to): (.*)$/\2/p' \
      | sed -e 's/\r$//' -e 's/^"//' -e 's/"$//' \
      | grep -v '^$' || true
  fi
  return 0
}

# Back-compat single-path accessor: the first path the payload names.
hook_file_path() {
  hook_file_paths "$1" | head -1
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
