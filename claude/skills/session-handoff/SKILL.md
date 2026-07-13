---
name: session-handoff
description: Create and continuously refresh a single live handoff document for the CURRENT session, so a fresh agent can pick up the work if this chat is lost. Designed to be run repeatedly on a timer via /loop.
argument-hint: "(optional) what this session is focused on"
---

Maintain a **live handoff document** for the current session. The goal is loss-insurance: if this chat becomes inaccessible, a fresh agent can open the file and resume with full context.

This is the rolling, auto-refreshed counterpart to `/handoff` (which writes a one-shot final doc). Run it repeatedly - typically via `/loop` - and it overwrites the same file in place each time so it always reflects the latest state.

## How it's meant to run

Drive it with the loop mechanism, started once per session:

```
/loop 20m /session-handoff
```

It also works as a one-off manual invocation at any breakpoint.

## Target file

- Directory: `~/git/handoffs/` - create it first if missing (`mkdir -p ~/git/handoffs`).
- Filename: `live-<slug>.md`, where `<slug>` is the current git branch with `/` replaced by `-`. If not in a git repo, derive a short slug from the task (or the passed argument).
- **Use the same filename for every run in this session** - overwrite it, never append and never create a second file. If you already chose a filename earlier this session, reuse that exact one.

## Each run

Regenerate the whole file from the current conversation state - don't append incrementally, or it bloats and drifts. Keep it compact and current. Sections:

1. **Title + Status** - one line on where things stand (e.g. "mid-implementation", "PR open, awaiting review", "debugging X").
2. **Focus** - what this session is doing and why. If an argument was passed, treat it as the focus.
3. **Current state** - branch, repo path, PR URL, Jira URL - whatever applies.
4. **Done so far** - what's landed/committed this session (reference commits/PRs by hash/URL, don't re-describe them).
5. **In flight / next steps** - what's actively being worked on and the immediate next actions, concrete enough to resume cold.
6. **Verification bar** - the exact commands that must pass (typecheck/lint/test/build) and their current status.
7. **Gotchas** - environment quirks, dev-data changes, non-obvious constraints discovered this session.
8. **Suggested skills** - which skills the next agent should invoke to continue.

## Discipline

- **Don't duplicate** content already in other artifacts (PRDs, plans, ADRs, issues, commits, diffs) - reference them by path or URL.
- **Redact secrets** - never write API keys, passwords, connection strings, or PII into the file.
- **Stay out of the way.** This runs mid-task on a timer. Update the file quietly and keep your chat reply to a single line (e.g. "Refreshed live handoff: `~/git/handoffs/live-<slug>.md`"). Do not derail, summarise, or re-plan the current work.
- **Never commit** the file automatically.
