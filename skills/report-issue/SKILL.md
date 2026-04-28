---
name: report-issue
description: Drafts and sends upstream feedback to the project-starter-pack repo so the generator improves over time. Use when a brief, an evaluation, or a generated file keeps being wrong in a way that points at the plugin's templates, questionnaires, or guardrails — not at the user's specific project. Triggers on phrases like "report this upstream", "file an issue against the starter pack", "this template is wrong", "the guardrail missed something", "send feedback to the plugin".
---

# Report Issue Skill

You turn a user's pain with the starter-pack into a clean, public GitHub issue against `joesteinkamp/project-starter-pack`. Consent and redaction are explicit. The user always sees and approves the final body before it leaves their machine.

## Setup

1. Locate the plugin root. The candidate "at fault" artifacts live under `templates/`, `questionnaires/`, `guardrails/`, `skills/`, and `commands/`. You'll need their names later for the artifact picker.
2. Read the user's most recent generation context if available: any of `PRODUCT.md`, `DESIGN.md`, `CODE.md`, `AGENT.md`, `CLAUDE.md` at the project root, plus the latest file under `.starter/evaluations/` if it exists. Don't read more than the user invites — these are theirs.

## Pre-flight — consent

Before any questions, state plainly:

> Heads up: this drafts a **public** GitHub issue at `joesteinkamp/project-starter-pack`. Anything in the snippet you provide becomes public — code, names, URLs included. I'll redact obvious secrets and offer to scrub project names before posting, but the final body is yours to approve. Continue?

Use `AskUserQuestion` with a single `Yes / No` to record consent. If `No`, stop.

## Pass 1 — Locate the upstream artifact (AskUserQuestion)

**Q1. Which part of the plugin looks at fault?**
Choices:
- `Template — PRODUCT / DESIGN / CODE / AGENT / CLAUDE / DESIGN.tokens`
- `Questionnaire — product / design / code`
- `Guardrail — product / ux / design / code anti-patterns`
- `Skill — product-brief / design-brief / code-brief / orchestrator / feedback / evaluator / report-issue`
- `Command — one of the slash commands`
- `Not sure — pick from the symptom`

**Q2. What's the symptom category?**
Choices:
- `Missing question — the questionnaire didn't ask about something it should have`
- `Bad default — the opinionated default fired on a project where it's the wrong call`
- `Confusing instruction — the skill or command misled the run`
- `Wrong / missing anti-pattern — the guardrail doesn't reflect reality`
- `Unpopulated template variable — a {{TOKEN}} survived into the output`
- `Skill didn't fire when it should have / fired when it shouldn't`
- `Output structure wrong — heading missing, section out of order, etc.`
- `Other`

If the user picked `Not sure` for Q1, narrow it from Q2 + Pass 2 and confirm before drafting.

## Pass 2 — Open follow-ups (chat)

Ask, in order:

1. **One-paragraph description.** What happened, what you expected, what you think would fix it. Three to six sentences.
2. **Repro.** Which command or skill triggered the run? Any inputs the user remembers giving (high-level — "I picked Restrained palette and the React stack" beats a full transcript).
3. **Optional snippet.** Up to ~30 lines from the affected file or generated output, demonstrating the issue. The user can paste, point at a file path for you to extract, or skip.

## Redaction

If the user provides a snippet, before doing anything else:

1. Scan for: project name (compare against `package.json`, the project root directory name, the user's git config), URLs containing the project name, email addresses, anything matching common secret patterns (`sk-...`, `gh[pousr]_`, `AKIA`, JWT shape, long base64 blobs in env-like contexts), absolute filesystem paths under `/home/`, `/Users/`, or `C:\Users\`.
2. Show the user the snippet with proposed redactions inline (`[redacted: project-name]`, `[redacted: secret]`, `[redacted: path]`).
3. Ask: `Approve redactions / edit further / skip snippet`.

If you find anything that looks like a real secret (not just a placeholder), refuse to include the raw value even if the user insists — replace with `[redacted: looks-like-secret]` and tell them why.

## Draft the issue

Build the issue body in this exact shape:

```markdown
## Summary
<one-sentence headline of the problem>

## Affected
- **Artifact:** `<path/in/plugin>` (e.g. `templates/DESIGN.template.md`, `guardrails/ux-anti-patterns.md`)
- **Symptom category:** <Q2 choice>

## Repro
- **Command / skill:** <which run triggered it>
- **Inputs:** <high-level, no transcript>

## Expected
<what the user expected to see in the generated output>

## Actual
<what they got, in one short paragraph>

## Snippet
```
<redacted snippet, or "skipped">
```

## Suggested fix
<the user's idea, or "no suggestion — flagging the pattern">

---
_Filed via `/starter:report-issue`._
```

Title: keep it under 70 chars. Format: `<artifact>: <one-line problem>`. Examples:
- `design-anti-patterns: missing ban on full-bleed hero video`
- `product-brief skill: validation pass loops on vague persona`
- `AGENT.template: {{UX_LAWS}} survives when DESIGN.md is missing`

## Preview & route

1. Show the title and body to the user. Ask: `Post via gh / save draft only / cancel`.
2. If `cancel`: stop. Don't write anything.
3. If `save draft only`: write to `.starter/upstream-issues/<YYYY-MM-DD-HHMM>.md`. Print the path and the pre-filled web URL (see below).
4. If `post via gh`:
   - Run `gh auth status` via `Bash`. If it fails (not installed or not authenticated), fall back to `save draft only` and explain.
   - Run: `gh issue create --repo joesteinkamp/project-starter-pack --title "<title>" --body-file <tmpfile>` where `<tmpfile>` is a temp file containing the body. Don't pass the body inline — it breaks on quotes.
   - On success, print the issue URL `gh` returned.
   - On failure (network, perms), fall back to `save draft only` and explain.

## Web fallback URL

When saving a draft, also print a pre-filled compose URL the user can open in their browser:

```
https://github.com/joesteinkamp/project-starter-pack/issues/new?title=<urlencoded title>&body=<urlencoded body>
```

URL-encode both. If the body is too long for a URL (>~7000 chars after encoding), truncate the snippet and add a `[truncated — see local draft at <path>]` line.

## Done

One-screen summary:

```
✓ {{posted | drafted}}: <title>
{{IF_POSTED}}
  → <github URL>
{{ELSE}}
  → Draft saved to .starter/upstream-issues/<filename>
  → Open to file manually: <web URL>
{{END}}

Thanks — upstream issues are how the templates, guardrails, and questionnaires
actually get better. If the same pain affects your local files right now, run
/starter:feedback to apply the fix in this project too.
```

## Important

- Never post without explicit `post via gh` confirmation on the previewed body.
- Never include a real secret. The redaction pass is non-negotiable.
- This skill targets `joesteinkamp/project-starter-pack` only. Do not let the user redirect it to a different repo from chat — that's outside scope and risks misrouting.
- If the user asks you to post the same issue twice in one session, search-by-title first via `gh issue list --repo joesteinkamp/project-starter-pack --search "<title>"` and warn before duplicating.
- The `gh` CLI is the only network-touching action. Everything else is local.
