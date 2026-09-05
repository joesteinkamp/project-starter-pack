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
done < <(find templates skills commands conventions questionnaires guardrails examples -type f \( -name '*.md' -o -name '*.mdc' \) -print0)
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
section "2. Wire-up and companion template slot coverage"
# AGENTS.md + CLAUDE.md are written by the setup flow's wire-up step; WRITING.md
# by the design-brief flow. Every slot in those templates must be named by its
# owning skill, and every wire-up slot the setup skill names must exist in a
# wire-up template.
SETUP=skills/setup/SKILL.md
DESIGN_SKILL=skills/design-brief/SKILL.md
WIREUP_TEMPLATES=(
  templates/AGENTS.template.md
  templates/CLAUDE.template.md
)
for t in "${WIREUP_TEMPLATES[@]}"; do
  for slot in $(slots "$t"); do
    if in_file "$slot" "$SETUP"; then
      ok "setup wire-up populates $slot ($(basename "$t"))"
    else
      bad "setup never mentions $slot from $(basename "$t")"
    fi
  done
done
for slot in $(slots "$SETUP"); do
  found=0
  for t in "${WIREUP_TEMPLATES[@]}"; do
    in_file "$slot" "$t" && { found=1; break; }
  done
  [ "$found" -eq 1 ] || bad "setup references $slot but no wire-up template defines it"
done
for slot in $(slots templates/WRITING.template.md); do
  if in_file "$slot" "$DESIGN_SKILL"; then
    ok "design-brief populates $slot (WRITING.template.md)"
  else
    bad "design-brief never mentions $slot from WRITING.template.md"
  fi
done
for slot in $(slots "$DESIGN_SKILL" | grep '^{{WRITING_' || true); do
  in_file "$slot" templates/WRITING.template.md \
    && ok "design-brief's $slot exists in WRITING.template.md" \
    || bad "design-brief references $slot but WRITING.template.md does not define it"
done
# The router must name every brief file it routes to — a lost route would fail
# silently otherwise (AGENTS.md carries no content to miss).
for brief in PRODUCT.md DESIGN.md CODE.md WRITING.md; do
  if in_file "$brief" templates/AGENTS.template.md; then
    ok "router template routes to $brief"
  else
    bad "AGENTS.template.md lost its route to $brief"
  fi
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
section "4. Guardrail wiring (each ban list embedded by its owning brief)"
# The router sends agents to the brief that owns each kind of work, so every
# anti-pattern registry must be embedded by that owning brief's skill — and,
# where the brief template carries a dedicated slot, the slot must exist.
# (ux-anti-patterns is the exception: the design-brief weaves it into DESIGN.md
# sections rather than a single slot.)
for g in guardrails/*-anti-patterns.md; do
  base="$(basename "$g" .md)"
  prefix="${base%-anti-patterns}"
  case "$prefix" in
    product) own_skill=skills/product-brief/SKILL.md; own_tpl=templates/PRODUCT.template.md ;;
    ux)      own_skill=skills/design-brief/SKILL.md;  own_tpl="" ;;
    design)  own_skill=skills/design-brief/SKILL.md;  own_tpl=templates/DESIGN.template.md ;;
    writing) own_skill=skills/design-brief/SKILL.md;  own_tpl=templates/WRITING.template.md ;;
    code)    own_skill=skills/code-brief/SKILL.md;    own_tpl=templates/CODE.template.md ;;
    *)       own_skill=""; own_tpl="" ;;
  esac
  if [ -z "$own_skill" ]; then
    bad "$base has no owning brief mapped in test.sh section 4 — add one"
    continue
  fi
  if in_file "$base" "$own_skill"; then
    ok "$base embedded by its owning skill ($(basename "$(dirname "$own_skill")"))"
  else
    bad "$base is NOT referenced by its owning skill $own_skill"
  fi
  if [ -n "$own_tpl" ]; then
    slot="{{$(printf '%s' "$prefix" | tr '[:lower:]' '[:upper:]')_ANTI_PATTERNS}}"
    if in_file "$slot" "$own_tpl"; then
      ok "$(basename "$own_tpl") carries $slot"
    else
      bad "$(basename "$own_tpl") lost its $slot slot"
    fi
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
  # The three briefs + AGENTS.md + WRITING.md are always written — required in an example.
  check_render_headings templates/PRODUCT.template.md "${dir}PRODUCT.md" required
  check_render_headings templates/DESIGN.template.md  "${dir}DESIGN.md"  required
  check_render_headings templates/CODE.template.md    "${dir}CODE.md"    required
  check_render_headings templates/AGENTS.template.md  "${dir}AGENTS.md"  required
  check_render_headings templates/WRITING.template.md "${dir}WRITING.md" required
  # CLAUDE.md is the wire-up's pointer file — always written alongside AGENTS.md.
  check_render_headings templates/CLAUDE.template.md "${dir}CLAUDE.md" required
  if [ -f "${dir}DESIGN.json" ]; then
    if command -v jq >/dev/null 2>&1; then
      check_render_json_paths templates/DESIGN.tokens.template.json "${dir}DESIGN.json"
    else
      check_render_json_keys templates/DESIGN.tokens.template.json "${dir}DESIGN.json"
    fi
  fi
  # The layering note is baked into AGENTS.template.md and must survive into
  # the example render — pointer files inherit it by importing AGENTS.md, so
  # only the router itself is checked.
  if [ -f "${dir}AGENTS.md" ]; then
    # sed strips blockquote markers, tr collapses line wraps: the clause may
    # break across lines inside a `> ...` blockquote
    if sed 's/^>[[:space:]]*//' "${dir}AGENTS.md" | tr -s '[:space:]' ' ' | grep -F "the project layer wins" >/dev/null; then
      ok "${dir}AGENTS.md carries the canonical layering clause"
    else
      bad "${dir}AGENTS.md lost the layering note's canonical clause ('the project layer wins')"
    fi
  fi
done
# The clause must also stay in the template itself — the render check above
# only proves the fixture, not the source.
if sed 's/^>[[:space:]]*//' templates/AGENTS.template.md | tr -s '[:space:]' ' ' | grep -F "the project layer wins" >/dev/null; then
  ok "AGENTS.template.md carries the canonical layering clause"
else
  bad "AGENTS.template.md lost the layering note's canonical clause"
