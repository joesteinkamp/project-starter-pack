# Project Anti-patterns

These are the project-scoping mistakes that quietly burn quarters. The starter-pack rejects them by default; if a project has a deliberate reason to override one, document the reason in `PROJECT.md`.

## 1. Output-as-goal

> "Ship the new checkout page."

A goal should describe the outcome — what changes for users or the business — not the artifact being produced. Rewrite as a result: "Reduce checkout abandonment from X% to Y%." If the artifact is the only thing that matters, the project is decoration.

## 2. Missing or generic non-goals

> "Keep it small."

Without explicit non-goals, every adjacent idea becomes "while we're in there". Non-goals must name actual work being refused: "Not in scope: account settings redesign, mobile-app parity, i18n." Anything less doesn't constrain anything.

## 3. Success metrics inherited wholesale

A project's success metrics are a **slice** of `PRODUCT.md` — sized to the initiative's time horizon and surface area. Copying the product-level metrics verbatim ("7-day retention up 10%") onto a 3-week project sets up a guaranteed miss and obscures whether the project itself worked.

## 4. Decisions log used as a journal

The decisions log is an append-only ledger of resolved choices, not a meeting transcript. One line per decision, dated, with the reason in under ten words. Long narratives belong in docs or PRs, not here.

## 5. Vanity deadlines

A deadline without a reason ("end of Q2") is a wish. Every constraint in `PROJECT.md` should carry the reason it exists — a launch event, a dependency unlock, a contractual date. Constraints without reasons get ignored under pressure and discredit the brief.

## 6. Scope slice that names everything

If the design surfaces and code subsystems list every section of `DESIGN.md` and `CODE.md`, this isn't a project — it's the product. Initiatives that touch everything don't ship. Cut.

## 7. Open questions with no owner and no deadline

Open questions without an owner stay open. Either assign one or move the question off the brief. The list should shrink, not grow.

## 8. "Phase 2" placeholders

> "Out of scope: phase 2."

"Phase 2" is the graveyard. Either the work is in scope or it's a non-goal — naming a phantom future phase commits to nothing and leaves the door open for scope creep.
