# Hooks (optional, advisory)

These hooks are **opt-in, warn-only, and not installed by default.** They print nudges when an
edited file drifts from the design system; they never block a tool call and never edit anything.

## Why advisory, not enforcing

`project-starter-pack` is AI-driven: `AGENT.md` already embeds the anti-pattern bans inline so the
agent self-checks before it writes. Hard blocking on something like "raw hex" produces false
positives (third-party CSS, generated files) and fights the designer. And genuine hard enforcement
— protected paths, dangerous-bash guards, a tool-call audit log — is a **user / global-layer**
concern (it belongs with your global instructions), not something a per-project starter pack should
duplicate. So these hooks stay advisory and optional. If you want project-specific reminders, opt
in; otherwise the embedded guardrails in `AGENT.md` are the enforcement.

## What they check

| Hook | Fires on | Nudge |
|---|---|---|
| `guard-design.sh` | Edit/Write to a style/component file **when `DESIGN.json` exists** | raw hex colors where the OKLCH token system applies |
| `check-anti-patterns.sh` | Edit/Write to a style/component file | a few high-signal `design-anti-patterns.md` bans: animating layout properties, `backdrop-filter: blur` (glassmorphism), gradient/clipped text |

Both read the tool-call JSON on stdin, inspect the edited file, print to stderr, and **exit 0**.

## Install / uninstall

```
hooks/install-hooks.sh                        # project-local (./.claude/settings.json)
hooks/install-hooks.sh --global               # all projects (~/.claude/settings.json)
hooks/install-hooks.sh --uninstall [--global] # remove exactly what the installer added
```

Requires `jq`. The installer preserves any existing hooks (yours are matched by exact path, so a
same-named script of your own is never touched), and the **first run** writes
`settings.json.bak` — your pre-install settings; later runs never overwrite it, so it always
restores the original. `--uninstall` removes only this pack's entries. `settings.snippet.json`
shows the exact config if you prefer to merge it by hand. If the install is project-local, add
`.claude/settings.json.bak` to your `.gitignore` (this repo's does).
