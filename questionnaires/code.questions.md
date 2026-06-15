# Technical Brief Questionnaire

The `code-brief` skill walks the user through this question set.

## Pass 1 — Structured

### Q1. Frontend framework

- `Next.js (App Router)`
- `Next.js (Pages Router)`
- `Vite + React`
- `SvelteKit`
- `Astro`
- `Remix`
- `Solid Start`
- `None (server-rendered HTML)`
- `Other`

→ `{{STACK_FRONTEND}}`

### Q2. Backend / runtime

- `Node.js (TypeScript)`
- `Bun`
- `Deno`
- `Edge runtime (Cloudflare Workers / Vercel Edge)`
- `Python (FastAPI / Django)`
- `Go`
- `Rust`
- `None — frontend only`
- `Other`

→ `{{STACK_BACKEND}}`

### Q3. Database

- `Postgres (managed)`
- `SQLite / Turso / D1`
- `MySQL`
- `MongoDB`
- `Firestore / Realtime`
- `KV / Redis only`
- `None`
- `Other`

→ `{{STACK_DATABASE}}`

### Q4. Hosting

- `Vercel`
- `Cloudflare Pages / Workers`
- `Netlify`
- `Fly.io / Railway`
- `AWS (custom)`
- `Self-hosted`
- `Other`

→ `{{STACK_HOSTING}}`

### Q5. Auth

- `None (anonymous)`
- `Magic link / passkeys`
- `OAuth (Google, GitHub, etc.)`
- `Email + password`
- `Hosted (Clerk / Auth0 / Supabase Auth)`
- `Custom`

→ `{{STACK_AUTH}}`

> Note any other load-bearing services the agent must respect — payments,
> email, search, queues, analytics, AI providers, CDN. Captured as a free-form
> follow-up.

→ `{{STACK_OTHER}}` (leave blank with a TODO if there are none worth pinning)

### Q6. Repo strategy

- `Single app`
- `Monorepo (Turborepo / Nx / pnpm workspaces)`
- `Polyrepo`

→ informs `{{ARCHITECTURE}}`

### Q7. Type system stance

- `Strict TypeScript everywhere` (recommended default)
- `TypeScript with looser settings`
- `JavaScript`
- `Other typed language`

→ informs `{{LANGUAGES_TOOLING}}`

### Q8. Testing posture

- `Unit + integration + e2e` (full pyramid)
- `Unit + e2e` (skip integration)
- `Unit only`
- `e2e only`
- `None yet`

→ informs `{{TESTING}}`

### Q9. Performance budget posture

- `Strict` — Core Web Vitals enforced in CI, JS bundle budgets per route
- `Considered` — targets exist, not enforced
- `Best-effort` — no formal budget yet

→ informs `{{PERFORMANCE}}`

## Pass 2 — Open follow-ups

### Q10. Architecture detail

> Where does business logic live (server, client, both)? Where does state
> live (server, URL, client store)? Module boundaries — how is the codebase
> divided into features?

→ `{{ARCHITECTURE}}`

### Q11. Languages & tooling

> Languages, package manager, linter (Biome, ESLint, etc.), formatter,
> type-checker, build tool. Note version pins that matter.

→ `{{LANGUAGES_TOOLING}}`

### Q12. Code conventions

> Naming (files, exports, components). Folder structure. Import style.
> Comment policy (default: comments only when WHY is non-obvious). Error-
> handling stance.

→ `{{CODE_CONVENTIONS}}`

### Q13. Testing detail

> What gets tested, what doesn't. Test runner. Coverage target (or "no
> coverage gate"). CI hooks.

→ `{{TESTING}}`

### Q14. Deployment & CI

> Branch strategy. CI provider. Required checks. Deploy targets. Preview
> environments.

→ `{{DEPLOYMENT}}`

### Q15. Performance budgets

> LCP / INP / CLS targets. JS bundle budget per route. Image weight cap.
> Server response budget. Treat as hard limits.

→ `{{PERFORMANCE}}`

### Q16. Security baselines

> Auth model. Secrets handling (env, vault). Input validation stance. CSP /
> security headers. Dependency policy (renovate, dependabot).

→ `{{SECURITY}}`

## Defaults applied if unanswered

| Slot | Default | Mark |
|---|---|---|
| `{{LANGUAGES_TOOLING}}` | TypeScript strict, Biome (lint + format), pnpm | `[default — confirm]` |
| `{{CODE_CONVENTIONS}}` | kebab-case files, named exports, comments only when WHY is non-obvious, errors propagate to boundary | `[default — confirm]` |
| `{{TESTING}}` | Unit (Vitest) + e2e (Playwright); no coverage gate | `[default — confirm]` |
| `{{PERFORMANCE}}` | LCP <2.5s, INP <200ms, CLS <0.1, JS bundle <150KB initial route | `[default — confirm]` |
| `{{SECURITY}}` | Secrets via env, CSP enforced, input validated at boundary, deps auto-updated weekly | `[default — confirm]` |
| `{{CODE_ANTI_PATTERNS}}` | Pull from `guardrails/code-anti-patterns.md` verbatim | always included |

## Pre-flight checks before writing

- If `CODE.md` exists, ask: **reuse / merge / overwrite**.
- Validate stack choices are internally consistent (e.g. don't pair Cloudflare Pages with a Node-only library).
- Always pull anti-patterns from `guardrails/code-anti-patterns.md` so the brief carries the bans inline.

## Extraction hints (brownfield)

`/starter:extract` fills most of this brief straight from the code: `package.json` /
`pyproject.toml` / `go.mod` seed `{{STACK_FRONTEND}}`, `{{STACK_BACKEND}}`, and `{{STACK_OTHER}}`;
DB drivers and host config seed `{{STACK_DATABASE}}`, `{{STACK_HOSTING}}`, `{{STACK_AUTH}}`;
package manager + tsconfig + linter config seed `{{LANGUAGES_TOOLING}}`; folder boundaries seed
`{{ARCHITECTURE}}` and `{{CODE_CONVENTIONS}}`; test dirs seed `{{TESTING}}`; CI/deploy config seeds
`{{DEPLOYMENT}}`; perf/bundle config seeds `{{PERFORMANCE}}`; auth/CSP/secrets handling seeds
`{{SECURITY}}`. This brief is the most reliably extractable of the three.
