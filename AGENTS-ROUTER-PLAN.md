# AGENTS.md-as-router plan — remove the orchestrator

**Baseline:** this plan assumes PORTABILITY-PLAN.md has landed — skills are the canonical
engine, the canonical output is `AGENTS.md`, Gemini is gone, `install.sh` / `render-ports.sh`
exist, and `conventions/question-mechanics.md` defines shared mechanics.

**Goal:** delete the `orchestrator` flow (skill + command + Cursor port) entirely. In its
place, the generated `AGENTS.md` becomes a small, near-static **router**: it tells any agent
*which project file to read for which kind of work* instead of carrying synthesized copies
of the briefs' content.

```
- Building UI or UX?            → read DESIGN.md (and DESIGN.json for tokens)
- Writing copy or content?      → read WRITING.md
- Product or brand decisions?   → read PRODUCT.md
- Code, stack, or architecture? → read CODE.md
```

**Why:** the orchestrator existed to synthesize brief content into one file. That synthesis
is (a) a drift machine — edit `DESIGN.md` and `AGENTS.md` is silently stale until someone
re-runs a flow — and (b) unnecessary, because agents can read the briefs directly; they just
need to be told *when*. A router has no synthesized content, so it never goes stale and never
needs regenerating. This is a **local** `AGENTS.md` — the project layer for one repo — not a
global instructions file; the layering note stays.

---

## The new AGENTS.md shape

Rewrite `templates/AGENTS.template.md` as:

| Section | Content | Slot? |
|---|---|---|
| Header + layering note | Same convention/derivation notes; layering text now **baked in** (see "Layering note" below) | static |
| Project summary | 2–3 sentences from `PRODUCT.md`'s one-liner | `{{PROJECT_SUMMARY}}` |
| **Routing table** | The core: per kind of work, which file to read before starting — DESIGN.md for UI/UX, WRITING.md for any user-facing words, PRODUCT.md for product/brand decisions, CODE.md for stack/conventions; DESIGN.json noted as the token companion when present | static |
| Ground rules | "Read the routed file *before* generating, not after"; don't invent context that contradicts a brief; ask when briefs conflict or don't cover the request | static |
| AI slop self-check | Kept verbatim — it's harness- and project-independent | static |
| When to ask the user | Kept verbatim | static |
| Maintaining these files | Briefs are the source of truth — edit them directly or re-run the matching flow (`product-brief`, `design-brief`, `code-brief`); pack location + per-tool invocation | `{{REGENERATION_NOTE}}` |

