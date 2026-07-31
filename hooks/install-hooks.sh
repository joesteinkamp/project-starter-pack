#!/usr/bin/env bash
#
# install-hooks.sh — opt-in installer for the advisory design + writing hooks.
#
# These hooks are NOT installed by default and they NEVER block — they only
# print nudges. Run this only if you want project-local enforcement reminders.
# Hard guardrails (protected paths, dangerous bash, audit logging) are a
# user/global-layer concern and deliberately live elsewhere, not in this pack.
#
# Usage:
#   hooks/install-hooks.sh                        # Claude Code, this project (./.claude/settings.json)
#   hooks/install-hooks.sh --global               # Claude Code, all projects (~/.claude/settings.json)
#   hooks/install-hooks.sh codex cursor           # those tools (always machine-wide — they have no per-project hook config)
#   hooks/install-hooks.sh antigravity            # ~/.gemini/antigravity-cli/hooks.json
#   hooks/install-hooks.sh --uninstall [targets]  # remove exactly what this installer added
#
# Targets default to `claude` alone, deliberately: Claude Code is the only one
# with a project-scoped config, so a bare run stays inside the repo you are
# standing in and never reaches into $HOME for tools you didn't ask about. Name
# the others explicitly.
#
# The same three scripts serve every tool — HOOK_PLATFORM, set in each wired
# command, selects how the event payload is parsed (see lib/hook-input.sh).
#
# Requires jq. The first run writes a .bak of each config it touches; later runs
# never overwrite that backup.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPTS=(guard-design.sh check-anti-patterns.sh check-writing-slop.sh)   # single source of truth (keep single-line: the test suite greps this line)

scope="project"
mode="install"
targets=()
for arg in "$@"; do
  case "$arg" in
    --global)    scope="global" ;;
    --uninstall) mode="uninstall" ;;
    claude|codex|cursor|antigravity) targets+=("$arg") ;;
    *) echo "install-hooks: unknown option '$arg' (use --global, --uninstall, and/or: claude codex cursor antigravity)" >&2; exit 2 ;;
  esac
