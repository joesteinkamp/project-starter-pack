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
# as a real binding (in either direction). Section 0 guarantees fences are
# balanced — an unclosed fence would make this delete to end-of-file.
strip_fences() { sed '/^```/,/^```/d' "$1" 2>/dev/null; }

# Extract unique {{SLOT}} tokens (2+ chars of [A-Z_]; this skips the throwaway
# single-letter placeholders like {{N}}/{{M}}/{{K}} in printed summaries).
slots() { strip_fences "$1" | grep -oE '\{\{[A-Z_]{2,}\}\}' | sort -u; }

# Is token $1 present anywhere in file $2 (outside code fences)?
# (grep without -q so it drains the pipe — `-q` exits early and the resulting
# SIGPIPE to sed would read as failure under pipefail)
in_file() { strip_fences "$2" | grep -F "$1" >/dev/null; }

# ---------------------------------------------------------------------------
section "0. Markdown fence hygiene"
# Every downstream check pipes files through strip_fences; an unbalanced ```
# silently swallows the rest of the file and the checks go blind.
fence_files=0
fence_bad=0
while IFS= read -r -d '' f; do
  fence_files=$((fence_files + 1))
  n="$(grep -c '^```' "$f" || true)"
  if [ $((n % 2)) -ne 0 ]; then
    bad "unbalanced \`\`\` fences in $f"
    fence_bad=1
  fi
