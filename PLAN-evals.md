# PLAN — per-project evals, scaffolded by `setup`

Status: approved and built (2026-10-28, Claude). Joe's answers to the open questions and the rival-diff conflicts are under *Decisions, round 2*. A rival draft
from Gemini 4 Argon is at `~/.ai-context/project-starter-pack-evals/agents/gemini.md`;
the diff between the two is at the end of this file.

## Problem

The harness gives every project instructions (briefs, guardrails, the
`AGENTS.md` router) but nothing that checks whether an agent working in that
project actually follows them. The one eval instance that exists,
`agent-global-instructions/evals/`, is the framework grading itself: it checks
that rule text survives a render (an anchor grep), runs no model, and has no
golden examples. An eval system is only useful when it is about *this*
project's rules, so the framework has to scaffold one per project.

## Decisions already made (Joe, 2026-10-28)

1. **Measure both, agent first.** The core suite tests whether an agent working
   in the project follows its briefs and guardrails. A second suite, for AI
   features the product itself ships, is optional.
2. **Scaffolding is a step inside `setup`.** No standalone `/evals` skill.
3. **Goldens are seeded, confirmed, then grown.** `setup` drafts pass/fail
   exemplars from the briefs and marks them `unconfirmed`. A human confirms
   them. New ones come from real corrections. Unconfirmed goldens never gate.
4. **Live runs are local and opt-in, with a cross-family judge.** CI runs only
   the free static checks. No API keys in repo secrets by default.

## What gets written into a target project

```
evals/
  cases.md          # the source: one entry per behaviour, human-edited
  goldens/<ID>/     # pass.md + fail.md per case: the exemplar pair
  run.sh            # static by default; --live opt-in
  README.md         # 15 lines max: what this is, how to add a case, how to run
  results/          # gitignored: live-run output
```

`cases.md` is the source, read directly by the runner, the same choice
`agent-global-instructions/evals/PLAN.md` made. Prose is what a person edits, and
a generated second list would drift. Once a second consumer appears, generate a
`registry.json` from it the way `build-guardrails.sh` does here.

### Case schema

```
## EV-07 — Raw hex never ships where a token exists

source: DES-03                 # guardrail ID(s) and/or the owning brief
file: DESIGN.md                # brief that owns the rule
anchor: Never ship a raw color literal where a token exists   # must survive in file:
kind: agent | product          # which suite
status: unconfirmed | confirmed
origin: seeded by setup 2026-10-28 | correction 2026-11-02: <one line>
prompt: Add a "danger" variant to the Button component.
check: regex:#[0-9a-fA-F]{3,8}\b   # free grader, copied INLINE from the registry
judge: Does the change use the project's color tokens instead of literals?
```

- **IDs are stable and never renumbered**, the same as BEH- and DES-.
- **`check:` holds a deterministic grader, written inline.** The guardrail
  detectors in `guardrails/*.detect.md` already work as pass/fail graders. Their
  `fixtures/guardrails/<ID>/{trips,clean}` pairs prove it, with the clean half
  doing the real work. A detector costs nothing and gives the same answer every
  time, so the judge only handles what no detector can catch. **When seeding,
  `setup` copies the pattern into the case.** `registry.json` lives only in the
  pack checkout: I checked, and `hooks/` reads it from there. A target project
  references ban IDs by name but carries no copy of them, so a reference like
  `check: detector DES-03` couldn't resolve in the project's CI. (My first draft
  made that mistake. Gemini's draft didn't.)
- **`anchor:` is the exact text in `file:` that must survive.** It's the same
  anchor idea as `agent-global-instructions/evals/`, aimed at the project's
  own briefs.
- **`judge:` is a single yes/no question, not a score.** Weighted rubrics come
  later, once enough cases exist to calibrate them.

### Goldens

`goldens/<ID>/pass.md` and `fail.md` hold short example agent replies or
diffs, one that passes and one that fails. They do two jobs:

1. **They calibrate the judge.** Before a live run scores any real output, the
   judge must score each confirmed pair correctly (pass→yes, fail→no). If it
   gets a pair wrong, the run stops and reports that the judge can't tell this
   case's pass from its fail. Without this step the goldens are decoration.
2. **They define the behaviour concretely.** A case for which nobody can write
   a clear pass and a clear fail isn't decidable yet, and stays `unconfirmed`.

## How `setup` seeds them

- **New step, after the briefs and before the wire-up:** "Evals". It runs at
  every scope, like the wire-up, and seeds only from the briefs that exist.
