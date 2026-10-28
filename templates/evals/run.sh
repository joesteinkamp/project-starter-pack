#!/usr/bin/env bash
#
# evals/run.sh — this project's evals. Written by project-starter-pack's setup
# flow; edit cases.md, not this file (re-running `setup evals` refreshes it).
#
#   ./evals/run.sh                       static: free, deterministic, CI-safe
#   ./evals/run.sh --verbose             static, also listing what passed
#   ./evals/run.sh --confirm EV-07       mark a case confirmed (goldens must separate)
#   ./evals/run.sh --live [EV-07 …]      run an agent on each case and grade it
#       --include-unconfirmed            also run draft cases (never gate)
#
# What each mode proves.
#   static  every case is well-formed; each rule's anchor still appears in the
#           brief that owns it; each inline `check:` trips on the case's fail
#           golden and stays quiet on its pass golden. Nothing here runs a model,
#           so a pass means the rules are still *written down and checkable* —
#           not that an agent follows them.
#   live    the far half: an agent works each case's prompt in a scratch
#           worktree, and its reply + diff is graded by the `check:` first, then
#           by a judge from a different model family — but only after that judge
#           has told the case's own pass golden from its fail golden.
#
# Only `status: confirmed` cases gate the exit code. Drafts print WARN.
#
# Exit 0 pass · 1 a confirmed case failed · 2 setup problem (bad args, no CLIs)
#      3 live run inconclusive (the judge could not be calibrated on a case)
#
# Dependencies: bash 3.2+, grep, sed, awk; jq only for agy's JSON output.
# Last line printed is always one machine-checkable summary:
#   EVALS mode=… … verdict=pass|fail|inconclusive

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CASES="${EVALS_CASES:-$HERE/cases.md}"
CONFIG="$HERE/config"
AI_DIR="${EVALS_AI_DIR:-$HOME/.ai}"

MODE=static VERBOSE=0 INCLUDE_UNCONFIRMED=0 CONFIRM_ID="" WANT_IDS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --verbose) VERBOSE=1 ;;
    --live) MODE=live ;;
    --include-unconfirmed) INCLUDE_UNCONFIRMED=1 ;;
    --confirm) MODE=confirm; CONFIRM_ID="${2:-}"; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    EV-*) WANT_IDS="$WANT_IDS $1 " ;;
    *) echo "run.sh: unknown argument: $1 (see --help)" >&2; exit 2 ;;
  esac
  shift
done
[ -f "$CASES" ] || { echo "run.sh: no cases file at $CASES" >&2; exit 2; }

# --- case parsing ------------------------------------------------------------
# cases.md is the source and is read directly: one `## EV-NN — headline` per
# case, then `key: value` lines. Streaming keeps this bash-3.2 safe (macOS).

reset_case() { id="" title="" source="" file="" anchor="" kind="" status="" origin="" prompt="" check="" judge=""; }

for_each_case() {  # $1 = function called once per parsed case
  local line cb="$1"
  reset_case
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
      '## EV-'*)
        [ -n "$id" ] && "$cb"
        reset_case
        id="${line#\#\# }"; id="${id%% *}"
        title="${line#*— }" ;;
      'source: '*) source="${line#source: }" ;;
      'file: '*) file="${line#file: }" ;;
      'anchor: '*) anchor="${line#anchor: }" ;;
      'kind: '*) kind="${line#kind: }" ;;
      'status: '*) status="${line#status: }" ;;
      'origin: '*) origin="${line#origin: }" ;;
      'prompt: '*) prompt="${line#prompt: }" ;;
      'check: '*) check="${line#check: }" ;;
      'judge: '*) judge="${line#judge: }" ;;
    esac
  done < "$CASES"
  [ -n "$id" ] && "$cb"
  return 0
}

golden() {  # $1 = id, $2 = pass|fail → path of the first matching golden, or empty
  local f
  for f in "$HERE/goldens/$1/$2".*; do [ -f "$f" ] && { echo "$f"; return; }; done
}

# `check:` is a detector copied inline from the pack's guardrail registry (the
# registry itself does not ship into projects). regex → grep -E, regexi → -iE.
has_check() { case "$check" in regex:*|regexi:*) return 0 ;; *) return 1 ;; esac; }
fires_on_text() {  # $1 = text; uses $check
  local pat="${check#*:}"
  # Herestring, not a pipe: grep -q exits on the first match, and a SIGPIPE on
  # the writer would read as a failed pipeline under pipefail.
  case "$check" in
    regex:*)  grep -qE  -- "$pat" <<<"$1" ;;
    regexi:*) grep -qiE -- "$pat" <<<"$1" ;;
    *) return 1 ;;
  esac
}
has_judge() { [ -n "$judge" ] && [ "$judge" != none ]; }

