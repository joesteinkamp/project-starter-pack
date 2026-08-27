#!/usr/bin/env bash
#
# validate-tokens.sh — WCAG contrast for a project's DESIGN.json colour tokens.
#
# skills/validate/SKILL.md Mode A names five token pairs and says "Compute the
# contrast, don't eyeball it". This computes them, so no model is asked to do
# arithmetic it cannot be held to. Every pair in every theme block the file
# ships is measured and printed with its ratio; the exit code is the verdict.
#
# Usage:  scripts/validate-tokens.sh [path/to/DESIGN.json]
#         (defaults to DESIGN.json at the git root, else ./DESIGN.json)
#
# Exit 0  every pair clears its floor
#      1  at least one pair is below its floor (each named, with its ratio)
#      2  the file, a token, or a token's value could not be read
#
# Dependencies: bash + jq. No others — see AGENTS.md. The OKLCH -> WCAG chain is
# pure jq; jq's math builtins are unary filters (`0 | cos`), not `cos(0)`.

set -uo pipefail

command -v jq >/dev/null 2>&1 || { echo "validate-tokens: jq is required." >&2; exit 2; }

file="${1:-}"
if [ -z "$file" ]; then
  root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
  file="$root/DESIGN.json"
  [ -f "$file" ] || file="DESIGN.json"
fi
[ -f "$file" ] || { echo "validate-tokens: no such file: $file" >&2; exit 2; }
jq empty "$file" 2>/dev/null || { echo "validate-tokens: $file is not valid JSON." >&2; exit 2; }

# The five pairs and their floors come from skills/validate/SKILL.md Mode A,
# unchanged: 4.5:1 for text, 3:1 for control boundaries (WCAG 1.4.11).
read -r -d '' PROGRAM <<'JQ'
# --- OKLCH -> OKLab -> linear sRGB -> WCAG relative luminance ----------------
# The OKLab matrix already yields *linear* sRGB, which is what WCAG relative
# luminance is defined on, so no gamma round-trip is needed. Components are
# clamped to [0,1]: exact for in-gamut colours, an approximation of the
# browser's gamut mapping outside it.
def parse_oklch($slot):
  if type != "string" then
    { err: "\($slot): value is \(type|tostring), expected an oklch() string" }
  elif test("/") then
    { err: "\($slot): alpha channel in \(.) — contrast needs a backdrop to composite against" }
  elif (test("^\\s*oklch\\(")|not) then
    { err: "\($slot): \(.) is not oklch() — the token system is OKLCH (design-anti-patterns.md)" }
  else
    ( capture("oklch\\(\\s*(?<l>[0-9.]+)(?<lp>%?)\\s+(?<c>[0-9.]+)\\s+(?<h>-?[0-9.]+|none)")? ) as $m
    | if $m == null then { err: "\($slot): could not parse \(.)" }
      else { L: (($m.l|tonumber) / (if $m.lp == "%" then 100 else 1 end)),
             C: ($m.c|tonumber),
             H: (if $m.h == "none" then 0 else ($m.h|tonumber) end) }
      end
  end;

def lum:
  . as $t
  | ($t.H * 3.14159265358979323846 / 180) as $hr
  | ($t.C * ($hr|cos)) as $a
  | ($t.C * ($hr|sin)) as $b
  | ($t.L + 0.3963377774*$a + 0.2158037573*$b) as $l_
  | ($t.L - 0.1055613458*$a - 0.0638541728*$b) as $m_
  | ($t.L - 0.0894841775*$a - 1.2914855480*$b) as $s_
  | ($l_*$l_*$l_) as $l | ($m_*$m_*$m_) as $m | ($s_*$s_*$s_) as $s
  | [ ( 4.0767416621*$l - 3.3077115913*$m + 0.2309699292*$s),
      (-1.2684380046*$l + 2.6097574011*$m - 0.3413193965*$s),
      (-0.0041960863*$l - 0.7034186147*$m + 1.7076147010*$s) ]
  | map(if . < 0 then 0 elif . > 1 then 1 else . end)
  | (0.2126*.[0] + 0.7152*.[1] + 0.0722*.[2]);

def ratio($x; $y):
  ($x|lum) as $a | ($y|lum) as $b
  | (if $a > $b then ($a+0.05)/($b+0.05) else ($b+0.05)/($a+0.05) end)
  | .*100 | round / 100;

# --- token lookup -----------------------------------------------------------
# A theme is "_" (the default `color` block) or a key under `themes`. A missing
# token is an error, never a skipped pair: a validator that reports "all pass"
# because it parsed nothing is the failure mode this exists to prevent.
def block($theme): if $theme == "_" then .color else .themes[$theme].color end;
def tname($theme): if $theme == "_" then "default" else $theme end;

def token($theme; $name):
  (block($theme) // {}) as $b
  | if ($b | has($name) | not) then { err: "\(tname($theme)):\($name): token missing" }
    elif ($b[$name] | has("$value") | not) then { err: "\(tname($theme)):\($name): no $value key" }
    else ($b[$name]["$value"] | parse_oklch("\(tname($theme)):\($name)"))
    end;

[ "foreground/background|foreground|background|4.5",
  "muted/background|muted|background|4.5",
  "accent/background|accent|background|4.5",
  "accentForeground/accent|accentForeground|accent|4.5",
  "borderStrong/background|borderStrong|background|3.0" ] as $pairs
| . as $doc
| (["_"] + ((.themes // {}) | keys)) as $themes
| $themes[] as $theme
| $pairs[]
| (. / "|") as [$label, $fg, $bg, $min]
| ($doc | token($theme; $fg)) as $a
| ($doc | token($theme; $bg)) as $b
| tname($theme) as $tname
| if ($a.err // $b.err) then
    "ERROR\t\($tname)\t\($label)\t-\t\($min)\t\($a.err // $b.err)"
  else
    ratio($a; $b) as $r
    | (if $r >= ($min|tonumber) then "PASS" else "FAIL" end) as $verdict
    | "\($verdict)\t\($tname)\t\($label)\t\($r)\t\($min)\t"
  end
JQ

out="$(jq -r "$PROGRAM" "$file" 2>&1)" || {
  echo "validate-tokens: could not evaluate $file" >&2
  printf '%s\n' "$out" >&2
  exit 2
}

fails=0; errors=0; total=0
printf '%-8s %-9s %-26s %8s %6s\n' STATUS THEME PAIR RATIO FLOOR
while IFS=$'\t' read -r status theme pair ratio min detail; do
  [ -n "${status:-}" ] || continue
  total=$((total + 1))
  printf '%-8s %-9s %-26s %8s %6s' "$status" "$theme" "$pair" "$ratio" "$min"
  case "$status" in
    FAIL)  fails=$((fails + 1));  printf '   below the %s:1 floor' "$min" ;;
    ERROR) errors=$((errors + 1)); printf '   %s' "$detail" ;;
  esac
  printf '\n'
done <<< "$out"

echo
if [ "$total" -eq 0 ]; then
  echo "validate-tokens: $file has no colour tokens to check." >&2
  exit 2
fi
if [ "$errors" -gt 0 ]; then
  echo "validate-tokens: $errors token(s) unreadable in $file — nothing above is trustworthy." >&2
  exit 2
fi
if [ "$fails" -gt 0 ]; then
  echo "validate-tokens: $fails of $total pair(s) below floor in $file." >&2
  exit 1
fi
echo "validate-tokens: all $total pair(s) clear their floor in $file."
