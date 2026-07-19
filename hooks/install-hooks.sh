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
#   hooks/install-hooks.sh            # install into ./.claude/settings.json (project)
#   hooks/install-hooks.sh --global   # install into ~/.claude/settings.json (all projects)
#
# Requires jq. Keeps a rolling backup (settings.json.bak) before editing.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPTS=(guard-design.sh check-anti-patterns.sh)   # single source of truth

scope="project"
[ "${1:-}" = "--global" ] && scope="global"

if [ "$scope" = "global" ]; then
  settings="$HOME/.claude/settings.json"
else
  settings="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/settings.json"
fi

command -v jq >/dev/null 2>&1 || { echo "install-hooks: jq is required." >&2; exit 1; }
mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' > "$settings"
jq empty "$settings" 2>/dev/null || {
  echo "install-hooks: $settings is not valid JSON — fix it (or delete it) and re-run." >&2
  exit 1
}
cp "$settings" "$settings.bak"   # single rolling backup

# chmod the hooks so the harness can run them.
for s in "${HOOK_SCRIPTS[@]}"; do chmod +x "$HERE/$s"; done

# Build the PostToolUse entries (one command per hook script) and merge them in,
# matching on Edit|Write|MultiEdit. Existing hooks are preserved.
cmds_json="$(printf '%s\n' "${HOOK_SCRIPTS[@]}" \
  | jq -R --arg dir "$HERE" '{type:"command", command:($dir + "/" + .)}' \
  | jq -s '.')"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
# Idempotent, and preserves user hooks: strip only OUR script entries from every
# PostToolUse block (whatever its matcher), drop blocks that end up empty, then
# add our commands to the first Edit|Write|MultiEdit block — or a new one.
jq --argjson cmds "$cmds_json" '
  .hooks //= {} |
  .hooks.PostToolUse //= [] |
  .hooks.PostToolUse |= map(
    .hooks = ((.hooks // []) | map(select(
      ((.command // "") | (endswith("guard-design.sh") or endswith("check-anti-patterns.sh"))) | not
    )))
  ) |
  .hooks.PostToolUse |= map(select((.hooks | length) > 0)) |
  (.hooks.PostToolUse | map(.matcher == "Edit|Write|MultiEdit") | index(true)) as $i |
  if $i != null then .hooks.PostToolUse[$i].hooks += $cmds
  else .hooks.PostToolUse += [ { matcher: "Edit|Write|MultiEdit", hooks: $cmds } ]
  end
' "$settings" > "$tmp" && mv "$tmp" "$settings"
trap - EXIT

echo "Installed ${#HOOK_SCRIPTS[@]} advisory hook(s) into $settings (backup written)."
echo "They warn only; nothing is ever blocked. Remove the PostToolUse entry to uninstall."
