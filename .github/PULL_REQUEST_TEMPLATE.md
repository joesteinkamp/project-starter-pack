## Summary

<!-- What this changes and why. One or two sentences. -->

## Linked issue

<!-- Closes #123, or Refs #456. Leave empty for a small fix.
     Growing the command surface, or adding a slot, question, or guardrail, wants an issue
     first — see CONTRIBUTING.md. -->

## Checks

- [ ] `./test.sh` is green
- [ ] If a template heading changed, `examples/saga-reader/` was re-rendered to match
- [ ] If a slot was added, it has a question (or a default) and a skill that fills it
- [ ] No harness-specific tool names added to `skills/`, `questionnaires/`, `conventions/`, or
      `guardrails/`
- [ ] `commands/cursor/` was not hand-edited

## Portability

<!-- The pack runs in Claude Code, Codex, Cursor, and Antigravity. Claude Code is the only
     target with both commands and a structured-question tool, so a step that depends on one is
     broken in three tools out of four. -->

- [ ] Works in all four tools, or
- [ ] Deliberately tool-specific, explained below

## Claims about other tools

<!-- If this PR asserts what Claude Code, Codex, Cursor, or Antigravity does — a config path, a
     discovery rule, a supported field — say how you confirmed it. Grepping this repo does not
     confirm it. See the probes recorded in memory/knowledge.md. -->

- [ ] No new claims about another tool's behavior
- [ ] Probed; how is described above

## Change log

<!-- CHANGELOG.md records decisions, not diffs. Propose the entry here; the maintainer approves
     it rather than it landing unasked. -->
