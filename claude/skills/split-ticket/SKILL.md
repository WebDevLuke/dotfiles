---
name: split-ticket
description: Examine a Jira ticket, trace its ancestors and descendants for full context, then propose a principled breakdown into smaller actionable tasks and create them on approval.
---

Take a Jira ticket, build complete context by walking its hierarchy and surrounding material, then propose a defensible decomposition into smaller, well-scoped tasks - and create them in Jira only after you approve. Use the Atlassian MCP for all Jira reads/writes.

Follow the communication style in CLAUDE.md: short and conversational, lead with the answer, use the `/question` skill for any multi-option fork.

## Step 0: Resolve the ticket

Take the issue key from the skill arguments. If none was given, ask for it before doing anything else - don't guess from context.

Fetch the ticket with `getJiraIssue` and confirm out loud what you're working on (key, summary, type, status). If the key doesn't resolve, say so and stop.

## Step 1: Walk the tree

Build the full picture in both directions:

- **Descendants (the work)** — child issues, subtasks, and issue links beneath the ticket. Follow them down so you understand everything already broken out.
- **Ancestors (the context)** — the parent and/or epic above the ticket, so the breakdown respects the goal it sits under and doesn't duplicate sibling work.

Use `getJiraIssue` for each node and `getJiraIssueRemoteIssueLinks` / the link fields to traverse.

**Large or deep trees:** don't deep-read everything blind. Do a shallow pass first, report the tree's shape (e.g. "3 child stories, 11 subtasks, 2 linked issues"), and confirm which branch or level you should actually split before pulling full detail. Unbounded traversal burns tokens for no gain.

You're splitting the *remaining* work, not re-creating tickets that already exist - which means you first need to know what already exists (see Step 4).

## Step 2: Gather context

Before proposing anything, ground yourself in:

- **Comments & history** — read the ticket's comments and recent activity for decisions already made, blockers, and scope that's already been discussed or de-scoped.
- **Linked Confluence / docs** — follow remote links and attached Confluence pages for spec/design context (`getConfluencePage`).
- **Codebase** — explore the relevant repo(s) so each proposed task maps to real files and implementation seams. Prefer the `Explore` agent for broad fan-out; a single targeted read is fine when you already know the path. If you're unsure which repo(s) are in scope, ask rather than searching everything.

If the work plausibly sits outside our code (vendor/SaaS config, infra), follow the Investigation Steer rule in CLAUDE.md and get a steer before launching a broad multi-repo hunt.

## Step 3: Challenge the intent

Decide whether splitting actually helps. **Do not invent busywork tickets.** Stop and say so if:

- The ticket is already small enough to action as-is.
- It's already well-decomposed into sensible children.
- It's too vague to split meaningfully - in which case the right move is to clarify scope first, not fabricate sub-tasks.

If splitting isn't warranted, explain why in a line or two and offer the alternative (action it directly / refine the ticket / nothing to do). Only continue when a split genuinely adds value.

## Step 4: Map existing coverage

Before drafting anything, list what each existing child/subtask/linked issue already covers. You're filling genuine gaps, not regenerating the tree. When a task you'd want to propose overlaps with a ticket that already exists, don't silently create a duplicate - flag the overlap and let the user decide whether to keep, supersede, or skip it.

## Step 5: Draft the breakdown

Decompose the remaining (uncovered) work into smaller tasks, then **self-check each proposed task against this rubric before showing it to the user.** Revise until each task passes:

| Principle | Test applied to each task |
|---|---|
| **Vertical slice** | Delivers a thin end-to-end piece of value, not a horizontal layer ("all the backend"). A task that can't ship on its own is a layer, not a slice. |
| **INVEST** | Independent, Negotiable, Valuable, Estimable, Small, Testable. |
| **Single responsibility** | One reason to change. If you can't name it without "and", split it again. |
| **Right-sized** | Reviewable in one go, but still delivers something meaningful. Flag any "task" that's really an epic in disguise. |
| **Testable** | You can write its acceptance criteria. If you can't, the task isn't well-formed yet. |

**Canonical pattern - static UI first, then hook up incrementally.** When a slice is a substantial new UI surface (a page or screen, especially greenfield), the default decomposition is: first a **static build with dummy/placeholder data** that nails the layout and UX, then a series of **hookup tasks that each wire one portion to real data or behaviour** (the data/list itself, filters and search, aggregates/summaries, navigation and click-throughs, export, etc.). This is a deliberate and acceptable departure from strict vertical slicing - the static build is the shared base every hookup task builds on, and each hookup is small, independently reviewable, and low-risk. Reach for it whenever a single end-to-end slice of the page would be oversized, or when getting the layout right up front de-risks all the wiring that follows. Keep the static build as one task; split the hookups by concern, not by arbitrary count.

