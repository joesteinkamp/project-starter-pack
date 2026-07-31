# Setup-as-front-door plan — fold the brief commands into `/setup`

**Baseline:** this plan assumes AGENTS-ROUTER-PLAN.md has landed — the orchestrator is gone,
`setup`'s final step is the lightweight "Wire up", `design-brief` owns `WRITING.md`, every
brief flow writes `AGENTS.md` + pointer files as a fallback, and `AGENTS.md` is a router.
Land this *after* router step 4; don't interleave the two executions.

**Goal:** delete the three brief **commands** — `commands/product-brief.md`,
`commands/design-brief.md`, `commands/code-brief.md` (and their generated Cursor ports).
`setup` becomes the single command front door, gaining a **scope option**: run everything,
or just the brief(s) you pick. The three brief **skills stay** — they remain the engine
that `setup` delegates to.

**Why:** the brief commands are three-line wrappers whose only content is "invoke the
skill". "Which brief do I want" is a choice, not a namespace — it belongs *inside* the one
flow as a question, not spread across four commands the user must know exist. Collapsing
them shrinks the command surface (and its port/parity/doc footprint) from six entries to
three: `setup`, `extract`, `validate` — generate, seed, check.

**Why the skills stay** (considered and rejected: folding their bodies into
`skills/setup/SKILL.md`):

- **Codex has no command surface** — `$product-brief` runs the skill directly and is the
  *only* invocation there. Deleting the skills breaks Codex; deleting the commands changes
  nothing for it.
- Natural-language triggers ("walk me through the product brief") in Claude Code and
  Antigravity resolve to skill descriptions, not commands.
- `setup`'s own rule — "each sub-flow owns its questions, guardrails, defaults, and
  preview; don't re-implement them here" — is what keeps `setup/SKILL.md` small. Inlining
  three flows would produce one giant file and strand the cross-references in `validate`,
  `extract`, and the flows' own hand-offs.

---

## The new setup flow

`skills/setup/SKILL.md` gains a **step 0 — Scope**, before the intro:

- **With no arguments:** ask one structured question (per `conventions/question-mechanics.md`):
  *"What should we run?"* — **Everything** (recommended; the three briefs then Wire up),
  **Product brief**, **Design brief** (UX + UI; also writes the `WRITING.md` companion and
  optionally `DESIGN.json`), **Technical brief**. Multi-select where the tool supports it,
  so "product + technical" is one run; single-select elsewhere ("Everything" covers the
  common multi case).
- **Disk-aware options:** before asking, check which briefs already exist and annotate each
  option ("PRODUCT.md exists — its flow will offer reuse / merge / overwrite"). When some
  briefs exist and others don't, recommend the missing ones instead of Everything.
- **Argument fast path:** `setup product` / `design` / `code` / `all` skips the question
  and runs that scope. `commands/setup.md` documents the mapping and passes `$ARGUMENTS`
  through; `render-ports.sh` already auto-emits the Cursor "type your input after the
  command" note the moment `$ARGUMENTS` appears. Unrecognized arguments fall back to the
  scope question.
- **Scoped sequence:** only the selected flows run, in brief order (product → design →
  code). The intro paragraph names just the selected scope; the brownfield `extract` offer
  fires only when the repo has code *and* the scope includes a brief that doesn't exist yet.
- **Wire up always runs** at the end, whatever the scope — it's idempotent (fill the two
  slots, write `AGENTS.md` + pointer files) and it's what keeps a single-brief run from
  leaving the router stale.
- **Done:** the summary lists files written *and* briefs still missing, each with its
  resume path: "run `setup` again and pick it" (plus the bare flow name, for tools that
  invoke skills directly).
- **On interruption:** same wording change — resume via `setup` + option, flow names as
  the skill-level alternative.

## Removals and ripples

