---
name: writing-pr-descriptions
description: >
  Use when drafting or rewriting a GitHub PR description — including running `gh pr create`, filling
  the GitHub UI, or summarising a feature branch for review. Produces a short, plain-English summary
  for human reviewers on top, with an optional collapsed details block for AI reviewers underneath.
  Trigger whenever the user asks to open a PR, write a PR body, or clean up an existing description
  that has become too verbose. Do NOT use for commit messages or internal design docs.
---

# Writing PR Descriptions

A PR description has two audiences with opposing needs:

- **Humans** (reviewers, future spelunkers in `git log`) need a short, plain-language summary they can read in 10 seconds.
- **AI reviewers** benefit from more structure and detail to ground their review.

Default LLM output optimises for the second audience and overwhelms the first. This skill flips the priority: **humans first, always.** AI-oriented detail is optional, collapsed, and clearly demarcated.

## The structure (every PR follows this)

```markdown
## Summary

<One or two plain-English sentences. What changed, in human terms.>

- <One sentence: a change or its reason>
- <One sentence: a change or its reason>
- <One sentence: a change or its reason>
**Jira:** <Link to associated Jira ticket>

<details>
<summary>Details for AI reviewers</summary>

<Structured / verbose content here: file-by-file notes, design rationale,
edge cases, follow-ups, risks. Use headers and tables freely.>

</details>
```

## Rules for the human summary

1. **Open with one or two plain sentences.** Describe the change the way you would explain it to a colleague at coffee. No `## Changes` / `## Motivation` headers, no "This PR…" preamble, no file dump.
2. **Bullets are one sentence each, maximum five.** If a bullet needs two sentences, it belongs in the AI details block.
3. **Mix what + why.** The reader should understand both without scrolling.
4. **No nested headers inside the summary.** The summary is the headline, not a document.
5. **No "Test Plan" / "How to test" section.** This org does not use them — do not add one, even if a template suggests it.
6. **No emojis** unless the user explicitly asked for them.
7. **Reference the ticket once.** Either at the end of the lead sentence or as a final bullet — never both.

## Rules for the AI-reviewer details

- Wrap in `<details><summary>Details for AI reviewers</summary> … </details>` so humans can collapse it.
- This is the place for verbose content: file-by-file breakdown, sequencing notes, alternatives considered, risks, follow-up work, links to traces / dashboards.
- **Optional.** Skip entirely for trivial PRs (typo fix, version bump, single-line change).

## Quick reference

| Audience | Section | Budget | Style |
|----------|---------|--------|-------|
| Humans | `## Summary` + bullets | 1–2 sentences + ≤ 5 single-sentence bullets | Plain English, what + why |
| AI reviewers | Collapsed `<details>` block | As long as needed | Structured, technical, exhaustive |

## Example

### ❌ Default verbose style (avoid)

```markdown
## Summary
This pull request introduces a new field `transaction_extend.arn` to the
Debezium CDC pipeline. The change is necessary because downstream consumers
have been unable to correlate `transaction_extend` rows back to the original
authorisation since the `transaction_id` rolls between extends...

## Changes
- Modified `application.properties.optpl` to add `arn` to the include list
- Updated `docker-compose.yml` to wire the new env var
- Adjusted `inject_secrets.sh` to keep local dev in sync
- ...

## Test Plan
- [ ] Run `docker-compose up` locally
- [ ] Verify `arn` appears in Kafka topic
- [ ] ...
```

### ✅ Skill output

```markdown
## Summary

Capture the `arn` column on `transaction_extend` so downstream consumers can join extends back to the original card auth. Closes PROJ-407.

- Adds `arn` to the Debezium column include list for `transaction_extend`.
- Wires the new column through `docker-compose` so local dev mirrors prod.
- No consumer changes yet — schema-only, safe to deploy ahead of readers.

<details>
<summary>Details for AI reviewers</summary>

**Files**
- `docker/local/debezium/application.properties.optpl` — added `arn` to `column.include.list`.
- `docker/local/docker-compose.yml` — passes the new column through to the connector env.
- `bash/inject_secrets.sh` — no functional change; keeps local env in sync.

**Why ARN specifically:** ARN is the only reliable join key between an extend row and the originating authorisation once the original `transaction_id` has rolled.

**Risk:** schema-only change. No consumer currently depends on the column, so the connector can be deployed before any reader.

</details>
```

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Summary opens with "This PR…" / "This pull request…" | Drop the preamble — lead with the change itself. |
| Bullets are multi-sentence paragraphs | Move the second sentence into the AI details block. |
| Includes a `## Test Plan` / `## How to test` section | Delete it — not used here. |
| Sub-headers (`### Changes`, `### Motivation`) inside the summary | Flatten them into bullets. |
| File-by-file list in the summary | Move to the AI details block. |
| Closes/refs scattered through prose **and** bullets **and** footer | Pick one place. End of lead sentence or final bullet. |
| `<details>` block opens with another `## Summary` header | The collapsed block has its own context — don't repeat the top summary. |

## When to use

- Drafting any new PR (`gh pr create`, GitHub web UI, internal PR template).
- Rewriting an existing PR description that became too verbose.
- Summarising a feature branch before merge.

## When NOT to use

- Commit messages — different conventions (see `CLAUDE.md`).
- Internal design docs / RFCs — those want more depth up front, not less.
- Release notes — different audience and structure.

## Red flags — stop and restructure

If you catch yourself writing any of these, the description is drifting back toward the verbose default:

- A sentence longer than one line in the summary.
- More than five bullets above the `<details>` block.
- A `## Test Plan` heading anywhere.
- A `### Changes` or `### Motivation` sub-header inside the summary.
- The phrase "This PR…" or "This pull request…" as the opening words.
- A file-by-file list outside the `<details>` block.

Delete and restart that section using the structure above.
