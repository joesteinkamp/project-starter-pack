# Roadmap — making the anti-pattern rules enforceable

> **Status: Phases 0–3 built. Phase 4 (CI) not built, by recommendation.**
> `./test.sh` went 294 → 336 passed, 0 failed, with no check deleted or relaxed. The plan below is
> kept as written; what actually happened, including where the build diverged from it, is recorded
> under **Outcome** at the end and in per-phase status lines. Every number in the investigation
> sections was measured against the tree and still holds.

The repo enforces its anti-pattern rules twice and binds the two nowhere. Five prose registries in
`guardrails/` (88 bans, 253 lines) are embedded into the briefs; seven hardcoded greps across three
hook scripts enforce a hand-picked subset. Add a ban to the prose and nothing detects it. Change a
ban and the grep keeps enforcing the old wording. The goal is one source of truth: **adding a ban
to the prose arms its detector in the same edit.**

---

## Verification of the stated claims

Every claim in the planning brief was checked against the live tree. Eight hold as stated; one
holds with an exception that changes a design decision.

| # | Claim | Outcome |
|---|---|---|
| 1 | `guardrails/` is five files, ~253 lines, prose only | **Confirmed, exactly.** `wc -l guardrails/*.md` → 59 + 48 + 39 + 51 + 56 = 253. No IDs, no severity, no machine-readable fields anywhere. |
| 2 | `check-anti-patterns.sh` hardcodes ~3 CSS checks | **Confirmed.** Layout-property transitions (two anchored patterns), `backdrop-filter: blur`, `background-clip: text`. |
| 3 | `check-writing-slop.sh` hardcodes ~3 prose greps plus em-dash density | **Confirmed.** AI-flagship vocabulary subset, empty-framing phrases, em-dash count `> 5`. |
| 4 | `guard-design.sh` hardcodes one hex check, gated on `DESIGN.json` | **Confirmed.** Gated on `$(git rev-parse --show-toplevel)/DESIGN.json`; matches `#rgb`/`#rgba`/`#rrggbb`/`#rrggbbaa` in a value position only. |
| 5 | All three hooks are advisory — warn to stderr, always `exit 0` | **Confirmed.** Every script ends `exit 0`; every message goes to stderr. |
| 6 | Every grep-enforced ban exists in prose; the reverse is false | **Confirmed with one exception.** The reverse is emphatically false (7 of 88 bans have a detector). But `guard-design.sh` flags **any** raw hex, and no prose ban says that. `design-anti-patterns.md` bans pure black and prescribes OKLCH neutrals; it never bans hex generally, and explicitly permits `#FFF`. So one detector currently enforces a rule the registry does not contain — drift in the direction nobody was watching. |
| 7 | `validate` Mode A asks for WCAG contrast on five token pairs, in those words, with no script | **Confirmed verbatim.** `skills/validate/SKILL.md:52` names `foreground/background`, `muted/background`, `accent/background`, `accentForeground/accent` (4.5:1), `borderStrong/background` (3:1 per 1.4.11), "in every theme block the file ships. Compute the contrast, don't eyeball it." No script exists. |
| 8 | No `.github/`, so no CI; `./test.sh` is the only gate | **Confirmed.** No `.github` directory. |
| 9 | `test.sh` reports near 294 passing checks | **Confirmed, exactly.** `294 passed, 0 failed`. |

### One thing the brief did not ask about, found while checking

`examples/saga-reader/DESIGN.md:145` renders the pure-black ban as:

> `- No pure black (`#000`) or pure white (`#FFF`) on body surfaces — OKLCH neutrals with warmth.`

`guardrails/design-anti-patterns.md:8` says:

> `- **No pure black (#000)** on body surfaces. … Pure white (#FFF) is fine.`

The fixture bans what the registry explicitly permits. `./test.sh` is green through this, because
nothing binds a rendered ban to its source — sections 5 and 6 check for leaked placeholders and
matching headings, not fidelity of content. This is the drift this roadmap exists to remove,
already present, in the one file the repo holds up as its worked example. It is fixed in Phase 0;
the check that would have *caught* it is Phase 2's, which is the strongest single argument for
building Phase 2.

---

## Open questions, answered

### 1. How do the hooks resolve paths once installed? Can they reach a generated registry?

**Yes, by `$(dirname "${BASH_SOURCE[0]}")/../guardrails/registry.json`. This is not a risk.**

`install-hooks.sh` computes `HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` and wires every
command as an **absolute path into the checkout**:

```
cmd() { printf 'env HOOK_PLATFORM=%s "%s/%s"' "$1" "$HERE" "$2"; }
```

So the installed Claude/Codex/Cursor entry invokes `<checkout>/hooks/check-anti-patterns.sh`
directly. Antigravity is the one indirection — it gets a generated wrapper at
`~/.gemini/antigravity-cli/hooks/psp-<name>.ag.sh` — and that wrapper is
`exec "<checkout>/hooks/<name>.sh"`, so `BASH_SOURCE` inside the real script still resolves into
the checkout. Nothing is ever copied. `install.sh` does not touch `hooks/` at all (its only
link operation is `ln -s` for commands and skills).

The same holds for skills: `install.sh` symlinks each skill *directory* into the tool's skills
folder, which is exactly why `../../` resolves and a bare path does not. A script at
`scripts/validate-tokens.sh` is reachable from `skills/validate/SKILL.md` as
`../../scripts/validate-tokens.sh`, by the same mechanism the guardrails already use.