**Delete:** `commands/product-brief.md`, `commands/design-brief.md`,
`commands/code-brief.md`. The Cursor ports (`commands/cursor/starter-*-brief.md`)
disappear on the next `render-ports.sh` run via its stale-port cleanup (they carry the
GENERATED marker); nothing manual.

| File | Change |
|---|---|
| `commands/setup.md` | Description gains the scope idea; body documents the `$ARGUMENTS` → scope mapping |
| `skills/setup/SKILL.md` | Step 0 Scope, scoped sequence, always-Wire-up, new Done/interruption wording (above) |
| `skills/product-brief` / `design-brief` / `code-brief` SKILL.md | No structural change — their "Next: the `X` flow" hand-offs already name flows, not commands. Sweep only for any `/starter:*-brief` string |
| `templates/CLAUDE.template.md` | Drop the three `/starter:*-brief` lines; the `/starter:setup` line documents the arg forms (`/starter:setup [product\|design\|code\|all]`); skill list unchanged (test §7 requires every skill listed) |
| `README.md` | Invocation table: the three brief rows' Claude/Cursor columns become `/starter:setup product` / `/starter-setup product` etc.; Codex (`$product-brief`) and Antigravity (natural language) columns unchanged. Command-count prose and quick-start snippets |
| `INSTALL.md` | Command roster shrinks to `setup`, `extract`, `validate`; the per-brief invocation note points at setup args or skill names |
| `templates/AGENTS.template.md` | "Maintaining these files" regeneration note: "re-run `setup` and pick the matching brief (or run the flow by name in tools that invoke skills directly)" |
| `examples/saga-reader/CLAUDE.md` | Re-render from the updated pointer template |
| `install.sh`, `render-ports.sh` | Nothing manual — both enumerate `commands/` |

Existing user projects need no migration: their `CLAUDE.md` pointer may advertise the dead
commands until any flow's Wire-up/fallback step next rewrites the pointer files, which
refreshes the list. Worth one line in the README's update notes, nothing more.

## test.sh rewiring

- **§7 parity needs no retarget** — both directions (`commands/*.md` → template line,
  advertised line → command file) are dir-driven, so deleting the commands and the
  template lines together keeps it green.
- **New grep ban**, same style as the `orchestrat` ban: `/starter:product-brief`,
  `/starter:design-brief`, `/starter:code-brief` (and the `starter-*-brief` port names)
  must appear nowhere in `skills/`, `commands/`, `templates/`, `README.md`, `INSTALL.md`.
- **New:** `skills/setup/SKILL.md` must name all three brief flows — the scope picker
  can't silently lose an option (mirror of the router's routing-line check).
- **New:** `commands/setup.md` must contain `$ARGUMENTS` — the fast path can't be
  silently dropped (it's also what triggers the Cursor args note in the port).
- §10e (`/starter:` confined to Claude-surface files) is unaffected.

## Sequencing

| Order | Step | Size |
|---|---|---|
| 1 | `setup` skill + command: Scope step, `$ARGUMENTS` mapping, Done/interruption wording | M |
| 2 | Delete the three commands + reference sweep (table above) + re-render ports & example | S |
| 3 | test.sh: grep ban + the two new setup checks | S |

One commit per step, `./test.sh` green at each; step 2's doc sweep and deletions land
together so §7 parity never breaks mid-sequence.

## Open decisions (for Joe)

1. **Scope question shape:** multi-select where supported, with "Everything" as the
   recommended first option — confirm, or force single-select everywhere for simplicity.
2. **Skill visibility:** confirm the three brief skills stay user-invocable (recommended,
   per the Codex/natural-language reasoning above) rather than becoming setup-internal.
3. **Scope creep line:** `validate` and `extract` keep their own commands — they're
   different verbs (check / seed) with their own entry reasons. Recommended: yes, leave
   them; fold later only if the same "thin wrapper" argument starts applying.
4. **Arg vocabulary:** `product | design | code | all` only. Recommended: keep it minimal;
   synonyms ("tech", "briefs") route through the fallback question instead of growing a
   parser.
