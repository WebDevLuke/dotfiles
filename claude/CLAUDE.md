# CLAUDE.md

> Keep this file under 200 lines. If it grows beyond that, abstract content into sub-files under `docs/` and link from here.

## Jira

If `docs/jira.md` is present (provided by a private plugin), follow it for full Jira workflows (via the Atlassian MCP). Otherwise there is no Jira integration configured.

Whenever you write or rewrite a Jira issue description - in any flow, whether or not the skill is explicitly invoked - always follow the `writing-jira-descriptions` skill (plain lead, ≤5 bullets, visible Given/When/Then acceptance criteria, and the verbose detail collapsed in a "Details for AI agents" ADF expand). This is the house format; use `contentFormat: "adf"` so the expand renders.

When estimating/pointing a Jira work item, follow the story-points guide in `docs/story-points.md` (Fibonacci 1/2/3/5/8/13; 8 hints at a split, 13 needs breaking down).

When a Jira issue is blocked (it has an open "is blocked by" link, or is in a Blocked status), prefix its title with a 🛑 emoji so blocked work is obvious at a glance. Remove the 🛑 once the blocker clears. Applies whenever you create or update issues.

## Agents and Skills

The source of truth for all Claude config is the **dotfiles repo** at `~/git/dotfiles/claude/`. Files are symlinked from there into `~/.claude/` by `setup/claude.sh`. **Never create agents or skills directly in `~/.claude/`** — always add them to the dotfiles repo so they're version-controlled and portable.

- Agents: `~/git/dotfiles/claude/agents/`
- Skills: `~/git/dotfiles/claude/skills/`

## Asking Questions

The `/question` skill is my preferred way of being asked questions whenever there's more than one route to take - design decisions, implementation approaches, triage choices, scoping, naming, or any fork where you'd otherwise present options in prose. In all these cases, invoke `/question` - it encodes the required `AskUserQuestion` format. Every multi-option question must follow it exactly.

## Response Length

Default to short, conversational replies - a few sentences, like talking to a colleague. Answer the question, make the point, stop. Lead with the answer or the single most important point; don't pre-explain, don't recap what I just said, and don't list every option you considered. When weighing options, give a recommendation in a line or two, not a catalogue.

Expand into detail (longer explanations, structured breakdowns, multiple sections) only when I ask for depth, or when the task genuinely needs it - a plan, a review, or a summary of real complexity. When in doubt, give the short version and offer to go deeper ("want the full breakdown?").

Strongly prefer terse, single-sentence-per-item statements (e.g. one line per option or finding). Do not produce a full multi-paragraph breakdown unless I explicitly ask for one - lead with the short version by default, every time.

This does not override the `/question` format or the Implementation summaries Outcome rule below. It sits above the structural formatting rules (Lists in Replies, etc.) - use that formatting only when a reply is genuinely long enough to need it, not as a reason to pad.

## CLI Tools

Assume all CLI tools are installed via Homebrew. When looking for a binary or checking its installation, check the Homebrew prefix first (`/opt/homebrew/bin/`).

## General Rules

Before starting work, confirm the correct file, directory, and repo. Ask if unsure. Never edit a file in the wrong project or config without confirming.

Do not over-scope. Stick to what was asked for. If something looks like it needs extra work, ask before expanding scope.

## Context Management

At natural breakpoints in a long session - after finishing a discrete task or milestone, or before starting an unrelated new one - if the conversation has grown large (many turns, large files read, lots of tool output), remind me in one line to run `/compact` so context doesn't climb too high. Don't repeat the nudge every turn (once per breakpoint is enough), and never interrupt mid-task - wait for a clean stopping point.

## Punctuation

Never use the em-dash character (`—`) anywhere - in chat replies, code comments, commit messages, PR descriptions, docs, or generated content. Use a plain hyphen (`-`) instead, with spaces around it when it would otherwise function as an em-dash. Same applies to the en-dash (`–`). Use straight quotes (`'`, `"`) rather than curly quotes (`'`, `'`, `"`, `"`) unless a file already consistently uses curly ones.

## Working Principles

These four principles apply to every task and override convenience.

