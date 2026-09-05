#!/usr/bin/env bash
#
# build-guardrails.sh — generate guardrails/registry.json from the five prose
# registries and their detector sidecars.
#
# The prose is the source of truth. This turns it into something a hook can
# execute, so adding a ban to the prose arms its detector in the same edit
# instead of requiring a second, hand-written change in a hook that nothing
# keeps in sync. See guardrails/_format.md for the contract being parsed.
#
# Usage:  ./build-guardrails.sh          # write guardrails/registry.json
#         ./build-guardrails.sh --check  # fail if the committed file is stale
#
# Exit 0  registry written (or already current, under --check)
#      1  --check and the committed registry.json is out of date
#      2  a source file violates the format — every violation is named
#
# Dependencies: bash + sed + jq. Fails loudly; never emits a partial registry.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 2
# PSP_GUARDRAILS_DIR lets a caller point the generator at a throwaway copy of
# guardrails/ instead of the live one. test.sh uses it to probe the failure
# modes without ever mutating a tracked file — a suite that edits the tree it
# is checking leaves damage behind when it is interrupted.
GDIR="${PSP_GUARDRAILS_DIR:-guardrails}"
[ -d "$GDIR" ] || { echo "build-guardrails: no such directory: $GDIR" >&2; exit 2; }
OUT="$GDIR/registry.json"
mode="${1:-write}"
case "$mode" in write|--check) ;; *) echo "build-guardrails: unknown option '$mode'" >&2; exit 2 ;; esac

command -v jq >/dev/null 2>&1 || { echo "build-guardrails: jq is required." >&2; exit 2; }

errors=0
err() { echo "build-guardrails: $*" >&2; errors=$((errors + 1)); }

VALID_SCOPES=" style tokens prose code "
VALID_CONF=" certain scoped "
VALID_KINDS=" regex regexi count unwritten token render manual "
# A scope with no hook cannot carry a live detector — see _format.md.
HOOKED_SCOPES=" style tokens prose "

registry='{}'

