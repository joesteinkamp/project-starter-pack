# Reporting security issues

Thanks for disclosing responsibly.

## How to report

Use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
on this repository. That keeps the report visible to the maintainer without exposing details
publicly.

If private reporting is unavailable, open an issue titled `security: brief description`
**without** exploit details, and the maintainer will reply with a private channel.

## What to include

- The issue and its potential impact.
- Steps to reproduce. Minimal is fine; a full proof of concept is not required.
- Whether you'd like credit in the fix.

## What to expect

- Acknowledgement within a few days.
- A fix or mitigation plan within about 30 days for confirmed issues.
- Public credit once a fix ships, if you want it.

## Scope

This pack is markdown plus two bash scripts. It has no runtime, no network calls, and no
telemetry. The flows execute inside your AI coding tool; the scripts run on your machine. Three
pieces of it touch the filesystem, and that is where the real surface is.

Issues worth reporting:

- **`install.sh` writing outside the target skills and commands directories**, or removing a file
  it did not create. It installs by symlink and refuses to replace anything that is not a link
  resolving back into the checkout; `--uninstall` is meant to remove exactly what was installed.
  A path that escapes that is a bug.
- **`hooks/*.sh` acting on a path from untrusted hook input.** The advisory hooks read a file path
  out of the harness's JSON payload and scan that file. They are warn-only and must stay that
  way: a hook that executes, writes, or blocks based on that path is a bug, as is one that can be
  made to read outside the project.
- **`render-ports.sh` writing outside `commands/cursor/`.**
- **A generated brief or `AGENTS.md` carrying content that escapes its markdown context** in a way
  that redirects a downstream agent reading it.

Out of scope:

- Anything requiring a malicious local user who already has write access to the repository or to
  your home directory. They can edit the scripts directly.
- The advisory hooks reporting a false positive, or missing a real anti-pattern. That's a bug,
  but an ordinary one — open a regular issue.
- Prompt content in a brief that you wrote yourself.