**One caveat that costs a line of `test.sh`:** the `../../` check at `test.sh:762` only guards the
alternation `(questionnaires|templates|guardrails|conventions)`. A new `scripts/` reference written
bare would pass the check and break under symlink install. Phase 1 must extend that alternation.

### 2. Which bans are mechanically detectable? (88 bans, classified)

Every ban in all five files was classified. `regex` means a grep finds it at a false-positive rate
the current hooks would accept; `token` means computable from `DESIGN.json` but not by grep;
`render` needs a rendered page or computed styles; `manual` needs a human or a model.

A fourth column was necessary and is reported honestly: **`scoped`** — detectable by regex only
with a scope restriction or a threshold, otherwise the false-positive rate is unacceptable. The
hooks already embody this distinction in a code comment (`"robust" and "leverage" are excluded
because tech docs use them honestly`), which is precisely the judgment that today lives in a
comment and is enforced by nothing.

| File | Bans | regex | token | scoped | render | manual |
|---|---:|---:|---:|---:|---:|---:|
| `writing-anti-patterns.md` | 28 | **16** | 0 | 5 | 0 | 7 |
| `design-anti-patterns.md` | 26 | **8** | 5 | 4 | 5 | 4 |
| `code-anti-patterns.md` | 14 | **6** | 0 | 3 | 0 | 5 |
| `ux-anti-patterns.md` | 12 | **1** | 0 | 1 | 2 | 8 |
| `product-anti-patterns.md` | 8 | **0** | 0 | 4 | 0 | 4 |
| **Total** | **88** | **31** | **5** | **17** | **7** | **28** |

**The payoff, stated plainly.** 36 of 88 bans (41%) are mechanically detectable today with no
judgment call — 31 by grep, 5 by arithmetic over `DESIGN.json`. Seven are enforced. That is a
**4.4× headroom**, and it is real work worth doing.

But the payoff is **concentrated, not uniform**, and the plan should not pretend otherwise:

- `writing-anti-patterns.md` alone carries 16 of the 31 clean regexes. It is where a registry pays
  for itself fastest.
- `design-anti-patterns.md` carries 8 regexes plus all 5 token checks — and the 5 token checks are
  Phase 1, which needs no registry at all.
- **`product-anti-patterns.md` yields zero clean detectors, and `ux-anti-patterns.md` yields one.**
  Twenty bans across those two files stay model-judged no matter what is built. For them the
  registry's value is a citable stable ID, not a detector. Anyone proposing to "cover the
  guardrails with greps" should read this row first.

35 of 88 (40%) are not detectable by any script at any point on this roadmap.

### 3. Can the contrast math be done in jq? — **Yes, exactly, and it is already written.**

Not hand-waved. `jq-1.7` exposes `cos`, `sin`, `sqrt`, `cbrt`, and `pow` as unary filters (`0 | cos`,
not `cos(0)` — the two-argument spelling is a compile error, which is the one gotcha). The full
OKLCH → OKLab → linear sRGB → WCAG relative luminance → contrast ratio chain is **28 lines of jq**
and is reproduced in the appendix.

Validation against known values:

| Input | jq result | Expected |
|---|---:|---:|
| `oklch(1 0 0)` vs `oklch(0 0 0)` (white/black) | 21.00 | 21.00 |
| `oklch(0.628 0.2577 29.23)` vs white (pure red on white) | 4.00 | 3.998 |
| `oklch(0.628 0.2577 29.23)` vs black | 5.25 | 5.252 |
| `oklch(0.5 0 0)` vs white | 6.00 | 6.00 |

Run against the real fixture, all ten pairs across both theme blocks pass:

```
default  foreground/background     14.29  min 4.5  PASS      dark  foreground/background    12.85  PASS
default  muted/background           5.22  min 4.5  PASS      dark  muted/background          5.56  PASS
default  accent/background          5.52  min 4.5  PASS      dark  accent/background         5.31  PASS
default  accentForeground/accent    5.52  min 4.5  PASS      dark  accentForeground/accent   5.31  PASS
default  borderStrong/background    3.18  min 3.0  PASS      dark  borderStrong/background   3.14  PASS
```

Two notes for whoever implements it. The `borderStrong` pairs clear the 3:1 floor by 0.18 and 0.14
— the fixture passes, but with no headroom, so a validator here is not decorative. And WCAG
luminance is defined on *linear* sRGB, which is what the OKLab matrix already produces, so the
gamma round-trip is unnecessary; out-of-gamut components are clamped to `[0,1]`, which is exact for
in-gamut colors and an approximation of the browser's gamut mapping outside it. Worth one comment
in the script, not a dependency.

**This closes reserved decision 4: no dependency is needed.**

### 4. What does `test.sh` already assert about `guardrails/`? Three things, in two sections.

**Section 4 — "Guardrail wiring"** (`test.sh:143`). For each `guardrails/*-anti-patterns.md`, it
maps the file to an owning skill and template by a hardcoded `case` on the filename prefix, then
asserts (a) the owning skill mentions the file's basename and (b) the owning template carries the
matching `{{<PREFIX>_ANTI_PATTERNS}}` slot. It reads **filenames only, never contents**. Adding
IDs and fields inside the files does not interact with it. Adding a *sixth* guardrail file does:
the `case` has a `*)` arm that fails with `"has no owning brief mapped in test.sh section 4"`.