# --- static ------------------------------------------------------------------

c_pass=0 c_fail=0 u_pass=0 u_warn=0 seen=" "

static_case() {
  local problems="" pf ff
  case "$seen" in *" $id "*) problems="$problems; duplicate ID" ;; esac
  seen="$seen$id "
  for k in file anchor kind status origin prompt; do
    [ -n "${!k}" ] || problems="$problems; no $k:"
  done
  case "$status" in confirmed|unconfirmed) ;; *) problems="$problems; status must be confirmed or unconfirmed" ;; esac
  case "$kind" in agent|product) ;; *) problems="$problems; kind must be agent or product" ;; esac
  has_check || has_judge || problems="$problems; needs a check: or a judge:"
  if [ -n "$check" ] && [ "$check" != none ] && ! has_check; then
    problems="$problems; check: must start regex: or regexi: (or be none)"
  fi
  if [ -n "$file" ]; then
    if [ ! -f "$ROOT/$file" ]; then
      problems="$problems; file: $file does not exist"
    elif [ -n "$anchor" ] && ! grep -qF -- "$anchor" "$ROOT/$file"; then
      problems="$problems; anchor no longer in $file — the rule was removed or reworded"
    fi
  fi
  pf="$(golden "$id" pass)"; ff="$(golden "$id" fail)"
  if [ -z "$pf" ] || [ -z "$ff" ]; then
    problems="$problems; goldens/$id needs both pass.* and fail.*"
  elif has_check; then
    fires_on_text "$(cat "$ff")" || problems="$problems; check: does not trip on its fail golden"
    fires_on_text "$(cat "$pf")" && problems="$problems; check: trips on its pass golden (false positive)"
  fi

  problems="${problems#; }"
  if [ -z "$problems" ]; then
    if [ "$status" = confirmed ]; then c_pass=$((c_pass+1)); else u_pass=$((u_pass+1)); fi
    [ "$VERBOSE" = 1 ] && printf '  ok    %s %s\n' "$id" "$title"
  elif [ "$status" = confirmed ] || [ "$problems" != "${problems#duplicate ID}" ]; then
    # A duplicate ID always gates: it makes every other message ambiguous.
    c_fail=$((c_fail+1))
    printf '  FAIL  %s — %s\n        %s\n        rule: %s (%s)\n        why it exists: %s\n' "$id" "$title" "$problems" "${source:-unstated}" "$file" "$origin"
  else
    u_warn=$((u_warn+1))
    printf '  WARN  %s (unconfirmed) — %s\n' "$id" "$problems"
  fi
}

run_static() {
  for_each_case static_case
  local v=pass; [ "$c_fail" -gt 0 ] && v=fail
  [ "$((c_pass + c_fail + u_pass + u_warn))" -eq 0 ] && echo "  (no cases yet — add one to evals/cases.md)"
  STATIC_VERDICT=$v
}

# --- confirm -----------------------------------------------------------------

confirm_case() {
  [ "$id" = "$CONFIRM_ID" ] || return 0
  FOUND=1
  local pf ff
  pf="$(golden "$id" pass)"; ff="$(golden "$id" fail)"
  [ -n "$pf" ] && [ -n "$ff" ] || { echo "run.sh: $id needs goldens/$id/pass.* and fail.* before it can be confirmed" >&2; exit 1; }
  if has_check; then
    fires_on_text "$(cat "$ff")" || { echo "run.sh: $id's check: does not trip on its fail golden" >&2; exit 1; }
    ! fires_on_text "$(cat "$pf")" || { echo "run.sh: $id's check: trips on its pass golden" >&2; exit 1; }
  fi
}

run_confirm() {
  [ -n "$CONFIRM_ID" ] || { echo "run.sh: --confirm needs a case ID" >&2; exit 2; }
  FOUND=0
  for_each_case confirm_case
  [ "$FOUND" = 1 ] || { echo "run.sh: no case $CONFIRM_ID in $CASES" >&2; exit 2; }
  local tmp; tmp="$(mktemp)"
  awk -v want="$CONFIRM_ID" '
    /^## EV-/ { split($2, a, " "); cur = a[1] }
    cur == want && /^status: unconfirmed$/ { print "status: confirmed"; next }
    { print }' "$CASES" > "$tmp" && mv "$tmp" "$CASES"
  echo "confirmed $CONFIRM_ID"
  echo "EVALS mode=confirm id=$CONFIRM_ID verdict=pass"
}

