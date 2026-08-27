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

# --- registry-driven detection ----------------------------------------------
# The bans live in guardrails/*-anti-patterns.md and their detectors in the
# matching .detect.md sidecars; build-guardrails.sh compiles both into
# guardrails/registry.json. The hooks read that, so adding a ban to the prose
# arms its detector without editing a hook. See guardrails/_format.md.
#
# Resolved relative to this file, never the cwd: the hooks are wired by
# absolute path into the checkout (install-hooks.sh), while they run inside
# whatever project the user is editing.
# NOTE: inside a function, BASH_SOURCE[0] is THIS file (hooks/lib/), not the
# hook that sourced it — hence ../../, not ../. Getting this wrong fails open:
# the registry is simply absent, every detector is skipped, and the hook still
# exits 0 having enforced nothing.
hook_registry() {
  printf '%s/../../guardrails/registry.json' "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Does $1 fall in scope $2?
hook_in_scope() {
  case "$2" in
    style|tokens) hook_is_style_file "$1" ;;
    prose)        hook_is_prose_file "$1" ;;
    *)            return 1 ;;
  esac
}

# Run every live detector of scope $2 against file $1, printing one advisory
# line per hit. Silent (and successful) when jq or the registry is absent — the
# hooks are advisory and must never fail the tool call that triggered them.
hook_check_scope() {
  local file="$1" scope="$2" reg
  reg="$(hook_registry)"
  if [ ! -f "$reg" ]; then
    echo "psp-hooks: no guardrails/registry.json at $reg — run ./build-guardrails.sh. Nothing was checked." >&2
    return 0
  fi
  command -v jq >/dev/null 2>&1 || {
    echo "psp-hooks: jq not found — guardrail detectors skipped. Nothing was checked." >&2
    return 0
  }
  hook_in_scope "$file" "$scope" || return 0

  # \x01 as the field separator, not @tsv: @tsv escapes backslashes, which
  # silently turns a pattern like \b(delve|...)\b into a literal-backslash
  # match that never fires. `join` under -r emits the pattern verbatim.
  local id kind pattern threshold fix name src hits
  while IFS=$'\x01' read -r id kind pattern threshold fix name src; do
    [ -n "$id" ] || continue
    case "$kind" in
      regex)  grep -qE  -- "$pattern" "$file" 2>/dev/null || continue ;;
      regexi) grep -qiE -- "$pattern" "$file" 2>/dev/null || continue ;;
      count)
        hits="$(grep -oE -- "$pattern" "$file" 2>/dev/null | wc -l | tr -d '[:space:]')"
        [ "${hits:-0}" -gt "${threshold:-0}" ] 2>/dev/null || continue
        echo "$id in $file — $name ($hits occurrences, keep to $threshold) — $fix ($src, advisory)" >&2
        continue ;;
      *) continue ;;
    esac
    echo "$id in $file — $name — $fix ($src, advisory)" >&2
  done < <(jq -r --arg scope "$scope" '
    to_entries
    | map(select(.value.scope == $scope
                 and (.value.kind == "regex" or .value.kind == "regexi" or .value.kind == "count")))
    | sort_by(.key)[]
    | [ .key, .value.kind, .value.pattern, (.value.threshold // 0 | tostring),
        (.value.fix // ""), .value.name, .value.file ]
    | join("\u0001")' "$reg" 2>/dev/null)
  return 0
}