done
[ ${#targets[@]} -eq 0 ] && targets=(claude)

command -v jq >/dev/null 2>&1 || { echo "install-hooks: jq is required." >&2; exit 1; }

# chmod the hooks so every harness can run them.
for s in "${HOOK_SCRIPTS[@]}"; do chmod +x "$HERE/$s"; done

# The wired command for one script on one platform. HOOK_PLATFORM is what lets
# one script read four different event payloads.
cmd() { printf 'env HOOK_PLATFORM=%s "%s/%s"' "$1" "$HERE" "$2"; }

# The JSON array of {type:command, command:...} entries for a platform.
cmds_json() {  # $1 = platform
  local p="$1" s out=()
  for s in "${HOOK_SCRIPTS[@]}"; do out+=("$(cmd "$p" "$s")"); done
  printf '%s\n' "${out[@]}" | jq -R '{type:"command", command:.}' | jq -s '.'
}

# Flat {command:...} entries — Cursor's hooks.json shape has no nested array.
flat_cmds_json() {  # $1 = platform
  local p="$1" s out=()
  for s in "${HOOK_SCRIPTS[@]}"; do out+=("$(cmd "$p" "$s")"); done
  printf '%s\n' "${out[@]}" | jq -R '{command:.}' | jq -s '.'
}

# Seed + validate a JSON config file, and take the one-time pristine backup.
prepare_config() {  # $1 = path
  local f="$1"
  mkdir -p "$(dirname "$f")"
  # -s, not -f: a zero-byte file must be seeded too, or the shape guard below
  # rejects it with a misleading message.
  [ -s "$f" ] || echo '{}' > "$f"
  jq empty "$f" 2>/dev/null || {
    echo "install-hooks: $f is not valid JSON — fix it (or delete it) and re-run." >&2
    return 1
  }
  [ -f "$f.bak" ] || cp "$f" "$f.bak"
}

# Replace a config's contents from a temp file. cat, not mv: mv from mktemp
# would replace the file and reset its permissions.
commit_config() {  # $1 = config path, $2 = temp path
  cat "$2" > "$1"; rm -f "$2"
}

# --- claude / codex: nested {matcher, hooks:[{type,command}]} ----------------
# Idempotent, and preserves user hooks: an entry is OURS only if its command
# exactly matches one we install (full path + platform — a user's own
# same-named script elsewhere on disk is not ours to touch). Strip ours, drop
# only blocks our strip emptied, then (install mode) append our commands to the
# first matching block — or a new one.
install_nested() {  # $1 = settings path, $2 = platform, $3 = matcher
  local settings="$1" platform="$2" matcher="$3" cmds filter tmp
  prepare_config "$settings" || return 1
  # Shape guard, all the way down: .hooks an object, .hooks.PostToolUse an
  # array, every entry an object, and every entry's .hooks an array (or
  # absent) — otherwise the merge below dies with a cryptic jq error.
  jq -e '((.hooks // {}) | type == "object")
         and (((.hooks // {}).PostToolUse // []) | type == "array")
         and (((.hooks // {}).PostToolUse // []) | all(type == "object"))
         and (((.hooks // {}).PostToolUse // []) | all((.hooks // []) | type == "array"))' \
     "$settings" >/dev/null 2>&1 || {
    echo "install-hooks: $settings has an unexpected shape — .hooks must be an object, .hooks.PostToolUse an array of objects, and each entry's .hooks an array. Fix it and re-run." >&2
    return 1
  }
  cmds="$(cmds_json "$platform")"
  filter='
    def ours: (type == "object") and ((.command // "") as $c | any($cmds[]; .command == $c));
    .hooks //= {} |
    .hooks.PostToolUse //= [] |
    .hooks.PostToolUse |= map(
      if any(.hooks[]?; ours) then
        (.hooks | map(select(ours | not))) as $kept |
        if ($kept | length) == 0 then empty else .hooks = $kept end
      else .
      end
    )'
  if [ "$mode" = install ]; then
    filter="$filter"'
    | (.hooks.PostToolUse | map(.matcher == $matcher) | index(true)) as $i |
    if $i != null then .hooks.PostToolUse[$i].hooks += $cmds
    else .hooks.PostToolUse += [ { matcher: $matcher, hooks: $cmds } ]
    end'
  else
    # Leave the file as we found it, not with our empty scaffolding in it: drop
    # PostToolUse (and .hooks) only when the strip above emptied them AND we are
    # the reason they exist.
    filter="$filter"'
    | if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end
    | if (.hooks | length) == 0 then del(.hooks) else . end'
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/psp-hooks.XXXXXX")"
  if ! jq --argjson cmds "$cmds" --arg matcher "$matcher" "$filter" "$settings" > "$tmp"; then
    rm -f "$tmp"
    echo "install-hooks: merge failed; $settings left unchanged (pre-install backup: $settings.bak)." >&2
    return 1
  fi
  commit_config "$settings" "$tmp"
}

# --- cursor: top-level "version", flat {command:...} under afterFileEdit -----
install_cursor() {
  local settings="$HOME/.cursor/hooks.json" cmds filter tmp
  [ -d "$HOME/.cursor" ] || { echo "  cursor: ~/.cursor not found — tool not installed here (skipped)"; return 0; }
  prepare_config "$settings" || return 1
  cmds="$(flat_cmds_json cursor)"
  filter='
    def ours: (type == "object") and ((.command // "") as $c | any($cmds[]; .command == $c));
    .hooks //= {} |
    .hooks.afterFileEdit //= [] |
    .hooks.afterFileEdit |= map(select(ours | not))'
  if [ "$mode" = install ]; then
    # Cursor requires a top-level version; only assert it when we are adding.
    filter="$filter"' | .version = 1 | .hooks.afterFileEdit += $cmds'
  else
    filter="$filter"'
    | if (.hooks.afterFileEdit | length) == 0 then del(.hooks.afterFileEdit) else . end
    | if (.hooks | length) == 0 then del(.hooks) else . end'
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/psp-hooks.XXXXXX")"
  if ! jq --argjson cmds "$cmds" "$filter" "$settings" > "$tmp"; then
    rm -f "$tmp"
    echo "install-hooks: merge failed; $settings left unchanged (pre-install backup: $settings.bak)." >&2
    return 1
  fi
  commit_config "$settings" "$tmp"
  echo "  cursor  -> $settings (afterFileEdit)"
}

# --- antigravity: its own hooks.json schema ---------------------------------
# Antigravity reads ~/.gemini/antigravity-cli/hooks.json (the path lives under
# ~/.gemini/ for historical reasons; the tool is not the retired Gemini CLI).
# Its schema is top-level *named* hooks, each holding PreToolUse/PostToolUse
# arrays with tool-name matchers. It invokes hooks by absolute path with no
# environment of ours, so we wire thin wrappers that export HOOK_PLATFORM.
install_antigravity() {
  # Separate statements, not one `local a=… b=$a`: the builtin expands every
  # argument before it assigns any, so $base would still be unbound under set -u.
  local base="$HOME/.gemini/antigravity-cli"
  local hd="$base/hooks"
  local hj="$base/hooks.json"
  local s add tmp
  if [ ! -d "$base" ]; then
    echo "  antigravity: $base not found — is the Antigravity CLI (agy) installed? (skipped)"
    return 0
  fi
  mkdir -p "$hd"
  if [ "$mode" = install ]; then
    for s in "${HOOK_SCRIPTS[@]}"; do
      # Resolve the real script through $0's dir at runtime rather than baking
      # $HERE into the quoted exec line — a path with a space or quote would
      # otherwise break the wrapper.
      printf '#!/usr/bin/env bash\nexport HOOK_PLATFORM=antigravity\nexec "%s/%s"\n' "$HERE" "$s" > "$hd/psp-${s%.sh}.ag.sh"
      chmod +x "$hd/psp-${s%.sh}.ag.sh"
    done
  else
    rm -f "$hd"/psp-*.ag.sh
    rmdir "$hd" 2>/dev/null || true
  fi
  prepare_config "$hj" || return 1
  add='{}'
  if [ "$mode" = install ]; then
    add="$(jq -n \
      --arg gd "$hd/psp-guard-design.ag.sh" \
      --arg ap "$hd/psp-check-anti-patterns.ag.sh" \
      --arg ws "$hd/psp-check-writing-slop.ag.sh" '{
      "psp-advisory": {
        PostToolUse: [ { matcher: "write_to_file|replace_file_content|multi_replace_file_content",
                         hooks: [ {type:"command",command:$gd,timeout:30},
                                  {type:"command",command:$ap,timeout:30},
                                  {type:"command",command:$ws,timeout:30} ] } ]
      }
    }')"
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/psp-hooks.XXXXXX")"
  # Named hooks live at the top level; drop any prior psp-* first so re-runs
  # never duplicate, then merge ours back (preserving the user's own entries).
  if ! jq --argjson add "$add" \
      '(to_entries | map(select(.key | startswith("psp-") | not)) | from_entries) + $add' \
      "$hj" > "$tmp"; then
    rm -f "$tmp"
    echo "install-hooks: merge failed; $hj left unchanged (pre-install backup: $hj.bak)." >&2
    return 1
  fi
  commit_config "$hj" "$tmp"
  echo "  antigravity -> $hj (PostToolUse on file writes, via $hd/)"
}

# --- run --------------------------------------------------------------------

install_claude() {
  local settings
  if [ "$scope" = "global" ]; then
    settings="$HOME/.claude/settings.json"
  else
    settings="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/settings.json"
  fi
  install_nested "$settings" claude "Edit|Write|MultiEdit" || return 1
  echo "  claude  -> $settings (PostToolUse on Edit|Write|MultiEdit)"
}

install_codex() {
  local settings="$HOME/.codex/hooks.json"
  [ -d "$HOME/.codex" ] || { echo "  codex: ~/.codex not found — tool not installed here (skipped)"; return 0; }
  # Codex surfaces file edits through apply_patch (with Write/Edit aliases);
  # hook-input.sh pulls the paths out of the apply_patch envelope.
  install_nested "$settings" codex "apply_patch|Edit|Write" || return 1
  echo "  codex   -> $settings (PostToolUse on apply_patch|Edit|Write)"
}

failed=0
for t in "${targets[@]}"; do
  case "$t" in
    claude)      install_claude      || { echo "  claude: skipped (error above)" >&2; failed=1; } ;;
    codex)       install_codex       || { echo "  codex: skipped (error above)" >&2; failed=1; } ;;
    cursor)      install_cursor      || { echo "  cursor: skipped (error above)" >&2; failed=1; } ;;
    antigravity) install_antigravity || { echo "  antigravity: skipped (error above)" >&2; failed=1; } ;;
  esac
done

global_flag=""
[ "$scope" = "global" ] && global_flag=" --global"
if [ "$mode" = "install" ]; then
  echo "Installed ${#HOOK_SCRIPTS[@]} advisory hook(s) for: ${targets[*]}."
  echo "They warn only; nothing is ever blocked. Uninstall with: hooks/install-hooks.sh --uninstall$global_flag ${targets[*]}."
else
  echo "Removed this pack's advisory hook(s) for: ${targets[*]} (matched by exact command under $HERE)."
  echo "If you moved the repo since installing, stale entries under the old path need removing by hand."
fi

exit "$failed"
