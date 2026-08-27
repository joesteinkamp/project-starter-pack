# Design anti-pattern detectors

> Machine records for `design-anti-patterns.md`. The prose is the rule; this is how a
> script finds it. `build-guardrails.sh` fails if an ID here has no ban there, or a ban
> there has no row here, so the two cannot drift apart. See `_format.md` for the contract.

| ID | Confidence | Scope | Detect | Fix |
|---|---|---|---|---|
| DES-01 | scoped | style | unwritten | —  |
| DES-02 | certain | tokens | unwritten | —  |
| DES-03 | certain | tokens | regex:`:[[:space:]]*[^;{}]*#([0-9a-fA-F]{8}\|[0-9a-fA-F]{6}\|[0-9a-fA-F]{3,4})\b` | use the OKLCH tokens from DESIGN.json  |
| DES-04 | — | — | token | —  |
| DES-05 | — | — | token | —  |
| DES-06 | — | — | token | —  |
| DES-07 | — | — | token | —  |
| DES-08 | certain | style | unwritten | —  |
| DES-09 | certain | style | unwritten | —  |
| DES-10 | — | — | token | —  |
| DES-11 | certain | style | regex:`(-webkit-)?background-clip[[:space:]]*:[[:space:]]*text` | rarely meets contrast and reads as dated  |
| DES-12 | — | — | render | —  |
| DES-13 | — | — | render | —  |
| DES-14 | — | — | manual | —  |
| DES-15 | — | — | manual | —  |
| DES-16 | scoped | style | unwritten | —  |
| DES-17 | scoped | style | unwritten | —  |
| DES-18 | certain | style | regex:`backdrop-filter[[:space:]]*:[[:space:]]*blur` | use deliberately or not at all  |
| DES-19 | scoped | style | unwritten | —  |
| DES-20 | certain | style | unwritten | —  |
| DES-21 | certain | style | regex:`(^\|[^[:alnum:]-])transition(-property)?[[:space:]]*:[[:space:]]*([^;}]*[[:space:],])?(all\|width\|height\|top\|left\|right\|bottom\|margin(-[a-z]+)?\|padding(-[a-z]+)?\|gap\|inset\|flex-basis)([[:space:],;}]\|$)\|(^\|["\'[:space:]])transition-(all\|width\|height)(["\'[:space:]]\|$)` | animate transform/opacity instead  |
| DES-22 | certain | style | unwritten | —  |
| DES-23 | — | — | manual | —  |
| DES-24 | — | — | render | —  |
| DES-25 | — | — | manual | —  |
| DES-26 | — | — | render | —  |
| DES-27 | — | — | render | —  |