- **State assumptions, never guess silently.** When a request is ambiguous or a fact is unverified, name the assumption out loud before acting on it. Picking the most plausible interpretation and writing code as if it were confirmed is how the wrong thing gets built.
- **Minimum code, nothing speculative.** Write the smallest change that solves the stated problem. No helpers, abstractions, flags, fallbacks, or error handling for scenarios that can't happen yet. If it isn't needed now, don't add it.
- **Surgical changes, don't refactor adjacent code.** Touch only what the task requires. Don't rename, reformat, reorder, or "clean up" unrelated code while passing through. Unsolicited refactors bloat the diff, hide the real change, and create review noise — raise them separately if they matter.
- **Define success, loop until verified.** Before starting, state in concrete, checkable terms what "done" looks like (build green, test passes, behaviour reproduced/fixed in the browser). Don't declare completion until that bar is actually met; iterate against the check, not against intent.

## Plan Files

Every plan file must open with an **Acceptance criteria** section, before the context or approach. List the criteria as checkable statements in Given / When / Then format (`**Given** … **when** … **then** …`), one bullet each. This operationalizes "Define success, loop until verified" - the criteria are the bar the implementation iterates against, and the final step is confirming each one holds. Cover the user-facing behaviour and the verification gates (tests, type-check, build) the work must pass.

## Implementation summaries

End every implementation summary with an **Outcome** line explaining, in non-technical terms, what the user can now do (or what now happens) as a result of the change. The Outcome line is the part that matters - keep any technical detail above it brief, and only include it when it genuinely helps.

Format: a bold `**Outcome:**` label followed by the content. No file paths, no symbol names, no jargon. Frame it from the user's perspective ("non-Pro users can now...", "admins see a new...", "the editor no longer...").

If the work changed one thing, write prose - a sentence or two. If it changed multiple distinct user-facing things (e.g. several bug fixes from a `/full-review` run, several features from a larger task), use bullets so each change lands separately and the reader can skim. A single paragraph stringing 4-5 outcomes together with semicolons is hard to read; bullets fix that.

Example (single change): `**Outcome:** Admins can now grant or revoke Pro for any user via the 3-dot menu on their profile - useful for testing features locked behind Pro without touching the database. Only visible in dev environments.`

Example (multiple changes):

```
**Outcome:**
- Non-Pro users now see a clear "This is a Pro feature." message instead of a raw error.
- Admins viewing their own profile no longer lose UI access to their saved views.
- The theme editor no longer drifts out of sync when a non-Pro user clicks Edit on a custom theme.
```

## Lists in Replies

When a chat reply presents a list of distinct items - findings, options, steps, recommendations, anything where each entry is its own self-contained block of more than a line or two - put a horizontal rule (`---`) between consecutive items so they're visually separated and easier to scan. The separator goes between items, not before the first or after the last.

This applies to substantial list items in prose replies (e.g. a numbered audit with a paragraph per finding). It does NOT apply to short one-line bullets, table rows, or code - those are already scannable and separators would just add noise. The litmus test: if each item is a mini-section the reader has to parse, separate them; if the list reads fine as tight bullets, leave it alone.

## Tables

Prefer Markdown tables when presenting comparable multi-field data - lists of options, rules, findings, or comparisons where every item shares the same attributes (name, type, effect, status). Tables make these far more scannable than bulleted prose. Keep using prose or bullets for narrative, single-attribute lists, or anything without a consistent column structure, and don't force a table when rows would be mostly empty or uneven.

## Questions Before Changes

When I phrase a message as a question — "shouldn't this be X?", "can this be Y?", "is there a way to Z?" — answer first, then wait for confirmation before editing files. Don't treat the question as an implicit instruction to make the change. Even if the answer is obviously "yes", I may want to discuss alternatives or scope first. Affirmative phrasing or follow-up like "do it" / "yes" is the trigger to proceed.

## Debugging

When fixing bugs, do NOT guess at root causes. Read the relevant code thoroughly before proposing a fix. If the first approach fails, step back and re-examine assumptions rather than trying successive hacky fixes.

## Investigation Steer

Before launching a broad, multi-repo or multi-directory code search to investigate a bug, integration question, or anything where the cause could plausibly sit outside our code (third-party service config, infrastructure, vendor docs, external SaaS UI), STOP and use `AskUserQuestion` to get an initial steer. Multi-repo greps and exploratory agents burn a lot of tokens, and the user often already knows the search would be wasted — e.g. "this isn't in our code, check the vendor docs", "only check repo X", "this is a config thing, not a code thing".

