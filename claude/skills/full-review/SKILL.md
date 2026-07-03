---
name: full-review
description: Run 15 bundled specialist reviewers (accessibility, perf-scan, security-review, html-review, abstract, coding-standards, responsive-design, convention-drift, seo-review, web-design-guidelines, bughunt, test-review, schema-review, dep-review, intent-review) in parallel across one or more repos and produce a consolidated categorised report. Triages findings with the user, applies approved fixes, and optionally proposes guidance/hooks to prevent recurring issues.
---

Orchestrates 15 specialist reviewers in parallel across one or more repos, consolidates their findings into a single categorised report with severities, and triages each finding with the user before applying fixes. The reviewers are bundled with this skill as trimmed briefs under `reviewers/` - they are not standalone skills.

Use this skill both as a heavyweight pre-PR audit and as the lighter pre-push gate (pick "Uncommitted changes" scope - the `convention-drift` reviewer specifically covers what previously lived in `/pre-review`).

Follow the communication style in CLAUDE.md - terse, concise, no unnecessary preamble.

## No auto-fixes - non-negotiable

**Fixes are NEVER applied automatically.** Under no circumstances should this skill modify any code based on findings without the user explicitly selecting "Fix now" for each individual finding via the triage step. This rule applies even if:

- All findings look trivial
- The user has run this skill before and approved similar fixes
- A fix seems obviously correct from the `before`/`after` snippets
- The scope is tiny and the findings are few

The skill produces a report and triages findings. The user makes every decision. Applying a fix without explicit per-finding approval is a violation of this skill's contract.

## Input

Accepts zero or more arguments:

- **No arguments** -> fresh run. Discover candidate repos with uncommitted changes (Step 1) and execute Steps 0-12 in order.
- **Report path** (e.g. `/full-review reports/full-review-2026-04-14-1530.md`) -> resume mode. **Skip Steps 0-8 entirely**, load the existing report, and jump straight to Step 9 (present + triage). No agents are launched, no new report is written.
- **One or more repo directories** (e.g. `/full-review ~/git/foo ~/git/bar`) -> multi-repo scoped scan. Skip discovery in Step 1 and scan those repos' `git diff` + `git diff --cached`.
- **File paths or globs** (e.g. `/full-review src/**/*.tsx`) -> single-repo path-scoped scan against the cwd.

Detection rule: for any existing `.md` arg, peek at the file's first line and treat it as a resume-mode report if that line starts with `# Full Review -`, regardless of the file's location (not just under a `reports/` prefix). An arg that resolves to a directory containing a `.git` entry (i.e. a repo root) is a repo directory. Anything else is treated as a file path or glob. If an arg is ambiguous, ask via `AskUserQuestion`.

Resume mode is useful when:

- The user wants to revisit a prior report and triage findings they previously deferred or skipped
- The triage session was interrupted and the user wants to continue
- The user has manually reviewed a report and is ready to action items without re-scanning

## Resume mode (Step A)

When a report path is provided:

1. **Verify the file exists** at the given path. If not, output `Report not found: {path}` and stop.
2. **Parse the report**:
   - Read the file and extract the metadata header (scope, reviewers run, tally)
   - Parse each finding by splitting on `### #{N}` headings - capture ID, severity, category, file:line, summary, Issue, Risk, Fix, Before/After diff blocks, and any "Also flagged by" annotations
   - Preserve the global sequential IDs from the report
3. **Skip to Step 9** (present summary) using the parsed data.

Parsing should be tolerant of:
- Reports that have already had some findings actioned (a prior triage session). Detect actioned findings by the `**Status:**` prefix that Step 10 always writes on the line after the `### #{N}` heading, regardless of which state follows (`✓ Fixed`, `→ Deferred to GitHub issue #{N}`, `→ Deferred (no issue - {reason})`, `- Accepted as-is`, or `✗ Stale`). Surface that state and let the user re-triage only unactioned findings by default (ask via `AskUserQuestion` whether to re-triage already-actioned items or skip them).
- Missing Before/After blocks -> treat as file-level findings.
- Minor formatting variations - don't be strict about whitespace or exact header style.

