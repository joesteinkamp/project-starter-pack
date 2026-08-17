#!/usr/bin/env bash
# render-ports.sh — generate the Cursor command ports from the canonical
# Claude-dialect commands in commands/*.md, so there is ONE source of truth and
# the ports can't drift.
#
#   ./render-ports.sh          # regenerate commands/cursor/
#
# The generated files are snapshots — NEVER hand-edit them (install.sh re-renders
# on every run). To change a command, edit commands/<name>.md and re-render. The
# ports are gitignored: generated locally, never committed.
#
# Why only Cursor: Claude Code reads commands/ directly — through the plugin
# manifest, or from the symlinks install.sh puts in ~/.claude/commands/starter/;
# either way it speaks this dialect natively. Codex and Antigravity have no
# command surface at all (both run the skills by name). Cursor is the one tool
# that wants a plain-markdown command file it cannot generate itself.
#
# Translation rules (canonical -> Cursor port):
#   - frontmatter:  stripped. Cursor commands are plain markdown; `description`
#                   is re-emitted as the first line of the body, and
#                   `allowed-tools` is dropped (Claude-only — Cursor governs
#                   tools in its own permissions layer).
#   - $ARGUMENTS:   kept, with a note — Cursor has no placeholder; it appends
#                   whatever the user typed after the command.
#   - !`cmd`:       -> run `cmd`. Cursor has no shell injection, so the agent is
#                   told to run it instead.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$DIR/commands"
OUT="$SRC/cursor"
PREFIX="starter-"
[ -d "$SRC" ] || { echo "render-ports: no commands/ dir at $SRC" >&2; exit 1; }

# --- frontmatter / body extractors (CR-stripped so CRLF files parse) ---------
fm_field() {  # $1 = file, $2 = key -> the trimmed value (empty if absent)
  awk -v key="$2" '
    { sub(/\r$/,"") }
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---"  { exit }
    infm && $0 ~ ("^" key ":") {
      v=$0; sub("^" key ":[[:space:]]*","",v); gsub(/[[:space:]]+$/,"",v); print v; exit
    }
  ' "$1"
}

fm_body() {  # $1 = file -> body after the frontmatter, leading blanks trimmed.
             #              No frontmatter -> the whole file.
  awk '
    { sub(/\r$/,"") }
    NR==1 && $0!="---" { plain=1 }
    plain { print; next }
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---"  { infm=0; started=1; next }
    started && !body && $0 ~ /^[[:space:]]*$/ { next }
    started { body=1; print }
  ' "$1"
}

# Single-quoted sed: backticks and $ stay literal.
to_norun_body() { sed -e 's/!`\([^`]*\)`/run `\1`/g'; }

# Write stdin to a destination atomically (temp + mv) so a mid-render failure
# never leaves a truncated port. The temp lives in the destination's OWN dir so
# the mv is a same-filesystem rename — and so mktemp gets the template argument
# BSD/macOS requires (a bare `mktemp` errors there, aborting the whole render).
emit() {  # $1 = destination path
  local t; t="$(mktemp "$(dirname "$1")/.port.XXXXXX")" || return 1
  # emit runs in a pipe subshell, so the caller's trap can't clean this up.
  if cat > "$t" && mv "$t" "$1"; then return 0; fi
  rm -f "$t"; return 1
}

mkdir -p "$OUT"
# Sweep temps orphaned by a previously-interrupted run (prune below only globs
# *.md, so these hidden .port.* files would otherwise linger).
rm -f "$OUT"/.port.* 2>/dev/null || true

n=0
generated=" "
for f in "$SRC"/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  [ "$base" = "README.md" ] && continue
  name="${base%.md}"
  title="$(printf '%s' "${name:0:1}" | tr '[:lower:]' '[:upper:]')${name:1}"
  desc="$(fm_field "$f" description)"
  body="$(fm_body "$f")"
  has_args=0; printf '%s\n' "$body" | grep -q '\$ARGUMENTS' && has_args=1
  port="$PREFIX$base"

  {
    printf '<!-- GENERATED from commands/%s by render-ports.sh — do not edit. -->\n' "$base"
    printf '# %s\n\n' "$title"
    [ -n "$desc" ] && printf '%s\n\n' "$desc"
    [ "$has_args" = 1 ] && printf '> Cursor has no argument placeholder — type your input after `/%s` and it is appended to this prompt; treat any `$ARGUMENTS` below as that input.\n\n' "$PREFIX$name"
    printf '%s\n' "$body" | to_norun_body
  } | emit "$OUT/$port"

  generated="$generated$port "
  n=$((n+1))
done

# Stale-port cleanup runs AFTER a complete render, never before — an aborted
# render must not be able to empty the port dir and install zero commands.
for p in "$OUT"/*.md; do
  [ -e "$p" ] || continue
  b="$(basename "$p")"
  case "$generated" in
    *" $b "*) ;;
    *)
      if head -1 "$p" | grep -q '^<!-- GENERATED from commands/'; then
        rm -f "$p"
      else
        echo "render-ports: leaving non-generated commands/cursor/$b in place (no GENERATED marker)" >&2
      fi
      ;;
  esac
done

echo "Rendered $n Cursor command port(s) -> commands/cursor/"
