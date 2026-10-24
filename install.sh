#!/usr/bin/env bash
# install.sh — install project-starter-pack into every AI tool you use.
#
#   ./install.sh                     # every target (asks once; --yes skips)
#   ./install.sh codex cursor        # just those
#   ./install.sh --uninstall         # remove exactly what this script installed
#   ./install.sh --uninstall cursor  # ...for one target
#   ./install.sh --list              # print the target table (machine-readable)
#
# The targets live in ONE place: targets_table() below. Argument parsing, the
# default target set, the presence check, and both install and uninstall all
# read it, and test.sh reads it too (through --list) to check the README and
# INSTALL.md tables against it. Adding a tool is one row, not a hunt through
# case branches — and a row the docs don't mention fails the linter.
#
# Everything is SYMLINKED, never copied: `git pull` in this checkout updates
# every tool at once. Re-running is idempotent. A target whose config directory
# does not exist is skipped cleanly — installing a tool you don't have is not an
# error.
#
# Antigravity's skills root is ~/.gemini/config (the machine-global one of its
# three discovery locations; the others are per-workspace). That root is created
# lazily, so a real install that has never written a global customization has
# only ~/.gemini/antigravity-cli. Either directory means "installed", which is
# why the presence column takes more than one marker.
#
# Why Claude commands go in a `starter/` SUBDIRECTORY and Cursor's are prefixed
# files: Claude Code derives the command name from the path, joining a
# subdirectory to the file as `/<dir>:<name>`. So commands/setup.md installed at
# ~/.claude/commands/starter/setup.md is invoked `/starter:setup` — identical to
# the plugin path, which is the point. One tool must not have two invocations
# for the same flow depending on how it was installed. Cursor has no such
# namespacing, so its ports keep the flat `starter-` prefix.
#
# Claude Code users who prefer the zero-script path can instead install the
# plugin; see INSTALL.md. The two paths coexist, but there is no reason to run
# both.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS="$DIR/skills"
CMDS="$DIR/commands"
PORTS="$DIR/commands/cursor"
PREFIX="starter-"   # render-ports.sh names every Cursor port with this prefix

# The target table. One row per tool; every path is relative to $HOME.
#
#   id | display name | presence markers | skills dir | commands | commands dir
#
#   presence markers  comma-separated dirs; ANY of them existing means the tool
#                     is installed here
#   commands          canonical  link commands/*.md as-is (Claude's dialect)
#                     rendered   run render-ports.sh, link the generated ports
#                     -          no command surface (skills only)
#   commands dir      where commands land, or - when there are none. For
#                     `canonical`, the last path segment is the namespace: it
#                     becomes the `/<ns>:` in `/<ns>:setup`.
#
# The display name is what the README and INSTALL.md tables call the tool;
# test.sh holds them to it.
targets_table() {
  cat <<'EOF'
claude|Claude Code|.claude|.claude/skills|canonical|.claude/commands/starter
codex|Codex|.codex|.codex/skills|-|-
cursor|Cursor|.cursor|.cursor/skills|rendered|.cursor/commands
antigravity|Antigravity|.gemini/config,.gemini/antigravity-cli|.gemini/config/skills|-|-
EOF
}

target_ids() { targets_table | cut -d'|' -f1; }
target_row() { targets_table | awk -F'|' -v id="$1" '$1 == id { print; exit }'; }

usage() {
  # The header comment, then the live table — so --help can never list a
  # target the script does not have.
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
  echo
  echo "Targets:"
  targets_table | awk -F'|' '{ printf "  %-12s %-12s ~/%s\n", $1, $2, $4 }'
}

mode="install"
assume_yes=0
targets=()
for a in "$@"; do
  case "$a" in
    --uninstall) mode="uninstall" ;;
    --yes|-y)    assume_yes=1 ;;
    --list)      targets_table; exit 0 ;;
    -h|--help)   usage; exit 0 ;;
    *)
      if [ -n "$(target_row "$a")" ]; then
        targets+=("$a")
      else
        echo "install: unknown arg '$a' (use: --yes | --uninstall | --list | $(target_ids | paste -sd' ' - | sed 's/ / | /g'))" >&2
        exit 2
      fi
      ;;
  esac
