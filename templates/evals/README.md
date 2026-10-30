# evals

Checks that agents working here follow this project's own briefs. Written by
project-starter-pack's `setup` flow; `cases.md` is yours to edit.

- `./evals/run.sh` — free and deterministic; safe in CI. Proves every rule is still
  written in its brief and every `check:` separates its goldens.
- `./evals/run.sh --live [EV-NN …]` — opt-in, spends tokens. An agent works each case in a
  scratch worktree of HEAD; a judge from another model family grades it, after first
  scoring the case's own goldens correctly. Needs the AI CLI roster at `~/.ai/clis`.
- `./evals/run.sh --confirm EV-NN` — mark a draft case confirmed once its goldens are right.

**Add a case** when an agent gets something wrong here: a new `## EV-NN — headline` entry
in `cases.md` (next unused number), with `goldens/EV-NN/fail.*` holding what the agent did
and `pass.*` what you approved. Write the judge question about the outcome, not the steps.

Only confirmed cases gate. `config` sets the agent under test and, optionally, the judge.
