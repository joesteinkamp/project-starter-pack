# Code Anti-patterns

Engineering habits that make codebases harder to change, harder to reason about, or harder to onboard into. The starter-pack treats these as banned by default; override per-project in `CODE.md` only with a documented reason.

## CODE-01 — Premature abstraction

Three similar lines of code is not a pattern. Wait until the third or fourth real use before extracting. Abstractions built on two examples almost always have to be torn down on the fourth.

## CODE-02 — Half-finished implementations

Stubs, TODO comments, "we'll add this later" branches, unused fallback paths. Either ship the feature or don't introduce the surface.

## CODE-03 — Defensive over trust

Validating internal function inputs that are guaranteed by the type system. Wrapping internal calls in try/catch "just in case". Trust internal code; validate at the boundary (user input, external APIs, file system).

## CODE-04 — Comment-as-rename-substitute

If a comment is explaining what the code does, the code probably needs renaming. Comments earn their place when they explain *why* — a hidden constraint, a workaround for a known bug, a non-obvious invariant.

## CODE-05 — Dead code kept "in case"

If a branch isn't reached, delete it. Version control remembers; the codebase doesn't need to.

## CODE-06 — Backward-compat shims for code you control

Renaming `_oldFn` to `oldFnDeprecated` and re-exporting. Keeping a removed feature behind a flag for "compatibility" with callers you also own. Just change all the callers.

## CODE-07 — Over-eager error handling

Catching errors only to re-throw them with a less informative message. Returning `null` when an exception was the right answer. Empty catch blocks. Errors should propagate to the layer that knows what to do with them.

## CODE-08 — State machines disguised as booleans

Five booleans (`isLoading`, `isError`, `isSuccess`, `isIdle`, `isRetrying`) that have illegal combinations. If the truth is a state machine, model it as one.

## CODE-09 — Test-by-implementation

Tests that mock everything and assert that the function called the mocks. Test the behavior, not the wiring.

## CODE-10 — Snapshot tests as a primary signal

Snapshots are useful for regression detection on stable surfaces. They're not a substitute for tests that say what the behavior should be.

## CODE-11 — "Utility files" that grow forever

`utils.ts`, `helpers.ts`, `lib.ts` with 30 unrelated functions. Group by feature, not by part-of-speech.

## CODE-12 — Silent type widening

`as any`, `// @ts-expect-error` without a comment, `unknown` returns coerced without a guard. Each one is a place future bugs will hide.

## CODE-13 — Magic timing

`setTimeout(fn, 100)` to "fix" a race condition. Sleep loops in tests. If the timing matters, make it explicit (a promise, a state transition, an event).

## CODE-14 — Bypassing safety as a shortcut

`--no-verify`, `--force`, `git reset --hard`, disabled lint rules, ignored type errors. If a check fails, the check is usually right.
