# Evals — Saga

Each case is one rule from this project's briefs, a prompt that tests whether an agent
follows it, and a pass/fail pair of examples in `goldens/<ID>/`. `./evals/run.sh` reads
this file directly. See `README.md` for how to add a case and run the suite.

IDs are stable: never renumber. Only `status: confirmed` cases gate.

---

## EV-01 — Colors come from the tokens, never raw hex

source: DES-03
file: DESIGN.md
anchor: No raw hex in style files; colors come from the `DESIGN.json` OKLCH tokens.
kind: agent
status: confirmed
origin: seeded by setup 2026-10-28 from DESIGN.md (UI Anti-patterns)
prompt: Add a quiet "destructive" variant to the Button primitive, for deleting a highlight.
check: regex::[[:space:]]*[^;{}]*#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b
judge: Does every color in the change come from the DESIGN.json OKLCH tokens rather than a literal value?

## EV-02 — Deleting offers undo, never an "Are you sure?" modal

source: UX-01, UX-02
file: DESIGN.md
anchor: Undo over confirm (**UX-01**, **UX-02**)
kind: agent
status: confirmed
origin: seeded by setup 2026-10-28 from DESIGN.md (Interaction principles)
prompt: Add a way to delete a highlight from the Marks view.
check: none
judge: Does deleting happen immediately with an inline "Deleted · Undo" toast, with no confirmation dialog?

## EV-03 — Copy uses the reader's words

source: WRITING.md (Vocabulary & terminology)
file: WRITING.md
anchor: Use the reader's words, exactly as their mental model has them
kind: agent
status: confirmed
origin: seeded by setup 2026-10-28 from WRITING.md (Vocabulary & terminology)
prompt: Write the empty state for the Marks view, shown before the reader has highlighted anything.
check: none
judge: Does the copy use only the reader's words (book, chapter, page, highlight, note, tag), in sentence case, with the primary action inline — and never "session", "annotation", "content", "item", or "upload"?

## EV-04 — No AI-flagship words in anything a reader sees

source: WRT-01
file: WRITING.md
anchor: AI-flagship words
kind: agent
status: confirmed
origin: seeded by setup 2026-10-28 from WRITING.md (writing bans)
prompt: Write the in-app release note announcing search in Marks.
check: regexi:\b(delve|delves|delving|tapestry|paradigm shift|game.changer)\b
judge: Is the note plain and declarative, the way a well-edited book sounds, with no hype or filler?

## EV-05 — Bringing readers back stays calm

source: UX-08, PRODUCT.md (Design principles)
file: PRODUCT.md
anchor: **Calm over engagement.** No streaks, no badges, no notifications that manufacture urgency.
kind: agent
status: unconfirmed
origin: seeded by setup 2026-10-28 from PRODUCT.md (Design principles)
prompt: Design and build a feature that helps readers return to books they haven't finished.
check: none
judge: Does the feature avoid streaks, badges, counters and urgency, and instead show the exact place to pick up?

## EV-06 — No silent type widening at the import boundary

source: CODE-12
file: CODE.md
anchor: **CODE-12 Silent type widening**
kind: agent
status: unconfirmed
origin: seeded by setup 2026-10-28 from CODE.md (Code anti-patterns)
prompt: Add support for importing a book from a plain-text file.
check: none
judge: Is untrusted input validated at the import boundary with real types — no `as any`, no bare `@ts-expect-error`, no coerced `unknown`?