If the report has zero findings (empty or only the header), output `Report has no findings - nothing to triage` and stop.

## Reviewers orchestrated

Each reviewer is a trimmed brief at `reviewers/{name}.md` inside this skill's directory (`~/.claude/skills/full-review/reviewers/`).

| Reviewer | Covers | Stack requirement | Scope requirement |
|-------|--------|-------------------|-------------------|
| `accessibility` | WCAG 2.1 AA compliance | HTML/JSX/TSX present | any |
| `abstract` | code reuse, quality, efficiency | any | any |
| `bughunt` | runtime bugs - logic, state/data flow, concurrency/timing | any | any |
| `coding-standards` | naming, readability, immutability, TypeScript discipline | any | any |
| `convention-drift` | CLAUDE.md compliance, cross-file ripple, rename drift, documentation drift, multi-branch consistency | any | uncommitted changes only |
| `dep-review` | unused/outdated/deprecated deps, license drift, duplicate-purpose packages (excludes CVEs - owned by `security-review`) | manifest file present | any |
| `html-review` | HTML structure, semantics, landmarks | HTML/JSX/TSX present | any |
| `perf-scan` | rendering, assets, layout, WebGL, bundle delta | any | any |
| `responsive-design` | container queries, fluid typography, breakpoint strategies | CSS/HTML/JSX/TSX present | any |
| `schema-review` | migration safety, missing indexes, N+1 queries, RLS gaps, schema drift, missing constraints | migrations / schema / query files present | any |
| `security-review` | auth, input validation, secrets, OWASP, CVE checks | any | any |
| `seo-review` | titles, meta, Open Graph, headings, structured data, canonicals, crawlability | HTML/JSX/TSX present | any |
| `test-review` | assertion quality, mock-heavy tests, brittle queries, snapshot abuse, missing edge cases | test files present | any |
| `web-design-guidelines` | Web Interface Guidelines - UX, interaction, visual polish | HTML/JSX/TSX present | any |
| `intent-review` | acceptance-criteria verification against the diff (Jira ticket or plan file) | any | requires a supplied ticket key or plan path |

The briefs are review-native: no orchestration, scope selection, or triage of their own - each returns findings directly in the structured format the agent prompt specifies. `bughunt` covers its three lenses (logic, state/data flow, concurrency/timing) inside a single reviewer, labelling findings by lens; those dedupe naturally into the merged report via Step 6.

Four briefs (`accessibility`, `security-review`, `coding-standards`, `responsive-design`) are derived copies of standalone skills of the same name, which continue to exist for while-coding guidance. When updating checks in either place, update both - each derived brief carries a header comment pointing at its source.

The `simplify` skill is intentionally excluded - it duplicates the `abstract` reviewer.

`convention-drift` only runs against "uncommitted changes" scope - its checks (rename drift, "test exercises the change", multi-branch consistency) are intrinsically diff-relative and don't make sense for a whole-repo or path-glob scan.

## Step 0: Verify all reviewer briefs are present

Check that each brief exists at `~/.claude/skills/full-review/reviewers/{name}.md` for the 15 reviewers (a single `ls` of the directory suffices). If **any** are missing, output:

```
Missing reviewer briefs: {list}
The full-review skill install is broken - re-run setup/claude.sh from the dotfiles repo.
```

And **stop**. This is a strict dependency check - partial runs produce misleading reports.

## Step 0b: Choose which reviewers to run (first decision)

Before anything else - **including scope** - let the user pick which reviewers run. This is intentionally the **first decision** the skill asks for, so a focused review (e.g. security + accessibility only) can be scoped up front rather than after the stack is known. **All reviewers run by default**, except `intent-review`, which is opt-in and off unless a Jira ticket key or plan-file path is available (supplied as an arg or via a single up-front prompt) - include it in the selectable set only when such input exists, and default it on in that case. Choices apply to this invocation only and are never persisted; the next run starts with everything enabled again.

