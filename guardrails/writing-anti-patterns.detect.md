# Writing anti-pattern detectors

> Machine records for `writing-anti-patterns.md`. The prose is the rule; this is how a
> script finds it. `build-guardrails.sh` fails if an ID here has no ban there, or a ban
> there has no row here, so the two cannot drift apart. See `_format.md` for the contract.

| ID | Confidence | Scope | Detect | Fix |
|---|---|---|---|---|
| WRT-01 | certain | prose | regexi:`\b(delve\|delves\|delving\|tapestry\|paradigm shift\|game.changer)\b` | use the plainer word  |
| WRT-02 | scoped | prose | unwritten | —  |
| WRT-03 | certain | prose | regexi:`it'?s worth noting\|at the end of the day\|in today'?s world\|let'?s dive in` | delete it; the sentence survives  |
| WRT-04 | certain | prose | unwritten | —  |
| WRT-05 | certain | prose | unwritten | —  |
| WRT-06 | — | — | manual | —  |
| WRT-07 | certain | prose | unwritten | —  |
| WRT-08 | — | — | manual | —  |
| WRT-09 | — | — | manual | —  |
| WRT-10 | certain | prose | regexi:`here'?s the thing\|let me be clear\|i'?ll be honest` | lead with the point  |
| WRT-11 | certain | prose | regexi:`what nobody tells you\|the part everyone misses` | cut the setup; let the claim stand  |
| WRT-12 | certain | prose | unwritten | —  |
| WRT-13 | certain | prose | unwritten | —  |
| WRT-14 | certain | prose | unwritten | —  |
| WRT-15 | scoped | prose | unwritten | —  |
| WRT-16 | certain | prose | unwritten | —  |
| WRT-17 | certain | prose | regexi:`in conclusion` | end on the concrete point or the next action  |
| WRT-18 | — | — | manual | —  |
| WRT-19 | certain | prose | unwritten | —  |
| WRT-20 | — | — | manual | —  |
| WRT-21 | — | — | manual | —  |
| WRT-22 | certain | prose | unwritten | —  |
| WRT-23 | certain | prose | count:5:`—` | keep 1-2 per piece; prefer commas or periods  |
| WRT-24 | certain | prose | unwritten | —  |
| WRT-25 | scoped | prose | unwritten | —  |
| WRT-26 | scoped | prose | unwritten | —  |
| WRT-27 | — | — | manual | —  |
| WRT-28 | scoped | prose | unwritten | —  |