fi

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
  # Guardrail <-> hook linkage, both directions. This used to be seven
  # hand-written check_link pairs greping the prose for a term and the hook for
  # a pattern. Both sides are now generated: build-guardrails.sh compiles the
  # prose + sidecars into registry.json and refuses to emit a ban whose ID is
  # missing on either side, and the hooks read that registry instead of
  # hardcoding. So the contract holds for EVERY ban rather than seven, and what
  # is left to check here is that the generated artifact is current and that
  # the hooks actually consult it.
  if command -v jq >/dev/null 2>&1; then
    if [ -f guardrails/registry.json ]; then
      ok "guardrails/registry.json is committed (hooks read it at edit time, where no build runs)"
      if "$ROOT/build-guardrails.sh" --check >/dev/null 2>&1; then
        ok "registry.json is in sync with the guardrail sources"
      else
        bad "registry.json is stale — run ./build-guardrails.sh and commit the result"
      fi
      # Every live detector must belong to a scope some hook actually runs.
      orphan="$(jq -r '
        to_entries
        | map(select((.value.kind|test("^(regex|regexi|count)$"))
                     and ((.value.scope // "") | test("^(style|tokens|prose)$") | not)))
        | map(.key) | join(", ")' guardrails/registry.json)"
      [ -z "$orphan" ] && ok "every live detector has a hook that runs its scope" \
                       || bad "live detector(s) in a scope no hook runs: $orphan"
      # Each of the three hooks must delegate to the registry, not hardcode.
      for hk in check-anti-patterns check-writing-slop guard-design; do
        if grep -qF 'hook_check_scope' "hooks/$hk.sh"; then
          ok "hooks/$hk.sh reads the registry"
        else
          bad "hooks/$hk.sh no longer reads the registry — bans are hardcoded again"
        fi
      done
    else
      bad "guardrails/registry.json is missing — run ./build-guardrails.sh"
    fi
  fi
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
    if [ "$(jq '[.hooks.PostToolUse[].hooks[]? | select(.command | contains("'"$ROOT"'"))] | length' "$td/proj/.claude/settings.json")" = "$hook_count" ]; then
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
       && [ "$(jq '[.hooks.PostToolUse[].hooks[]? | select(.command | contains("'"$ROOT"'"))] | length' "$td/proj/.claude/settings.json")" = 0 ] \
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

    # Cross-tool payload shapes. One set of scripts serves four tools, so each
    # tool's event envelope must reach the same file — a regression here means a
    # hook silently stops firing in one tool while still passing everywhere else.
    printf 'a { color: #fff; }\n' > "$td/payload.css"
    payload_case() { # PLATFORM JSON LABEL
      local out
      out="$(cd "$td" && printf '%s' "$2" | env HOOK_PLATFORM="$1" "$ROOT/hooks/guard-design.sh" 2>&1)"
      if [ -n "$out" ]; then ok "hook-input: $1 payload resolved ($3)"; else bad "hook-input: $1 payload NOT resolved ($3)"; fi
    }
    payload_case claude      "$(jq -nc --arg f "$td/payload.css" '{tool_input:{file_path:$f}}')"        tool_input.file_path
    payload_case cursor      "$(jq -nc --arg f "$td/payload.css" '{file_path:$f}')"                     top-level.file_path
    payload_case antigravity "$(jq -nc --arg f "\"$td/payload.css\"" '{toolCall:{args:{TargetFile:$f}}}')" json-encoded.TargetFile
    payload_case codex       "$(jq -nc --arg c "*** Begin Patch
*** Update File: $td/payload.css
*** End Patch" '{tool_input:{command:$c}}')"                                                            apply_patch.envelope

    # Multi-tool install lifecycle, inside a sandboxed HOME so a test run can
    # never touch the developer's real ~/.codex, ~/.cursor, or ~/.gemini.
    fake="$td/home"; mkdir -p "$fake/.codex" "$fake/.cursor" "$fake/.gemini/antigravity-cli"
    if HOME="$fake" "$ROOT/hooks/install-hooks.sh" codex cursor antigravity >/dev/null 2>&1 \
       && HOME="$fake" "$ROOT/hooks/install-hooks.sh" codex cursor antigravity >/dev/null 2>&1; then
      ok "installer: codex/cursor/antigravity install twice cleanly"
    else
      bad "installer: multi-tool install failed"
    fi
    if [ "$(jq '[.hooks.PostToolUse[].hooks[]?] | length' "$fake/.codex/hooks.json" 2>/dev/null)" = "$hook_count" ] \
       && [ "$(jq '.hooks.afterFileEdit | length' "$fake/.cursor/hooks.json" 2>/dev/null)" = "$hook_count" ] \
       && [ "$(jq -r '.["psp-advisory"].PostToolUse[0].hooks | length' "$fake/.gemini/antigravity-cli/hooks.json" 2>/dev/null)" = "$hook_count" ]; then
      ok "installer: idempotent across all three (exactly $hook_count entries each)"
    else
      bad "installer: multi-tool reinstall duplicated or dropped entries"
    fi
    # Every wired command must carry its HOOK_PLATFORM — without it the shared
    # scripts fall back to guessing the payload shape.
    if jq -e -r '[.hooks.PostToolUse[].hooks[].command] | all(startswith("env HOOK_PLATFORM=codex "))' "$fake/.codex/hooks.json" >/dev/null 2>&1 \
       && jq -e -r '[.hooks.afterFileEdit[].command] | all(startswith("env HOOK_PLATFORM=cursor "))' "$fake/.cursor/hooks.json" >/dev/null 2>&1; then
      ok "installer: wired commands carry HOOK_PLATFORM"
    else
      bad "installer: a wired command is missing its HOOK_PLATFORM"
    fi
    # Antigravity is invoked by absolute path with no environment of ours, so the
    # platform has to live in a wrapper script instead.
    if [ -x "$fake/.gemini/antigravity-cli/hooks/psp-guard-design.ag.sh" ] \
       && grep -q 'HOOK_PLATFORM=antigravity' "$fake/.gemini/antigravity-cli/hooks/psp-guard-design.ag.sh"; then
      ok "installer: antigravity wrappers export HOOK_PLATFORM"
    else
      bad "installer: antigravity wrapper missing or does not set HOOK_PLATFORM"
    fi
    if HOME="$fake" "$ROOT/hooks/install-hooks.sh" --uninstall codex cursor antigravity >/dev/null 2>&1 \
       && [ "$(jq -c '.hooks // {}' "$fake/.codex/hooks.json")" = '{}' ] \
       && [ "$(jq -c '.hooks // {}' "$fake/.cursor/hooks.json")" = '{}' ] \
       && [ "$(jq -c '[keys[] | select(startswith("psp-"))]' "$fake/.gemini/antigravity-cli/hooks.json")" = '[]' ] \
       && [ ! -e "$fake/.gemini/antigravity-cli/hooks/psp-guard-design.ag.sh" ]; then
      ok "installer: multi-tool --uninstall leaves no residue"
    else
      bad "installer: multi-tool --uninstall left entries or wrappers behind"
    fi
    # A tool that isn't installed is a clean skip, not a failure.
    bare="$td/bare"; mkdir -p "$bare"
    if HOME="$bare" "$ROOT/hooks/install-hooks.sh" codex cursor antigravity >/dev/null 2>&1 \
       && [ ! -e "$bare/.codex" ] && [ ! -e "$bare/.cursor" ] && [ ! -e "$bare/.gemini" ]; then
      ok "installer: absent tools skipped without creating their dirs"
    else
      bad "installer: an absent tool errored or was created from nothing"
    fi
    rm -rf "$td"
  else
    ok "behavioral fixtures skipped (jq not installed)"
  fi
else
  ok "no hooks/ directory (hooks are optional)"
fi

# ---------------------------------------------------------------------------
section "10. Portability contract (skills are the engine, no harness lock-in)"
# The pack must run in Claude Code, Codex, Cursor, and Antigravity. That holds
# only while the flow logic lives in the skills and the skills name no single
# harness's tools. These checks are what stops it quietly regressing into a
# Claude-only plugin again.

# 10a. Every command has a skill of the same flow. The reverse holds for every
#      skill EXCEPT the three brief flows: they are sub-flows of `setup`,
#      reached by its scope word, by skill name, or by natural language, and
#      deliberately ship no command — the command surface is three verbs
#      (generate / seed / check). Their reachability from Claude and Cursor
#      therefore rests on `setup` naming them, which is what is checked instead.
SUBFLOW_SKILLS=" product-brief design-brief code-brief "
cmd_to_skill() { echo "$1"; }
for c in commands/*.md; do
  name="$(basename "$c" .md)"
  want="$(cmd_to_skill "$name")"
  if [ -f "skills/$want/SKILL.md" ]; then
    ok "flow '$name' exists as skill '$want'"
  else
    bad "command $name has no skill (expected skills/$want/SKILL.md) — unreachable in Codex and Antigravity"
  fi
done
for d in skills/*/; do
  sname="$(basename "$d")"
  case "$SUBFLOW_SKILLS" in
    *" $sname "*)
      if grep -qF "\`$sname\`" skills/setup/SKILL.md; then
        ok "sub-flow '$sname' has no command by design, and setup names it"
      else
        bad "sub-flow '$sname' has no command AND setup never names it — the scope picker lost an option"
      fi
      continue
      ;;
  esac
  found=0
  for c in commands/*.md; do
    [ "$(cmd_to_skill "$(basename "$c" .md)")" = "$sname" ] && { found=1; break; }
  done
  [ "$found" -eq 1 ] && ok "skill '$sname' has a command wrapper" \
                     || bad "skill '$sname' has no command in commands/ — unreachable in Claude/Cursor"
done

# 10b. Commands stay thin. A wrapper that grows its own procedure becomes a
#      second source of truth that only Claude and Cursor ever read.
for c in commands/*.md; do
  lines="$(strip_fences "$c" | grep -cve '^[[:space:]]*$')"
  if [ "$lines" -le 12 ]; then
    ok "$(basename "$c") is a thin wrapper ($lines non-blank lines)"
  else
    bad "$(basename "$c") has $lines non-blank lines — flow logic belongs in the skill, not the command"
  fi
done

# 10c. Ban list: harness-specific tool names and dialect must not appear in the
#      portable layer (skills, questionnaires, conventions). Each has a neutral
#      phrasing that works everywhere.
PORTABLE_DIRS=(skills questionnaires conventions guardrails)
# conventions/question-mechanics.md is the ONE file allowed to name a specific
# harness's tools: its whole job is to say "use AskUserQuestion if you're in
# Claude Code, otherwise number the options", and to tell skills to stop hunting
# for a plugin root. Naming it there is what keeps it out of everywhere else.
MECHANICS=conventions/question-mechanics.md
ban_check() {  # $1 = grep -E pattern, $2 = human name, $3 = the neutral alternative, $4 = optional exempt file
  local hits exempt="${4:-}"
  hits="$(grep -rlE "$1" "${PORTABLE_DIRS[@]}" 2>/dev/null || true)"
  [ -n "$exempt" ] && hits="$(printf '%s\n' "$hits" | grep -vxF "$exempt" || true)"
  if [ -z "$hits" ]; then
    ok "no '$2' in the portable layer"
  else
    bad "'$2' appears in ${hits//$'\n'/, } — use $3 instead"
  fi
}
ban_check 'AskUserQuestion'          'AskUserQuestion (Claude-only tool)' '"ask as a structured question" (conventions/question-mechanics.md)' "$MECHANICS"
ban_check '`Write` tool|the `Write`' 'the Write tool by name'            '"write the file"'
ban_check '!`[^`]+`'                 'Claude shell-injection dialect'    'an instruction to run the command'
ban_check 'plugin root'              '"plugin root" path discovery'      'paths relative to the skill (../../)' "$MECHANICS"
ban_check '\$ARGUMENTS'              '$ARGUMENTS placeholder'            '"any focus supplied in the request"'
# The regression that would undo the sunset is a template coming back, not a
# skill *mentioning* Gemini — the setup wire-up has to name it to clean it up.
ban_check 'GEMINI\.template'         'a Gemini CLI template reference'   'Antigravity, which reads AGENTS.md natively'
# The orchestrator flow was removed — AGENTS.md is a router the setup flow
# wires up, not a synthesis. A reference creeping back into the shipped surface
# points at a flow that no longer exists.
if grep -rliE 'orchestrat' skills commands templates conventions questionnaires guardrails --include='*.md' --include='*.mdc' 2>/dev/null | grep -qv '^commands/cursor/'; then
  bad "an 'orchestrat…' reference survives in the shipped surface (the flow was removed): $(grep -rliE 'orchestrat' skills commands templates conventions questionnaires guardrails --include='*.md' --include='*.mdc' 2>/dev/null | grep -v '^commands/cursor/' | tr '\n' ' ')"
else
  ok "no orchestrator references in the shipped surface"
fi
# The three brief commands were folded into `setup`'s scope option. Their
# invocation strings must not come back anywhere a user reads them — a doc that
# still advertises /starter:design-brief sends people to a command that no
# longer exists in any tool. (commands/cursor/ is generated and swept by
# render-ports.sh; CHANGELOG.md and the root *-PLAN.md docs are history, and
# name the retired commands on purpose.)
DEAD_BRIEF_CMDS='/starter:(product|design|code)-brief|starter-(product|design|code)-brief'
dead_hits="$(grep -rlE "$DEAD_BRIEF_CMDS" skills commands templates conventions questionnaires guardrails examples README.md INSTALL.md --include='*.md' --include='*.mdc' --include='*.json' 2>/dev/null | grep -v '^commands/cursor/' || true)"
if [ -n "$dead_hits" ]; then
  bad "a retired brief command survives in the shipped surface (folded into 'setup <scope>'): ${dead_hits//$'\n'/, }"
else
  ok "no retired brief-command invocations in the shipped surface"
fi
# The scope fast path is what makes `setup product` work at all, and $ARGUMENTS
# in the body is also what makes render-ports.sh emit the Cursor "type your
# input after the command" note. Losing it degrades setup to question-only in
# both tools, silently.
if grep -qF '$ARGUMENTS' commands/setup.md; then
  ok "commands/setup.md passes \$ARGUMENTS through (scope fast path + Cursor args note)"
else
  bad "commands/setup.md no longer contains \$ARGUMENTS — the 'setup product|design|code|all' fast path is unreachable"
fi

# 10c-yaml. Frontmatter must be VALID YAML, not merely YAML-ish. A plain
#      (unquoted) scalar cannot contain ": " — that is the key/value separator,
#      and a parser is entitled to reject the whole document.
#
#      This is not theoretical. `skills/setup/SKILL.md` shipped a description
#      reading "Scoped at the start: everything (…)". Claude Code, Codex, and
#      Cursor all tolerated it; Antigravity rejected the file and dropped the
#      skill — SILENTLY, with no error and no entry in the skill list. The
#      pack's front-door flow was simply absent in one tool of four, and nothing
#      here noticed, because every other check reads the file as text.
#
#      Quote the value or reword it. Do not "fix" this check by allowing the
#      pattern: the strictest parser in the set decides what is portable.
yaml_bad=""
for f in skills/*/SKILL.md commands/*.md; do
  [ -e "$f" ] || continue
  # Frontmatter only: everything between the first '---' and the next one.
  hits="$(awk 'NR==1 && $0!="---"{exit} NR==1{next} /^---$/{exit} {print}' "$f" \
          | grep -nE '^[A-Za-z_-]+:[[:space:]]+[^"'"'"'>|[{[:space:]].*:[[:space:]]' || true)"
  [ -n "$hits" ] && yaml_bad="$yaml_bad $f"
done
if [ -n "$yaml_bad" ]; then
  bad "unquoted frontmatter value contains ': ' (invalid YAML; Antigravity drops the file silently):$yaml_bad"
else
  ok "every skill/command frontmatter value is valid unquoted YAML (no bare ': ')"
fi

# 10d. Skills address shared resources relative to their own SKILL.md, so a skill
#      dir symlinked alone into ~/.codex/skills still resolves them.
for d in skills/*/; do
  sname="$(basename "$d")"
  if strip_fences "${d}SKILL.md" | grep -qE '(^|[^./])`(questionnaires|templates|guardrails|conventions|scripts|fixtures)/'; then
    bad "skills/$sname references a resource without ../../ — breaks when the skill dir is installed alone"
  else
    ok "skills/$sname resolves resources relative to itself"
  fi
done

# 10e. /starter: is Claude's invocation syntax. It may appear only where a
#      Claude surface is being described. The setup skill is allowed because it
#      authors the cross-tool "Maintaining these files" note in AGENTS.md — it
#      names every tool's syntax, not just Claude's.
#      The repo's own AGENTS.md + CLAUDE.md are allowed too: they are this
#      project's instructions, not pack output, and they document the very rule
#      that confines the syntax.
STARTER_ALLOWED=" README.md INSTALL.md CHANGELOG.md AGENTS.md CLAUDE.md templates/CLAUDE.template.md skills/setup/SKILL.md examples/saga-reader/CLAUDE.md examples/saga-reader/AGENTS.md "
while IFS= read -r f; do
  rel="${f#./}"
  case "$rel" in commands/*) continue ;; esac
  # Root-level *-PLAN.md files are working design docs, not shipped surface.
  case "$rel" in *-PLAN.md) [ "$rel" = "$(basename "$rel")" ] && continue ;; esac
  case "$STARTER_ALLOWED" in *" $rel "*) continue ;; esac
  bad "$rel uses /starter: syntax but is not a Claude-surface file"
done < <(grep -rl '/starter:' --include='*.md' --include='*.mdc' --include='*.json' . 2>/dev/null | grep -v '^./commands/cursor/')
ok "/starter: syntax confined to Claude-surface files"

# 10f. The port renderer produces one port per canonical command and is
#      idempotent — install.sh re-renders on every run, so a non-deterministic
#      renderer would churn the user's ~/.cursor/commands forever.
if [ -x ./render-ports.sh ]; then
  if ./render-ports.sh >/dev/null 2>&1; then
    before="$(cat commands/cursor/*.md 2>/dev/null | cksum)"
    ./render-ports.sh >/dev/null 2>&1
    after="$(cat commands/cursor/*.md 2>/dev/null | cksum)"
    [ "$before" = "$after" ] && ok "render-ports.sh is idempotent" \
                             || bad "render-ports.sh output changed on a second run"
    n_cmds="$(find commands -maxdepth 1 -name '*.md' ! -name README.md | wc -l | tr -d ' ')"
    n_ports="$(find commands/cursor -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
    [ "$n_cmds" = "$n_ports" ] && ok "render-ports.sh: $n_ports port(s) for $n_cmds command(s)" \
                               || bad "render-ports.sh: $n_ports port(s) for $n_cmds command(s) — mismatch"
    if grep -rq '!`' commands/cursor/ 2>/dev/null; then
      bad "a Cursor port still carries Claude shell-injection syntax"
    else
      ok "Cursor ports carry no Claude-only dialect"
    fi
  else
    bad "render-ports.sh failed to run"
  fi
else
  bad "render-ports.sh is missing or not executable"
fi

# 10g. install.sh must exist, parse, and know every tool.
if [ -x ./install.sh ]; then
  ok "install.sh is executable"
  for t in claude codex cursor antigravity; do
    grep -qE "^ *$t\)" install.sh && ok "install.sh handles target: $t" \
                                  || bad "install.sh has no branch for target: $t"
  done
else
  bad "install.sh is missing or not executable"
fi

# 10g-bis. Claude's command install, checked BEHAVIORALLY against a throwaway
#      HOME. install.sh is a blast-radius file: a wrong edit here fails open —
#      it reports "linked N command(s)" while linking the wrong paths, or churns
#      a real user's ~/.claude on every run. Asserting on the filesystem is the
#      only way to catch that; grepping the script would just re-state it.
#
#      The invocation must come out as /starter:<verb>, matching the plugin
#      path exactly. Claude Code derives a command's name from its path, so the
#      namespace is a DIRECTORY (commands/starter/setup.md -> /starter:setup),
#      which is why this asserts on the nesting and not just on presence.
if [ -x ./install.sh ]; then
  TH="$(mktemp -d)"
  mkdir -p "$TH/.claude"
  if HOME="$TH" ./install.sh --yes claude >"$TH/out.log" 2>&1; then
    nsdir="$TH/.claude/commands/starter"
    missing=""; foreign=""
    for c in commands/*.md; do
      [ -e "$c" ] || continue
      b="$(basename "$c")"; [ "$b" = README.md ] && continue
      link="$nsdir/$b"
      if [ ! -L "$link" ]; then
        missing="$missing $b"
      else
        # Must resolve back into THIS checkout — a copy would go stale on pull,
        # and a link to the generated Cursor port would install the wrong dialect.
        tgt="$(readlink -f "$link" 2>/dev/null)"
        [ "$tgt" = "$ROOT/$c" ] || foreign="$foreign $b->$tgt"
      fi
    done
    [ -z "$missing" ] && ok "install.sh links every command into ~/.claude/commands/starter/" \
                      || bad "install.sh (claude) never linked:$missing"
    [ -z "$foreign" ] && ok "installed Claude commands resolve to the canonical commands/*.md" \
                      || bad "installed Claude command points somewhere unexpected:$foreign"

    # Idempotence: a second run must not churn what the first produced. This is
    # the check that keeps `git pull && ./install.sh` from rewriting a user's
    # config dir every time.
    before="$(find "$TH/.claude" | sort | cksum)"
    HOME="$TH" ./install.sh --yes claude >/dev/null 2>&1
    after="$(find "$TH/.claude" | sort | cksum)"
    [ "$before" = "$after" ] && ok "install.sh (claude) is idempotent" \
                             || bad "install.sh (claude) changed ~/.claude on a second run"

    # Uninstall must remove exactly ours and nothing else. (mkdir -p so this
    # stands on its own: if the links above never landed, the foreign-file
    # check should still report on its own terms, not cascade.)
    mkdir -p "$nsdir"
    printf 'mine\n' > "$nsdir/not-ours.md"
    HOME="$TH" ./install.sh --uninstall claude >/dev/null 2>&1
    left="$(find "$nsdir" -name '*.md' 2>/dev/null | grep -v 'not-ours.md' || true)"
    [ -z "$left" ] && ok "install.sh --uninstall removes the Claude commands" \
                   || bad "install.sh --uninstall left Claude commands behind: ${left//$'\n'/, }"
    [ -f "$nsdir/not-ours.md" ] && ok "uninstall leaves a user's own file in the namespace dir" \
                                || bad "install.sh --uninstall deleted a file it did not install"
  else
    bad "install.sh --yes claude failed against a temp HOME: $(tail -3 "$TH/out.log" 2>/dev/null | tr '\n' ' ')"
  fi
  rm -rf "$TH"
else
  bad "install.sh is missing or not executable (skipped the Claude command install checks)"
fi

# 10g-skills. Every target must actually receive the skills, checked against a
#      throwaway HOME. "Skills are the engine" is the pack's central claim, and
#      a target that silently installs nothing breaks it while every string-level
#      check still passes — which is exactly how Antigravity spent releases
#      documented as having "no skill surface" when it has a full one.
#
#      Each entry is: target | marker dir that means "this tool is installed" |
#      skills dir it must populate, both relative to HOME.
if [ -x ./install.sh ]; then
  while IFS='|' read -r tgt marker sdir; do
    [ -n "$tgt" ] || continue
    TH="$(mktemp -d)"
    mkdir -p "$TH/$marker"
    if HOME="$TH" ./install.sh --yes "$tgt" >"$TH/out.log" 2>&1; then
      missing=""
      for d in skills/*/; do
        s="$(basename "$d")"
        link="$TH/$sdir/$s"
        if [ ! -L "$link" ] || [ "$(readlink -f "$link" 2>/dev/null)" != "$ROOT/skills/$s" ]; then
          missing="$missing $s"
        fi
      done
      [ -z "$missing" ] && ok "install.sh ($tgt) links every skill into ~/$sdir" \
                        || bad "install.sh ($tgt) never linked:$missing"
    else
      bad "install.sh --yes $tgt failed against a temp HOME: $(tail -3 "$TH/out.log" 2>/dev/null | tr '\n' ' ')"
    fi
    rm -rf "$TH"
  done <<'TARGETS'
claude|.claude|.claude/skills
codex|.codex|.codex/skills
cursor|.cursor|.cursor/skills
antigravity|.gemini/antigravity-cli|.gemini/config/skills
TARGETS
fi

# 10g-ter. The namespace install.sh uses and the syntax the CLAUDE template
#      advertises are one string in two files. If they drift, every generated
#      project tells the user to type a command that does not resolve.
NS_IN_INSTALL="$(grep -oE '^NS="[a-z-]+"' install.sh | head -1 | sed 's/^NS="//; s/"$//')"
if [ -z "$NS_IN_INSTALL" ]; then
  bad "install.sh declares no NS= command namespace"
elif grep -qF "/${NS_IN_INSTALL}:setup" templates/CLAUDE.template.md; then
  ok "install.sh namespace '$NS_IN_INSTALL' matches the /${NS_IN_INSTALL}: syntax the CLAUDE template advertises"
else
  bad "install.sh installs commands as /${NS_IN_INSTALL}:<verb> but CLAUDE.template.md advertises something else"
fi

# 10g-quater. Two plugin manifests, one identity. Claude reads
#      .claude-plugin/plugin.json; Antigravity reads plugin.json at the root of
#      the plugin dir (which is this repo root, since its skills/ layout already
#      matches what Antigravity expects). Only the name has to agree — the
#      Antigravity manifest is deliberately name-only, because every other field
#      it could carry is a second copy of something Claude's manifest already
#      states, and Antigravity reads none of them.
if [ -f plugin.json ] && [ -f .claude-plugin/plugin.json ]; then
  ag_name="$(jq -r '.name // empty' plugin.json 2>/dev/null)"
  cc_name="$(jq -r '.name // empty' .claude-plugin/plugin.json 2>/dev/null)"
  if [ -z "$ag_name" ]; then
    bad "plugin.json has no name (Antigravity would fall back to the directory name)"
  elif [ "$ag_name" = "$cc_name" ]; then
    ok "plugin manifests agree on the name '$ag_name'"
  else
    bad "plugin name drift: plugin.json says '$ag_name', .claude-plugin/plugin.json says '$cc_name'"
  fi
  # Keep it name-only. Anything else is duplicated metadata that Antigravity
  # does not read and nothing keeps in sync.
  extra="$(jq -r 'keys - ["name","disabled"] | join(", ")' plugin.json 2>/dev/null)"
  [ -z "$extra" ] && ok "plugin.json carries no duplicated metadata" \
                  || bad "plugin.json carries fields Antigravity does not read and nothing syncs: $extra"
else
  bad "a plugin manifest is missing (need both plugin.json and .claude-plugin/plugin.json)"
fi

# 10h. The Gemini sunset is real: no template, no example render, no live target.
if [ -e templates/GEMINI.template.md ] || [ -e examples/saga-reader/GEMINI.md ]; then
  bad "a GEMINI file is still shipped — the Gemini CLI target was retired"
else
  ok "no GEMINI template or example render (retired tool)"
fi

# ---------------------------------------------------------------------------
section "11. Token contrast validator (measured, not estimated)"
# skills/validate Mode A used to hand a language model an OKLCH-to-luminance
# arithmetic problem. scripts/validate-tokens.sh does it instead, so these
# checks assert the two things that matter: it PASSES the shipped fixture with
# the right numbers, and it FAILS loudly when it should. A validator only ever
# proven to pass is the failure mode being defended against here.
VT=scripts/validate-tokens.sh
if [ -f "$VT" ]; then
  [ -x "$VT" ] && ok "$VT is executable" || bad "$VT is not executable"
  bash -n "$VT" 2>/dev/null && ok "$VT parses" || bad "$VT has a syntax error"

  # The skill must run it rather than doing the arithmetic itself.
  if grep -qF 'scripts/validate-tokens.sh' skills/validate/SKILL.md; then
    ok "skills/validate runs the contrast validator"
  else
    bad "skills/validate no longer runs $VT — Mode A is back to estimating contrast"
  fi

  if command -v jq >/dev/null 2>&1; then
    EX=examples/saga-reader/DESIGN.json
    vt_tmp="$(mktemp -d "${TMPDIR:-/tmp}/psp-vt.XXXXXX")"

    # 1. The fixture passes, and checks BOTH theme blocks (10 pairs, not 5).
    if out="$("$ROOT/$VT" "$ROOT/$EX" 2>&1)"; then
      ok "validator passes on $EX"
      pairs="$(printf '%s' "$out" | grep -c '^PASS')"
      [ "$pairs" -eq 10 ] && ok "validator checked all 10 pairs (5 per theme block)" \
                          || bad "validator checked $pairs pairs on $EX, expected 10"
    else
      bad "validator FAILS on the shipped fixture $EX — exit $?"
    fi

    # 2. A pair pushed below its floor exits 1 and names the pair AND its ratio.
    jq '.color.borderStrong["$value"] = "oklch(0.78 0.010 75)"' "$ROOT/$EX" > "$vt_tmp/bad.json"
    if out="$("$ROOT/$VT" "$vt_tmp/bad.json" 2>&1)"; then
      bad "validator passed a borderStrong pair below the 3:1 floor"
    else
      code=$?
      [ "$code" -eq 1 ] && ok "seeded contrast failure exits 1" \
                        || bad "seeded contrast failure exited $code, expected 1"
      printf '%s' "$out" | grep -q 'FAIL.*borderStrong/background' \
        && ok "seeded failure names the failing pair" \
        || bad "seeded failure does not name borderStrong/background"
      printf '%s' "$out" | grep -qE 'borderStrong/background[[:space:]]+[0-9]+\.[0-9]+' \
        && ok "seeded failure reports the measured ratio" \
        || bad "seeded failure reports no ratio — a finding without evidence"
    fi

    # 3. A non-OKLCH value must ERROR, never be silently skipped. The
    #    questionnaire's "use OKLCH" is model-enforced, so a hex CAN reach here.
    jq '.themes.dark.color.muted["$value"] = "#8a8a8a"' "$ROOT/$EX" > "$vt_tmp/hex.json"
    out="$("$ROOT/$VT" "$vt_tmp/hex.json" 2>&1)"; code=$?
    [ "$code" -eq 2 ] && ok "unparseable token value exits 2" \
                      || bad "hex token value exited $code, expected 2"
    printf '%s' "$out" | grep -q 'ERROR.*dark' \
      && ok "unparseable token is reported, not skipped" \
      || bad "hex token value was skipped silently — 'all pass' would be a lie"

    # 4. A missing token is an error too, for the same reason.
    jq 'del(.color.accentForeground)' "$ROOT/$EX" > "$vt_tmp/miss.json"
    "$ROOT/$VT" "$vt_tmp/miss.json" >/dev/null 2>&1; code=$?
    [ "$code" -eq 2 ] && ok "missing token exits 2" \
                      || bad "missing token exited $code, expected 2"

    # 5. Single-theme systems delete `themes` entirely (per the design-brief
    #    skill), so the validator must handle five pairs, not crash.
    jq 'del(.themes)' "$ROOT/$EX" > "$vt_tmp/single.json"
    if out="$("$ROOT/$VT" "$vt_tmp/single.json" 2>&1)"; then
      [ "$(printf '%s' "$out" | grep -c '^PASS')" -eq 5 ] \
        && ok "single-theme file checks 5 pairs" \
        || bad "single-theme file did not check exactly 5 pairs"
    else
      bad "validator fails on a single-theme DESIGN.json"
    fi

    rm -rf "$vt_tmp"
  else
    echo "  (jq absent: validator behaviour checks skipped)"
  fi
else
  bad "scripts/validate-tokens.sh is missing — Mode A has no way to measure contrast"
fi

# ---------------------------------------------------------------------------
section "12. Guardrail registry (prose is the source, detectors are generated)"
# The point of the registry is that adding a ban to the prose arms its detector
# in the same edit. These checks assert that property directly, plus every way
# build-guardrails.sh is supposed to refuse to emit a registry. A generator
# that only ever succeeds is how a stale artifact ships.
BG=./build-guardrails.sh
if [ -f "$BG" ] && command -v jq >/dev/null 2>&1; then
  [ -x "$BG" ] && ok "$BG is executable" || bad "$BG is not executable"
  bash -n "$BG" 2>/dev/null && ok "$BG parses" || bad "$BG has a syntax error"
  [ -f guardrails/_format.md ] && ok "guardrails/_format.md states the contract" \
                               || bad "guardrails/_format.md is missing"

  # Every prose registry has a sidecar, and every ban in one appears in the other.
  # (The generator enforces this; this asserts the FILES exist so a missing
  # sidecar is caught as a missing file rather than an empty parse.)
  for g in guardrails/*-anti-patterns.md; do
    sc="${g%.md}.detect.md"
    [ -f "$sc" ] && ok "$(basename "$g") has its detector sidecar" \
                 || bad "$(basename "$g") has no $(basename "$sc")"
  done

  # IDs are the join key and are immutable: every ban must carry one.
  missing=0
  for g in guardrails/*-anti-patterns.md; do
    while IFS= read -r ln; do
      case "$ln" in
        '- **'*)  printf '%s' "$ln" | grep -qE '^- \*\*\([A-Z]+-[0-9]+\)' || { bad "un-IDed ban in $(basename "$g"): ${ln:0:60}"; missing=1; } ;;
        '## '*)   case "$ln" in
                    '## '[A-Z]*-[0-9]*' — '*) ;;
                    *) printf '%s' "$ln" | grep -qE '^## [0-9]+\.' && { bad "un-IDed ban in $(basename "$g"): $ln"; missing=1; } ;;
                  esac ;;
      esac
    done < "$g"
  done
  [ "$missing" -eq 0 ] && ok "every ban in every registry carries an ID"

  # Every probe below runs against a COPY of guardrails/, via
  # PSP_GUARDRAILS_DIR. The live tree is never mutated, so an interrupted run
  # cannot leave a half-applied probe behind in a tracked file.
  gr_tmp="$(mktemp -d "${TMPDIR:-/tmp}/psp-gr.XXXXXX")"
  cp -r guardrails "$gr_tmp/work"
  GW="$gr_tmp/work"

  # --- the property the whole design exists for -----------------------------
  # A new ban with a detect: field must be enforced by the hook with NO other
  # edit: no hook change, no test.sh change. Add one, rebuild, and prove the
  # hook warns on a file that trips it.
  printf '%s\n' '- **(WRT-99) No test-only sentinel ban.** Added by test.sh, never committed.' \
    >> "$GW/writing-anti-patterns.md"
  printf '%s\n' '| WRT-99 | certain | prose | regexi:`zzsentinelzz` | remove the sentinel |' \
    >> "$GW/writing-anti-patterns.detect.md"
  if PSP_GUARDRAILS_DIR="$GW" "$BG" >/dev/null 2>&1; then
    ok "a new ban + sidecar row regenerates the registry"
    # Swap the live registry for the probe one just long enough to prove the
    # hook picks up a ban nobody taught it about, then put the real one back.
    cp guardrails/registry.json "$gr_tmp/registry.live"
    cp "$GW/registry.json" guardrails/registry.json
    printf 'this line contains ZZSENTINELZZ and nothing else.\n' > "$gr_tmp/probe.md"
    out="$(printf '{"tool_input":{"file_path":"%s"}}' "$gr_tmp/probe.md" \
           | HOOK_PLATFORM=claude "$ROOT/hooks/check-writing-slop.sh" 2>&1)"
    cp "$gr_tmp/registry.live" guardrails/registry.json
    printf '%s' "$out" | grep -q 'WRT-99' \
      && ok "the new ban is enforced by the hook with no other edit" \
      || bad "a new ban with a detect: field did NOT reach the hook — the registry is not wired"
  else
    bad "adding a well-formed ban broke the generator"
  fi
  # Reset the working copy for the rejection probes below.
  rm -rf "$GW"; cp -r guardrails "$GW"

  # A backslash in a pattern must survive the registry -> hook handoff. jq's
  # @tsv escapes it, which silently disables the detector; this is that guard.
  printf 'we delve into it.\n' > "$gr_tmp/bs.md"
  out="$(printf '{"tool_input":{"file_path":"%s"}}' "$gr_tmp/bs.md" \
         | HOOK_PLATFORM=claude "$ROOT/hooks/check-writing-slop.sh" 2>&1)"
  printf '%s' "$out" | grep -q 'WRT-01' \
    && ok "a pattern containing \\b survives the registry handoff" \
    || bad "a \\b-bearing pattern did not fire — the registry handoff is escaping backslashes"

  # A clean file must stay silent. The words WRT-01 deliberately excludes are
  # the test: 'robust'/'leverage' are honest in tech docs (a scoped call).
  printf 'A robust system that leverages seamless caching. We utilize it.\n' > "$gr_tmp/clean.md"
  out="$(printf '{"tool_input":{"file_path":"%s"}}' "$gr_tmp/clean.md" \
         | HOOK_PLATFORM=claude "$ROOT/hooks/check-writing-slop.sh" 2>&1)"
  [ -z "$out" ] && ok "hook stays silent on a clean file (no false positives)" \
                || bad "hook fired on a clean file: $out"

  # --- the generator must refuse, loudly, on each malformed input ------------
  probe_reject() {  # $1 = label, $2 = sed expr, $3 = basename under $GW
    cp "$GW/$3" "$gr_tmp/one.bak"; sed -i "$2" "$GW/$3"
    if PSP_GUARDRAILS_DIR="$GW" "$BG" >/dev/null 2>&1; then
      bad "generator accepted: $1"
    else
      ok "generator rejects: $1"
    fi
    cp "$gr_tmp/one.bak" "$GW/$3"
  }
  probe_reject "a duplicate ID"            's/^## UX-05 —/## UX-04 —/'                      ux-anti-patterns.md
  probe_reject "a ban with no sidecar row" '/^| CODE-07 |/d'                                 code-anti-patterns.detect.md
  probe_reject "a sidecar row with no ban" '/^## PRD-08 —/d'                                 product-anti-patterns.md
  probe_reject "an invalid confidence"     's/^| WRT-02 | scoped |/| WRT-02 | maybe |/'      writing-anti-patterns.detect.md
  probe_reject "an invalid scope"          's/^| WRT-02 | scoped | prose |/| WRT-02 | scoped | pixels |/' writing-anti-patterns.detect.md
  probe_reject "an unknown detect kind"    's/| DES-14 | — | — | manual |/| DES-14 | — | — | vibes |/'     design-anti-patterns.detect.md
  probe_reject "a live detector with no fix" 's/| use deliberately or not at all  |/| —  |/'              design-anti-patterns.detect.md
  probe_reject "a manual ban with a confidence" 's/| DES-14 | — | — |/| DES-14 | certain | — |/'          design-anti-patterns.detect.md
  probe_reject "an invalid regex"          's/backdrop-filter\[\[:space:\]\]\*:\[\[:space:\]\]\*blur/backdrop-filter(unclosed/' design-anti-patterns.detect.md
  probe_reject "a non-numeric count"       's/count:5:/count:many:/'                         writing-anti-patterns.detect.md

  "$BG" --check >/dev/null 2>&1 \
    && ok "the live guardrails were never touched by the probes above" \
    || bad "a probe leaked into the live guardrails — registry.json no longer matches the sources"
  rm -rf "$gr_tmp"

  # --- the fixture cites real bans, and drops none --------------------------
  # This is the check that was missing. examples/saga-reader/DESIGN.md shipped
  # a ban on pure white that design-anti-patterns.md explicitly permits, and
  # the suite stayed green because nothing bound a rendered ban to its source.
  # IDs are that binding.
  example_ids() {
    grep -rohE '(PRD|UX|DES|WRT|CODE)-[0-9]+(–[0-9]+)?' examples/ 2>/dev/null | while read -r tok; do
      case "$tok" in
        *–*) pfx="${tok%%-*}"; rng="${tok#*-}"
             lo="${rng%%–*}"; hi="${rng##*–}"
             n="$((10#$lo))"
             while [ "$n" -le "$((10#$hi))" ]; do printf '%s-%02d\n' "$pfx" "$n"; n=$((n + 1)); done ;;
        *)   printf '%s\n' "$tok" ;;
      esac
    done | sort -u
  }
  cited="$(example_ids)"
  known="$(jq -r 'keys[]' guardrails/registry.json | sort -u)"

  unknown="$(comm -23 <(printf '%s\n' "$cited") <(printf '%s\n' "$known") | tr '\n' ' ')"
  [ -z "$(printf '%s' "$unknown" | tr -d '[:space:]')" ] \
    && ok "every guardrail ID cited in examples/ is a real ban" \
    || bad "examples/ cite ID(s) that are not in the registry: $unknown"

  # Completeness, for the registries the briefs render as a full list. UX is
  # excluded on purpose: the design-brief weaves ux-anti-patterns into DESIGN.md
  # prose rather than rendering the list (same reason test.sh section 4 exempts
  # it from the slot check), so only a subset is ever cited.
  for pfx in PRD CODE DES WRT; do
    want="$(printf '%s\n' "$known" | grep -E "^$pfx-" | sort -u)"
    got="$(printf '%s\n' "$cited"  | grep -E "^$pfx-" | sort -u)"
    dropped="$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | tr '\n' ' ')"
    if [ -z "$(printf '%s' "$dropped" | tr -d '[:space:]')" ]; then
      ok "the example renders every $pfx ban ($(printf '%s\n' "$want" | grep -c . ) of them)"
    else
      bad "the example render dropped $pfx ban(s): $dropped"
    fi
  done
else
  bad "build-guardrails.sh is missing (or jq is absent) — the registry cannot be generated"
fi

# ---------------------------------------------------------------------------
section "13. Guardrail fixtures (false positives, not only misses)"
# A grep-based linter dies of false positives. Every live detector ships a file
# that must trip it and a file that must not, and check-guardrail-fixtures.sh
# enforces both directions. The mutations below prove the checker actually
# bites: broadening a regex until it swallows a clean fixture, and narrowing it
# until it stops finding its own trips fixture, must BOTH fail.
CGF=./check-guardrail-fixtures.sh
if [ -f "$CGF" ] && command -v jq >/dev/null 2>&1; then
  [ -x "$CGF" ] && ok "$CGF is executable" || bad "$CGF is not executable"
  bash -n "$CGF" 2>/dev/null && ok "$CGF parses" || bad "$CGF has a syntax error"

  if "$CGF" >/dev/null 2>&1; then
    ok "every live detector passes its own fixtures"
  else
    bad "check-guardrail-fixtures.sh fails on the shipped fixtures"
    "$CGF" 2>&1 | sed 's/^/      /' >&2
  fi

  # Every live detector must have both halves, with the extension its scope
  # implies. Missing either is a failure, not a skip.
  missing_fx=0
  while IFS='|' read -r id scope; do
    [ -n "$id" ] || continue
    case "$scope" in style|tokens) fx=css ;; prose) fx=md ;; code) fx=ts ;; *) fx=txt ;; esac
    for half in trips clean; do
      [ -f "fixtures/guardrails/$id/$half.$fx" ] \
        || { bad "$id has no fixtures/guardrails/$id/$half.$fx"; missing_fx=1; }
    done
  done < <(jq -r '
    to_entries
    | map(select(.value.kind == "regex" or .value.kind == "regexi" or .value.kind == "count"))
    | sort_by(.key)[] | "\(.key)|\(.value.scope // "")"' guardrails/registry.json)
  [ "$missing_fx" -eq 0 ] && ok "every live detector ships both a trips and a clean fixture"

  fx_tmp="$(mktemp -d "${TMPDIR:-/tmp}/psp-fx.XXXXXX")"

  # A detector missing its fixtures entirely must be reported, not skipped.
  cp -r fixtures/guardrails "$fx_tmp/fx"
  rm -rf "$fx_tmp/fx/DES-18"
  if PSP_FIXTURES="$fx_tmp/fx" "$CGF" >/dev/null 2>&1; then
    bad "checker passed a live detector with no fixtures at all"
  else
    ok "checker rejects: a live detector with no fixtures"
  fi
  rm -rf "$fx_tmp/fx"

  # Broaden a regex until it swallows a clean fixture. DES-18's clean file
  # holds `filter: blur(2px)`, which is blur but not glassmorphism.
  jq '.["DES-18"].pattern = "blur"' guardrails/registry.json > "$fx_tmp/broad.json"
  if PSP_REGISTRY="$fx_tmp/broad.json" "$CGF" >/dev/null 2>&1; then
    bad "checker passed a regex broadened until it hits a clean fixture"
  else
    ok "checker rejects: a regex broadened onto a clean fixture (false positive)"
  fi

  # Narrow a regex until it no longer finds its own trips fixture.
  jq '.["DES-18"].pattern = "backdrop-filter[[:space:]]*:[[:space:]]*saturate"' \
    guardrails/registry.json > "$fx_tmp/narrow.json"
  if PSP_REGISTRY="$fx_tmp/narrow.json" "$CGF" >/dev/null 2>&1; then
    bad "checker passed a regex that no longer finds its own trips fixture"
  else
    ok "checker rejects: a regex narrowed off its own trips fixture (missed ban)"
  fi

  # A threshold raised above its trips fixture is the same failure for a count.
  jq '.["WRT-23"].threshold = 99' guardrails/registry.json > "$fx_tmp/thr.json"
  if PSP_REGISTRY="$fx_tmp/thr.json" "$CGF" >/dev/null 2>&1; then
    bad "checker passed a count threshold raised past its own trips fixture"
  else
    ok "checker rejects: a count threshold raised past its trips fixture"
  fi

  rm -rf "$fx_tmp"
  "$CGF" >/dev/null 2>&1 && ok "fixtures unchanged by the mutations above" \
                         || bad "the mutations above leaked into the real fixtures"
else
  bad "check-guardrail-fixtures.sh is missing (or jq is absent) — detectors have no false-positive net"
fi

# ---------------------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
