#!/usr/bin/env bash
# install.sh — install project-starter-pack into every AI tool you use.
#
#   ./install.sh                     # all four targets (asks once; --yes skips)
#   ./install.sh codex cursor        # just those
#   ./install.sh --uninstall         # remove exactly what this script installed
#   ./install.sh --uninstall cursor  # ...for one target
#
# Targets:
#   claude       ~/.claude/skills/<name>            (symlink per skill)
#   codex        ~/.codex/skills/<name>             (symlink per skill; invoke $<name>)
#   cursor       ~/.cursor/skills/<name>            (symlink per skill)
#              + ~/.cursor/commands/starter-<name>.md  (rendered ports, symlinked)
#   antigravity  nothing to install — it reads the generated AGENTS.md natively
#                and starts flows from natural language. Prints the pointer.
#
# Everything is SYMLINKED, never copied: `git pull` in this checkout updates all
# four tools at once. Re-running is idempotent. A target whose config directory
# does not exist is skipped cleanly — installing a tool you don't have is not an
# error.
#
# Claude Code users who prefer the zero-script path can instead clone this repo
# into ~/.claude/plugins/ and get the /starter:* commands plus the skills; see
# INSTALL.md. The two paths coexist, but there is no reason to run both.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS="$DIR/skills"
PORTS="$DIR/commands/cursor"
PREFIX="starter-"

mode="install"
assume_yes=0
targets=()
for a in "$@"; do
  case "$a" in
    --uninstall)          mode="uninstall" ;;
    --yes|-y)             assume_yes=1 ;;
    claude|codex|cursor|antigravity) targets+=("$a") ;;
    -h|--help)            sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "install: unknown arg '$a' (use: --yes | --uninstall | claude | codex | cursor | antigravity)" >&2; exit 2 ;;
  esac
done
[ ${#targets[@]} -eq 0 ] && targets=(claude codex cursor antigravity)

skill_names() { local d; for d in "$SKILLS"/*/; do [ -f "$d/SKILL.md" ] && basename "$d"; done; }

# Is $1 a symlink that resolves into this checkout? Only those are ours to
# replace or remove — a real directory or a link elsewhere is the user's.
ours() {
  [ -L "$1" ] || return 1
  local t; t="$(cd "$(dirname "$1")" && readlink "$1")" || return 1
  case "$t" in "$DIR"/*) return 0 ;; *) return 1 ;; esac
}

link_one() {  # $1 = source path, $2 = destination path
  if [ -e "$2" ] && ! ours "$2"; then
    echo "    skipped $(basename "$2") — a real file/dir is already there (not ours to replace)" >&2
    return 0
  fi
  rm -f "$2"
  ln -s "$1" "$2"
}

unlink_one() {  # $1 = destination path
  ours "$1" && rm -f "$1"
  return 0
}

# --- per-target -------------------------------------------------------------

install_skills() {  # $1 = tool label, $2 = tool config dir, $3 = skills dir
  local label="$1" base="$2" dest="$3" n
  if [ ! -d "$base" ]; then
    echo "  $label: $base not found — tool not installed here (skipped)"
    return 0
  fi
  if [ "$mode" = uninstall ]; then
    n=0
    while IFS= read -r s; do unlink_one "$dest/$s" && n=$((n+1)); done < <(skill_names)
    rmdir "$dest" 2>/dev/null || true
    echo "  $label: removed skills from $dest"
    return 0
  fi
  mkdir -p "$dest"
  n=0
  while IFS= read -r s; do link_one "$SKILLS/$s" "$dest/$s"; n=$((n+1)); done < <(skill_names)
  echo "  $label: linked $n skill(s) -> $dest"
}

install_cursor_commands() {
  local base="$HOME/.cursor" dest="$HOME/.cursor/commands" n=0 p
  [ -d "$base" ] || return 0
  if [ "$mode" = uninstall ]; then
    for p in "$dest/$PREFIX"*.md; do [ -e "$p" ] || continue; unlink_one "$p" && n=$((n+1)); done
    rmdir "$dest" 2>/dev/null || true
    echo "  cursor: removed $n command port(s) from $dest"
    return 0
  fi
  # Re-render every run so a port can never drift from its canonical command.
  "$DIR/render-ports.sh" >/dev/null
  mkdir -p "$dest"
  # Prune ports for commands that no longer exist before linking the current set.
  for p in "$dest/$PREFIX"*.md; do
    [ -e "$p" ] || continue
    [ -e "$PORTS/$(basename "$p")" ] || unlink_one "$p"
  done
  for p in "$PORTS"/*.md; do
    [ -e "$p" ] || continue
    link_one "$p" "$dest/$(basename "$p")"; n=$((n+1))
  done
  echo "  cursor: linked $n command port(s) -> $dest  (invoke /${PREFIX}setup)"
}

install_antigravity() {
  if [ "$mode" = uninstall ]; then
    echo "  antigravity: nothing was installed — nothing to remove"
    return 0
  fi
  cat <<EOF
  antigravity: nothing to install — it has no skill or command surface.
    It reads the generated AGENTS.md in your projects natively, and starts a
    flow from plain language. Point it at this checkout:
      "walk me through the product brief using the project-starter-pack
       questionnaire at $DIR"
    Flows: setup · product-brief · design-brief · code-brief · validate · extract
EOF
}

# --- run --------------------------------------------------------------------

if [ "$mode" = install ] && [ "$assume_yes" -eq 0 ] && [ -t 0 ]; then
  echo "About to symlink project-starter-pack from $DIR into: ${targets[*]}"
  printf 'Continue? [Y/n] '
  read -r reply
  case "$reply" in [nN]*) echo "Aborted."; exit 0 ;; esac
fi

echo "== project-starter-pack: $mode =="
for t in "${targets[@]}"; do
  case "$t" in
    claude)      install_skills claude "$HOME/.claude" "$HOME/.claude/skills" ;;
    codex)       install_skills codex  "$HOME/.codex"  "$HOME/.codex/skills" ;;
    cursor)      install_skills cursor "$HOME/.cursor" "$HOME/.cursor/skills"; install_cursor_commands ;;
    antigravity) install_antigravity ;;
  esac
done

if [ "$mode" = install ]; then
  echo "Done. Everything is symlinked — 'git pull' in $DIR updates every tool."
  echo "Reverse with: $0 --uninstall"
else
  echo "Done. Removed only symlinks pointing into $DIR."
fi
