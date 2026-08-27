# Writing Anti-patterns

The prose tells that an AI wrote it (or that nobody read it back). The starter-pack treats these as banned by default in every word the product ships — UI labels, error messages, empty states, docs, marketing pages, release notes. Adapted from [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop) (MIT).

## Vocabulary

- **(WRT-01) No AI-flagship words.** delve, foster, leverage, utilize, facilitate, empower, streamline, robust, seamless, cutting-edge, transformative, elevate, embark, supercharge, harness, tapestry, realm, beacon, multifaceted, meticulous, paramount, ever-evolving, game changer, paradigm shift. Each has a plainer word; use it.
- **(WRT-02) No empty adverbs.** just, literally, honestly, simply, actually, truly, fundamentally, crucially — cut unless the word carries real emphasis, uncertainty, or contrast.
- **(WRT-03) No empty phrases.** "it's worth noting", "at the end of the day", "in today's world", "when it comes to", "in order to", "let's dive in". Delete them; the sentence survives.

## Sentence patterns

- **(WRT-04) No binary contrasts.** "It's not X. It's Y." State the point once: "Y matters more."
- **(WRT-05) No negative listing.** "Not A. Not B. C." Just say C.
- **(WRT-06) No colon reveals.** "The best part: it learns." Write a plain sentence; keep colons for lists, labels, and quotes.
- **(WRT-07) No dramatic fragmentation.** "X. And Y. And Z." stacked for effect reads as performance, not emphasis.
- **(WRT-08) No robotic rhythm.** Repeated sentence shapes and identical paragraph structures are a tell; vary length and shape the way speech does.
- **(WRT-09) No synonym cycling.** Pick the clear word for a thing and repeat it; rotating synonyms for style loses the referent.

## Openers & framing

- **(WRT-10) No throat-clearing.** "Here's the thing", "Let me be clear", "I'll be honest". Lead with the point.
- **(WRT-11) No faux-insight setups.** "What nobody tells you", "the part everyone misses". Cut the setup; let the claim stand on its own.
- **(WRT-12) No rhetorical setups.** "What if I told you", "Think about it", questions the next sentence answers.
- **(WRT-13) No weasel attribution.** "Experts agree", "studies show", "many argue". Name the source or cut the claim.

## Puffery

- **(WRT-14) No importance puffery.** "marks a pivotal moment", "plays a vital role", "stands as a testament". State the fact and let the reader judge its weight.
- **(WRT-15) No fake-strong verbs.** "serves as a centralized hub" → "tracks sponsors and approvals in one place". Say what the thing does.
- **(WRT-16) No trailing analysis clauses.** "…, highlighting the team's commitment". Replace with a concrete action or outcome, or end the sentence.

## Endings

- **(WRT-17) No summary-recap endings.** "In conclusion", "Ultimately". The reader was just there; end on the concrete point or the next action.
- **(WRT-18) No fake-profound kickers.** Don't close by inflating the point into a metaphor. The clearest concrete sentence already written is the ending.

## Formatting

- **(WRT-19) No emoji in headings.**
- **(WRT-20) No mid-sentence decorative bold.** Bold marks structure for scanning, not applause.
- **(WRT-21) No bullet lists where prose reads better.** Three connected thoughts are a paragraph, not a list.
- **(WRT-22) No headers over two-sentence sections.**
- **(WRT-23) No em-dash clusters.** In microcopy, zero. In long-form, one or two per piece, and only where they beat commas or periods.

## Microcopy

- **(WRT-24) No cutesy error messages.** "Oops! Something went wrong" tells the user nothing. Say what happened and what to do next.
- **(WRT-25) No blame-the-user copy.** "You entered an invalid email" → "That email is missing an @".
- **(WRT-26) No exclamation-point enthusiasm in system messages.** The product stays calm; the user brings the feelings.
- **(WRT-27) No hedging where the UI must commit.** "You might want to consider saving" is a label failing its job. "Save draft."
- **(WRT-28) No vague verbs on buttons.** "Submit", "OK", "Continue" where a specific verb fits: "Save draft", "Delete 3 files", "Send invite".

## The slop test

If a reader who has skimmed a thousand AI-written pages would glance at the copy and say "yep, AI wrote this", the writing fails. The positive test is short: lead with the point, active voice, concrete numbers over abstract claims, a named source behind every "research says", every sentence earning its place. Read it aloud; if you wouldn't say it to a sharp colleague, don't ship it.