done
if [ ${#targets[@]} -eq 0 ]; then
  while IFS= read -r t; do targets+=("$t"); done < <(target_ids)
fi

skill_names() { local d; for d in "$SKILLS"/*/; do [ -f "$d/SKILL.md" ] && basename "$d"; done; }

# Canonical commands only: the top level of commands/, never the generated
# cursor/ ports (a subdir, so the glob skips it) and never README.md.
command_names() {
  local f b
  for f in "$CMDS"/*.md; do
    [ -e "$f" ] || continue
    b="$(basename "$f" .md)"
    [ "$b" = "README" ] && continue
    printf '%s\n' "$b"
  done
}

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

tool_present() {  # $1 = comma-separated presence markers
  local m ms
  IFS=',' read -ra ms <<<"$1"
  for m in "${ms[@]}"; do [ -d "$HOME/$m" ] && return 0; done
  return 1
}

install_skills() {  # $1 = target id, $2 = skills dir
  local id="$1" dest="$2" n=0 s
  if [ "$mode" = uninstall ]; then
    while IFS= read -r s; do unlink_one "$dest/$s"; done < <(skill_names)
    rmdir "$dest" 2>/dev/null || true
    echo "  $id: removed skills from $dest"
    return 0
  fi
  mkdir -p "$dest"
  while IFS= read -r s; do link_one "$SKILLS/$s" "$dest/$s"; n=$((n+1)); done < <(skill_names)
  echo "  $id: linked $n skill(s) -> $dest"
}

# Claude's dialect, linked unchanged. The last segment of the dir is the
# namespace Claude Code turns into `/<ns>:<verb>`.
install_canonical_commands() {  # $1 = target id, $2 = commands dir
  local id="$1" dest="$2" ns n=0 c p
  ns="$(basename "$dest")"
  if [ "$mode" = uninstall ]; then
    for p in "$dest"/*.md; do [ -e "$p" ] || continue; unlink_one "$p" && n=$((n+1)); done
    # Only ever removes the namespace dir, and only when empty — anything the
    # user put in there keeps the dir alive.
    rmdir "$dest" 2>/dev/null || true
    echo "  $id: removed $n command(s) from $dest"
    return 0
  fi
  mkdir -p "$dest"
  # Prune ours for commands that no longer exist, before linking the current set.
  for p in "$dest"/*.md; do
    [ -e "$p" ] || continue
    [ -e "$CMDS/$(basename "$p")" ] || unlink_one "$p"
  done
  while IFS= read -r c; do
    link_one "$CMDS/$c.md" "$dest/$c.md"; n=$((n+1))
  done < <(command_names)
  echo "  $id: linked $n command(s) -> $dest  (invoke /$ns:setup)"
}

# Generated ports, for a tool that cannot read Claude's dialect. The ports
# share one directory with the user's own commands, so everything here is
# scoped to the PREFIX render-ports.sh gives them.
install_rendered_commands() {  # $1 = target id, $2 = commands dir
  local id="$1" dest="$2" n=0 p
  if [ "$mode" = uninstall ]; then
    for p in "$dest/$PREFIX"*.md; do [ -e "$p" ] || continue; unlink_one "$p" && n=$((n+1)); done
    rmdir "$dest" 2>/dev/null || true
    echo "  $id: removed $n command port(s) from $dest"
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
  echo "  $id: linked $n command port(s) -> $dest  (invoke /${PREFIX}setup)"
}

install_target() {  # $1 = target id
  local id name markers sdir cstyle cdir
  IFS='|' read -r id name markers sdir cstyle cdir <<<"$(target_row "$1")"
  if ! tool_present "$markers"; then
    echo "  $id: ~/${markers//,/ or ~/} not found — tool not installed here (skipped)"
    return 0
  fi
  install_skills "$id" "$HOME/$sdir"
  case "$cstyle" in
    canonical) install_canonical_commands "$id" "$HOME/$cdir" ;;
    rendered)  install_rendered_commands  "$id" "$HOME/$cdir" ;;
    -)         ;;
    *) echo "install: target '$id' has unknown commands style '$cstyle'" >&2; return 1 ;;
  esac
}

# --- run --------------------------------------------------------------------

if [ "$mode" = install ] && [ "$assume_yes" -eq 0 ] && [ -t 0 ]; then
  echo "About to symlink project-starter-pack from $DIR into: ${targets[*]}"
  printf 'Continue? [Y/n] '
  read -r reply
  case "$reply" in [nN]*) echo "Aborted."; exit 0 ;; esac
fi

echo "== project-starter-pack: $mode =="
for t in "${targets[@]}"; do install_target "$t"; done

if [ "$mode" = install ]; then
  echo "Done. Everything is symlinked — 'git pull' in $DIR updates every tool."
  echo "Reverse with: $0 --uninstall"
else
  echo "Done. Removed only symlinks pointing into $DIR."
fi