for prose in "$GDIR"/*-anti-patterns.md; do
  base="$(basename "$prose")"
  sidecar="${prose%.md}.detect.md"
  [ -f "$sidecar" ] || { err "$base has no sidecar ($(basename "$sidecar"))"; continue; }

  # --- prose side: ID -> name. Two accepted shapes (see _format.md). ---------
  prose_ids=""
  names_json='{}'
  while IFS=$'\t' read -r id name; do
    [ -n "$id" ] || continue
    case " $prose_ids " in
      *" $id "*) err "duplicate ID $id in $base" ;;
      *) prose_ids="$prose_ids $id" ;;
    esac
    names_json="$(printf '%s' "$names_json" | jq --arg i "$id" --arg n "$name" '.[$i] = $n')"
  done < <(sed -nE \
      -e 's/^- \*\*\(([A-Z]+-[0-9]+)\) (.+)\*\*.*$/\1\t\2/p' \
      -e 's/^## ([A-Z]+-[0-9]+) — (.+[^[:space:]])[[:space:]]*$/\1\t\2/p' "$prose")

  [ -n "$prose_ids" ] || err "$base declares no bans — the ID shapes in _format.md did not match"

  # --- sidecar side: one row per ban ----------------------------------------
  side_ids=""
  # A regex cell legitimately contains `\|`, and splitting on a bare | would cut
  # the pattern in half. Park the escaped pipes on \x01, split, then restore.
  while IFS= read -r row; do
    case "$row" in *'|'*) ;; *) continue ;; esac
    parked="${row//\\|/$'\x01'}"
    IFS='|' read -r -a cols <<< "$parked"
    [ "${#cols[@]}" -ge 6 ] || continue
    unpark() { printf '%s' "${1//$'\x01'/|}" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'; }
    id="$(printf '%s' "${cols[1]}" | tr -d '[:space:]')"
    printf '%s' "$id" | grep -qE '^[A-Z]+-[0-9]+$' || continue
    conf="$(unpark "${cols[2]}")"
    scope="$(unpark "${cols[3]}")"
    detect="$(unpark "${cols[4]}")"
    fix="$(unpark "${cols[5]}")"

    case " $side_ids " in
      *" $id "*) err "duplicate ID $id in $(basename "$sidecar")" ; continue ;;
      *) side_ids="$side_ids $id" ;;
    esac
    case " $prose_ids " in
      *" $id "*) ;;
      *) err "$id is in $(basename "$sidecar") but has no ban in $base" ; continue ;;
    esac

    kind="${detect%%:*}"
    pattern=""; threshold=""
    case "$kind" in
      regex|regexi)
        pattern="${detect#*:}" ;;
      count)
        rest="${detect#count:}"; threshold="${rest%%:*}"; pattern="${rest#*:}"
        printf '%s' "$threshold" | grep -qE '^[0-9]+$' \
          || err "$id: count threshold '$threshold' is not a number" ;;
      unwritten|token|render|manual)
        kind="$detect" ;;
      *) err "$id: unknown detect kind '$kind'"; continue ;;
    esac
    case " $VALID_KINDS " in *" $kind "*) ;; *) err "$id: unknown detect kind '$kind'"; continue ;; esac

    if [ -n "$pattern" ]; then
      # Strip the backticks _format.md requires around a pattern.
      pattern="$(printf '%s' "$pattern" | sed -E 's/^`//; s/`$//')"
      [ -n "$pattern" ] || err "$id: $kind with an empty pattern"
      printf 'x\n' | grep -qE "$pattern" >/dev/null 2>&1
      [ $? -le 1 ] || err "$id: pattern is not a valid ERE: $pattern"
    fi

    live=0
    case "$kind" in regex|regexi|count) live=1 ;; esac

    if [ "$live" -eq 1 ] || [ "$kind" = unwritten ]; then
      case " $VALID_CONF " in *" $conf "*) ;; *) err "$id: confidence must be certain|scoped, got '$conf'" ;; esac
      case " $VALID_SCOPES " in *" $scope "*) ;; *) err "$id: scope must be one of$VALID_SCOPES got '$scope'" ;; esac
    else
      [ "$conf" = "—" ]  || err "$id: $kind must have confidence '—', got '$conf'"
      [ "$scope" = "—" ] || err "$id: $kind must have scope '—', got '$scope'"
    fi

    if [ "$live" -eq 1 ]; then
      [ -n "$fix" ] && [ "$fix" != "—" ] || err "$id: a live detector needs a Fix clause"
      case " $HOOKED_SCOPES " in
        *" $scope "*) ;;
        *) err "$id: scope '$scope' has no hook, so a live detector there would never run" ;;
      esac
    fi

    name="$(printf '%s' "$names_json" | jq -r --arg i "$id" '.[$i] // ""')"
    registry="$(printf '%s' "$registry" | jq \
      --arg id "$id" --arg name "$name" --arg file "$base" --arg kind "$kind" \
      --arg conf "$conf" --arg scope "$scope" --arg pat "$pattern" \
      --arg thr "$threshold" --arg fix "$fix" '
      .[$id] = ({ name: $name, file: $file, kind: $kind }
        + (if $conf  == "—" or $conf  == "" then {} else { confidence: $conf } end)
        + (if $scope == "—" or $scope == "" then {} else { scope: $scope } end)
        + (if $pat   == ""  then {} else { pattern: $pat } end)
        + (if $thr   == ""  then {} else { threshold: ($thr|tonumber) } end)
        + (if $fix   == "—" or $fix   == "" then {} else { fix: $fix } end))')"
  done < "$sidecar"

  for id in $prose_ids; do
    case " $side_ids " in
      *" $id "*) ;;
      *) err "$id is a ban in $base but has no row in $(basename "$sidecar")" ;;
    esac
  done
done

if [ "$errors" -gt 0 ]; then
  echo "build-guardrails: $errors problem(s) — registry NOT written." >&2
  exit 2
fi

new="$(printf '%s' "$registry" | jq -S '.')"

if [ "$mode" = --check ]; then
  if [ -f "$OUT" ] && [ "$(jq -S '.' "$OUT" 2>/dev/null)" = "$new" ]; then
    echo "build-guardrails: $OUT is current ($(printf '%s' "$new" | jq 'length') bans)."
    exit 0
  fi
  echo "build-guardrails: $OUT is stale — run ./build-guardrails.sh and commit the result." >&2
  exit 1
fi

printf '%s\n' "$new" > "$OUT"
printf '%s' "$new" | jq -r '
  (length|tostring) + " bans -> '"$OUT"'",
  "  live detectors: " + ([.[]|select(.kind=="regex" or .kind=="regexi" or .kind=="count")]|length|tostring),
  "  unwritten (detectable, not yet written): " + ([.[]|select(.kind=="unwritten")]|length|tostring),
  "  token / render / manual: " + ([.[]|select(.kind=="token" or .kind=="render" or .kind=="manual")]|length|tostring)'