**Section 9 — "guardrail ↔ hook linkage"** (`test.sh:434`). This is the part that interacts, and
it matters: `check_link` already implements a **hand-maintained, two-directional version of the
exact contract this roadmap wants to generate.** Seven hardcoded pairs, each asserting the term is
still in the guardrail file *and* the pattern is still in the hook:

```
check_link "layout properties" "$DG" hooks/check-anti-patterns.sh "transition"
check_link "glassmorphism"     "$DG" hooks/check-anti-patterns.sh "backdrop-filter"
check_link "gradient text"     "$DG" hooks/check-anti-patterns.sh "background-clip"
check_link "OKLCH"             "$DG" hooks/guard-design.sh        "OKLCH"
check_link "delve"             "$WG" hooks/check-writing-slop.sh  "delve"
check_link "worth noting"      "$WG" hooks/check-writing-slop.sh  "worth noting"
check_link "em-dash clusters"  "$WG" hooks/check-writing-slop.sh  "em-dash clusters"
```

These are **substring greps on prose**. Rewording a ban breaks them. That is by design and it is
the check to **retarget, not delete** (`AGENTS.md`: "If a change would require relaxing a check,
retarget the check"). Phase 2 replaces all seven with one generated loop over
`registry.json` that asserts the same contract for *every* ban rather than seven — strictly
stronger, which is the bar a retarget has to clear.

**Section 10c — the portability ban list** (`test.sh:684`) includes `guardrails` in
`PORTABLE_DIRS`. Any structured field added to a guardrail file is subject to the harness-name
bans. One is a live tripwire for this work: `ban_check '!`[^`]+`'` (Claude's shell-injection
dialect) matches a `!` immediately followed by a backticked span. A `detect:` regex written as
`` !`foo` `` would fail the suite. Machine fields must stay tool-neutral, and regexes should be
fenced or table-celled rather than written as bare inline code after a `!`.

### 5. Does `DESIGN.json` always carry OKLCH? — Yes by contract, no by enforcement.

`questionnaires/design.questions.md:199` asks for OKLCH values for the seven color slots, and
`:270` instructs: *"Validate color tokens use OKLCH (not hex/HSL) — auto-convert with a note if
the user provides hex."* Both the tokens template and the `saga-reader` render carry
`oklch(L C H)` in all fourteen color slots (seven default, seven under `themes.dark`).

The format the validator would parse is stable and shallow: `.color.<name>["$value"]` for the
default theme and `.themes.<mode>.color.<name>["$value"]` for each override, values as CSS strings
like `"oklch(0.98 0.008 85)"`. `test.sh` section 6 already asserts the key paths match the
template in both directions, so the *shape* is guaranteed.

The **format of the value is not**. "Validate OKLCH" is an instruction to a language model, and the
`test.sh` structural check compares key paths, not value syntax. A hex value would sail through
today. So `validate-tokens.sh` must fail loudly and specifically on a value it cannot parse rather
than silently skipping the pair — the failure mode to design against is a validator that reports
"all pairs pass" because it parsed none of them.

### 6. What breaks in `examples/saga-reader/`? — Nothing in Phases 0–1. Phase 2 forces a re-render, but only under one of the two format options.

The example is checked by section 5 (no `{{` or `SECTION:` leaks) and section 6 (every slot-free
template heading appears in the render; `DESIGN.json` key paths match the template both ways).
Neither reads guardrail content.

What decides it is how the briefs consume guardrails. All three brief skills say to pull the ban
list in **"embedded inline, not just linked"** (`skills/product-brief/SKILL.md:44`,
`skills/code-brief/SKILL.md:47`, `skills/design-brief/SKILL.md:62`). In practice the model
*paraphrases* — `examples/saga-reader/PRODUCT.md:69-76` renders the eight product bans as eight
one-line bullets, none copied verbatim.

So:

- **Adding machine fields to the prose does not force a re-render**, because the render is a
  paraphrase, not a copy.
- **Rendering the IDs into the briefs does** — and it is worth doing, because a brief that says
  `(DES-17)` is a brief whose bans `validate` can cite and whose fidelity `test.sh` can check.
  That is the whole point, and it means `examples/saga-reader/{PRODUCT,DESIGN,CODE,WRITING}.md`
  get re-rendered in Phase 2.
- This is also the constraint that decides reserved decision 2. Anything placed in the prose is
  copied toward every user's briefs. A `detect:` regex in the prose is machine noise headed for a
  designer's `DESIGN.md`.

---

## Phases

### Phase 0 — Fix the drift that already exists

> **Built.** Joe chose to add the ban rather than narrow the hook's claim, so
> `design-anti-patterns.md` gained `DES-03` ("No raw hex where a token system applies") and the
> registry grew to 89 bans. The fixture's pure-white contradiction is fixed in both the ban list
> and the colour-strategy line.

**What changes.** One paragraph of cleanup, no new format, no new files. Correct
`examples/saga-reader/DESIGN.md:145` so it stops banning pure white, which
`guardrails/design-anti-patterns.md:8` explicitly permits. Then resolve the claim-6 exception:
`guard-design.sh` flags all raw hex while no prose ban says so. Either the prose gains the ban it
is already enforcing, or the hook's header stops citing a ban it is exceeding. Both are one-line
edits and they are opposite decisions, so Joe picks.

**Files touched.**
- `examples/saga-reader/DESIGN.md` (line 145)
- one of: `guardrails/design-anti-patterns.md` (Color section) **or** `hooks/guard-design.sh` (header comment, lines 3–8)
- `hooks/README.md` (the `guard-design.sh` row of the "What they check" table, if the ban moves)

**Definition of done.** `grep -c 'pure white' examples/saga-reader/DESIGN.md` returns 0 for the
banning sense, and the fixture's stance on `#FFF` matches the guardrail's. `./test.sh` still
reports `294 passed, 0 failed` — this phase adds no checks, and it must not subtract any.

**What it unblocks.** Nothing. It is a bug fix that stands alone.

**Joe approves:** the direction of the hex resolution. Adding a ban to `design-anti-patterns.md` is
squarely "a change would add a slot, question, or guardrail" under `AGENTS.md` → *When to ask the
user*, so the prose option cannot proceed without him. The hook-comment option is a comment fix
and does not need a gate.

> The check that would have caught this contradiction is Phase 2's. Phase 0 fixes the instance;
> only IDs plus a fidelity check prevent the next one.

---

### Phase 1 — Compute the contrast instead of asking a model for it

> **Built.** `scripts/validate-tokens.sh`, pure bash + jq, no new dependency. All ten pairs on the
> fixture match the ratios predicted in open question 3. `test.sh` section 11 seeds four failures
> (a pair below floor, a hex value, a missing token, a single-theme file); all four were
> mutation-tested by breaking the validator and confirming the suite goes red.

**What changes.** `skills/validate/SKILL.md` Mode A hands a language model an OKLCH-to-luminance
arithmetic problem across ten token pairs and asks it not to eyeball the answer. Replace that with
`scripts/validate-tokens.sh`: it reads `DESIGN.json`, walks the default `color` block and every
block under `themes.*`, computes the five named pairs with the jq in the appendix, prints a row per
pair with the measured ratio, and exits 1 naming every failing pair and its ratio. It fails loudly
on any value it cannot parse as `oklch(...)`, so a hex value that slipped past the
questionnaire's model-enforced OKLCH rule surfaces as an error rather than a skipped pair. The
skill then *runs* the script instead of doing the arithmetic, and reports its output as measured
evidence.

**Files touched.**
- `scripts/validate-tokens.sh` (new; new top-level `scripts/` directory)
- `skills/validate/SKILL.md` (Setup step; the Mode A accessibility row at line 52)
- `test.sh` (extend the `../../` alternation at line 762 to include `scripts`; new section asserting the validator's behaviour)
- `README.md` (repo layout list, one line)

**Definition of done.** Three checkable facts:
1. `scripts/validate-tokens.sh examples/saga-reader/DESIGN.json` exits 0 and prints ten rows with
   ratios matching the table in open question 3.
2. A copy of that file with `borderStrong` moved one step lighter exits 1 and names
   `borderStrong/background` and its ratio — added to `test.sh` as a seeded-failure fixture, so the
   validator is proven to fail and not only to pass.
3. A copy with a hex value in one slot exits non-zero with a parse error naming the slot, rather
   than reporting a pass.
4. `./test.sh` is green, with count risen from 294 and **no check retargeted or relaxed**.

**What it unblocks.** Nothing depends on it, which is the point — it is the one phase with no
prerequisite and no reserved decision blocking it. It also establishes `scripts/` as the home for
deterministic measurement, which Phases 2 and 3 both use.

**Joe approves:** creation of a top-level `scripts/` directory. This is new surface, though not
*command* surface — the anti-goal is a fourth verb, and this adds none; `validate` stays the verb
and gains a tool. The alternative is `skills/validate/scripts/`, which is rejected because
`design-brief` is the natural second consumer (it writes `DESIGN.json` and could verify before
writing) and each skill dir is symlinked alone, so one skill reaching into another's directory does
not resolve.

> **Recommended ordering deviation from the sibling roadmap.** `agent-global-instructions`
> `docs/ROADMAP.md` places the contrast validator third, behind the registry keystone. Nothing in
> it actually depends on the registry: it touches no guardrail file, needs no ID scheme, and is
> gated by none of the five reserved decisions. Its math is proven above. Putting it first means
> the repo gets its largest correctness win while the format decisions are still being made.

---

### Phase 2 — Make `guardrails/` a real registry — **keystone**

> **Built**, after Joe settled decisions 1, 2 and 5: per-file prefixes, sidecar tables, and
> `confidence` instead of `severity`. 89 bans, 10 live detectors, 39 marked `unwritten`.
> Two bugs surfaced that only behavioural testing could have caught — see **Outcome**.

**What changes.** Every ban gains a stable, immutable ID in the prose, and a machine record
carrying `severity`-or-`confidence`, a `detect:` expression or `manual`, and the file scope it
applies to. `guardrails/_format.md` states the contract a parser can rely on, the way
`references/frameworks/_format.md` does in the sibling repo. `build-guardrails.sh` — bash and jq,
no new dependency — parses the five registries and emits `guardrails/registry.json`, exiting
non-zero with an itemized message on a duplicate ID, a missing required field, an invalid
severity, an ID present in the prose but absent from the machine record, or the reverse. The three
hooks stop hardcoding and read `registry.json` via `$(dirname "${BASH_SOURCE[0]}")/../guardrails/registry.json`,
filtering to the bans whose scope matches the edited file. `test.sh` section 9's seven hardcoded
`check_link` calls are replaced by one loop over the registry that asserts the same two-directional
contract for every detector-bearing ban. The brief skills render `(ID)` alongside each ban, and the
example is re-rendered.

**Files touched.**
- `guardrails/_format.md` (new)
- `guardrails/{product,ux,design,writing,code}-anti-patterns.md` (IDs, and machine fields if decision 2 goes inline)
- `guardrails/{product,ux,design,writing,code}-anti-patterns.detect.md` (new, only if decision 2 goes sidecar)
- `build-guardrails.sh` (new, repo root, beside `render-ports.sh` and `install.sh`)
- `guardrails/registry.json` (new, generated — and **committed**, not gitignored, because the hooks read it at edit time on a user's machine where no build step runs)
- `hooks/check-anti-patterns.sh`, `hooks/check-writing-slop.sh`, `hooks/guard-design.sh`
- `hooks/README.md` ("What they check" table stops enumerating three bans each)
- `test.sh` (section 4 unchanged; section 9's `check_link` block replaced; new section for the generator's failure modes)
- `skills/{product-brief,design-brief,code-brief}/SKILL.md` (render the ID with each ban)
- `skills/validate/SKILL.md` (cite ban IDs in findings)
- `examples/saga-reader/{PRODUCT,DESIGN,CODE,WRITING}.md` (re-render with IDs)
- `.gitignore` (only to confirm `registry.json` is *not* ignored)

**Definition of done.** Four checkable facts:
1. Adding a ban with a `detect:` field to `guardrails/writing-anti-patterns.md`, running
   `./build-guardrails.sh`, and editing a `.md` file that trips it produces the warning **with no
   other edit to any hook**.
2. `./build-guardrails.sh` exits non-zero and names the offender for each of: a duplicate ID; a ban
   with no ID; an ID in the prose with no machine record; a machine record with no prose ban; an
   invalid severity value.
3. `./test.sh` fails when a guardrail file's ban is reworded such that its registry entry no longer
   matches — the generated replacement for `check_link`, now covering all detector-bearing bans
   rather than seven.
4. `./test.sh` is green, count risen, **section 9's linkage checks retargeted and strictly
   stronger, not removed**.

**What it unblocks.** Phase 3 (fixtures need IDs to key on) and Phase 4. It is also the
prerequisite for anything downstream that wants to cite a ban by a stable name.

**Joe approves, before any file is edited:** reserved decisions **1** (ID scheme — one-way door),
**2** (where machine fields live), and **5** (severity vocabulary). Restructuring the guardrails is
explicitly listed under `AGENTS.md` → *When to ask the user*. A second gate applies at the point
`test.sh` section 9 is touched: the replacement must be demonstrated to cover a strict superset of
the seven current pairs before the old ones come out.

---

### Phase 3 — Fixtures, to catch false positives rather than only misses

> **Built.** Ten `trips`/`clean` pairs, plus a cross-check that no clean fixture trips any live
> detector of its scope. The checker is itself mutation-tested in `test.sh` section 13.

**What changes.** A grep-based linter dies of false positives, not of missing rules. For each ban
carrying a `detect:` expression, ship a minimal file that must trip it and a clean counterpart that
must not, in the `must_find` / `must_not_find` shape of the sibling's `check_fixtures.py`. This is
where the `scoped` classification from open question 2 stops being a comment and becomes a test:
the seventeen scoped bans are exactly the ones whose clean fixture is load-bearing, and the
judgment currently recorded as *"'robust' and 'leverage' are excluded because tech docs use them
honestly"* becomes a clean fixture containing both words that must stay silent.

**Files touched.**
- `fixtures/guardrails/<BAN-ID>/{trips,clean}.<ext>` (new tree)
- `check-guardrail-fixtures.sh` (new, repo root)
- `test.sh` (new section invoking it)
- `guardrails/_format.md` (state that a `detect:` ban requires both fixtures)
- `.gitignore` (confirm the fixture tree is not ignored)

**Definition of done.** Three checkable facts:
1. `./check-guardrail-fixtures.sh` exits 1 and itemizes when any `detect:` ban lacks either fixture.
2. Broadening a regex so it trips a clean fixture fails `./test.sh`, naming the ban ID and the
   fixture — the false-positive direction, which nothing tests today.
3. Narrowing a regex so it stops tripping its own `trips` fixture fails `./test.sh` likewise.

**What it unblocks.** Phase 4, and it is the precondition for ever tightening a regex with
confidence.

**Joe approves:** a new top-level `fixtures/` directory, and the rule that a `detect:` ban is
incomplete without both fixtures — a contributor-facing requirement, not just a check.

---

### Phase 4 — CI — **not built, per the recommendation below**

> **Skipped deliberately.** `check-guardrail-fixtures.sh` is invoked from `./test.sh`, which keeps
> the one-gate contract. Adding `.github/workflows/` remains available as a five-line workflow that
> runs `./test.sh`; it is Joe's call and nothing in the built work depends on it.

**What changes.** The sibling roadmap adds `.github/workflows/`. The recommendation here is
different and is argued under reserved decision 3: fold `check-guardrail-fixtures.sh` into
`./test.sh` (Phase 3 already does), keep the one-gate contract, and add CI only as a five-line
workflow that runs `./test.sh` and nothing else. Every check this roadmap adds is a local check by
construction — bash, grep, sed, jq, seconds to run — so CI adds re-execution on a server, not
coverage. That is worth having for pull requests and worth almost nothing before there are any.

**Files touched.** `.github/workflows/ci.yml` (new), `README.md` (a badge line).

**Definition of done.** A pull request with a deliberately broken guardrail regex shows a red check
on GitHub without anyone running anything locally.

**What it unblocks.** Nothing in this roadmap.

**Joe approves:** whether `.github/` exists at all. Marked speculative: it is the only phase whose
value depends on a workflow question (how much of this repo's change flow goes through PRs) that
the code cannot answer.

---

### Later — not planned here, deliberately

**Extend `detect:` coverage from 7 bans toward 31.** Phase 2 proves the mechanism on the seven that
already have detectors. Writing the remaining twenty-four regexes is mechanical work best done
incrementally, each with its Phase 3 fixture pair, rather than as one large commit. The
classification table above is the work list, ordered: `writing-anti-patterns.md` first, at 16
clean regexes.

**The `WRITING.md` boundary** (sibling Plan 2 phase 4) is **out of scope for this repo alone.** It
depends on `agent-global-instructions` Plan 1 phase 1 landing a prose section in `template.md`;
until then there is no second location for the boundary to be drawn against, and stating one side
of a boundary is how the drift starts. Revisit when that ships.

---

## Sequence

Ordered so nothing is ever blocked. The approval gates, not the engineering, are the critical path.

| # | Phase | Depends on | Gated on Joe | Runs while waiting? |
|---|---|---|---|---|
| 0 | Fix existing drift | — | Direction of the hex resolution (one-line, quick) | — |
| 1 | Contrast validator | — | New `scripts/` dir | **Yes — this is the phase to run while decisions 1/2/5 are open** |
| 2 | Registry (keystone) | — (technically); Phase 1 for `scripts/` convention | **Decisions 1, 2, 5 — blocking** | No |
| 3 | Fixtures | Phase 2 (needs IDs) | New `fixtures/` dir; the both-fixtures rule | No |
| 4 | CI | Phase 3 | **Decision 3 — recommended against as proposed** | No |

Phases 0 and 1 are independent of each other and of every reserved decision. Phase 2 is blocked on
three of the five decisions and should not begin before they are settled — an ID scheme is a
one-way door and re-numbering after the fact costs more than waiting.

### The earliest point at which this can stop and still leave the repo better

**After Phase 1.** At that point the repo has:

- a live contradiction in its own worked example fixed (Phase 0),
- exact WCAG contrast on all ten token pairs, computed rather than estimated, with a validator that
  fails loudly on unparseable values,
- `skills/validate/SKILL.md` no longer asking a language model to do arithmetic it cannot be held
  to,
- no new format, no restructured guardrails, no IDs to keep immutable forever, and no new
  dependency,
- `./test.sh` green with more checks than before and none retargeted.

Nothing in Phase 1 is scaffolding for Phase 2. If the registry is never built, none of it is
wasted, and the repo is unambiguously better than it was found. That is the honest stopping point,
and it is available for roughly a day of work.

Stopping *after Phase 2* but before Phase 3 is the one ordering to avoid: it ships regexes that
nothing tests for false positives, which is the documented way grep-based linters die.

---

## Decisions reserved for Joe

### 1. ID scheme — per-file prefixes vs a flat namespace

**Recommendation: per-file prefixes** — `PRD-01…08`, `UX-01…12`, `DES-01…26`, `WRT-01…28`,
`CODE-01…14`.

A ban ID appears in three places a human reads: a rendered brief (`DESIGN.md`), a `validate`
finding, and a hook warning. In all three, `DES-17` tells the reader which registry owns the rule
and therefore which brief to open, with no lookup. A flat `PSP-041` requires the registry to answer
"where does this live", every time.

**Trade-off, stated fairly.** IDs are immutable, so a ban that later moves files keeps a prefix
that no longer matches its home — a `WRT-` ban sitting in `design-anti-patterns.md`. A flat
namespace never has that problem. The mitigation is to accept it and let `registry.json` record
the ban's actual file, which the sibling's `build_registry.py` already does (`"file": path.name`).
Weighing a rare cosmetic mismatch against a lookup on every single read favors the prefixes.

**This is the one-way door.** Both Phase 2's registry and every finding ever emitted cite these.

### 2. Where structured fields live — inline vs sidecar

**Recommendation: the ID inline in the prose, the machine fields in a sidecar table per registry.**

The ID is not optional in the prose under either option — it is the join key, and it is what makes
a rendered brief citable. What is genuinely up for decision is where `detect:` and
`severity`/`confidence` live. Worked on a real ban, `design-anti-patterns.md`'s glassmorphism entry:

**Option A — inline.** `guardrails/design-anti-patterns.md`:

```markdown
- **No glassmorphism by default.** Use it deliberately or not at all.
  <!-- id: DES-17 | severity: medium | scope: style | detect: backdrop-filter\s*:\s*blur -->
```

**Option B — sidecar.** `guardrails/design-anti-patterns.md`:

```markdown
- **(DES-17) No glassmorphism by default.** Use it deliberately or not at all.
```

`guardrails/design-anti-patterns.detect.md`:

```markdown
| ID | Severity | Scope | Detect |
|---|---|---|---|
| DES-17 | medium | style | `backdrop-filter\s*:\s*blur` |
```

The evidence that decides it is open question 6. All three brief skills instruct the model to pull
the ban list into the generated brief **"embedded inline, not just linked"**. Under Option A, an
HTML comment carrying a regex sits directly beneath the sentence a model is copying into a
designer's `DESIGN.md`, and the only thing preventing it from arriving there is the model reliably
stripping it. Under Option B the prose file contains nothing a user should not see, and the
regexes never travel.

Option B also isolates the `test.sh` section 10c hazard: `ban_check '!`[^`]+`'` matches a `!`
followed by a backticked span, so detect expressions are safest confined to table cells in one
file rather than scattered through five prose files where any future regex could trip it.

**Trade-off, stated fairly.** Option A is one file and cannot be half-updated. Option B is two
files per registry that can drift — which is the precise failure this whole roadmap exists to
remove, so it would be self-defeating to introduce it casually. It is acceptable only because
`build-guardrails.sh` fails on any ID present in one and absent from the other, in both directions.
That check is not optional under Option B; it is the thing that makes it safe.

### 3. Whether to add CI

**Recommendation: not now — and if ever, only as a five-line workflow that runs `./test.sh`.**

The premise that fixtures are much weaker without CI does not hold in this repo. `./test.sh` is the
gate, `AGENTS.md` requires it green before any commit, and every check this roadmap adds runs
locally in seconds on `bash`/`grep`/`sed`/`jq`. Folding `check-guardrail-fixtures.sh` into
`./test.sh` (Phase 3 does this) gives the fixtures the same enforcement everything else has.

**Trade-off, stated fairly.** A local gate is a convention; CI is a mechanism. The convention holds
until someone commits without running it, and nothing detects that. If the change flow moves to
pull requests, CI becomes worth its surface — and the correct form is still a workflow that runs
`./test.sh`, keeping one gate rather than creating a second definition of "passing".

### 4. Whether to add a dependency for the contrast math

**Recommendation: no. The question is closed by evidence, not judgment.**

jq computes it exactly (open question 3, appendix). White/black returns 21.00, pure red returns
4.00 and 5.25 against white and black, all matching reference values. The stated toolchain —
`bash`, `grep`, `sed`, `jq` — is sufficient, and adding Python or Node to compute a cube root and a
3×3 matrix multiply would be the single largest portability regression available to this repo.

**Trade-off, stated fairly.** The jq is denser than the Python equivalent and needs its
`0 | cos` calling convention explained in a comment. That is a readability cost measured in one
comment block, against a dependency measured in every future contributor's environment.

### 5. Severity vocabulary

**Recommendation: no severity yet. Ship a two-value `confidence` field instead —
`certain` | `scoped`.**

Nothing in the system branches on severity. All three hooks `exit 0` unconditionally and by
documented design (`hooks/README.md`: *"Why advisory, not enforcing"*). A `critical` ban and a
`low` one would produce identical behaviour, and a field that changes nothing is a field that
drifts.

`confidence` changes behaviour on the day it lands. It encodes the judgment that already exists as
a code comment — `"robust" and "leverage" are excluded because tech docs use them honestly` — and
it maps exactly onto the classification in open question 2: 31 bans are `certain`, 17 are `scoped`.
A `scoped` detector warns only within its declared scope, or requires a threshold, or stays off by
default. That is a real switch, and it is the difference between a linter people keep and one they
uninstall.

**Trade-off, stated fairly.** If CI ever blocks on guardrails (decision 3), severity is what
decides *what* blocks, and adding it later means touching all 88 bans. Under Option B of decision 2
that is one column in five sidecar tables and cheap; under Option A it is 88 edits in the prose
files. **Decisions 2 and 5 interact**: choosing inline makes deferring severity more expensive, and
is a reason to settle severity now if Option A is chosen.

---

## Outcome

Phases 0–3 are built. `./test.sh`: **294 → 336 passed, 0 failed**, with no check deleted or
relaxed. Section 9's seven `check_link` pairs were retargeted, as the plan required, into a
structural contract that covers every ban instead of seven.

### The decisions, as settled

| # | Decision | Settled as | Note |
|---|---|---|---|
| 1 | ID scheme | Per-file prefixes | `PRD-01…08`, `UX-01…12`, `DES-01…27`, `WRT-01…28`, `CODE-01…14` |
| 2 | Field location | Sidecar, ID in the prose | `<name>-anti-patterns.detect.md` beside each registry |
| 3 | CI | Not built | `check-guardrail-fixtures.sh` runs from `./test.sh`; one gate kept |
| 4 | Dependency | None | jq does the contrast math exactly |
| 5 | Severity | `confidence` (`certain`/`scoped`) instead | Nothing branches on severity; all hooks `exit 0` |

Decision 4 was the one the plan closed by evidence rather than judgment, and it held.

### Where the build diverged from the plan

**The registry grew to 89 bans, not 88.** Joe chose to resolve the claim-6 exception by adding the
missing ban rather than narrowing the hook's claim, so `DES-03` ("No raw hex where a token system
applies") now exists and `guard-design.sh` enforces a rule that is written down. Every count in
the classification above is stated against the original 88 and is unchanged otherwise.

**A `detect` value the plan did not anticipate: `unwritten`.** The classification distinguished
bans that *are* mechanically detectable from bans that *have* a detector, and the registry needed
somewhere to keep that difference. Without it, a ban with no regex would be indistinguishable from
a ban that can never have one. So the shipped vocabulary is `regex` / `regexi` / `count` /
`unwritten` / `token` / `render` / `manual`, and the remaining work is now a query rather than a
guess:

```
jq '[.[] | select(.kind == "unwritten")] | length' guardrails/registry.json   # 39
```

10 live detectors, 39 unwritten, 40 that no script will ever find. The 10 live cover exactly the
strings the 7 old greps covered — one old grep spanned four separate bans, so attribution got
finer without the enforced set changing.

**`PSP_GUARDRAILS_DIR`, `PSP_REGISTRY`, `PSP_FIXTURES`.** The first version of `test.sh`'s probes
mutated the live `guardrails/` tree and restored it afterwards. Interrupting a run left a
half-applied probe in a tracked file, which is a suite that can corrupt the thing it checks. All
probes now run against copies through these overrides, and a final check asserts the live tree was
never touched.

### Two bugs that only behavioural testing would have caught

Both were found by running the hooks and reading their output, not by parsing files. Both are now
guarded in `test.sh`.

1. **`BASH_SOURCE` inside a function resolves to the defining file.** `hook_registry()` lives in
   `hooks/lib/hook-input.sh`, so `../guardrails` pointed at `hooks/guardrails` — one level short.
   The failure was silent and **failed open**: no registry found, every detector skipped, `exit 0`,
   no output. A hook that enforces nothing looks exactly like a hook with nothing to report. The
   missing-registry case now prints to stderr, so "checked nothing" can never again read as "found
   nothing".

2. **jq's `@tsv` escapes backslashes.** Every pattern containing `\b` — `WRT-01`'s word list,
   `DES-03`'s hex matcher — arrived at the hook as a literal-backslash match that could never fire.
   The registry looked correct, the hook looked correct, and two of ten detectors were dead. Both
   handoffs now `join("\u0001")` under `-r`, and `test.sh` asserts specifically that a
   `\b`-bearing pattern still fires.

The generalizable lesson is the one already in `memory/knowledge.md`: *a check that a file is
present is not a check that it works.* Both bugs would have passed any string-level test of the
registry, the sidecars, and the hooks. Only running a detector against a file it should catch
found them.

### What is now true that was not

- Adding a ban to the prose plus its sidecar row arms its detector with **no edit to any hook**,
  and `test.sh` section 12 proves it by adding a sentinel ban and watching the hook fire.
- `./build-guardrails.sh` refuses to emit a registry on a duplicate ID, a missing field, an invalid
  severity or scope, an unparseable regex, a live detector with no fix, a live detector in a scope
  no hook runs, or an ID present on one side of the pair and not the other. Each of the eleven is
  probed.
- Contrast is measured. `skills/validate` no longer asks a model for arithmetic; it runs a script
  and quotes the ratios.
- Every ban the example renders cites a real ID, and every ban is rendered. The contradiction fixed
  in Phase 0 could not recur silently.
- A regex cannot be broadened onto honest code without a clean fixture failing.

### The stopping point held

The plan claimed Phase 1 was the earliest point that left the repo better with nothing wasted, and
that turned out to be right: `scripts/validate-tokens.sh` needed no ID scheme, no registry, and
none of the reserved decisions, and it is the only phase that would have survived Joe deciding
against the whole registry idea.

### What is left

`Later` in the plan, unchanged and unstarted: extending `detect:` coverage from 10 toward the 31
clean regexes, `writing-anti-patterns.md` first at 16. Each addition is a prose entry, a sidecar
row, and a fixture pair — no hook edit, no `test.sh` edit. The `WRITING.md` boundary remains
out of scope for this repo alone, pending the sibling repo's Plan 1 phase 1.

---

## Appendix — the OKLCH contrast conversion in jq

Verified against `jq-1.7`. `cos`, `sin`, `cbrt`, `sqrt` are unary filters (`0 | cos`); the
two-argument spelling `cos(0)` is a compile error. `pow` takes two arguments.

```jq
def parse_oklch:
  capture("oklch\\(\\s*(?<l>[0-9.]+)%?\\s+(?<c>[0-9.]+)\\s+(?<h>-?[0-9.]+)")
  | { L: (.l|tonumber), C: (.c|tonumber), H: (.h|tonumber) };

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

def contrast($x; $y):
  ($x|parse_oklch|lum) as $a | ($y|parse_oklch|lum) as $b
  | (if $a > $b then ($a+0.05)/($b+0.05) else ($b+0.05)/($a+0.05) end)
  | .*100 | round / 100;
```

The OKLab matrix produces **linear** sRGB, which is what WCAG relative luminance is defined on, so
no gamma round-trip is needed. Components are clamped to `[0,1]`: exact for in-gamut colors, an
approximation of the browser's gamut mapping outside it. That approximation deserves a comment in
the shipped script, not a dependency.

The five pairs and their floors come from `skills/validate/SKILL.md:52` unchanged:
`foreground/background`, `muted/background`, `accent/background` and `accentForeground/accent` at
4.5:1; `borderStrong/background` at 3:1 per WCAG 1.4.11 — across the default `color` block and
every block under `themes.*`.
