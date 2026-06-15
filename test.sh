#!/usr/bin/env bash
#
# test.sh — integrity linter for project-starter-pack.
#
# PSP has no build/render step (it is markdown + AI-driven), so this checks the
# one contract that can silently rot as the pack grows: the slot ↔ question ↔
# orchestrator ↔ template wiring, plus that the shipped example is a complete,
# placeholder-free render.
#
# Run from anywhere:  ./test.sh
# Exit 0 if every check passes, nonzero otherwise.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

pass=0
fail=0

ok()   { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL %s\n' "$1"; fail=$((fail + 1)); }
head() { printf '\n== %s ==\n' "$1"; }

# Extract unique {{SLOT}} tokens (slots are always 4+ chars of [A-Z_]; this
# skips throwaway placeholders like {{N}}/{{M}}/{{K}} in printed summaries).
slots() { grep -oE '\{\{[A-Z_]{4,}\}\}' "$1" 2>/dev/null | sort -u; }

# Is token $1 present anywhere in file $2?
in_file() { grep -qF "$1" "$2"; }

# ---------------------------------------------------------------------------
head "1. Template slot ↔ questionnaire parity (per brief)"
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
head "2. Orchestrator coverage of synthesized-template slots"
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
head "3. DESIGN.json token slots are traceable to the design questionnaire"
for slot in $(slots templates/DESIGN.tokens.template.json); do
  if in_file "$slot" questionnaires/design.questions.md; then
    ok "DESIGN.json $slot is sourced by a question"
  else
    bad "DESIGN.json $slot has no source in design.questions.md"
  fi
done

# ---------------------------------------------------------------------------
head "4. Guardrail wiring"
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
head "5. Example renders are complete (no leaked placeholders)"
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
head "6. Command ↔ skill ↔ plugin parity"
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
# Every skill a command says to "Invoke" must exist.
for c in commands/*.md; do
  while IFS= read -r ref; do
    ref="${ref//\`/}"
    if [ -f "skills/${ref}/SKILL.md" ]; then
      ok "$(basename "$c") → skill '$ref' exists"
    else
      bad "$(basename "$c") invokes skill '$ref' which is missing"
    fi
  done < <(grep -oE 'the `[a-z][a-z-]*` skill' "$c" | grep -oE '`[a-z][a-z-]*`')
done

# ---------------------------------------------------------------------------
head "7. Extract maps only to real brief slots"
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
head "8. Optional hooks: syntax + guardrail linkage"
# The advisory hooks are optional; if present they must parse, and the design
# bans they key on must still exist in the guardrail (so a hook can't silently
# enforce a rule the registry dropped).
if [ -d hooks ]; then
  for h in hooks/*.sh; do
    if bash -n "$h" 2>/dev/null; then
      ok "$(basename "$h") parses"
    else
      bad "$(basename "$h") has a syntax error"
    fi
  done
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
