---
name: plan-review
description: Adversarially scrutinise a proposed plan (not code) for correctness, security, performance, completeness, and unresolved questions - report findings by severity, triage each, then revise the plan in place. Use before committing to a plan, or when asked to review/critique/pressure-test a plan.
---

Pressure-test a proposed plan the way `full-review` pressure-tests a diff - but the subject is the **plan document, not the code**. You are looking for weaknesses in the thinking: wrong assumptions, missing steps, security and performance risks, and unresolved questions that will bite during implementation. You are not reviewing code, and you never write implementation code from this skill.

Follow the communication style in CLAUDE.md - terse, concise, no preamble.

## What this is not

- Not `full-review` - that runs specialist reviewers against actual code/diffs. This runs against a plan before any code exists.
- Not `nitpick` - that *interviews the user* one question at a time to fill product gaps. This *critiques a concrete written plan* and ranks issues by severity. When this skill surfaces unresolved open questions worth a proper interview, hand off to `nitpick` (Step 8) rather than duplicating it.

## Step 1: Locate the plan

Find the plan to review, in this order:

1. A path passed as an argument (a markdown plan file) - read it.
2. The plan just produced in plan mode this session.
3. A plan clearly discussed/agreed in the current conversation.

If none of these exist, stop and say so: `No plan found to review - produce or point me at a plan first.` Do not invent a plan to critique.

## Step 2: Understand the goal

Before finding fault, restate in one or two lines what the plan is trying to achieve and the constraints it operates under. Every finding is judged against **this goal** - a "problem" that doesn't threaten the goal is noise, not a finding. If the goal itself is unclear from the plan, that is your first and most important finding.

## Step 3: Review across lenses

Work through the plan against each lens below. For each, ask "what in this plan is wrong, missing, or will fail?" - not "how would I have written it".

| Lens | What to look for |
| --- | --- |
| **Correctness & bugs** | Wrong assumptions, logic gaps, steps that won't produce the stated result, unhandled edge cases, ordering that breaks (step B needs something step A hasn't done), state/data the plan assumes exists but doesn't. |
| **Security** | Auth/authz gaps, untrusted input the plan doesn't validate, secrets handling, data exposure, injection surfaces, permissions widened without need. |
| **Performance** | Operations that won't hold up as data/traffic grows, N+1 patterns, expensive work on a hot path, missing pagination/caching, synchronous work that should be deferred. |
| **Scope & completeness** | Missing steps, unstated assumptions, over-scoping (building what wasn't asked), gaps between the plan and the goal, and crucially **no verification/testing story** - how will each step be proven done? |
| **Open questions** | Decisions the plan leaves implicit or unmade, forks it silently picked one side of, "we'll figure it out later" gaps that should be resolved before starting. |

### Light grounding checks

Stay focused on the plan, but spot-check its **factual claims** against the codebase so you catch a plan built on a false premise. Targeted lookups only - never a full code review:

- Do referenced files, functions, components, or endpoints actually exist and look as the plan describes?
- Are the plan's claims about *current* behaviour accurate?
- Does the plan contradict a documented convention (CLAUDE.md, README, project docs)?

A plan resting on "we'll modify `X`" where `X` doesn't exist, or "the current code does Y" when it does Z, is a high-severity correctness finding.

## Step 4: Adversarially verify each finding

Before a finding goes in the report, try to knock it down. For each candidate: state the concrete failure it predicts (what input/condition leads to what wrong outcome), then ask "is this actually true given the plan and the code I checked, or does the plan already handle it elsewhere?" Drop anything that is a matter of taste, is already covered later in the plan, or that you can't tie to a concrete failure. A short, high-confidence list beats a long speculative one. If nothing survives, say so plainly (see Step 9).

## Step 5: Categorised report

Produce a single report grouped by lens, findings ranked most-severe first. Assign each a severity:

- **Critical** - the plan will fail or cause harm (data loss, security hole, breaks the stated goal) if implemented as written.
- **Major** - a real defect or significant gap that will need rework, but not catastrophic.
- **Minor** - worth fixing, low blast radius.
- **Question** - an unresolved decision the plan should settle before starting.

For each finding give: a one-line summary, the concrete problem, the risk if left unaddressed, and a suggested fix to the plan. Number findings sequentially so triage can reference them.

## Step 6: Triage with the user

Present the findings and triage them **via the `/question` skill format** (`AskUserQuestion`). Do not batch-decide on the user's behalf. For each finding (or a sensible group), offer: **Fix in plan** / **Defer** / **Reject**. Respect the "Questions Before Changes" rule - findings are proposals until the user approves them.

When a finding's options carry a recommendation, **mark it** - put the recommended option first and append "(Recommended)" to its label - per the `/question` format. Marking your steer is required, but it is not the same as acting on it: still present every option and let the user choose. Never pre-apply the recommended resolution to the plan before the user has selected it.

## Step 7: Revise the plan in place

For every finding the user approved as **Fix in plan**, update the plan (the plan-mode plan or the plan file) to incorporate the fix. Keep edits surgical - change what the finding requires, don't rewrite the whole plan. If the plan has an Acceptance criteria section (per CLAUDE.md's Plan Files rule), make sure approved fixes are reflected there too. Show a short summary of what changed.

## Step 8: Hand off open questions

If unresolved **Question** findings remain that need a proper back-and-forth to settle (not a one-line answer), offer to continue in `nitpick`, which is built for exactly that interview. Don't run the interview yourself here.

## Step 9: Nothing-to-fix case

If the plan survives review with no findings, say so directly - `Plan holds up: no correctness, security, performance, completeness, or open-question issues found against the stated goal.` Don't manufacture findings to look thorough. A clean plan is a valid outcome.

## Closing

End with an **Outcome** line (per CLAUDE.md) describing, in plain terms, the state of the plan now - e.g. what risks were removed and whether it's ready to implement.
