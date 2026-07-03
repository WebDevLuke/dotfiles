# Triage pattern

Standard shape for skills that produce a list of findings (PR comments, audit issues, performance hits, security gaps, etc.) and let the user decide what to do with each. Covers the whole lifecycle: how a finding is structured, how the list is presented, how the user is asked to triage, and the broad shape of the action phase.

The skill itself owns what specifically happens to each decision (e.g. apply edits, post replies on a PR thread, append to a follow-up doc) — that part is too varied to share.

## 1. Finding format

Each finding is a markdown block separated by `---`:

```markdown
---
**Severity:** CRITICAL | HIGH | MEDIUM | LOW
**File:** `path/to/file.tsx:42` (or just the path for file-level findings)
**Summary:** one-line description of the issue

**Issue:** 1–3 sentences explaining what's wrong and where, with enough context that a reviewer understands without opening the file.

**Risk:** one sentence — what happens if this isn't fixed.

**Fix:** 1–2 sentences describing the concrete change.

**Before:**
​```{lang}
// exact snippet that must match the file
​```

**After:**
​```{lang}
// replacement snippet
​```
---
```

### Field rules

- **Severity is relative to the skill's category.** A CRITICAL accessibility issue is critical *for accessibility*; not equivalent to a CRITICAL security issue. When findings are merged across categories (e.g. by `/full-review`), qualify the label (`[CRITICAL / Accessibility]`).
- **`Before:` and `After:` snippets must be exact** — they get used directly with the `Edit` tool by downstream consumers. Whitespace, casing, and quotes must match the file.
- **For file-level findings with no discrete snippet** (e.g. "split this file", "add a missing test file"), omit `Before:` and `After:` and put the full detail in `Fix:`.
- **Skills that don't need machine-actionable output** (e.g. `/review-pr-comments` consuming GitHub comment threads, `convention-drift` flagging cross-file or rename-drift pointers) may **omit `Before:` / `After:` entirely** and treat `Fix:` as a description of the change. The other fields stay.
- **No issues found** → output exactly: `No findings.` Don't pad with explanations.
- **Don't wrap the whole response in a code fence**, and don't add introductions or summaries — just the finding blocks separated by `---`. Wrapping in a fence breaks parsing for skills that consume the output (`/full-review`).

### Field labels can be adapted to source

When findings come from a non-code source, swap field labels to suit. For example, `/review-pr-comments` uses:

```markdown
**Reviewer:** @username
**Comment:** [verbatim comment text]
```

…in place of `**Issue:**`, since the "issue" is literally the reviewer's comment. Keep the structural shape (one finding per block, separated by `---`); adapt labels where it improves clarity.

## 2. Present the summary

Present ALL findings as a numbered list **in chat**, before any `AskUserQuestion` calls. Each finding gets:

```
### [N]. [SEVERITY] [file:line] — [one-line summary]

**Issue:** [or **Reviewer:** + **Comment:** for PR comments]
**Risk:** [why it matters — what breaks or who is affected]
**My assessment:** [agree / partially agree / disagree — with brief reasoning]
**Suggested action:** [specific fix / accept as-is / defer with follow-up]
```

`My assessment:` and `Suggested action:` are agent-synthesised fields layered on top of the raw finding — your judgement of whether the issue is real, and what you'd recommend doing.

After the full list, show a tally:

```
- X CRITICAL · X HIGH · X MEDIUM · X LOW
- X to fix · X to accept · X to defer (your recommendations)
```

## 3. Triage with AskUserQuestion

Use `AskUserQuestion` to ask about findings, **batching up to 4 per call** (the tool's limit). For each finding:

- The `header` includes the finding number, severity, and a short hint (e.g. `#3 HIGH file.ts:42`)
- The question text restates the **full assessment** so the user doesn't need to scroll up to the summary
- Present 2–3 options with short `label` and `description`. Be opinionated — put the recommended action first with `(Recommended)`.

If there are more than 4 findings, send multiple `AskUserQuestion` calls sequentially until all are covered.

**Collect all decisions before actioning anything.** After each answer, briefly acknowledge the choice in one line and move on.

### Default option set

For most audit/review skills:

- **Fix now** — apply the change in this session
- **Accept as-is** — no action; intentional or not worth fixing
- **Defer with follow-up** — capture in a follow-up note (Jira ticket, TODO comment, plan doc) — the skill defines where

Skills that map cleanly onto a binary decision (e.g. `/review-pr-comments`) may use **Address** / **Don't address** instead. Whatever labels you pick, keep the semantic shape (a "do it now" + a "skip it" + optionally a "defer it" path) so users get a consistent feel.

## 4. Action

Once all decisions are collected, the skill applies them. The shape varies by skill:

- **Fix now** items → make the code change directly via `Edit`. Note each fix in one line: `✓ Fixed: {file}:{line} — {summary}`.
- **Defer** items → write to wherever the skill specifies (e.g. a GitHub issue via `gh issue create`, `plans/`, a Jira ticket, a code-level TODO).
- **Accept** items → no action. Just count them for the final tally.

Each skill describes its own deferral target and any side-effects (e.g. posting replies on PR threads, annotating a report file). After all actions are done, show a one-line tally:

```
Done — {F} fixed · {A} accepted · {D} deferred
```

Run a quick re-read of changed files only to verify no new issues were introduced.

## Why this shape

- **List in chat first** so the user gets the full picture before being interrupted by interactive questions. Without this, the only place to see the findings is buried in `AskUserQuestion` headers — hard to scan, hard to refer back to.
- **Batched questions** so users can rip through small/obvious findings quickly without one-question-at-a-time fatigue.
- **Collect-before-act** so users can change their mind mid-triage; nothing is destroyed until the whole pass is done.
- **Consistent shape across skills** so users don't have to relearn the flow each time.