Ask before searching when:
- The behaviour could be explained by an external service / SaaS setting (Auth0, Stripe, Vercel, GitHub, etc.) just as plausibly as by our code
- The investigation would span 2+ repos or large unfamiliar areas
- The user has framed the problem in terms of "behaviour" not "code"

A single targeted file read (you already know the path) doesn't need a steer - just read it. The rule is about open-ended hunts, not surgical lookups.

## UI Changes

When adding or removing a UI element (page, section, setting, nav item), always update ALL references to it — sidebar navigation, help menus, breadcrumbs, and any index/listing components. Never add a feature without updating all cross-references.

## Tailwind CSS

Always use utility classes for spacing (padding, margin, gap, etc.). Hard-coding these in `style` attributes is a code smell — use the appropriate Tailwind classes instead (e.g. `p-4`, `mt-2`, `gap-6`).

## Comments

Default to no comment. A comment must add context that isn't immediately obvious from the code itself — a hidden constraint, a non-obvious invariant, a workaround for a specific bug, behavior that would surprise a reader. If a comment paraphrases or summarises the code it sits next to, delete it.

**Litmus test before writing any comment:** could a competent reader figure this out from the next ~10 lines? If yes, no comment. The reader can read.

Specifically forbidden:
- Doc-block paraphrases of property names (e.g. `/** The user's name. */ name: string`)
- "Adds X to Y" comments above code that obviously adds X to Y
- Headline comments on data structures explaining what the structure obviously is
- Section banners that describe a single block of code (the code is the description)
- Recapping context already in the surrounding file or function name

Acceptable comments are short — a sentence, occasionally two. If the explanation is growing, it belongs in a doc, a commit message, or a PR description, not inline.

## Multiline Comments

When a comment spans multiple lines, use a single block comment with the delimiters on their own lines. Do not stack consecutive single-line comments (`//` or `#`) and do not place text on the opening/closing delimiter lines.

```
/*
Comment
Comment
Comment
*/
```

Use the equivalent block syntax for the language (e.g. `/* */` in JS/TS/CSS, `""" """` in Python, `=begin`/`=end` in Ruby). Single-line comments remain fine for one-liners.

## Comment Wrapping

Never manually wrap a comment across multiple lines just to keep it inside a column width. Keep each comment on a single line and let the editor's soft-wrap handle visual wrapping per reader. Manual wrapping picks an arbitrary column that's wrong for anyone whose window differs from yours, and forces awkward re-flows when the comment is edited. Applies to `//` and to `/* */` block comments that hold a single sentence or paragraph. Genuinely multi-paragraph comments (with semantic line breaks between paragraphs) still follow the Multiline Comments rule above. JSDoc (`/** */`) is the exception, since IDE tooling renders it as docs and the wrapping is part of the rendered output.

## Equality Comparisons

In JS/TS, always use strict equality operators (`===` and `!==`). Never use loose equality (`==` or `!=`), even for `null`/`undefined` checks where the typed contract makes them functionally equivalent. Consistency makes intent unambiguous and avoids hidden coercion footguns. If you need to check for both `null` and `undefined`, write it explicitly (`x === null || x === undefined`) or use `x == null` only when a linter rule has been configured to allow that specific exception — and not otherwise.

## Block Braces

Always use braces on `if`, `else`, `for`, `while`, `do`, etc., even when the body is a single statement. No brace-less one-liners (`if (x) return;`), no inline-after-condition (`if (x) doThing();`). The body always lives inside `{ … }` on its own line(s).

```ts
// ✅
if (x === null) {
  return;
}

// ❌
if (x === null) return;
if (x === null)
  return;
```

The reason: brace-less bodies are easy to misread when scanning, easy to break when adding a second statement, and visually inconsistent next to multi-line bodies in the same file. Always-braces removes the ambiguity.