**Dropped from AGENTS.md** (agents now read the source instead): `{{PRODUCT_CONTEXT}}`,
`{{UX_LAWS}}`, `{{DESIGN_LAWS}}`, `{{ACCESSIBILITY_LAWS}}`, `{{CODE_CONVENTIONS}}`, and all
five `{{*_ANTI_PATTERNS}}` embeds. Accessibility gets one static routing line ("the WCAG
commitment lives in PRODUCT.md; the keyboard/motion/target rules in DESIGN.md — read both
before shipping UI") so the commitment stays discoverable from the one file every agent reads.

Two slots survive, both fillable by any flow in under a minute. `AGENTS.md` stops being a
synthesized artifact and becomes furniture.

## Anti-patterns move fully into the briefs

The bans must stay one hop from the router. Today three of four owning files already embed
their lists inline; close the gap:

- `DESIGN.template.md` — has `{{DESIGN_ANTI_PATTERNS}}` (+ UX bans woven into flows). ✔ no change
- `CODE.template.md` — has `{{CODE_ANTI_PATTERNS}}`. ✔ no change
- `WRITING.template.md` — has `{{WRITING_ANTI_PATTERNS}}`. ✔ no change
- `PRODUCT.template.md` — **add `{{PRODUCT_ANTI_PATTERNS}}`** (an "Anti-patterns" section),
  filled by the `product-brief` skill from `guardrails/product-anti-patterns.md`, same
  embedded-inline rule as the others.

The router's routing table notes that each brief carries its own ban list, so "read the file"
also means "see the bans".

## WRITING.md gets a new owner: the design-brief

The orchestrator synthesized `WRITING.md` from `PRODUCT.md` + `DESIGN.md`. New owner:
**`design-brief` emits it as a second companion file** (exactly like it already optionally
emits `DESIGN.json`), in a short final "Writing companion" step — both source briefs are on
disk by the time the design flow finishes. The `{{WRITING_*}}` slot definitions move verbatim
from `skills/orchestrator/SKILL.md` into `skills/design-brief/SKILL.md`.

- *Considered and rejected:* a standalone `writing-brief` flow (an eighth skill + command +
  port for ~5 slots — ceremony without payoff), and folding it into `product-brief`
  (microcopy rules need `DESIGN.md`'s components and flows, which don't exist yet).

## Who writes AGENTS.md (and the harness pointer files)

`AGENTS.md` is the single source of truth. Every harness that reads it natively (Codex,
Cursor, Antigravity, Copilot) gets nothing extra. Every harness with **its own filename
convention** gets a **thin pointer file** whose only job is to route into `AGENTS.md`:

| File | Pointer mechanism | Extras |
|---|---|---|
| `CLAUDE.md` | `@AGENTS.md` import | the pack's flow/command list (test.sh §7 binds it) + `{{HARNESS_PROJECT_NOTES}}` |
| *(future tools)* | same pattern — a new pointer template per filename convention, never new content | — |

Each pointer file is a few lines: the import/`read AGENTS.md first` line, a "derived — edit
the briefs, not this file" note, and nothing that duplicates `AGENTS.md`. `GEMINI.md` stays
dead (Gemini CLI is deprecated; the portability plan already deleted its template) — if a
live tool with its own filename convention appears, it gets a pointer template on this
pattern.

- **`setup`** — step 5 ("Orchestrate") is replaced by a lightweight **"Wire up"** step: fill
  the two slots, write `AGENTS.md` + **all pointer files**, print the summary. No harness
  picker — the pointers are one-liners, so **always write them all**, no question asked.
- **Every brief flow** — on Done, if `AGENTS.md` is missing, write it (and the pointer files)
  from the templates (`{{PROJECT_SUMMARY}}` from `PRODUCT.md` if present, else a
  `[TODO — run product-brief]` marker). Idempotent and cheap; covers users who run a single
  brief without `setup`.
- **Cursor scoped rules** (`.cursor/rules/project.mdc`) — **delete the template and option.**
  Its whole purpose was inlining `{{AGENT_BODY}}`; with a router that Cursor reads natively
  via `AGENTS.md`, it duplicates a file that no longer has a body to inline.

### Layering note

The canonical note lived in `skills/orchestrator/SKILL.md`. It moves to being **baked into
`AGENTS.template.md`** with the generic `<global layer>` pointer ("the operator's own global
instructions"). Pointer files don't restate it — they import `AGENTS.md`, which carries it.
The `{{LAYERING_NOTE}}` slot disappears everywhere. test.sh §6's "the project layer wins"
render check retargets to `AGENTS.md` only.

## Removals and ripples

**Delete:** `skills/orchestrator/`, `commands/orchestrate.md`,
`commands/cursor/starter-orchestrate.md` (regenerated out by `render-ports.sh`),
`templates/cursor-rules.template.mdc`, `examples/saga-reader/.cursor/rules/`.

**Update every remaining reference** (current grep hits for `orchestrat`):

| File | Change |
|---|---|
| `skills/setup/SKILL.md` | Step 5 → "Wire up"; resume list drops `orchestrator`; "sections left as TODOs" note now refers to brief files, not AGENTS.md sections |
| `skills/code-brief/SKILL.md` | "Next:" line → "run `setup` to finish, or the pack wires AGENTS.md automatically" |
| `skills/extract/SKILL.md` | Next-steps → validate, then the flows; no orchestrate |
| `skills/validate/SKILL.md` | `WRITING.md` byline: derived by `design-brief`, not orchestrator |
| `templates/CLAUDE.template.md` | Drop `/starter:orchestrate` + `orchestrator` skill from the advertised lists; "re-run the orchestrator flow" → "edit the briefs / re-run the matching brief flow" |
| `templates/AGENTS.template.md` | Full rewrite (router, above) |
| `templates/WRITING.template.md` | Byline: generated by the `design-brief` flow |
| `install.sh`, `render-ports.sh` | Nothing manual — orchestrator disappears from the skill/command sets they enumerate |
| `README.md`, `INSTALL.md`, `examples/README.md`, `hooks/README.md` | Command list, "What you get" table (owners change: AGENTS.md → setup/any flow; WRITING.md → design-brief; pointer files always written), harness section (no picker), "AGENT.md embeds the bans" → "the briefs embed the bans" |
| `examples/saga-reader/` | Re-render `AGENTS.md` as the router; `CLAUDE.md` as a pointer; update `WRITING.md` byline; delete the `.cursor` render |

**test.sh rewiring:**

- **§2** (orchestrator ↔ synthesized templates): retarget — every slot in
  `AGENTS.template.md` and `CLAUDE.template.md` must be named by `skills/setup/SKILL.md`;
  every `{{WRITING_*}}` slot by `skills/design-brief/SKILL.md`.
- **§4** (guardrail wiring): "embedded by orchestrator" → each `guardrails/*-anti-patterns.md`
  must be embedded by its **owning brief template/skill** (product → PRODUCT, ux+design →
  DESIGN, writing → WRITING, code → CODE).
- **§6** (example structure): follows the new templates automatically; drop the optional
  `.cursor/rules/project.mdc` check.
- **§7** (parity): drop `/starter:orchestrate` expectations; add the inverse guard — the
  string `orchestrat` must appear **nowhere** in `skills/`, `commands/`, `templates/`
  (grep-able ban, same style as the existing checks).
- **New:** `AGENTS.template.md` must contain a routing line for each of the four brief files
  (`PRODUCT.md`, `DESIGN.md`, `CODE.md`, `WRITING.md`) — the router can't silently lose a route.

## Migration (pre-flight, in setup and each brief flow)

If the project root has a legacy **synthesized** `AGENTS.md` or `AGENT.md` (detectable by its
`## UX laws` / `## Design laws` headings), offer once: replace with the router (recommended —
content it carried lives in the briefs) or keep it untouched. Never overwrite silently; a
hand-written `AGENTS.md` (no such headings) always gets the keep-or-replace question.

## Sequencing

| Order | Step | Size |
|---|---|---|
| 1 | Router `AGENTS.template.md` + bake layering note + product bans slot + `CLAUDE.md` pointer template | S |
| 2 | WRITING.md → design-brief; setup "Wire up" step; brief-flow AGENTS.md fallback | M |
| 3 | Deletions + reference sweep (table above) | M |
| 4 | test.sh rewiring + example re-render | M |

One commit per step, `./test.sh` green at each; test changes land with the step they guard.

## Open decisions (for Joe)

1. ~~Always write `CLAUDE.md`?~~ **Decided:** every harness with its own filename convention
   gets a thin pointer file into `AGENTS.md`, always written — no picker. ~~Include
   `GEMINI.md`?~~ **Decided:** no — Gemini CLI is deprecated; `CLAUDE.md` is the only
   pointer shipped today.
2. **Cursor scoped rules:** confirm deleting `.mdc` outright vs. keeping a thin pointer
   variant. Recommended: delete — `AGENTS.md` is read natively and there's no body to scope.
3. **WRITING.md owner:** confirm design-brief-companion over a standalone `writing-brief`
   flow.
4. **Pointer roster:** beyond `CLAUDE.md`, also cover other own-filename tools (e.g.
   Windsurf's `.windsurfrules`, Cline's `.clinerules`)? Recommended: not yet; the pattern
   makes adding one a 5-line template whenever a tool earns it.