# --- live: choosing who runs and who judges ----------------------------------

cfg() {  # $1 = key in evals/config (`key: value` lines)
  [ -f "$CONFIG" ] && sed -n "s/^$1:[[:space:]]*//p" "$CONFIG" | head -n1
}
today() { date +%Y-%m-%d; }
locked() {  # a pool marked locked until a date that has not passed (~/.ai/pools)
  [ -f "$AI_DIR/pools" ] || return 1
  awk -F'|' -v c="$1" -v t="$(today)" '$1==c && $3=="locked" && $4>=t {f=1} END {exit !f}' "$AI_DIR/pools"
}
usable() {
  grep -qxF -- "$1" "$AI_DIR/clis" 2>/dev/null && command -v "$1" >/dev/null 2>&1 && ! locked "$1"
}
family_of() {  # $1 = cli, $2 = model → Anthropic | OpenAI | Google | unknown
  case "$2" in
    *claude*|opus*|sonnet*|haiku*|fable*) echo Anthropic; return ;;
    *gpt*|o[0-9]*) echo OpenAI; return ;;
    *gemini*) echo Google; return ;;
  esac
  case "$1" in claude) echo Anthropic ;; codex) echo OpenAI ;; agy) echo Google ;; *) echo unknown ;; esac
}

# The judge must come from a different model family than the agent under test.
# When the harness's model-routing table exists, take the highest-tier row of
# another family that a usable CLI reaches (pools already filtered by usable);
# otherwise fall back to any usable CLI whose default family differs.
pick_judge_from_routing() {  # $1 = agent family → "cli|model|family" or nothing
  local f="$AI_DIR/model-routing.md" tier row fam cmds cmd cli model BT='`'
  [ -f "$f" ] || return 0
  for tier in T1 T2; do
    while IFS= read -r row; do
      row="${row//\\|//}"
      fam="$(awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}' <<<"$row")"
      [ "$fam" = "$1" ] && continue
      cmds="$(awk -F'|' '{print $6}' <<<"$row")"
      while IFS= read -r cmd; do
        cli="${cmd%% *}"
        usable "$cli" || continue
        model="$(sed -nE 's/.*(--model|-m) ([^ `]+).*/\2/p' <<<"$cmd")"
        model="${model//<low\/medium\/high>/high}"
        case "$model" in *'<'*) model="" ;; esac
        echo "$cli|$model|$fam"; return 0
      done < <(grep -oE "${BT}[^${BT}]+${BT}" <<<"$cmds" | tr -d "$BT")
    done < <(grep -E "^\| [^|]+ \| [A-Za-z]+ \| $tier" "$f")
  done
}

choose_runners() {
  AGENT_CLI="${EVALS_AGENT:-$(cfg agent)}"
  AGENT_MODEL="${EVALS_AGENT_MODEL:-$(cfg agent_model)}"
  if [ -z "$AGENT_CLI" ]; then
    local c
    while IFS= read -r c; do usable "$c" && { AGENT_CLI="$c"; break; }; done < "$AI_DIR/clis"
  fi
  if [ -z "$AGENT_CLI" ] || ! usable "$AGENT_CLI"; then
    echo "run.sh: no usable agent CLI (set agent: in evals/config, or check $AI_DIR/clis and $AI_DIR/pools)" >&2; exit 2
  fi
  AGENT_FAM="$(cfg agent_family)"; [ -n "$AGENT_FAM" ] || AGENT_FAM="$(family_of "$AGENT_CLI" "$AGENT_MODEL")"

  JUDGE_CLI="${EVALS_JUDGE:-$(cfg judge)}"
  JUDGE_MODEL="${EVALS_JUDGE_MODEL:-$(cfg judge_model)}"
  if [ -z "$JUDGE_CLI" ]; then
    local pick c
    pick="$(pick_judge_from_routing "$AGENT_FAM")"
    if [ -n "$pick" ]; then
      JUDGE_CLI="${pick%%|*}"; pick="${pick#*|}"; JUDGE_MODEL="${pick%%|*}"
    else
      while IFS= read -r c; do
        usable "$c" || continue
        [ "$(family_of "$c" "")" != "$AGENT_FAM" ] && [ "$(family_of "$c" "")" != unknown ] && { JUDGE_CLI="$c"; break; }
      done < "$AI_DIR/clis"
    fi
  fi
  if [ -z "$JUDGE_CLI" ]; then
    # One family on this machine: run anyway, and say loudly what that means.
    JUDGE_CLI="$AGENT_CLI"; JUDGE_MODEL="$AGENT_MODEL"
  fi
  usable "$JUDGE_CLI" || { echo "run.sh: judge CLI $JUDGE_CLI is not usable here" >&2; exit 2; }
  JUDGE_FAM="$(family_of "$JUDGE_CLI" "$JUDGE_MODEL")"
  if [ "$JUDGE_FAM" = unknown ] || [ "$AGENT_FAM" = unknown ]; then INDEP=unknown
  elif [ "$JUDGE_FAM" = "$AGENT_FAM" ]; then INDEP=no
  else INDEP=yes; fi
}

