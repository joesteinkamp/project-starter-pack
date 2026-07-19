---
description: Synthesize PRODUCT.md, DESIGN.md, and CODE.md into AGENT.md and the selected harness files
---

Invoke the `orchestrator` skill.

Synthesize the three briefs into agent instructions: `AGENT.md` (the universal agents.md spec,
always written) plus the harness files the user selects — `CLAUDE.md`, `GEMINI.md`, and/or a
Cursor file. The skill owns the full procedure: inputs, pre-flight, harness selection,
synthesis, preview, and the final summary.