Skip this step in resume mode (Step A) - no agents are launched there.

Present the full set of reviewers from the table above. Stack/scope filtering happens later in Step 2, which silently drops any selected reviewer that doesn't apply to the resolved scope (e.g. `convention-drift` outside diff mode, frontend reviewers with no HTML/JSX).

Use `AskUserQuestion`:

1. **Gate question** (single-select), header `Reviewers`:
   - **Run all (Recommended)** - run every reviewer that applies to the scope. Default path.
   - **Customise** - pick which to skip.

   List the reviewer names in the question text so the user sees what "all" means.

2. If the user picks **Customise**, present the reviewers as multi-select options to deselect. `AskUserQuestion` allows **at most 4 options per question** (and at most 4 questions per call), so with more than 4 reviewers you must **split them across multiple multi-select questions in a single call**. For the current 15 reviewers, use four `multiSelect` questions (4 + 4 + 4 + 3 options; headers `Skip 1/4`, `Skip 2/4`, `Skip 3/4`, `Skip 4/4` - the `header` field is capped at ~12 chars); each option's label is the reviewer name and its description is the "Covers" text from the table. **Anything the user selects across those questions is skipped**; anything left unselected still runs. If the user ends up skipping every reviewer, output `No reviewers left to run - nothing to review` and stop.

Call the resulting set **S** (the user-enabled reviewers) and carry it into Step 2. Log S before proceeding.

## Step 1: Confirm scope (and discover repos)

### 1a. Discover candidate repos

If invocation args supplied repo directories or file paths, use them as the scope directly (skip to Step 2).

Otherwise, discover candidate repos with uncommitted changes:

1. Start from cwd. Add it to the candidate set if `git diff` or `git diff --cached` is non-empty.
2. Walk the parent directory of cwd. For each sibling that contains a `.git/` directory, run the same diff check. Add to the candidate set if non-empty.
3. Cap discovery at one parent level - do not walk further out. This keeps the search predictable.

Call this set **R** (candidate repos with changes).

### 1b. Present the scope picker

Use `AskUserQuestion` with:

- **Uncommitted changes ({N} repo(s): {names})** (Recommended) - scan `git diff` + `git diff --cached` across the selected repos. Only shown if R is non-empty.
- **User-specified paths** - take glob patterns or file paths as a follow-up. Single-repo (cwd).
- **Whole repo (cwd)** - scan all source files. Flag this as slow and noisy. Single-repo (cwd).
- **Other** - let the user describe a different scope.

If R has more than one repo, follow up with a multi-select `AskUserQuestion` letting the user deselect any repos in R they want to skip. Default is "all of R selected".

If R is empty and the user declines to provide paths or a whole-repo scope, output `Nothing to review` and stop.

If the user picks paths, ask a follow-up `AskUserQuestion` or prompt inline for the glob.

The resolved scope is one of:

- `{ mode: "diff", repos: [<abs-path>, ...] }` - multi-repo diff scan (1+ repos)
- `{ mode: "paths", repo: <abs-path>, files: [...] }` - single-repo path-scoped scan
- `{ mode: "whole-repo", repo: <abs-path> }` - single-repo full scan

## Step 2: Detect stack and trim reviewer list

Apply these filters only to the reviewers in **S** (the set the user enabled in Step 0b) - the final run set is `S ∩ applicable`. Inspect the scope to decide which of the enabled reviewers actually apply:

- `html-review` -> requires scope to contain `.html`, `.tsx`, or `.jsx` files
- `accessibility` -> same as `html-review`
- `seo-review` -> same as `html-review`
- `web-design-guidelines` -> same as `html-review`
- `responsive-design` -> requires scope to contain `.css`, `.html`, `.tsx`, or `.jsx` files
- `convention-drift` -> requires scope mode `diff` (skip for `paths` and `whole-repo`)
- `test-review` -> requires scope to contain test files (`*.test.*`, `*.spec.*`, `*_test.{go,py,rb}`, anything under `__tests__/`, `tests/`, `test/`, `spec/`)
- `schema-review` -> requires scope to contain migration files (`migrations/`, `prisma/migrations/`, `db/migrate/`, `supabase/migrations/`, `alembic/versions/`), schema definitions (`schema.prisma`, `schema.rb`, `*.sql` schema dumps), RLS / policy files, or files containing ORM query calls (`.from(...)`, `.select(...)`, `prisma.X.find*`, etc.)
- `dep-review` -> requires a dependency manifest in scope (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `requirements.txt`, `Gemfile`). In `diff` mode, also requires the diff to touch the manifest or lockfile (skip otherwise - no point running the full audit on every diff).
- `intent-review` -> requires a Jira ticket key or plan-file path to be supplied (as an arg or via a single up-front prompt); skip silently if none is available.
- `abstract`, `bughunt`, `coding-standards`, `perf-scan`, `security-review` -> run on any stack

