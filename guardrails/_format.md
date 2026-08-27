# Guardrail format

The contract `build-guardrails.sh` parses. Violations fail generation — loudly, with the offending
ID named. This file is not a registry; it is the spec the five registries follow.

Each registry is a **pair of files**:

- `<name>-anti-patterns.md` — the prose. The rule as a human reads it, and the copy the brief
  flows embed into a project's `PRODUCT.md` / `DESIGN.md` / `CODE.md` / `WRITING.md`.
- `<name>-anti-patterns.detect.md` — the machine record. How a script finds the ban.

They are bound by ID. The generator fails if either side names an ID the other does not, so the
two cannot drift apart. **This is the only thing making a sidecar safe**, and it is why detectors
live beside the prose rather than inside a hook.

## Why the split

The brief flows copy guardrail prose toward a user's briefs ("embedded inline, not just linked").
Anything in the prose file is one paste away from a designer's `DESIGN.md`. A regex is not a rule a
designer should read, so regexes stay in the sidecar and the prose stays prose. The ID is the
exception: it lives in the prose, because a rendered brief that cites `DES-18` is one whose bans a
review can name and a script can check.

## IDs

`<PREFIX>-<NN>`, zero-padded, two digits minimum. One prefix per registry:

| Registry | Prefix |
|---|---|
| `product-anti-patterns.md` | `PRD` |
| `ux-anti-patterns.md` | `UX` |
| `design-anti-patterns.md` | `DES` |
| `writing-anti-patterns.md` | `WRT` |
| `code-anti-patterns.md` | `CODE` |

**IDs are immutable once published.** Briefs, findings, fixtures, and hook output cite them. A ban
that is deleted retires its number; the number is never reused. A new ban takes the next free
number in its file, **not** a number that matches its position — first publication numbered in
document order, everything after that appends. A ban that moves to another registry keeps its
original prefix; `registry.json` records the file it actually lives in, so the prefix is a name,
not a location.

## Prose shape

Two shapes, because the five registries are genuinely two shapes. The generator accepts both.

**Bulleted registries** (`design`, `writing`) — the ID opens the bolded lead:

```markdown
- **(DES-18) No glassmorphism by default.** Use it deliberately or not at all.
```

**Sectioned registries** (`product`, `ux`, `code`) — the ID replaces the ordinal:

```markdown
## CODE-13 — Magic timing

`setTimeout(fn, 100)` to "fix" a race condition. …
```

The text between the ID and the end of the bold (or the end of the heading) is the ban's **name**
in `registry.json`. Keep it a single declarative clause.

## Sidecar shape

One GFM table, five columns, one row per ban, in the same order as the prose:

```markdown
| ID | Confidence | Scope | Detect | Fix |
|---|---|---|---|---|
| DES-18 | certain | style | regex:`backdrop-filter[[:space:]]*:[[:space:]]*blur` | use deliberately or not at all |
```

### Detect

One of these. The first two are live detectors; the rest are not.

| Value | Meaning |
|---|---|
| ``regex:`<ERE>` `` | POSIX ERE, case-sensitive. Any match warns. |
| ``regexi:`<ERE>` `` | The same, case-insensitive. |
| ``count:<n>:`<ERE>` `` | A density check: warns only above `n` matches in one file. |
| `unwritten` | Mechanically detectable, detector not written yet. **This is the work queue.** |
| `token` | Computable from `DESIGN.json`, not by grep — see `scripts/validate-tokens.sh`. |
| `render` | Needs a rendered page or computed styles. No script will find it. |
| `manual` | A human or a model judges it. No script will find it. |

A `|` inside a regex must be escaped as `\|`, or it ends the table cell. The generator unescapes
it. Write regexes with POSIX classes (`[[:space:]]`), not Perl shorthand beyond `\b` — the hooks
run under `grep -E` on whatever the user's machine has.

### Confidence

Required for `regex`, `regexi`, `count`, and `unwritten`; `—` otherwise.

- `certain` — near-zero false positives. Warns wherever its scope applies.
- `scoped` — real signal, but needs a scope or threshold to stay useful. This field is where the
  judgment that used to live in a code comment goes. `robust` and `leverage` are excluded from
  `WRT-01` because tech docs use them honestly; that is a `scoped` call, and Phase 3's clean
  fixtures are what hold it.

There is deliberately **no severity field**. All three hooks `exit 0` by design
(`hooks/README.md`), so a severity would change nothing and drift. Add one when something branches
on it.

### Scope

Which files a detector applies to, and therefore which hook runs it. Required for `regex`,
`regexi`, `count`, and `unwritten`; `—` otherwise.

| Scope | Files | Hook |
|---|---|---|
| `style` | `.css .scss .sass .less .tsx .jsx .svelte .vue .astro` | `check-anti-patterns.sh` |
| `tokens` | the same, but only when the project ships `DESIGN.json` | `guard-design.sh` |
| `prose` | `.md .mdx .markdown .txt` | `check-writing-slop.sh` |
| `code` | — | none yet |

`code` has no hook. An `unwritten` row may name it; a **live** detector may not, and the generator
rejects one that does — a detector no hook runs is a rule that looks enforced and is not.

### Fix

The one-clause remedy printed after the warning. Required for live detectors, `—` otherwise. Write
the action, not the restated ban: `animate transform/opacity instead`, not `don't animate layout`.

## Adding a ban

1. Write the prose entry with the next free ID for that file.
2. Add its sidecar row.
3. Run `./build-guardrails.sh`.
4. If it carries a live detector, add its fixtures (`fixtures/guardrails/<ID>/`) — a detector
   without a clean fixture is how a linter dies of false positives.
5. Run `./test.sh`.

Nothing else is edited. No hook changes, no `test.sh` changes. That property is the point of this
format, and `test.sh` section 12 asserts it.

**Adding or restructuring a guardrail needs the user's approval first** — see `AGENTS.md`,
*When to ask the user*.