# --- live: invoking a CLI headless -------------------------------------------
# Sandboxed autonomous modes only — never a full-bypass flag. The agent under
# test may edit inside its scratch worktree; the judge may not edit anything.

with_timeout() {
  local t="${EVALS_TIMEOUT:-600}"
  if command -v timeout >/dev/null 2>&1; then timeout "$t" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$t" "$@"
  else "$@"; fi
}

invoke() {  # $1 cli $2 model $3 dir $4 edits(1|0) $5 prompt → reply on stdout
  local cli="$1" model="$2" dir="$3" edits="$4" p="$5"
  case "$cli" in
    claude)
      local perm=(); [ "$edits" = 1 ] && perm=(--permission-mode acceptEdits)
      # ${perm[@]+…}: an empty array is "unbound" under set -u in bash 3.2.
      (cd "$dir" && with_timeout claude -p ${model:+--model "$model"} ${perm[@]+"${perm[@]}"} "$p" </dev/null 2>/dev/null) ;;
    codex)
      local sb=read-only; [ "$edits" = 1 ] && sb=workspace-write
      with_timeout codex exec --skip-git-repo-check ${model:+-m "$model"} --sandbox "$sb" --cd "$dir" "$p" </dev/null 2>/dev/null ;;
    agy)
      # agy's headless default mode writes nothing in the repo, so its agent
      # runs are graded on the reply alone. -p must come last.
      (cd "$dir" && with_timeout agy ${model:+--model "$model"} --disable-slash-commands --output-format json -p "$p" </dev/null 2>/dev/null) \
        | grep '^{' | jq -r '.response // empty' ;;
    agent)
      (cd "$dir" && with_timeout agent -p ${model:+--model "$model"} "$p" </dev/null 2>/dev/null) ;;
    *) echo "run.sh: no headless form known for $cli" >&2; return 2 ;;
  esac
}

judge_says() {  # $1 = output to grade → PASS | FAIL | NONE
  local q reply
  q="You are grading one piece of work against one rule from this project's own briefs.
Reply with exactly one first line, VERDICT: PASS or VERDICT: FAIL, then one sentence naming the evidence.

Rule (from $file): $anchor
Question: $judge
The author was asked: $prompt

--- WORK START ---
$1
--- WORK END ---"
  reply="$(invoke "$JUDGE_CLI" "$JUDGE_MODEL" "$ROOT" 0 "$q")"
  reply="$(grep -m1 -oE 'VERDICT:[[:space:]]*(PASS|FAIL)' <<<"$reply" | grep -oE 'PASS|FAIL')"
  echo "${reply:-NONE}"
}

scratch_tree() {  # → path of a throwaway copy of HEAD the agent may edit
  local t; t="$(mktemp -d "${TMPDIR:-/tmp}/evals.XXXXXX")"
  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$ROOT" worktree add -q --detach "$t/tree" HEAD >/dev/null 2>&1 || return 1
  else
    mkdir "$t/tree" && (cd "$ROOT" && tar cf - --exclude=./evals/results .) | (cd "$t/tree" && tar xf -)
  fi
  echo "$t/tree"
}
drop_tree() {  # the tree is ours and dirty by design; delete it, then prune its registration
  rm -rf "$(dirname "$1")"
  git -C "$ROOT" worktree prune 2>/dev/null || true
}
tree_diff() {
  git -C "$1" rev-parse --git-dir >/dev/null 2>&1 || return 0
  git -C "$1" add -A -N >/dev/null 2>&1
  git -C "$1" diff
}

# --- live: one case ----------------------------------------------------------

l_cpass=0 l_cfail=0 l_upass=0 l_ufail=0 l_uncal=0 cal_ok=0 cal_n=0