done < <(find templates skills commands questionnaires guardrails examples -type f \( -name '*.md' -o -name '*.mdc' \) -print0)
[ "$fence_bad" -eq 0 ] && ok "all $fence_files markdown files have balanced fences"

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
  templates/WRITING.template.md
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
shopt -u nullglob   # leaving it on would make later empty globs vanish silently
if [ ${#example_dirs[@]} -eq 0 ]; then
  bad "no example renders found under examples/"
fi
for dir in ${example_dirs[@]+"${example_dirs[@]}"}; do
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
# render, every key path in the tokens template must appear in the example
# JSON (and vice versa), and every harness render must carry the layering
# note's canonical clause — the fixture must not be able to contradict the rule
# it demonstrates.
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
    if ! strip_fences "$rendered" | grep -xF "$h" >/dev/null; then
      bad "$rendered lacks heading from $(basename "$template"): $h"
      missing=1
    fi
  done < <(strip_fences "$template" | grep -E '^#{1,4} ')
  [ "$missing" -eq 0 ] && ok "$rendered carries every $(basename "$template") heading"
}
# Replace template slots with scalars so the template parses as JSON: quoted
# slots become a string, bare (numeric/array) slots become 0.
mock_json() { sed -E 's/"\{\{[A-Z_]+\}\}"/"x"/g; s/\{\{[A-Z_]+\}\}/0/g' "$1"; }
# Object key paths only (array indices excluded, so value-array length differences
# between template and render don't count as structure).
json_key_paths() { jq -r '[paths | select(all(.[]; type == "string")) | join(".")] | unique | .[]' 2>/dev/null; }
# Structural check: the full set of key paths must match in BOTH directions —
# a dropped dark leaf, a duplicated key name elsewhere, or a fixture that
# drifted ahead of the schema all fail. `themes` is the one optional subtree
# (single-theme systems delete it, per the design-brief skill).
check_render_json_paths() {
  local template="$1" rendered="$2"
  [ -f "$rendered" ] || { bad "example render missing: $rendered"; return; }
  if ! jq empty "$rendered" 2>/dev/null; then
    bad "$rendered is not valid JSON"
    return
  fi
  if ! mock_json "$template" | jq empty 2>/dev/null; then
    bad "$(basename "$template") does not parse as JSON after slot mock-interpolation"
    return
  fi
  local tpaths rpaths diff_out
  tpaths="$(mock_json "$template" | json_key_paths)"
  rpaths="$(json_key_paths < "$rendered")"
  if ! jq -e 'has("themes")' "$rendered" >/dev/null 2>&1; then
    tpaths="$(printf '%s\n' "$tpaths" | grep -v '^themes')"
  fi
  diff_out="$(diff <(printf '%s\n' "$tpaths") <(printf '%s\n' "$rpaths") | grep -E '^[<>]' || true)"
  if [ -z "$diff_out" ]; then
    ok "$rendered key paths match $(basename "$template")"
  else
    bad "$rendered key paths diverge from $(basename "$template"): $(printf '%s' "$diff_out" | head -4 | tr '\n' ' ')"
  fi
}
# jq-less fallback: presence-only on key names — far weaker (documented so
# nobody mistakes it for a structure check). CI should have jq.
check_render_json_keys() {
  local template="$1" rendered="$2"
  [ -f "$rendered" ] || { bad "example render missing: $rendered"; return; }
  local missing=0 key
  while IFS= read -r key; do
    if ! grep -qF "$key" "$rendered"; then
      bad "$rendered lacks token key from $(basename "$template"): $key"
      missing=1
    fi
  done < <(grep -oE '"[a-zA-Z0-9$_][a-zA-Z0-9$_-]*"[[:space:]]*:' "$template" | sed 's/[[:space:]]*$//' | sort -u)
  [ "$missing" -eq 0 ] && ok "$rendered carries every $(basename "$template") key (presence-only: no jq)"
}
for dir in ${example_dirs[@]+"${example_dirs[@]}"}; do
  # The three briefs + AGENT.md + WRITING.md are always written — required in an example.
  check_render_headings templates/PRODUCT.template.md "${dir}PRODUCT.md" required
  check_render_headings templates/DESIGN.template.md  "${dir}DESIGN.md"  required
  check_render_headings templates/CODE.template.md    "${dir}CODE.md"    required
  check_render_headings templates/AGENT.template.md   "${dir}AGENT.md"   required
  check_render_headings templates/WRITING.template.md "${dir}WRITING.md" required
  # Harness files are optional per project; checked when the example ships them.
  check_render_headings templates/CLAUDE.template.md "${dir}CLAUDE.md" optional
  check_render_headings templates/GEMINI.template.md "${dir}GEMINI.md" optional
  check_render_headings templates/cursor-rules.template.mdc "${dir}.cursor/rules/project.mdc" optional
  if [ -f "${dir}DESIGN.json" ]; then
    if command -v jq >/dev/null 2>&1; then
      check_render_json_paths templates/DESIGN.tokens.template.json "${dir}DESIGN.json"
    else
      check_render_json_keys templates/DESIGN.tokens.template.json "${dir}DESIGN.json"
    fi
  fi
  # The layering note's canonical clause (skills/orchestrator/SKILL.md) must
  # survive into every harness render — a fixture stating the opposite rule
  # passed silently before this check.
  for hf in AGENT.md CLAUDE.md GEMINI.md .cursor/rules/project.mdc; do
    [ -f "${dir}${hf}" ] || continue
    # sed strips blockquote markers, tr collapses line wraps: the clause may
    # break across lines inside a `> ...` blockquote
    if sed 's/^>[[:space:]]*//' "${dir}${hf}" | tr -s '[:space:]' ' ' | grep -F "the project layer wins" >/dev/null; then
      ok "${dir}${hf} carries the canonical layering clause"
    else
      bad "${dir}${hf} lost the layering note's canonical clause ('the project layer wins')"
    fi
  done
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
# Every command must invoke at least one existing skill. Commands use the
# canonical phrase "invoke the `<skill>` skill" — only that phrase is parsed,
# so ordinary backticked words near the word "skill" can't false-positive.
for c in commands/*.md; do
  found_skill=0
  for ref in $(grep -oiE 'invokes? the `[a-z][a-z0-9-]*` skill' "$c" | grep -oE '`[a-z][a-z0-9-]*`' | tr -d '\`'); do
    if [ -f "skills/${ref}/SKILL.md" ]; then
      found_skill=1
      ok "$(basename "$c") → skill '$ref' exists"
    else
      bad "$(basename "$c") invokes '$ref' but skills/$ref is missing"
    fi
  done
  [ "$found_skill" -eq 1 ] || bad "$(basename "$c") never invokes an existing skill (expected the phrase: invoke the \`<name>\` skill)"
done
# The CLAUDE template advertises the command + skill inventory; bind it to the
# real dirs in both directions so a rename can't strand the advertised list.
CT=templates/CLAUDE.template.md
for c in commands/*.md; do
  name="$(basename "$c" .md)"
  if grep -qF "/starter:${name}" "$CT"; then
    ok "CLAUDE template advertises /starter:${name}"
  else
    bad "commands/${name}.md exists but CLAUDE.template.md never advertises /starter:${name}"
  fi
done
for adv in $(grep -oE '/starter:[a-z-]+' "$CT" | sort -u); do
  name="${adv#/starter:}"
  if [ -f "commands/${name}.md" ]; then
    ok "advertised ${adv} is a real command"
  else
    bad "CLAUDE.template.md advertises ${adv} but commands/${name}.md is missing"
  fi
done
for d in skills/*/; do
  name="$(basename "$d")"
  if grep -qF "\`${name}\`" "$CT"; then
    ok "CLAUDE template lists skill ${name}"
  else
    bad "skills/${name} exists but CLAUDE.template.md never lists it"
  fi
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
# the installer must wire the same scripts, and the guardrail ↔ hook contract
# must hold in BOTH directions (a hook can't enforce a rule the registry
# dropped, and the registry can't ban something no hook checks anymore).
if [ -d hooks ]; then
  for h in hooks/*.sh hooks/lib/*.sh; do
    [ -f "$h" ] || continue
    if bash -n "$h" 2>/dev/null; then
      ok "$h parses"
    else
      bad "$h has a syntax error"
    fi
  done
  # settings.snippet.json and install-hooks.sh HOOK_SCRIPTS are two declarations
  # of the same wiring — they must list the same hook scripts, and each must
  # exist. (Digit/uppercase-safe pattern: check-a11y.sh must not extract as
  # y.sh. HOOK_SCRIPTS must stay single-line — this grep reads only that line.)
  script_pat='[A-Za-z0-9][A-Za-z0-9._-]*\.sh'
  snippet_scripts="$(grep -oE "$script_pat" hooks/settings.snippet.json | grep -v '^install-hooks' | sort -u)"
  installer_scripts="$(grep -m1 '^HOOK_SCRIPTS=' hooks/install-hooks.sh | grep -oE "$script_pat" | sort -u)"
  if [ -n "$snippet_scripts" ] && [ "$snippet_scripts" = "$installer_scripts" ]; then
    ok "settings.snippet.json and install-hooks.sh wire the same scripts"
  else
    bad "settings.snippet.json vs install-hooks.sh HOOK_SCRIPTS mismatch (snippet: ${snippet_scripts//$'\n'/ } / installer: ${installer_scripts//$'\n'/ })"
  fi
  for s in $snippet_scripts; do
    if [ -f "hooks/$s" ]; then
      ok "wired hook hooks/$s exists"
    else
      bad "wired hook hooks/$s does not exist"
    fi
  done
  # Guardrail ↔ hook linkage, both directions.
  DG=guardrails/design-anti-patterns.md
  WG=guardrails/writing-anti-patterns.md
  check_link() { # TERM GUARDRAIL HOOK_FILE PATTERN
    local term="$1" guard="$2" hook="$3" pattern="$4"
    if grep -qiF "$term" "$guard"; then
      ok "$(basename "$guard" .md) still covers: $term"
    else
      bad "a hook keys on '$term' but $(basename "$guard") no longer mentions it"
    fi
    if grep -qF "$pattern" "$hook"; then
      ok "$(basename "$hook") still checks: $pattern"
    else
      bad "$(basename "$guard") bans '$term' but $(basename "$hook") no longer greps for '$pattern'"
    fi
  }
  check_link "layout properties" "$DG" hooks/check-anti-patterns.sh "transition"
  check_link "glassmorphism"     "$DG" hooks/check-anti-patterns.sh "backdrop-filter"
  check_link "gradient text"     "$DG" hooks/check-anti-patterns.sh "background-clip"
  check_link "OKLCH"             "$DG" hooks/guard-design.sh        "OKLCH"
  check_link "delve"             "$WG" hooks/check-writing-slop.sh  "delve"
  check_link "worth noting"      "$WG" hooks/check-writing-slop.sh  "worth noting"
  check_link "em-dash clusters"  "$WG" hooks/check-writing-slop.sh  "—"
  # Behavioral fixtures — the install lifecycle and the hooks' pattern matching
  # are exercised for real, not just parsed. The installer's worst historical
  # defects (false success, deleting user hooks, destroying the backup) live
  # here so the suite, not session notes, guards against their return.
  if command -v jq >/dev/null 2>&1; then
    td="$(mktemp -d "${TMPDIR:-/tmp}/psp-test.XXXXXX")"
    mkdir -p "$td/proj/.claude"
    cat > "$td/proj/.claude/settings.json" <<'FIXTURE'
{"model":"opus","hooks":{"PostToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"/home/me/scripts/guard-design.sh"}]}]}}
FIXTURE
    orig_settings="$(cat "$td/proj/.claude/settings.json")"
    if (cd "$td/proj" && "$ROOT/hooks/install-hooks.sh" >/dev/null 2>&1 && "$ROOT/hooks/install-hooks.sh" >/dev/null 2>&1); then
      ok "installer: runs twice cleanly"
    else
      bad "installer: failed on a plain double install"
    fi
    hook_count="$(printf '%s\n' "$installer_scripts" | grep -c .)"
    if [ "$(jq '[.hooks.PostToolUse[].hooks[]? | select(.command | startswith("'"$ROOT"'"))] | length' "$td/proj/.claude/settings.json")" = "$hook_count" ]; then
      ok "installer: idempotent (exactly our $hook_count entries after 2 runs)"
    else
      bad "installer: duplicated or dropped its own entries on reinstall"
    fi
    if [ "$(jq -r '[.hooks.PostToolUse[].hooks[]? | select(.command == "/home/me/scripts/guard-design.sh")] | length' "$td/proj/.claude/settings.json")" = 1 ]; then
      ok "installer: user's same-named hook preserved"
    else
      bad "installer: deleted the user's own guard-design.sh hook"
    fi
    if [ "$(jq -r '.model' "$td/proj/.claude/settings.json")" = "opus" ]; then
      ok "installer: unrelated top-level keys preserved"
    else
      bad "installer: clobbered unrelated settings keys"
    fi
    if [ "$(cat "$td/proj/.claude/settings.json.bak")" = "$orig_settings" ]; then
      ok "installer: backup still pristine after 2 runs"
    else
      bad "installer: second run overwrote the pre-install backup"
    fi
    if (cd "$td/proj" && "$ROOT/hooks/install-hooks.sh" --uninstall >/dev/null 2>&1) \
       && [ "$(jq '[.hooks.PostToolUse[].hooks[]? | select(.command | startswith("'"$ROOT"'"))] | length' "$td/proj/.claude/settings.json")" = 0 ] \
       && [ "$(jq '[.hooks.PostToolUse[].hooks[]? | select(.command == "/home/me/scripts/guard-design.sh")] | length' "$td/proj/.claude/settings.json")" = 1 ]; then
      ok "installer: --uninstall removes exactly ours, keeps the user's"
    else
      bad "installer: --uninstall removed the wrong entries"
    fi
    mkdir -p "$td/bad/.claude"
    echo '{"hooks":{"PostToolUse":[{"matcher":"Edit|Write|MultiEdit","hooks":{"oops":1}}]}}' > "$td/bad/.claude/settings.json"
    bad_before="$(cat "$td/bad/.claude/settings.json")"
    if (cd "$td/bad" && "$ROOT/hooks/install-hooks.sh" >/dev/null 2>&1); then
      bad "installer: exited 0 on a malformed per-entry .hooks shape"
    else
      if [ "$(cat "$td/bad/.claude/settings.json")" = "$bad_before" ]; then
        ok "installer: rejects malformed shape and leaves the file untouched"
      else
        bad "installer: mutated a settings file it then failed on"
      fi
    fi
    mkdir -p "$td/empty/.claude" && : > "$td/empty/.claude/settings.json"
    if (cd "$td/empty" && "$ROOT/hooks/install-hooks.sh" >/dev/null 2>&1); then
      ok "installer: zero-byte settings.json handled"
    else
      bad "installer: choked on a zero-byte settings.json"
    fi
    # Hook pattern behavior: real file + real tool JSON through the real hook.
    # The hook runs with cwd=$td (a non-repo dir) so guard-design resolves its
    # DESIGN.json gate against the fixture dir, not this repo.
    hook_case() { # HOOK EXT CONTENT EXPECT(warn|quiet) LABEL
      local hook="$1" f="$td/case_$5.$2" out
      printf '%s\n' "$3" > "$f"
      out="$(cd "$td" && printf '{"tool_input":{"file_path":"%s"}}' "$f" | "$ROOT/hooks/$hook" 2>&1)"
      if [ "$4" = warn ]; then
        if [ -n "$out" ]; then ok "$hook warns: $5"; else bad "$hook MISSED: $5"; fi
      else
        if [ -z "$out" ]; then ok "$hook quiet: $5"; else bad "$hook FALSE-POSITIVE: $5"; fi
      fi
    }
    echo '{}' > "$td/DESIGN.json"   # guard-design only fires when a token file exists
    hook_case check-anti-patterns.sh css 'a { transition: all 0.3s; }'                     warn  transition-all
    hook_case check-anti-patterns.sh css 'a { transition: margin-top 0.2s; }'              warn  transition-margin
    hook_case check-anti-patterns.sh jsx '<div className="p-2 transition-all">x</div>'     warn  tailwind-transition-all
    hook_case check-anti-patterns.sh jsx '<div className="transition-colors" style={{ width: w }}>x</div>' quiet jsx-transition-colors
    hook_case check-anti-patterns.sh css 'a { transition: var(--all-fast); }'              quiet var-all-fast
    hook_case check-anti-patterns.sh css ':root { --page-transition: all; }'               quiet custom-prop-name
    hook_case check-anti-patterns.sh css 'a { backdrop-filter: blur(4px); }'               warn  glassmorphism
    hook_case guard-design.sh        css 'a { color: #fff; }'                              warn  hex-3
    hook_case guard-design.sh        css 'a { color: #aabbccdd; }'                         warn  hex-8
    hook_case guard-design.sh        css '#dad { color: red; }'                            quiet id-selector
    hook_case guard-design.sh        jsx '<a href="#add">x</a>'                            quiet href-anchor
    rm -rf "$td"
  else
    ok "behavioral fixtures skipped (jq not installed)"
  fi
else
  ok "no hooks/ directory (hooks are optional)"
fi

# ---------------------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
