---
name: writing-jira-descriptions
description: Structure Jira ticket descriptions with a lean human summary, always-visible Given/When/Then acceptance criteria, and a collapsed "Details for AI agents" expand (ADF) for verbose technical content. Use whenever creating or rewriting a Jira ticket description, in any flow.
---

# Writing Jira Descriptions

A Jira description has two audiences with opposing needs:

- **Humans** (the assignee, reviewers, future readers) need a short, plain-language summary and a clear bar for "done" they can read in 10 seconds.
- **AI agents** picking up the ticket benefit from structured, exhaustive detail to ground their work.

Default LLM output optimises for the second audience and overwhelms the first. This skill flips the priority: **humans first, always.** AI-oriented detail is collapsed inside a Jira expand (accordion) and clearly demarcated.

This is the house format: apply it to every Jira description you create or rewrite, whether invoked explicitly or as part of another flow (e.g. creating follow-up tickets, split-ticket output).

## The structure (every ticket follows this)

Visible part, in order:

1. **Lead** - one or two plain-English sentences describing the change and why. No heading above it, no "This ticket..." preamble.
2. **Bullets** - up to 5, one sentence each, mixing what + why. When the ticket explains a change to existing behaviour, use a concrete before/after scenario ("Today X happens... After the change, Y happens...").
3. **Acceptance criteria** (`### Acceptance criteria`) - always visible, never inside the expand. Given/When/Then format, one bullet each, covering user-facing behaviour and the verification gates (typecheck, lint, build, tests). If the criteria are inferred rather than stated, still write them, and flag the inferred ones to the user in chat so they can correct them.
4. **Repo** (`### Repo`) - one line naming the target repo(s), when known.

Collapsed part:

5. **Expand titled "Details for AI agents"** - the verbose content: background/mechanics, scope of work, constraints and evidence, verification steps, file paths, alternatives considered, risks. Use whatever `###` headings fit the ticket; don't force a fixed set.

## Rules for the visible part

- Lead sentence describes the change the way you'd explain it to a colleague - no headers, no file dumps.
- Bullets are one sentence each, maximum five. A bullet needing two sentences belongs in the expand.
- If a motivation is commonly assumed but wrong, say so explicitly in a bullet (e.g. "Bundle size is not the motivation - ...").
- Reference related tickets once, where most relevant - not scattered through prose and bullets.
- No emojis unless asked.

## Rules for the expand

- Title it exactly `Details for AI agents`.
- This is the place for exhaustive content: mechanics, file-by-file notes, evidence from investigations, "do not do X" warnings for future agents, verification technique details.
- **Skip it entirely for trivial tickets** (config tweak, typo, one-liner) - those get just the lead, bullets, and acceptance criteria.

## ADF mechanics

Jira expands cannot be expressed in Markdown. Use the Atlassian MCP with `contentFormat: "adf"` and pass the description as an ADF document object:

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    { "type": "paragraph", "content": [{ "type": "text", "text": "Lead sentence..." }] },
    { "type": "bulletList", "content": [ ... ] },
    { "type": "heading", "attrs": { "level": 3 }, "content": [{ "type": "text", "text": "Acceptance criteria" }] },
    { "type": "bulletList", "content": [ ... ] },
    {
      "type": "expand",
      "attrs": { "title": "Details for AI agents" },
      "content": [ headings, paragraphs, bulletLists... ]
    }
  ]
}
```

- Inline code: text nodes with `"marks": [{ "type": "code" }]`. Bold (for **Given**/**when**/**then**): `"marks": [{ "type": "strong" }]`.
- Gotcha: MCP read-backs render descriptions as flattened Markdown, so the expand looks like a plain heading in tool results even when it saved correctly. If the edit was accepted without error, the expand is there; suggest a browser glance rather than re-editing.

## Fallback for legacy renderers

Some contexts don't render ADF expands - notably ISD's legacy wiki-renderer fields (see memory: ISD plan fields use the legacy renderer). There, keep the identical structure but replace the expand with a plain `### Details for AI agents` section. Same content, no accordion.

## Red flags - stop and restructure

- The lead opens with "This ticket..." / "This task...".
- A bullet runs to multiple sentences.
- Acceptance criteria ended up inside the expand, or missing entirely.
- File-by-file detail or investigation evidence above the expand.
- An expand on a ticket with nothing technical to say.

## When NOT to use

- GitHub PR descriptions - use `writing-pr-descriptions` (this skill is its Jira sibling).
- Jira comments - keep those short and freeform.
- Confluence pages, release notes, commit messages.
