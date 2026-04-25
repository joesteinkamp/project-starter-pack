# UX Anti-patterns

The interaction-layer mistakes that make products feel hostile, fragile, or generic. The starter-pack rejects them by default.

## 1. Confirm-instead-of-undo

A modal asking "Are you sure?" is friction the user pays every time. Undo is friction the user pays only when they actually erred. Default to undo; reserve confirmation for irreversible actions.

## 2. Modal-first thinking

Modals interrupt. Most flows that "need" a modal actually want an inline panel, a route, or a side sheet. If you reach for a modal, ask whether the work is genuinely interruption-worthy.

## 3. Hidden state

If the user has done something, the UI should show it. Loading without a hint that loading is happening, success without an acknowledgment, errors that disappear in 2 seconds — all corrode trust.

## 4. Empty states that aren't empty states

A screen with "no items yet" and nothing else is a wasted opportunity. Empty states are the cheapest onboarding surface in the product.

## 5. Generic error messages

"An error occurred" tells the user nothing. Errors should name what failed, why, and what to do next.

## 6. Forms that re-validate on blur and only show errors at submit

Either validate as the user types (with care) or at submit (with care) — but be consistent and let the user fix one error at a time, not nine.

## 7. Click targets smaller than 44×44

Mobile baseline. Desktop can be smaller, but not so small that pointer accuracy becomes a skill check.

## 8. Dark patterns

Pre-checked opt-ins, sneak-into-cart, roach-motel cancellation flows, confirm-shaming. The starter-pack treats these as out-of-bounds regardless of business request.

## 9. Lossy navigation

Back button breaks. Refresh wipes state. URL doesn't reflect what's on screen. The browser's affordances are part of the UX; don't fight them.

## 10. Accessibility as cleanup

Treating WCAG as a thing you do at the end produces interfaces that pass audits and fail users. Build keyboard reachability and focus visibility into the first version of every component.

## 11. Onboarding as a tour

A four-step modal carousel teaches the user nothing they'll remember. Onboarding is a flow, not a tour. Show value on the first screen.

## 12. Recall-over-recognition

Asking the user to remember (a code, a name, a category) when the system could remind them. Recognition is cheaper than recall.
