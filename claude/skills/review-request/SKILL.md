---
name: review-request
description: Generate a ready-to-paste Slack message asking for PR reviewers.
model: sonnet
---

# Review Request

Generate a Slack message requesting PR reviewers for the current branch.

## Input

Accepts either:

- No argument: auto-detects from the current branch's open PR(s)
- One or more PR numbers or URLs: `/review-request 18` or `/review-request https://github.com/org/repo/pull/18`

## Steps

### 1. Find the PR(s)

- If PR numbers or URLs were provided, use those
- Otherwise, detect the current branch and find its open PR:
  ```
  gh pr view --json number,title,url
  ```
- If no PR is found, let the user know and stop

### 2. Extract context

- **Jira ticket key:** Extract from the branch name (e.g. `PROJ-123` from `fix/PROJ-123-update-reset-password-email`). If no ticket key is found, omit the ticket line.
- **PR URL(s):** From step 1
- **Summary:** Read the PR title and body to understand what the PR covers

### 3. Print the Slack message

Print the message as plain text (no code block wrapping) so Claude Code's markdown renderer shows `*bold*` and emoji formatting correctly in the preview. The user selects and copies the rendered text manually.

Message format:

```
:clipboard: *[TICKET-KEY]* — Ready for review

[One sentence giving a holistic summary of what was addressed — don't list individual fixes]
⠀
[PR link 1]
[PR link 2 if multiple]
⠀
```

Layout rules:

- **Spacer lines** between the summary and PR links. Slack strips empty lines and regular-whitespace-only lines (including U+00A0 non-breaking space in some Slack clients), so each spacer line must contain the character **⠀ (U+2800 BRAILLE PATTERN BLANK)**. This character renders invisibly but is never stripped by Slack because it is not whitespace. Use **one** spacer line per gap.

When generating the message, paste the ⠀ character literally on each spacer line. Do not describe it ("nbsp", "blank line"), paste the actual character — the user copies the message straight into Slack.

- Keep the summary under 20 words
- If multiple PRs were provided, list all of them
- If no Jira ticket key was found, use the PR title instead of the ticket key line
