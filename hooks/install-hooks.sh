#!/usr/bin/env bash
#
# install-hooks.sh — opt-in installer for the advisory design hooks.
#
# These hooks are NOT installed by default and they NEVER block — they only
# print nudges. Run this only if you want project-local enforcement reminders.
# Hard guardrails (protected paths, dangerous bash, audit logging) are a
# user/global-layer concern and deliberately live elsewhere, not in this pack.
#
# Usage:
#   hooks/install-hooks.sh                        # install into ./.claude/settings.json (project)
#   hooks/install-hooks.sh --global               # install into ~/.claude/settings.json (all projects)
#   hooks/install-hooks.sh --uninstall [--global] # remove exactly what this installer added
#
# Requires jq. The first run writes settings.json.bak (your pre-install
# settings); later runs never overwrite it.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPTS=(guard-design.sh check-anti-patterns.sh)   # single source of truth (keep single-line: the test suite greps this line)

scope="project"
mode="install"
for arg in "$@"; do
  case "$arg" in
    --global)    scope="global" ;;
    --uninstall) mode="uninstall" ;;
    *) echo "install-hooks: unknown option '$arg' (use --global and/or --uninstall)" >&2; exit 2 ;;
  esac
done

if [ "$scope" = "global" ]; then
  settings="$HOME/.claude/settings.json"
else
  settings="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/settings.json"
fi

command -v jq >/dev/null 2>&1 || { echo "install-hooks: jq is required." >&2; exit 1; }
mkdir -p "$(dirname "$settings")"
# -s, not -f: a zero-byte settings file must be seeded too, or the shape guard
# below rejects it with a misleading message.
[ -s "$settings" ] || echo '{}' > "$settings"
jq empty "$settings" 2>/dev/null || {
  echo "install-hooks: $settings is not valid JSON — fix it (or delete it) and re-run." >&2
  exit 1
}
# Shape guard, all the way down: .hooks an object, .hooks.PostToolUse an array,
# every entry an object, and every entry's .hooks an array (or absent) —
# otherwise the merge below would die with a cryptic jq error.
jq -e '((.hooks // {}) | type == "object")
       and (((.hooks // {}).PostToolUse // []) | type == "array")
       and (((.hooks // {}).PostToolUse // []) | all(type == "object"))
       and (((.hooks // {}).PostToolUse // []) | all((.hooks // []) | type == "array"))' \
   "$settings" >/dev/null 2>&1 || {
  echo "install-hooks: $settings has an unexpected shape — .hooks must be an object, .hooks.PostToolUse an array of objects, and each entry's .hooks an array. Fix it and re-run." >&2
  exit 1
}
# First run only — keep the pristine pre-install settings recoverable forever.
[ -f "$settings.bak" ] || cp "$settings" "$settings.bak"

# chmod the hooks so the harness can run them.
for s in "${HOOK_SCRIPTS[@]}"; do chmod +x "$HERE/$s"; done

# Build the PostToolUse entries (one command per hook script), derived from
# HOOK_SCRIPTS so the strip below can never drift from the install list.
cmds_json="$(printf '%s\n' "${HOOK_SCRIPTS[@]}" \
  | jq -R --arg dir "$HERE" '{type:"command", command:($dir + "/" + .)}' \
  | jq -s '.')"

# Idempotent, and preserves user hooks: an entry is OURS only if its command
# exactly matches one of the commands we install (full path — a user's own
# same-named script elsewhere on disk is not ours to touch). Strip ours, drop
# only blocks our strip emptied, then (install mode) append our commands to the
# first Edit|Write|MultiEdit block — or a new one.
strip_filter='
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
if [ "$mode" = "install" ]; then
  filter="$strip_filter"'
  | (.hooks.PostToolUse | map(.matcher == "Edit|Write|MultiEdit") | index(true)) as $i |
  if $i != null then .hooks.PostToolUse[$i].hooks += $cmds
  else .hooks.PostToolUse += [ { matcher: "Edit|Write|MultiEdit", hooks: $cmds } ]
  end'
else
  filter="$strip_filter"
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/psp-hooks.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
if ! jq --argjson cmds "$cmds_json" "$filter" "$settings" > "$tmp"; then
  echo "install-hooks: merge failed; $settings left unchanged (pre-install backup: $settings.bak)." >&2
  exit 1
fi
# cat, not mv: mv from mktemp would replace the file and reset its permissions.
cat "$tmp" > "$settings"
rm -f "$tmp"
trap - EXIT

global_flag=""
[ "$scope" = "global" ] && global_flag=" --global"
if [ "$mode" = "install" ]; then
  echo "Installed ${#HOOK_SCRIPTS[@]} advisory hook(s) into $settings (pre-install backup: $settings.bak)."
  echo "They warn only; nothing is ever blocked. Uninstall with: hooks/install-hooks.sh --uninstall$global_flag."
else
  echo "Removed this pack's advisory hook(s) from $settings (matched by exact path under $HERE)."
  echo "If you moved the repo since installing, stale entries under the old path need removing by hand."
fi