For every proposed task, prepare:

- A clear title and one-line description.
- The areas / seams it touches, described at the level of *what the work is*, not *how to build it*. Reference existing components, systems, or endpoints for grounding (from Step 2), but do **not** prescribe the specific new files, paths, hooks, or components to create - that's implementation detail for whoever picks up the ticket, and listing it is too granular and prescriptive.
- Acceptance criteria in Given / When / Then form.
- Its dependencies — what blocks it, what it blocks — so the sequence and any parallelism are explicit.
- A story-point estimate, sized against the Fibonacci scale below. Show it in the proposal so the user can adjust before approving - you're surfacing a starting point, not dictating the team's number.

**Story-point sizing scale:**

| SP | Effort | Time (est) | Complexity | Risk / uncertainty | Notes |
|---|---|---|---|---|---|
| **1** | Minimal | Minutes | Smallest | None | |
| **2** | Minimal | Hours | Minimal | None | |
| **3** | Mild | Few days | Minimal | None | |
| **5** | Moderate | Many days | Medium | Moderate | |
| **8** | Severe | Week | Moderate | Moderate | A sign the ticket *may* need breaking down. Not always. |
| **13** | Maximum | Weeks / month | High | High | A sign the ticket *needs* breaking down. |

Because this skill exists to break work down, proposed slices should generally land at **5 or below**. Treat any slice you'd size at 8 as a prompt to look for a further split, and an 13 as a slice that isn't done being decomposed.

## Step 6: Propose and confirm

Present the breakdown for review **before touching Jira**, as a table with one row per task and these columns:

| Column | Contents |
|---|---|
| **#** | Sequence number, for referring to tasks in discussion. |
| **Title** | The task's clear, concise title. |
| **Why it's needed** | One short sentence on why this task has to exist - the gap it fills or the value it delivers. |
| **Deps** | What blocks it (other tasks by # or existing ticket keys), so sequence and parallelism are explicit. |
| **SP** | The story-point estimate from the Step 5 scale. |

Below the table, give the dependency order / sequence (what can run in parallel), a short rationale for why the split falls where it does, the story-point total, and anything you deliberately left out of scope.

Nothing gets created until the user approves. Iterate on the proposal if they push back - this is a discussion, not a one-shot.

## Step 7: Place and create

Once approved, ask two placement questions (use the `/question` skill, don't assume):

1. **Where the new tasks live** — subtasks/children beneath the original, sibling stories under the parent epic, or separate issues.
2. **What happens to the original ticket** — becomes a parent/tracking container, keeps one slice as its own scope while the rest splits out, or gets closed.

Write each ticket body to this template:

```
> {one- to two-sentence intro to the epic's core objective — the same shared intro across the epic's tickets}

## What to build
{the work, grounded in existing systems/components per Step 5, without prescribing new files}

## Acceptance criteria
{Given / When / Then bullets}

## Out of scope
{what this ticket deliberately does not cover, pointing at the sibling that does}

## Repo
{which repo the work lives in — useful when the split spans more than one}

## Verification
{the gates the work must pass — tests, type-check, build}
```

Template conventions:

- **Prefix the title with 🛑** when the ticket has an open blocker (an unresolved "is blocked by" link). Drop the prefix once it's unblocked.
- **No "Parent" or "Dependencies" section in the body.** The epic link and the blocked-by / blocks / relates links are native Jira and must not be duplicated in prose — model dependencies as real issue links (next bullets), not text.

Then create the issues with `createJiraIssue`:

- Set the parent/epic link to match the chosen placement and copy the relevant acceptance criteria into each.
- **Inherit** labels, components, fix version, and priority from the original. Leave **sprint** and **assignee** unset - those are refinement/planning decisions.
- Set the **story-point estimate** on each (the value confirmed in the proposal). Story points are a Jira *custom field* - identify the correct field id for this project (via `getJiraIssueTypeMetaWithFields` / `getJiraProjectIssueTypesMetadata`) rather than assuming a name.
- Link tickets with `createIssueLink` where there are dependencies, and apply the agreed change to the original ticket.

## Step 8: Summarise

Report what was created with clickable links to each new ticket, the story-point total, and the dependency order. Note what happened to the original ticket. End with an **Outcome** line per CLAUDE.md - in plain terms, what the user can now do (e.g. "The epic is now broken into 4 independently-shippable stories, each estimated and with its own acceptance criteria, ready to pick up in order").

The skill ends here - it does **not** chain into `/start-task` or begin any work. Starting a task is a separate, explicit action.

If nothing was created (Step 3 stopped the split), just summarise the assessment and the recommended next step - no Outcome line needed.
