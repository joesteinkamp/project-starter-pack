# Design Anti-patterns

The visual-layer tells that an AI made it (or that a designer wasn't paying attention). The starter-pack treats these as banned by default. These bans are locked at every lock posture a brief chooses — an "open" area never unlocks them.

## Color

- **No purple gradients on dark backgrounds** as the default for "AI" or "tech" products. It is the single most overused signature of the era.
- **No pure black (#000)** on body surfaces. Use OKLCH neutrals with a hint of warmth or coolness. Pure white (#FFF) is fine.
- **No raw hex where a token system applies.** When the project ships `DESIGN.json`, colors come from its OKLCH tokens. A hex literal in a style file is a slip back to the old palette, not a second opinion. Third-party and generated files are out of scope.
- **No neon-on-black** as an accent system. Saturated hues on near-black is a category reflex, not a choice.
- **No more than one decisive accent.** A "Restrained" or "Committed" palette uses one accent on ≤10% of surface.
- **No gray text on colored backgrounds.** Contrast ratios verified, not eyeballed.

## Typography

- **No system-default-only stacks** as a design choice. If "system-ui" is the answer, justify it.
- **No tight line-height (<1.4) for body copy.**
- **No measure wider than 75ch** for paragraph text.
- **No type scale flatter than 1.2.** Hierarchy needs contrast.
- **No gradient text.** It rarely meets contrast and always reads as dated.
- **No all-caps headlines longer than 4 words.**

## Layout & components

- **No nested cards** (a card inside a card). If the content needs grouping, use spacing or hairline borders.
- **No identical-card grids of features.** Vary scale, vary weight, give the eye somewhere to land.
- **No hero-metric template** ("10× faster", "99.9% uptime", "10,000 happy users") as the headline pattern unless the metric is genuinely the product.
- **No side-stripe borders** as a "highlight" pattern.
- **No drop shadows as default surface elevation.** Use shadows for state changes only.
- **No glassmorphism by default.** Use it deliberately or not at all.
- **No rounded rectangles with drop shadows everywhere.** That is the SaaS default; choose intentionally.

## Motion

- **No bounce easing.** Reads as toy-like in serious products.
- **No animations on layout properties** (`width`, `height`, `top`/`left`/`right`/`bottom`, margins, padding, `gap`, `inset`, `flex-basis` — and `transition: all`, which animates them implicitly). Animate transforms.
- **No motion that ignores `prefers-reduced-motion`.**
- **No "delight" animations on critical paths.** Don't make the user wait for a transition to dismiss before they can act.

## Composition tells

- **No identical icon-above-headline-above-paragraph card grids** as the feature row.
- **No three-column "How it works" section** with a number, an icon, a verb.
- **No "trusted by" logo strip** that's 6 logos at 40% opacity.
- **No screenshot of the product floating on a tilted plane with a glow underneath.**

## The slop test

If a designer who has seen a thousand AI-generated UIs would look at the screen and say "yep, AI", the design fails. Find the tell, kill it, ship.