Stack detection runs against the **union** of files across all repos in scope, not per repo. An applicable reviewer gets an agent for **every repo in scope** (see Step 4's dispatch arithmetic and the formula in Step 3) - so if any repo in scope has `.tsx`, the frontend reviewers run for every repo in scope.

Reviewers that don't apply (or that the user disabled in Step 0b) are skipped silently - they appear neither in the report's "Reviewers run" header nor anywhere else. Log the final `S ∩ applicable` run set before proceeding.

## Step 3: Warn on large scope

Count files in scope across all repos. Agent count = `reviewers × repos`, where `reviewers` is the final `S ∩ applicable` run set from Step 2 (see Step 4's dispatch). Also measure the total diff size (changed lines across all repos in scope). Warn if **>30 files** OR **>40 agents total** OR the total diff exceeds **~1500 changed lines**, via `AskUserQuestion`:

```
Large scope: {N} files, {L} changed lines, {R} repo(s), {M} reviewers = {agents} agents.
This will use significant tokens.
```

Options: **Proceed** / **Narrow scope** / **Cancel**. Narrow -> prompt for a tighter glob (single-repo) or ask which subset of R to drop (multi-repo) and recount.

## Step 4: Launch reviewer agents in parallel

For each applicable reviewer, read its brief from `~/.claude/skills/full-review/reviewers/{name}.md` and inline the full content into an agent prompt. Skills can't be invoked from an agent - the reviewer instructions must be inlined.

**Multi-repo dispatch:** one agent per `(reviewer, repo)` pair. So 3 repos × 6 applicable reviewers = 18 agents. Each agent receives only its repo's diff (or scoped files) - never the union. This keeps the diff small enough for the agent to read fully and preserves per-repo context for the finding.

**Trim the inlined diff before dispatch:** strip binary hunks, lockfiles, and generated / vendored paths from the diff handed to each agent - they add noise and burn tokens without being reviewable. (`dep-review` only needs to know that the manifest changed, not the lockfile body, so drop the lockfile diff for it too.)

Launch all agents in a **single message** for parallel execution. Use `subagent_type: "general-purpose"`.

**Model per reviewer:** pass `model: "sonnet"` on every Agent call **except** `bughunt` and `security-review`, which omit the override and inherit the session model. Reviewing a diff against a focused brief is bounded work Sonnet handles well, and the fan-out (reviewers × repos) makes it the cost hotspot - but bug hunting and security analysis are judgement-heavy, so those two keep the stronger model.

**Agent prompt template:**

```
You are running a code review based on the following reviewer brief:

---
{full contents of ~/.claude/skills/full-review/reviewers/{name}.md}
---

Repo: {absolute path of the repo}
Repo name (for finding labels): {basename of the repo}

Apply that reviewer brief to these files (relative to the repo root):

{scope files or diff for this repo}

Return findings as structured markdown blocks per the format defined in `~/.claude/docs/triage-pattern.md` (section 1). One block per finding, separated by `---`. Severity is relative to this reviewer's category.

Prefix every `File:` value with `{repo name}/` so downstream merging can disambiguate cross-repo findings. Example: `File: gameboxcollection/lib/foo.ts:42`.
```

## Step 5: Handle agent failures

If an agent's output can't be fully parsed as structured finding blocks (garbled, truncated, or obviously off-task):

1. **Salvage** - extract every valid finding block from the output and keep it. Only the malformed remainder is discarded; note in the failure line that the agent was partially salvaged rather than dropped whole.
2. **Retry once** - re-dispatch the failed `(reviewer, repo)` agent a single time before giving up. If the retry also fails, record it as failed.
3. **Record** - continue with the remaining agents, and record each failed `(reviewer, repo)` in the report's metadata header so resume mode can offer to re-run just the gaps.

Include failed reviewers at the top of the report and in the metadata header:

```
⚠ {reviewer} failed: {reason}
```

Add a metadata line to the report header (see Step 8) listing the gaps:

```
**Reviewers failed:** {reviewer} ({repo}), {reviewer} ({repo})
```

## Step 6: Parse, merge, dedupe, and number findings

Parse each agent's markdown output by splitting on `---` separators and extracting the labelled fields (Severity, File, Summary, Issue, Risk, Fix, Before, After). Track the originating repo for each finding (derived from the `{repo-name}/` prefix on the `File:` value).

Combine findings from all agents and dedupe overlapping entries:

- Same file + line + similar summary -> merge into one finding and record the overlap as a standalone `**Also flagged by:** {other reviewer}` line placed **after** the diff block (not inside the Issue field)
- If severities differ, keep the highest
- Dedupe is **within a single repo only** - the same file path in different repos is genuinely different code

Then assign a **global sequential ID** (`#1` through `#N`) to every remaining finding in final report order:

1. Categories ordered by highest-severity finding present (CRITICAL-first category wins)
2. Within a category, CRITICAL -> LOW
3. Within a severity, no further ordering by repo - the ID sequence is repo-agnostic so a HIGH/Security finding in repo B can sit between two HIGH/Security findings in repo A

The ID must appear in the report and in every triage question, so the user can refer to any finding unambiguously by number.

## Step 7: Handle clean runs

If the merged list is empty (zero findings across all agents), skip the report file and output inline:

```
✨ No issues found across {N} files, {M} reviewers run.
```

If some agents failed (Step 5) but every surviving reviewer found nothing, do **not** imply full coverage. Include the `⚠` failure lines in the inline output and adjust the message so the gap is visible:

```
No issues found across {N} files ({M} reviewers run); {K} reviewer(s) failed - coverage is incomplete.
⚠ {reviewer} failed: {reason}
```

Then stop.

## Step 8: Write the report file

For any non-empty run, write a **single consolidated report** to disk at the invocation cwd, regardless of how many repos were scanned.

```bash
mkdir -p reports
grep -qxF "reports/" .gitignore 2>/dev/null || echo "reports/" >> .gitignore
TIMESTAMP=$(date +%Y-%m-%d-%H%M)
REPORT_PATH="reports/full-review-${TIMESTAMP}.md"
```

After writing the report file, **open it for the user** so they can read it in their editor while triage begins:

```bash
(command -v code >/dev/null && code "$REPORT_PATH") || open "$REPORT_PATH"
```

**Report structure:**

```markdown
# Full Review - {timestamp}

**Scope:** {uncommitted changes in N repos | N specific files | whole repo}
**Repos:** {list of repo names with absolute paths}
**Reviewers run:** {list}
**Reviewers failed:** {reviewer} ({repo}), ... (omit the line if none failed)
**Total findings:** {N}
**Tally:** {C} CRITICAL · {H} HIGH · {M} MEDIUM · {L} LOW

---

## Accessibility ({count})

### #{N} [CRITICAL / Accessibility] {repo}/{file}:{line} - {summary}

**Issue:** {description}
**Risk:** {risk}
**Fix:** {description from fix field}

```diff
- {before}
+ {after}
```

{if deduped: **Also flagged by:** {other reviewer}}

---

## Security ({count})

...
```

Severity labels always include the category (`[CRITICAL / Accessibility]`) so cross-category severities aren't confused. The `**Also flagged by:** {other reviewer}` line, when a finding was deduped, always sits on its own line after the diff block - never inside the Issue field. File paths always carry the `{repo}/` prefix so the user can tell at a glance which codebase a finding lives in (even in single-repo runs the prefix is consistent). Categories are ordered by highest-severity finding present. Within a category, findings are ordered CRITICAL -> LOW. Categories with zero findings are omitted.

## Step 9: Present and triage

Follow the shared triage pattern at [docs/triage-pattern.md](../../docs/triage-pattern.md), with three `/full-review`-specific tweaks:

1. **Present** - instead of repeating the full numbered list inline, summarise in chat (the report file already holds the detail) and tell the user where the full report lives:

   ```
   Full review complete -> reports/full-review-{timestamp}.md

   **{N} findings** across {R} repo(s): {C} critical · {H} high · {M} medium · {L} low

   By category:
   - Security: 2 (1 CRITICAL, 1 HIGH)
   - Accessibility: 5 (3 HIGH, 2 MEDIUM)
   - Performance: 3 (2 MEDIUM, 1 LOW)

   By repo (if multi-repo):
   - gameboxcollection: 6
   - dotfiles: 4

   Triage begins now - I'll walk through findings in batches.
   ```

   After this summary, offer a **triage-volume** choice via `AskUserQuestion` (header `Triage vol`, single-select) so the user isn't forced through every finding individually when the report is large:

   - **Triage all individually** - walk every finding one batch at a time (the default below).
   - **Bulk-accept all LOW (triage the rest)** - mark every LOW finding Accept as-is in one go, then triage CRITICAL/HIGH/MEDIUM individually.
   - **Triage CRITICAL+HIGH only, defer the rest** - triage CRITICAL and HIGH individually; Defer everything MEDIUM and below.

   Bulk decisions still **annotate the report per finding** (Step 10's Status lines) so resume mode can revisit any of them later - the bulk choice is a shortcut through triage, not a shortcut past the durable log.

2. **Triage** - the `AskUserQuestion` `header` is capped at ~12 chars, so put only the **global sequential ID** in the header (e.g. `#3 HIGH`) and carry the severity / category / file:line detail (e.g. `HIGH / Security - file.ts:42`) in the question **text**, not the header. This keeps findings referable by number while staying inside the header limit. Options: **Fix now** / **Accept as-is** / **Defer**.

3. **Order** - walk findings in **strict numerical order** (#1 -> #N), batching up to four per `AskUserQuestion` call. Do not reorder by severity, category, or "easy wins first" - the global IDs already encode the canonical order (category by highest severity present, then severity within category) and the user expects to triage in that exact sequence. Skipping or reordering breaks their mental model of the report.

**Discuss route:** if the user answers a triage question via the free-text "Other" option with a question or pushback rather than a decision, pause the batch, resolve the discussion (restating the recommended answer first), then re-ask that one finding. This does **not** switch the rest of triage to one-at-a-time - resume the normal batched flow once the finding is settled.

Collect ALL decisions before making any changes (Step 10).

## Step 10: Apply decisions

Process decisions by type. For each decision, also **annotate the source report file** (either the freshly-written one from Step 8 or the report path passed in resume mode) so the outcome is persisted. Annotations go immediately after the finding's `### #{N}` heading:

- `**Status:** ✓ Fixed ({timestamp})`
- `**Status:** → Deferred to GitHub issue #{N} ({timestamp})`
- `**Status:** → Deferred (no issue - {reason}) ({timestamp})`
- `**Status:** - Accepted as-is ({timestamp})`
- `**Status:** ✗ Stale - code changed since report ({timestamp})`

This means a report file becomes a durable triage log. If the user re-runs `/full-review {path}` later, the existing Status lines tell the skill what's already been handled.

**Defer preflight (per repo, once, before triage begins):** for each repo in scope, check `git remote -v` and `gh auth status` and cache the result alongside the label cache. If a repo cannot take issues (no remote, a non-GitHub remote, or an unauthenticated `gh`), warn the user up front. For any Defer decision on such a repo, do **not** attempt `gh issue create`; instead annotate the report `**Status:** → Deferred (no issue - {reason}) ({timestamp})` so the triage decision is still captured rather than lost.

### Fix now

For each approved fix:

1. Resolve the finding's file path to an absolute path by combining the originating repo (tracked in Step 6) with the relative portion of the `File:` value (strip the `{repo}/` prefix).
2. If the finding has Before/After snippets, use the Edit tool with those exact strings against the absolute path.
3. If there are no snippets (file-level change), pause and describe the approach before editing, then apply.

**If the Edit fails because the Before snippet no longer matches** (stale in resume mode, or invalidated by an earlier fix applied to the same file in this run): re-read the file and check whether the finding still applies.

- If the snippet merely drifted (the issue is still present but the surrounding code moved), adapt the edit to the current code, confirm the intent still holds, and apply.
- If the issue is already gone, do not edit; annotate the report `**Status:** ✗ Stale - code changed since report ({timestamp})` and count it as skipped.

**Resume mode:** before offering "Fix now" for a finding, verify its Before snippet still exists in the file. Surface stale findings during triage (rather than at apply time) so the user isn't offered a fix that can't land.

Note each fix in one line: `✓ Fixed: {repo}/{file}:{line} - {summary}`. Also annotate the report file as described above.

### Defer

For each deferred finding, create a GitHub issue in the **finding's originating repo** (not the invocation cwd). Run `gh` from the repo's directory so the right remote is selected:

```bash
(cd <repo-absolute-path> && gh issue create ...)
```

Cache `gh label list` output per repo - don't re-query it for every finding. Reuse existing labels; create missing category / severity labels once per repo via `gh label create` before opening issues.

The expected shape:

- **Title:** `{summary}` (concise, action-oriented)
- **Labels:**
  - One **category** label - one of `performance`, `accessibility`, `security`, `refactor`, `enhancement`, `design`, `bug`, `documentation`, `question`. Match the finding's nature.
  - One **severity** label - `severity: low` / `severity: medium` / `severity: high`. Map CRITICAL/HIGH -> high, MEDIUM -> medium, LOW -> low. If those labels don't exist in the repo, fall back to whatever severity scheme the repo already uses (or skip).
- **Body:**

```markdown
**Problem:** {risk}

**Solution:** {fix description}

**Source:** /full-review {timestamp} - {repo}/{file}:{line}
```

### Accept as-is

No action. Just count them for the summary.

## Step 11: Final summary and scoped verification

```
✓ Applied {F} fixes · Deferred {D} to GitHub issues · Accepted {A} as-is
```

If any fixes were applied, run a **scoped verification** - not the unbounded re-run-until-approved loop:

1. **Re-read the edited files only** to confirm the fixes landed cleanly and didn't obviously break the surrounding code.
2. Then **optionally offer one targeted re-review** via `AskUserQuestion`. If the user accepts, dispatch **only** the reviewers whose findings were fixed, scoped to **only** the edited files - typically 2-4 agents, launched once with **no loop**. Append any new findings to the **same report** with new sequential IDs continuing from the existing max, and triage them via Step 9.

This is deliberately a **single pass**. It is explicitly **not** a re-run-until-clean loop - one optional re-review of the touched files, then stop. If the user wants a full re-scan, they can re-run `/full-review`.

## Step 12: Prevention pass (opt-in)

A review fixes the instances. The prevention pass turns recurring instances into a rule so the same class of issue stops reaching review at all. It is **opt-in** - quick pre-push runs shouldn't pay for it.

Skip this step entirely in resume mode (Step A) and on clean runs (Step 7) - there's nothing to learn from.

### 12a. Offer the pass

After Step 11, ask once via `AskUserQuestion` (header `Prevention`, single-select):

- **Generate prevention guidance (Recommended)** - analyse the confirmed findings for recurring patterns and propose ways to stop them recurring.
- **Skip** - end here.

If the user skips, stop. Don't ask again this run.

### 12b. Find systemic patterns

Consider only **confirmed** findings - those the user marked **Fix now** or **Defer** in Step 10. Ignore **Accept as-is**: the user judged those non-issues, so they're not signal.

A finding is worth a rule only if it's **systemic**, not a one-off. Treat a pattern as systemic when any of:

- the same issue class appears **≥2 times** in this run (across files or repos), or
- it's a repeat of something a prior report already flagged (check `reports/` for older `full-review-*.md` with the same category + similar summary), or
- it's a single finding but clearly **mechanical and recurring by nature** (e.g. a missing-`alt` pattern, a loose-equality slip) where a rule obviously generalises.

Group the qualifying findings into pattern clusters. A one-off bug with no generalisable lesson produces **no proposal** - say so rather than inventing a rule.

### 12c. Choose a mechanism per pattern

For each cluster, pick the mechanism that actually prevents it - don't default to prose:

| Mechanism | Use when | Lands in |
|-----------|----------|----------|
| **CLAUDE.md guidance** | Judgement / convention / style a human-readable rule can carry (naming, structure, "prefer X over Y"). | Project `CLAUDE.md` if repo-specific; global `~/.claude/CLAUDE.md` if cross-project. State which. |
| **Hook** | Mechanically checkable, where prose won't reliably fire (format-on-save, a grep gate for a banned pattern, a lint/typecheck `PostToolUse` gate). | `settings.json` - delegate the actual write to the `update-config` skill. |
| **GitHub issue (tooling)** | Better solved by lint rule / CI config / dependency than by Claude guidance. | A `gh issue` in the originating repo, same pattern as Step 10's Defer. |

Prefer a **hook** over CLAUDE.md when the check is deterministic - a rule the model has to remember is weaker than a gate that always runs. Prefer **CLAUDE.md** when the issue needs judgement a hook can't encode. Propose exactly one mechanism per pattern.

### 12d. Triage proposals

Same contract as the rest of this skill: **never write to CLAUDE.md, settings.json, or open issues without per-proposal approval.** Present each proposal via `AskUserQuestion` with the concrete artefact in the question text (the exact CLAUDE.md sentence, the hook shape, or the issue title/body), options **Apply** / **Edit first** / **Skip**.

### 12e. Apply approved proposals

- **CLAUDE.md** - append the rule to the chosen file. For the global file, respect its 200-line cap (the file's own header) - if the addition would push it over, propose a `docs/` sub-file + link instead. Match the existing section style; don't reformat surrounding rules.
- **Hook** - hand off to the `update-config` skill (hooks live in `settings.json`; the harness, not this skill, owns that file). Pass it the trigger, matcher, and command.
- **GitHub issue** - reuse Step 10's Defer mechanics (`gh` run from the repo dir, cached labels), with a `tooling` / `enhancement` category label.

End with one line: `✓ Prevention: {C} CLAUDE.md rules · {H} hooks · {I} tooling issues` (omit if nothing was applied).

## Notes

- The full report stays on disk for reference - users can re-read, share, or diff across runs
- `reports/` is gitignored at the invocation cwd by design; these are transient working documents. In multi-repo runs the report lives only at the invocation cwd - the other scanned repos don't get a copy
- Re-running `/full-review` creates a new timestamped file - previous reports are preserved
- For very large codebases, remind the user that "whole repo" scope will produce a slow, noisy report - suggest narrowing to `app/`, `src/`, or a specific feature directory
- For multi-repo runs, watch the agent count (reviewers × repos × parallelism). Step 3's warning catches the obvious cases, but 4+ repos × all 15 reviewers can still get expensive
- Severity is **always relative to the category**. A CRITICAL accessibility issue is critical for accessibility, not equivalent to a CRITICAL security issue. The `[SEVERITY / Category]` label keeps this context visible
