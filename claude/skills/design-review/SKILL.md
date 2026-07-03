---
name: design-review
description: Analyse a web page for logic holes, visual inconsistencies, edge cases, and UX friction — no code review, purely design.
---

Review a web page's design quality by examining its component structure and visual rendering. This is a **design-only** audit — do not critique code quality, naming, architecture, or implementation patterns. Focus exclusively on what the user sees and experiences.

## Inputs

This skill accepts one or both of:

- **Component file path** — a page or component file (e.g. `app/settings/page.tsx`). Read it to understand the page's structure, states, and flows.
- **Screenshot** — an image file path. Read it to analyse the rendered visual layout.

If `$ARGUMENTS` is provided, treat it as the input (file path, screenshot path, or both space-separated). If no args are given, ask the user what page they want reviewed.

If only one input type is provided, proceed with what you have — but note in the report which audit categories would benefit from the missing input (e.g. "Visual consistency checks are limited without a screenshot").

## Step 0: Understand the page

Before auditing, build a mental model of the page:

1. **If a component file was provided:** Read the file and its key child components (one level deep — don't crawl the entire tree). Map out:
   - What states the page can be in (loading, empty, populated, error, etc.)
   - What user actions are available (buttons, links, forms, toggles)
   - What data drives the view and what happens when it's missing
   - What flows start or end on this page

2. **If a screenshot was provided:** Read the image and note:
   - Visual hierarchy — what draws the eye first, second, third
   - Spacing rhythm — is it consistent or irregular
   - Typography scale — are heading levels clear
   - Colour usage — is contrast sufficient, are colours meaningful
   - Alignment — do elements line up on a consistent grid

3. **Cross-reference** both inputs if available — flag anywhere the code implies a state the screenshot doesn't show, or where the screenshot reveals something the code doesn't obviously produce.

## Step 1: Audit

Review the page across four categories. For each finding, assign a severity:

- **Critical** — the user hits a dead end, loses data, or can't complete a core task
- **Warning** — confusing, inconsistent, or fragile — works but degrades the experience
- **Nit** — minor polish issue, non-blocking

### Logic holes

Look for:
- Missing states (no empty state, no loading state, no error state)
- Dead ends (actions with no feedback, flows that strand the user)
- Impossible or contradictory conditions (edit button visible but save is missing, delete confirmation but no cancel)
- Orphaned UI (elements that appear but serve no reachable purpose)
- Broken flow continuity (where does the user go after completing this action?)

### Visual consistency

Evaluate against general design principles (not project-specific tokens):
- Spacing rhythm — are gaps between elements consistent and intentional
- Typography hierarchy — do heading sizes, weights, and colours establish clear levels
- Colour meaning — are colours used consistently (e.g. red always means destructive)
- Alignment — do elements sit on a visible grid, or do things feel randomly placed
- Visual weight balance — is the page lopsided or cluttered in one area

### Edge cases

Consider what happens with:
- **Zero items** — empty lists, no results, first-time user with no data
- **Many items** — 100+ entries, long lists, pagination or scroll behaviour
- **Long text** — names, titles, or descriptions that overflow their container
- **Missing data** — optional fields that are null, images that fail to load
- **Narrow viewport** — does the layout break or become unusable on small screens
- **Rapid interaction** — double-clicking buttons, spamming form submissions

### UX friction

Look for:
- Unclear affordances (is that clickable? is this a button or a label?)
- Missing feedback (did my action work? is something loading?)
- Cognitive load (too many choices, unclear grouping, no progressive disclosure)
- Accessibility gaps (contrast, focus indicators, screen reader concerns visible from structure)
- Inconsistent patterns (similar actions styled differently across the page)

## Step 2: Report

Present findings as a **severity-ranked flat list**, worst-first. Each finding follows this format:

```
### [severity] Finding title
**Category:** Logic Holes | Visual Consistency | Edge Cases | UX Friction

One or two sentences describing the issue — what's wrong and why it matters to the user. Be specific: reference the exact element, state, or interaction.
```

Group consecutive items of the same severity under a shared severity heading to reduce visual noise:

```
## Critical

### Missing empty state for game shelf
**Category:** Logic Holes
...

### No error feedback on failed save
**Category:** Logic Holes
...

## Warning

### Inconsistent button sizing in header vs footer
**Category:** Visual Consistency
...
```

At the top of the report, include a one-line summary: total finding count broken down by severity (e.g. "**12 findings:** 2 critical, 5 warnings, 5 nits").

If a category had **no findings**, note it briefly: "**Visual Consistency:** No issues found."

If there is genuinely nothing to flag across all four categories, say so — don't invent findings to justify the review.

## Step 3: Triage findings

After delivering the full report, collect the user's decisions on **all findings at once before making any changes**. This is a two-phase process: first gather all answers, then apply fixes.

### Phase 1: Collect decisions

Walk through each finding **one at a time** using `AskUserQuestion`. Present the finding title and description as context, then ask the user what to do with it.

Every finding MUST be presented using the `AskUserQuestion` tool — never write options as plain text.

For each finding:

1. Write one sentence restating the issue as context
2. Call `AskUserQuestion` with:
   - `header`: the severity tag (e.g. "Critical", "Warning", "Nit")
   - `question`: the finding title phrased as "How do you want to handle: [finding]?"
   - Options (adapt based on severity and category):
     - **"Fix now (Recommended)"** — describe the expected corrected behaviour in design terms, then implement the fix
     - **"Defer"** — acknowledge and move on, optionally note it somewhere
     - **"Not an issue"** — user disagrees, skip it
     - **"Discuss further"** — dig deeper into this finding before deciding

3. After the user selects:
   - **Fix now:** Note the decision and move to the next finding. Do NOT make changes yet.
   - **Defer:** Note the decision and move to the next finding.
   - **Not an issue:** Accept without argument, move to the next finding.
   - **Discuss further:** Explore the finding — ask a follow-up question to understand the user's concern or intent, then re-present the action options. Once resolved, move to the next finding.

Continue until **every finding** has a decision.

### Phase 2: Apply fixes

Once all decisions are collected, present a summary of decisions (e.g. "Fixing 4, deferring 2, skipping 2") and then implement all "Fix now" items. For each fix:

1. Describe what the corrected version should look like in design language (what the user sees, not implementation details)
2. Make the changes
3. Briefly confirm what was done before moving to the next fix

After all fixes are applied, proceed to Step 4.

## Step 4: Self-review

After applying all fixes, verify each one actually resolves its finding. Do NOT skip this step.

For each "Fix now" item:

1. **Re-read the changed file(s)** — read the actual code that was modified, not from memory.
2. **Check against the original finding** — does the change address the specific issue described? Does it introduce any new problems visible to the user (broken layout, missing states, inconsistent styling)?
3. **Check cross-references** — if the fix added, removed, or renamed a UI element, verify that all navigation, menus, breadcrumbs, and index/listing components were updated to match.
4. **Verdict** — mark as **Verified** (fix resolves the issue cleanly) or **Needs revision** (fix is incomplete, introduces a new issue, or missed a cross-reference).

Present the self-review as a compact checklist:

```
## Self-review

- [x] Finding title — Verified
- [ ] Finding title — Needs revision: [what's wrong]
```

If any fix needs revision, correct it immediately and re-verify. Only present the final summary after all fixes pass self-review.

Final summary: how many were fixed (and verified), deferred, and dismissed.

## Rules

- **No code critique.** Never comment on code quality, naming, patterns, or architecture. The only reason to read code is to understand what the user sees.
- **Be specific.** "The spacing feels off" is not a finding. "The gap between the header and the first list item (32px) is double the gap between list items (16px), breaking the visual rhythm" is.
- **No invented findings.** If the page is solid, say so. A clean report is a valid outcome.
- **Stay in design language.** When describing fixes, talk about what the user experiences — not components, props, or CSS classes.
- **One question at a time** during triage. Never batch findings into a list of options.
