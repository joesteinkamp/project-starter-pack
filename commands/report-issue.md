---
description: Draft and send upstream feedback to project-starter-pack so the generator improves
---

Invoke the `report-issue` skill.

When a brief, an evaluation, or a generated file keeps disappointing, the root cause is usually upstream: a template, questionnaire, or guardrail in the `joesteinkamp/project-starter-pack` repo. This command turns that pain into a clean issue.

1. Confirm consent — the issue body will be **public** on GitHub.
2. Ask which artifact looks at fault (template / questionnaire / guardrail / skill / command / unsure).
3. Ask the symptom category and a one-paragraph description.
4. Optionally accept a redacted snippet from the user's project. Offer to scrub project name, URLs, names, and obvious secrets/PII.
5. Draft the issue body (Summary, Affected file, Repro, Expected, Actual, Snippet, Suggested fix). Preview to the user.
6. Post via `gh issue create --repo joesteinkamp/project-starter-pack` if `gh` is available and authenticated. Otherwise save the draft to `.starter/upstream-issues/<timestamp>.md` and print a pre-filled GitHub "new issue" URL the user can open in their browser.