live_case() {
  case "$WANT_IDS" in "") ;; *" $id "*) ;; *) return 0 ;; esac
  if [ "$status" != confirmed ] && [ "$INCLUDE_UNCONFIRMED" = 0 ] && [ -z "$WANT_IDS" ]; then return 0; fi
  [ -n "$prompt" ] || return 0
  local tag="" verdict how out tree pf ff
  [ "$status" = confirmed ] || tag=" (unconfirmed)"

  tree="$(scratch_tree)" || { echo "run.sh: could not make a scratch worktree" >&2; exit 2; }
  out="$(invoke "$AGENT_CLI" "$AGENT_MODEL" "$tree" 1 "$prompt")"
  out="$out
$(tree_diff "$tree")"
  drop_tree "$tree"

  # The check grades first: it is free, deterministic, and already proven on
  # the goldens by static mode, so a hit needs no judge at all.
  verdict=PASS how=check
  if has_check && fires_on_text "$out"; then verdict=FAIL
  elif has_judge; then
    how=judge
    # A judge that cannot tell this case's own pass golden from its fail golden
    # has nothing to say about the agent's work on it.
    pf="$(golden "$id" pass)"; ff="$(golden "$id" fail)"
    cal_n=$((cal_n+1))
    if [ -n "$pf" ] && [ -n "$ff" ] && [ "$(judge_says "$(cat "$pf")")" = PASS ] && [ "$(judge_says "$(cat "$ff")")" = FAIL ]; then
      cal_ok=$((cal_ok+1))
      verdict="$(judge_says "$out")"
    else
      verdict=NONE
    fi
  fi
  if [ "$verdict" = NONE ]; then
    l_uncal=$((l_uncal+1))
    printf '  UNCAL %s%s — the judge could not separate its goldens (or gave no verdict); not graded\n' "$id" "$tag"
    printf '## %s — UNCALIBRATED\n\n' "$id" >> "$RESULTS"
    return 0
  fi

  if [ "$status" = confirmed ]; then
    if [ "$verdict" = PASS ]; then l_cpass=$((l_cpass+1)); else l_cfail=$((l_cfail+1)); fi
  else
    if [ "$verdict" = PASS ]; then l_upass=$((l_upass+1)); else l_ufail=$((l_ufail+1)); fi
  fi
  printf '  %-5s %s%s (%s) — %s\n' "$verdict" "$id" "$tag" "$how" "$title"
  # shellcheck disable=SC2016  # literal Markdown fence
  printf '## %s — %s (%s)\n\nprompt: %s\n\n```\n%s\n```\n\n' "$id" "$verdict" "$how" "$prompt" "$out" >> "$RESULTS"
}

run_live() {
  [ -f "$AI_DIR/clis" ] || { echo "run.sh: --live needs the AI CLI roster at $AI_DIR/clis (installed by the agent-global-instructions harness). Static mode still works." >&2; exit 2; }
  run_static
  [ "$STATIC_VERDICT" = pass ] || { echo "  static checks failed — fix those before a live run"; echo "EVALS mode=live verdict=fail reason=static"; exit 1; }
  choose_runners
  mkdir -p "$HERE/results"
  RESULTS="$HERE/results/$(date +%Y%m%d-%H%M%S)-$$.md"
  printf '# Live eval run %s\n\nagent: %s %s · judge: %s %s · family-independent: %s\n\n' \
    "$(date)" "$AGENT_CLI" "$AGENT_MODEL" "$JUDGE_CLI" "$JUDGE_MODEL" "$INDEP" > "$RESULTS"
  [ "$INDEP" = no ] && echo "  WARN: same-family judge ($JUDGE_FAM judging $AGENT_FAM) — self-consistent against the goldens, not a refutation"
  for_each_case live_case
  local v=pass
  [ "$l_uncal" -gt 0 ] && v=inconclusive
  [ "$l_cfail" -gt 0 ] && v=fail
  echo "  results: $RESULTS"
  echo "EVALS mode=live agent=$AGENT_CLI:${AGENT_MODEL:-default} judge=$JUDGE_CLI:${JUDGE_MODEL:-default} family-independent=$INDEP calibrated=$cal_ok/$cal_n confirmed-pass=$l_cpass confirmed-fail=$l_cfail uncalibrated=$l_uncal unconfirmed-pass=$l_upass unconfirmed-fail=$l_ufail verdict=$v"
  case "$v" in pass) exit 0 ;; fail) exit 1 ;; *) exit 3 ;; esac
}

case "$MODE" in
  confirm) run_confirm ;;
  live) run_live ;;
  static)
    run_static
    echo "EVALS mode=static confirmed-pass=$c_pass confirmed-fail=$c_fail unconfirmed-pass=$u_pass unconfirmed-warn=$u_warn verdict=$STATIC_VERDICT"
    [ "$STATIC_VERDICT" = pass ] ;;
esac