This applies to every language with C-family `if` syntax (JS/TS, Go, Rust, Java, C#, etc.). For Python, the equivalent is "always indent the body on the next line; never use the inline `if x: y` form".

## Ternaries

Use ternaries only when both branches are short, simple expressions that fit comfortably on one line — e.g. `x > 0 ? "pos" : "neg"`, `isOpen ? <Foo /> : null`. Prefer `if`/`else` (or guard clauses with early `return`) when:

- the condition or either branch wraps onto multiple lines,
- a branch contains a function call with arguments that don't fit alongside the `?`/`:`,
- the ternary is nested inside another ternary,
- a branch performs work other than producing the value (side effects, control flow).

Even if the ternary is technically valid, multi-line ternaries force the reader to mentally re-flow the structure to parse it. An `if` with an early `return` reads top-to-bottom in source order. The same goes for chains: `a ? x : b ? y : c ? z : w` should always be a `switch`, mapping object, or sequential `if`s — never a chain.

## Component Spacing

Don't hardcode outer spacing (margin, padding) on a component's root element when that spacing controls **where the component sits in a layout** — that belongs at the call site via `className`.

This applies to components that are **stacked or composed by a parent** (e.g. page sections, list rows, card groups). The parent orchestrates the rhythm between them.

It does **not** apply when the padding is **intrinsic to what the component is** — content padding inside a self-contained unit like a card, toolbar, list item, or page landmark (footer, header). If the padding defines the component's density rather than its position, it belongs inside the component.

## Component File Structure

Always extract non-scaffolding, non-layout UI components into their own separate file — even if they're only used once. Inline component definitions are acceptable only for scaffolding (pages, layouts, route wrappers) and pure layout containers. Everything else (cards, forms, modals, data displays, interactive widgets, etc.) gets its own file.

## Component Size & Splitting

Beyond file-level extraction, watch for components that have grown too complex internally. Line count is a symptom, not a rule — soft thresholds:

- **~150 lines** — start noticing.
- **~250 lines** — actively look for splits.
- **~400 lines** — treat as a smell. Some components legitimately stay large (wizard orchestrators, complex forms), but most have hidden seams.

Better signals than line count:

- **Multiple `useEffect`s / `useState`s touching unrelated concerns** → extract each cluster into a custom hook (`useShelfZoom`, `useBoxRotation`).
- **A prop only used by one JSX subtree** → that subtree is its own component.
- **Repeated JSX with small variations** → variant prop, `.map()`, or shared sub-component.
- **You can name a sub-section** ("the d-pad", "the stat chips") → that name is the component.
- **You scroll to read it** → readers will too.

Length is the symptom; the cause is usually multiple concerns living together. Splits should track concerns, not arbitrary line counts. Don't pre-emptively split a cohesive component just because it crossed a threshold — and don't leave a multi-concern component intact just because it's still under one.

## Git Commits

Never commit automatically. Only run `git commit` when I have explicitly prompted for it in the current message ("commit this", "commit and push", "make a commit", etc.). A general directive earlier in the session ("ship it", "land it", "do all three phases") is **not** standing authorisation to commit — at most it authorises the implementation work; the commit step still needs its own prompt. The same rule applies to `git push`, `git revert`, branch creation, and any other history-modifying operation: explicit prompt required, every time. When in doubt, stage the changes, summarise what's ready, and ask.

## GitHub PR Descriptions

Always invoke the `/writing-pr-descriptions` skill when generating or rewriting a PR description (for `gh pr create`, the GitHub web UI, or any internal PR template). It is the source of truth for structure and supersedes any older Problem / Solution / Test plan format. Do not hand-roll a description or add a Test Plan section - the skill encodes the required humans-first summary plus collapsed AI-reviewer details.

## GitHub PR Comments

When replying to comments on GitHub PRs (e.g. via `gh`), always append the following signature at the end of the comment body:

```
---
Posted by AI Luke Harrison ([WebDevLuke](https://github.com/WebDevLuke)) 🤖
```

### Style

The signature makes clear these comments are automated, not me talking directly - so write them straight to the point, not personable. No greetings, no "thanks", no "good catch", no first-person opinion or filler. State what changed and why, and stop.

- Keep every comment as brief as it can be while still communicating the point clearly and effectively.
- Lead with the resolution (what was changed / the answer), then any essential reasoning.
- Use tables and/or bullet points to break up anything with more than one part - don't write a wall of prose.
- Cut hedging, pleasantries, and restatements of the reviewer's comment.
