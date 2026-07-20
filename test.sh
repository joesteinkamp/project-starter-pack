#!/usr/bin/env bash
#
# test.sh — integrity linter for project-starter-pack.
#
# PSP has no build/render step (it is markdown + AI-driven), so this checks the
# one contract that can silently rot as the pack grows: the slot ↔ question ↔
# orchestrator ↔ template wiring, plus that the shipped example is a complete,
# placeholder-free render whose structure matches the templates.
#
# Run from anywhere:  ./test.sh
# Exit 0 if every check passes, nonzero otherwise.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

pass=0
fail=0

ok()      { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
bad()     { printf '  FAIL %s\n' "$1"; fail=$((fail + 1)); }
section() { printf '\n== %s ==\n' "$1"; }

# Drop fenced code blocks so a slot quoted in an example snippet doesn't count
# as a real binding (in either direction).
strip_fences() { sed '/^```/,/^```/d' "$1" 2>/dev/null; }

# Extract unique {{SLOT}} tokens (2+ chars of [A-Z_]; this skips the throwaway
# single-letter placeholders like {{N}}/{{M}}/{{K}} in printed summaries).
slots() { strip_fences "$1" | grep -oE '\{\{[A-Z_]{2,}\}\}' | sort -u; }

# Is token $1 present anywhere in file $2 (outside code fences)?
# (grep without -q so it drains the pipe — `-q` exits early and the resulting
# SIGPIPE to sed would read as failure under pipefail)
in_file() { strip_fences "$2" | grep -F "$1" >/dev/null; }

# ---------------------------------------------------------------------------
section "1. Template slot ↔ questionnaire parity (per brief)"
# Every {{SLOT}} in a brief template must be mentioned somewhere in its
# questionnaire (as a → target or in the Defaults table), and every slot the
# questionnaire references must exist in the template.
# check_brief LABEL TEMPLATE QUESTIONS [EXTRA_TEMPLATE]
# EXTRA_TEMPLATE lets a brief's questionnaire also feed a companion template
# (the DESIGN brief feeds both DESIGN.md and the DESIGN.json tokens file).
check_brief() {
  local label="$1" template="$2" questions="$3" extra="${4:-}"
  local slot
  for slot in $(slots "$template"); do
    if in_file "$slot" "$questions"; then
      ok "$label: $slot has a question/default"
    else
      bad "$label: $slot in $template has NO source in $questions"
    fi
  done
  for slot in $(slots "$questions"); do
    if in_file "$slot" "$template"; then continue; fi
    if [ -n "$extra" ] && in_file "$slot" "$extra"; then continue; fi
    bad "$label: $slot in $questions has no slot in $template${extra:+ or $extra}"
  done
}
check_brief "PRODUCT" templates/PRODUCT.template.md questionnaires/product.questions.md
check_brief "DESIGN"  templates/DESIGN.template.md  questionnaires/design.questions.md templates/DESIGN.tokens.template.json
check_brief "CODE"    templates/CODE.template.md    questionnaires/code.questions.md

# ---------------------------------------------------------------------------
section "2. Orchestrator coverage of synthesized-template slots"
# Every slot in a synthesized template (AGENT + every harness file) must be named
# by the orchestrator skill, and every slot the orchestrator names must exist in
# one of those templates.
ORCH=skills/orchestrator/SKILL.md
SYNTH_TEMPLATES=(
  templates/AGENT.template.md
  templates/CLAUDE.template.md
  templates/GEMINI.template.md
  templates/cursor-rules.template.mdc
)
for t in "${SYNTH_TEMPLATES[@]}"; do
  for slot in $(slots "$t"); do
    if in_file "$slot" "$ORCH"; then
      ok "orchestrator populates $slot ($(basename "$t"))"
    else
      bad "orchestrator never mentions $slot from $(basename "$t")"
    fi
  done
done
for slot in $(slots "$ORCH"); do
  found=0
  for t in "${SYNTH_TEMPLATES[@]}"; do
    in_file "$slot" "$t" && { found=1; break; }
  done
  [ "$found" -eq 1 ] || bad "orchestrator references $slot but no synthesized template defines it"
done

# ---------------------------------------------------------------------------
section "3. DESIGN.json token slots are traceable to the design questionnaire"
for slot in $(slots templates/DESIGN.tokens.template.json); do
  if in_file "$slot" questionnaires/design.questions.md; then
    ok "DESIGN.json $slot is sourced by a question"
  else
    bad "DESIGN.json $slot has no source in design.questions.md"
  fi
done

# ---------------------------------------------------------------------------
section "4. Guardrail wiring"
# Each anti-pattern registry must be referenced by at least one skill and by
# the orchestrator's embed list.
for g in guardrails/*-anti-patterns.md; do
  base="$(basename "$g" .md)"
  if grep -rqF "$base" skills/; then
    ok "$base referenced by a skill"
  else
    bad "$base is referenced by NO skill"
  fi
  if in_file "$base" "$ORCH"; then
    ok "$base embedded by orchestrator"
  else
    bad "$base is NOT embedded by orchestrator"
  fi
done

# ---------------------------------------------------------------------------
section "5. Example renders are complete (no leaked placeholders)"
shopt -s nullglob
example_dirs=(examples/*/)
if [ ${#example_dirs[@]} -eq 0 ]; then
  bad "no example renders found under examples/"
fi
for dir in "${example_dirs[@]}"; do
  found_leak=0
  while IFS= read -r -d '' f; do
    if grep -qE '\{\{|SECTION:' "$f"; then
      bad "leaked placeholder in $f"
      found_leak=1
    fi
  done < <(find "$dir" -type f \( -name '*.md' -o -name '*.json' -o -name '*.mdc' \) -print0)
  [ "$found_leak" -eq 0 ] && ok "${dir} is placeholder-free"
done

# ---------------------------------------------------------------------------
section "6. Example renders match template structure"
# The example is the fixture that proves the templates render completely: every
# heading a template defines (slot-free ones) must appear in the example's
# render, and every key in the tokens template must appear in the example JSON.
# Otherwise a template can grow a section the example silently omits.
check_render_headings() {
  local template="$1" rendered="$2" required="$3"
  if [ ! -f "$rendered" ]; then
    if [ "$required" = required ]; then
      bad "example render missing: $rendered (from $(basename "$template"))"
    fi
    return
  fi
  local missing=0 h
  while IFS= read -r h; do
    case "$h" in *'{{'*) continue ;; esac
    if ! grep -qxF "$h" "$rendered"; then
      bad "$rendered lacks heading from $(basename "$template"): $h"
      missing=1
    fi
  done < <(strip_fences "$template" | grep -E '^#{1,4} ')
  [ "$missing" -eq 0 ] && ok "$rendered carries every $(basename "$template") heading"
}
# Presence check, not structural: a key name found anywhere in the render
# satisfies it. Catches a wholesale-dropped block (e.g. no "dark" key at all),
# not a partial one whose key names also appear elsewhere (e.g. in "light").
check_render_json_keys() {
  local template="$1" rendered="$2"
  [ -f "$rendered" ] || { bad "example render missing: $rendered"; return; }
  local missing=0 key
  while IFS= read -r key; do
    if ! grep -qF "$key" "$rendered"; then
      bad "$rendered lacks token key from $(basename "$template"): $key"
      missing=1
    fi
  done < <(grep -oE '"[a-zA-Z$][a-zA-Z]*"[[:space:]]*:' "$template" | sed 's/[[:space:]]*$//' | sort -u)
  [ "$missing" -eq 0 ] && ok "$rendered carries every $(basename "$template") key"
}
for dir in "${example_dirs[@]}"; do
  # The three briefs + AGENT.md are always written — required in an example.
  check_render_headings templates/PRODUCT.template.md "${dir}PRODUCT.md" required
  check_render_headings templates/DESIGN.template.md  "${dir}DESIGN.md"  required
  check_render_headings templates/CODE.template.md    "${dir}CODE.md"    required
  check_render_headings templates/AGENT.template.md   "${dir}AGENT.md"   required
  # Harness files are optional per project; checked when the example ships them.
  check_render_headings templates/CLAUDE.template.md "${dir}CLAUDE.md" optional
  check_render_headings templates/GEMINI.template.md "${dir}GEMINI.md" optional
  check_render_headings templates/cursor-rules.template.mdc "${dir}.cursor/rules/project.mdc" optional
  [ -f "${dir}DESIGN.json" ] && check_render_json_keys templates/DESIGN.tokens.template.json "${dir}DESIGN.json"
done

# ---------------------------------------------------------------------------
section "7. Command ↔ skill ↔ plugin parity"
# plugin.json points at the dirs.
if grep -qF '"commands"' .claude-plugin/plugin.json && grep -qF '"skills"' .claude-plugin/plugin.json; then
  ok "plugin.json declares commands + skills dirs"
else
  bad "plugin.json missing commands or skills declaration"
fi
# Every skill dir has a SKILL.md whose name matches the dir.
for d in skills/*/; do
  name="$(basename "$d")"
  if [ -f "${d}SKILL.md" ]; then
    if grep -qE "^name: ${name}\b" "${d}SKILL.md"; then
      ok "skill '$name' has matching SKILL.md"
    else
      bad "skill '$name' SKILL.md frontmatter name does not match dir"
    fi
  else
    bad "skills/$name has no SKILL.md"
  fi
done
# Every command must invoke at least one existing skill, and any backticked
# token on an invoke/skill line must resolve to a real skill dir — regardless
# of the exact phrasing around it.
# CONSTRAINT: every lowercase-only `token` on a line mentioning invoke/skill is
# treated as a skill name. Keep non-skill references on such lines uppercase or
# dotted (`PRODUCT.md`, `package.json`) — a bare lowercase one false-fails.
for c in commands/*.md; do
  found_skill=0
  while IFS= read -r line; do
    case "$line" in
      *[Ii]nvoke*\`*[a-z]*\`* | *\`*[a-z]*\`*skill* | *skill*\`*[a-z]*\`*) ;;
      *) continue ;;
    esac
    for ref in $(printf '%s\n' "$line" | grep -oE '`[a-z][a-z-]*`' | tr -d '\`'); do
      if [ -f "skills/${ref}/SKILL.md" ]; then
        found_skill=1
        ok "$(basename "$c") → skill '$ref' exists"
      else
        bad "$(basename "$c") names '$ref' in a skill context but skills/$ref is missing"
      fi
    done
  done < "$c"
  [ "$found_skill" -eq 1 ] || bad "$(basename "$c") never invokes an existing skill"
done

# ---------------------------------------------------------------------------
section "8. Extract maps only to real brief slots"
# Every {{SLOT}} the extract skill claims to fill must exist in a brief template
# (or the DESIGN.json tokens file) — so the mapping can't reference a slot the
# briefs don't have.
EXTRACT=skills/extract/SKILL.md
BRIEF_TEMPLATES=(
  templates/PRODUCT.template.md
  templates/DESIGN.template.md
  templates/CODE.template.md
  templates/DESIGN.tokens.template.json
)
if [ -f "$EXTRACT" ]; then
  for slot in $(slots "$EXTRACT"); do
    found=0
    for t in "${BRIEF_TEMPLATES[@]}"; do
      in_file "$slot" "$t" && { found=1; break; }
    done
    if [ "$found" -eq 1 ]; then
      ok "extract maps $slot to a real slot"
    else
      bad "extract references $slot which no brief template defines"
    fi
  done
fi

# ---------------------------------------------------------------------------
section "9. Optional hooks: syntax, wiring parity, guardrail linkage"
# The advisory hooks are optional; if present they must parse, the snippet and
# the installer must wire the same scripts, and the design bans the hooks key
# on must still exist in the guardrail (so a hook can't silently enforce a rule
# the registry dropped).
if [ -d hooks ]; then
  for h in hooks/*.sh; do
    if bash -n "$h" 2>/dev/null; then
      ok "$(basename "$h") parses"
    else
      bad "$(basename "$h") has a syntax error"
    fi
  done
  # settings.snippet.json and install-hooks.sh HOOK_SCRIPTS are two declarations
  # of the same wiring — they must list the same hook scripts, and each must exist.
  snippet_scripts="$(grep -oE '[a-z][a-z-]*\.sh' hooks/settings.snippet.json | grep -v '^install-hooks' | sort -u)"
  installer_scripts="$(grep -m1 '^HOOK_SCRIPTS=' hooks/install-hooks.sh | grep -oE '[a-z][a-z-]*\.sh' | sort -u)"
  if [ -n "$snippet_scripts" ] && [ "$snippet_scripts" = "$installer_scripts" ]; then
    ok "settings.snippet.json and install-hooks.sh wire the same scripts"
  else
    bad "settings.snippet.json vs install-hooks.sh HOOK_SCRIPTS mismatch (snippet: ${snippet_scripts//$'\n'/ } / installer: ${installer_scripts//$'\n'/ })"
  fi
  for s in $snippet_scripts; do
    [ -f "hooks/$s" ] && ok "wired hook hooks/$s exists" || bad "wired hook hooks/$s does not exist"
  done
  # NOTE: these terms are keyed on by guard-design.sh / check-anti-patterns.sh —
  # the three files move in lockstep; change a hook's pattern, update this list.
  DG=guardrails/design-anti-patterns.md
  for term in OKLCH glassmorphism "layout properties" "gradient text"; do
    if grep -qiF "$term" "$DG"; then
      ok "design guardrail still covers: $term"
    else
      bad "a hook keys on '$term' but design-anti-patterns.md no longer mentions it"
    fi
  done
else
  ok "no hooks/ directory (hooks are optional)"
fi

# ---------------------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
