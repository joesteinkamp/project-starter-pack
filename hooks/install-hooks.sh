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
# Requires jq. Makes a timestamped backup of the settings file before editing.

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
cp "$settings" "$settings.bak.$(date +%Y%m%d%H%M%S 2>/dev/null || echo backup)"

# chmod the hooks so the harness can run them.
for s in "${HOOK_SCRIPTS[@]}"; do chmod +x "$HERE/$s"; done

# Build the PostToolUse entries (one command per hook script) and merge them in,
# matching on Edit|Write|MultiEdit. Existing hooks are preserved.
cmds_json="$(printf '%s\n' "${HOOK_SCRIPTS[@]}" \
  | jq -R --arg dir "$HERE" '{type:"command", command:($dir + "/" + .)}' \
  | jq -s '.')"

tmp="$(mktemp)"
# Idempotent: drop any block we previously installed (same matcher + our scripts),
# preserving the user's own hooks, then add a fresh one. Re-running won't duplicate.
jq --argjson cmds "$cmds_json" '
  .hooks //= {} |
  .hooks.PostToolUse //= [] |
  .hooks.PostToolUse |= map(select(
    (.matcher != "Edit|Write|MultiEdit")
    or
    (((.hooks // []) | map(.command)
      | any(endswith("guard-design.sh") or endswith("check-anti-patterns.sh"))) | not)
  )) |
  .hooks.PostToolUse += [ { matcher: "Edit|Write|MultiEdit", hooks: $cmds } ]
' "$settings" > "$tmp" && mv "$tmp" "$settings"

echo "Installed ${#HOOK_SCRIPTS[@]} advisory hook(s) into $settings (backup written)."
echo "They warn only; nothing is ever blocked. Remove the PostToolUse entry to uninstall."