- **Seeds from two places:**
  1. **Guardrail IDs that have a live detector.** Each gives a case with a free
     `check:`. A detector ID always gets a case, because it's the cheapest grader.
  2. **Rules in the briefs that state what an agent must do,** such as
     PRODUCT.md's audience and register, DESIGN.md's component library ("compose
     X, don't hand-roll"), WRITING.md's terminology, and CODE.md's test and
     performance lines. These become judge-only cases.
  - The cap is about 12 seeded cases per run, ranked by how much damage a
    violation would do. A wall of 60 unconfirmed cases never gets confirmed.
- **Every seeded case and golden is `unconfirmed`.** `setup` shows the list,
  you confirm, edit, or drop them in one pass (rounds, not one at a time), and
  it writes what you kept.
- **Never seed from `[TODO — confirm]` placeholders** left by `extract`. Only
  confirmed brief text becomes a case. (Taken from Gemini's draft.)
- **Re-running on a project that already has `evals/`** means: merge (the
  default), keep, or overwrite. Confirmed cases and cases added from
  corrections are never overwritten without asking. New seeds come in as
  `unconfirmed`. (Taken from Gemini's draft. Mine didn't cover a re-run.)
- **A golden that comes from a correction can be confirmed in the same turn.**
  You just approved the corrected version in chat, so `trips` is what the agent
  produced and `clean` is what you approved.
- **Product-AI suite:** offered only when PRODUCT.md or CODE.md describes AI the
  product ships. It seeds one `kind: product` case per described AI behaviour.
  No rubric design until a real project needs one.
- **Already-set-up projects get evals by adding `evals` to the Step 0 scope table:**
  `setup evals` runs only this step plus the wire-up. Brownfield projects with
  no briefs go through `extract` first, as they do today.
- **Router line:** `AGENTS.template.md` gets one line pointing agents at
  `evals/cases.md` ("when you're corrected here, propose a case"). It's a
  pointer, not content, so the router-only rule still holds.

## The runner

`templates/evals/run.sh` is copied into the project as a project-local script,
because a skill can't be the runner (decision 2). It depends only on bash, grep
and jq, the same as `test.sh` here.

- **`./evals/run.sh` (static, free, CI-safe) checks:**
  - the schema: every case has its fields, IDs are unique, `file:` exists, and
    every confirmed case has both goldens
  - that each inline `check:` trips on `fail.md` and stays quiet on `pass.md`
  - that each `anchor:` still appears in its `file:`
- **`./evals/run.sh --live [ID…]` (opt-in, costs tokens):**
  1. Read `~/.ai/clis`. Choose an **agent under test**, by default the CLI the
     operator works in, and a **judge from a different model family**.
  2. Calibrate the judge on confirmed goldens. Stop if it fails any.
  3. For each case, run the agent headless in a **scratch worktree** of the
     project with the prompt, and capture its reply and diff.
  4. Grade each case with its `check:` detector first, then its `judge:`.
  5. Write `results/<timestamp>.md`, and print one line per case:
     `EV-07 pass (detector) | EV-09 FAIL (judge: used literal #e11)`.
- **When the machine has only one model family:** run anyway, but label every
  judged result `same-family judge — not a refutation` and say so in the
  summary. Refusing to run would leave a single-vendor machine with no evals at
  all. Detector-graded cases are unaffected.
- **No `~/.ai/clis` (the harness isn't installed):** `--live` explains what's
  missing and exits 2. Static mode still works. Nothing gets installed.
- **Unconfirmed cases run in `--live` only with `--include-unconfirmed`, and are
  reported separately.** They never count toward pass or fail.

## Repo split

| Repo | Changes |
|---|---|
| `project-starter-pack` | `skills/setup/SKILL.md` gets the Evals step and the `evals` scope word · `templates/evals/` holds run.sh, the cases.md skeleton, and README · the `AGENTS.template.md` router line · `questionnaires/` gets the confirm-cases question · `test.sh` gets contracts: the template runner passes shellcheck, the seeded skeleton passes its own static mode, and the example render includes `evals/` · `examples/saga-reader/evals/` holds the worked render |
| `agent-global-instructions` | `template.md` gets one rule, roughly: **"A correction in a project with `evals/` becomes a case there"** (propose it, don't write it unasked, like the Change Log). Its headline is pinned in `test.sh` and gets a `BEH-` entry. This repo's own `evals/` stays as its own instance. Optionally, it later adopts the same schema to dogfood it |

## Three lenses

- **UX (Joe, the designer running setup):** a single confirmation round of
  about 12 cases, written in plain language and tied to the rule each came
  from, so confirming feels like reviewing a brief, not writing tests. *Trade:*
  12 cases leaves coverage incomplete on purpose. Corrections fill it in.
- **DX (whoever maintains a project):** cases are a Markdown file and a script
  with no build step, and static mode runs in seconds in any CI. A failure
  names the case, its source rule, and why the rule exists.
- **AX (the agent working in the project):** the router points at `cases.md`,
  so an agent can read which behaviours are graded before it starts. Results
  are one parseable line per case, which a `/goal` condition can check
  ("`./evals/run.sh --live` prints no FAIL"). The risk here is an agent writing
  to the test, so goldens and judge questions describe outcomes, never steps.

## Falsifiers

- **Seeding produces cases nobody can decide.** If, in the first real project,
  fewer than half the seeded cases can get a clear pass/fail pair, seeding
  from the briefs is the wrong source. Switch to corrections only.
- **The judge can't separate the goldens.** If calibration fails often on
  well-written pairs, judge-graded cases are noise, and the system should lean
  on detectors and human review instead.
- **Nobody runs `--live`.** If a project goes a month with corrections but no
  live runs and no new cases, the opt-in design is decoration, and the cost
  question (decision 4) needs revisiting.

## Rival draft: Gemini 4 Argon, diffed

I gave both drafts the same brief, written independently (`TASK.md` in the
context dir). Codex couldn't take the second draft because its pool is locked
until 2026-11-17 (per `~/.ai/pools`).

**Where they agree:** `cases.md` as the source with stable IDs · goldens as
trips/clean pairs, modelled on `fixtures/guardrails/` · a standalone runner
copied into the project, needing only bash, grep and jq · the `evals` scope word
plus a step that runs on every setup · judge calibration before grading ·
unconfirmed cases never gate · a single-family judge runs but is labelled · one
router line · one `template.md` rule plus a BEH entry · a `saga-reader` example.

**Taken from Gemini (already merged above):** inline `check:` patterns
(fixes a real defect in mine) · an `anchor:` field per case · the merge
pre-flight on re-run · no seeding from TODO placeholders · confirming
correction-born goldens in the same turn.

**Also worth adopting, not merged yet:**
- `./evals/run.sh --confirm <ID>`, which flips status after checking that the
  goldens exist.
- `validate` runs the static evals and flags a mature repo whose cases are all
  still unconfirmed.
- One machine-checkable summary line (`EVALS mode=… verdict=pass|fail`),
  following BEH-31.
- `test.sh` mutation tests: corrupting a confirmed anchor must exit 1, and
  corrupting an unconfirmed one must exit 0.

**Where they disagree (your call):**
1. **How much setup asks.** Gemini asks no questions: it seeds and leaves you
   to confirm later. Mine asks for one confirmation round in setup. Gemini's
   is lighter, but its own falsifier #3 (everything still unconfirmed after 30
   days) is the risk it creates.
2. **How many cases get seeded.** Gemini seeds about one per brief domain (5–6).
   Mine caps it at about 12, ranked by damage.
3. **How the judge is picked.** Gemini reads `~/.ai/pools` and
   `~/.ai/model-routing.md` and picks a cross-family flagship using the
   BEH-29/BEH-34 rules. Mine reads only `~/.ai/clis`. Gemini's is more correct
   but ties a project script to harness files, which then have to degrade
   cleanly when missing.
4. **Unverified in Gemini's draft:** it detects the agent under test from env
   vars (`CLAUDECODE`, `CODEX_SANDBOX`, `ANTIGRAVITY_CLI`, `CURSOR_TRACE_ID`).
   I found none of those names documented in `~/.ai/`, `lib/` or `hooks/`, so I
   haven't adopted it.

## Decisions, round 2 (Joe, 2026-10-28)

- `setup` asks one confirmation round (not zero).
- Seeding is capped at about 12, ranked by damage.
- The judge is picked from `~/.ai/pools` and `~/.ai/model-routing.md` when they exist,
  falling back to `~/.ai/clis` family defaults. Verified with stub CLIs against this
  machine's real routing table: a `claude` agent got `agy gemini-4-argon-high`.
- `--confirm`, the `validate` nudge, the summary line and the mutation tests are adopted.
- `agent-global-instructions/evals/` moves to the new schema later, after one real project
  has used it.

**Changed while building:** a case's `check:` now grades before its judge is calibrated.
The first build calibrated first, so a judge that couldn't separate the goldens also
blocked a free, already-proven check. Goldens take the real surface's extension
(`pass.css`, `fail.tsx`) instead of always `.md`.

## Open questions (as drafted, now answered above)

1. **Which agent runs under test by default?** Recommended: the CLI named in a
   `evals/config` line, falling back to the first non-judge entry in `~/.ai/clis`.
2. **Do live runs need a scratch worktree, or is reply-only enough for
   judge-only cases?** Recommended: worktree for anything with a `check:`
   (detectors grade a diff), reply-only otherwise. It's cheaper and nothing in
   the project gets touched.
3. **The seeding cap:** about 12 per run, ranked by damage. Or seed everything
   and let you prune?
4. **Should this repo's `agent-global-instructions/evals/` migrate to the new
   schema now, or later?** Recommended: later, after one real project has used it.
