#!/usr/bin/env bash
#
# check-guardrail-fixtures.sh — every live detector must trip its own fixture
# and stay quiet on its clean one.
#
# A grep-based linter dies of false positives, not of missing rules. The
# `clean` half of each pair is the load-bearing one: it is where a judgment
# like "'robust' and 'leverage' are excluded because tech docs use them
# honestly" stops being a code comment and becomes a test. Broaden a regex so
# it swallows a clean fixture and this fails.
#
# Usage:  ./check-guardrail-fixtures.sh
#
# Exit 0  every live detector has both fixtures and behaves on them
#      1  at least one detector is missing a fixture or misbehaves (itemized)
#      2  the registry or jq is unavailable
#
# Dependencies: bash + grep + jq.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 2

REG="${PSP_REGISTRY:-guardrails/registry.json}"
DIR="${PSP_FIXTURES:-fixtures/guardrails}"

command -v jq >/dev/null 2>&1 || { echo "check-guardrail-fixtures: jq is required." >&2; exit 2; }
[ -f "$REG" ] || { echo "check-guardrail-fixtures: no $REG — run ./build-guardrails.sh." >&2; exit 2; }

fails=0
checked=0
fail() { echo "  !! $*" >&2; fails=$((fails + 1)); }

# The scope decides the fixture's extension: a prose detector has no business
# being handed a stylesheet.
ext_for() { case "$1" in style|tokens) echo css ;; prose) echo md ;; code) echo ts ;; *) echo txt ;; esac; }

# Does the detector described by $2..$4 fire on file $1?
detector_fires() {  # file kind pattern threshold
  local file="$1" kind="$2" pattern="$3" threshold="${4:-0}" hits
  case "$kind" in
    regex)  grep -qE  -- "$pattern" "$file" 2>/dev/null ;;
    regexi) grep -qiE -- "$pattern" "$file" 2>/dev/null ;;
    count)
      hits="$(grep -oE -- "$pattern" "$file" 2>/dev/null | wc -l | tr -d '[:space:]')"
      [ "${hits:-0}" -gt "$threshold" ] 2>/dev/null ;;
    *) return 1 ;;
  esac
}

# \x01 as the field separator, not @tsv: @tsv escapes backslashes and would
# hand us a pattern that no longer means what the registry says.
live_detectors() {
  jq -r '
    to_entries
    | map(select(.value.kind == "regex" or .value.kind == "regexi" or .value.kind == "count"))
    | sort_by(.key)[]
    | [ .key, .value.kind, .value.pattern, (.value.threshold // 0 | tostring), (.value.scope // "") ]
    | join("\u0001")' "$REG"
}

while IFS=$'\x01' read -r id kind pattern threshold scope; do
  [ -n "$id" ] || continue
  checked=$((checked + 1))
  ext="$(ext_for "$scope")"
  trips="$DIR/$id/trips.$ext"
  clean="$DIR/$id/clean.$ext"

  if [ ! -f "$trips" ]; then
    fail "$id: missing $trips — a live detector needs a file that proves it fires"
  elif ! detector_fires "$trips" "$kind" "$pattern" "$threshold"; then
    fail "$id: does NOT fire on its own trips fixture ($trips) — detector broken, or the fixture drifted"
  fi

  if [ ! -f "$clean" ]; then
    fail "$id: missing $clean — without it nothing guards against false positives"
  elif detector_fires "$clean" "$kind" "$pattern" "$threshold"; then
    fail "$id: fires on its own clean fixture ($clean) — the pattern is too broad"
  fi
done < <(live_detectors)

# Cross-check: no clean fixture may trip ANY live detector of its scope, not
# only its own. This is what catches a neighbouring regex growing greedy.
while IFS=$'\x01' read -r id kind pattern threshold scope; do
  [ -n "$id" ] || continue
  ext="$(ext_for "$scope")"
  for other in "$DIR"/*/"clean.$ext"; do
    [ -f "$other" ] || continue
    case "$other" in "$DIR/$id/"*) continue ;; esac
    if detector_fires "$other" "$kind" "$pattern" "$threshold"; then
      fail "$id fires on another ban's clean fixture ($other) — over-broad across the whole '$scope' scope"
    fi
  done
done < <(live_detectors)

if [ "$checked" -eq 0 ]; then
  echo "check-guardrail-fixtures: no live detectors in $REG — nothing to check." >&2
  exit 2
fi
if [ "$fails" -gt 0 ]; then
  echo "check-guardrail-fixtures: $fails failure(s) across $checked live detector(s)." >&2
  exit 1
fi
echo "check-guardrail-fixtures: $checked live detector(s), each proven to fire on its trips fixture and stay quiet on every clean one."
