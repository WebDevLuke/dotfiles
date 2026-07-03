---
name: review-pr-comments
description: Pull down unresolved GitHub PR comments, analyse each one, and present a summary with recommendations before taking any action.
---

# Review PR Comments

Pull down unresolved comments from a GitHub pull request, read each one, assess validity, and present a summary before taking any action.

**Never take action until the user has reviewed your summary and told you what to do.**

## Input

Accepts either:
- A PR number: `/review-pr-comments 123`
- A PR URL: `/review-pr-comments https://github.com/org/repo/pull/123`
- No argument: auto-detects from the current branch's open PR

## Steps

### 1. Find the PR

- If a PR number or URL was provided, use that
- Otherwise, detect the current branch and find its open PR:
  ```
  gh pr view --json number,title,url
  ```
- If no PR is found, let the user know and stop

### 2. Pull unresolved comments

Fetch all review comments and PR comments that are unresolved:

```
gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '[.[] | select(.position != null or .in_reply_to_id == null)]'
gh api repos/{owner}/{repo}/pulls/{number}/reviews
gh api repos/{owner}/{repo}/issues/{number}/comments
```

Filter to unresolved threads only — skip comments that have been resolved or are part of resolved review threads.

### 3. Read and analyse each comment

For each unresolved comment/thread:

1. **Read the comment** in full, including any replies in the thread
2. **Read the referenced code** — use the file path and line numbers from the comment to read the actual current code
3. **Assess validity** — is the reviewer's concern legitimate given the current state of the code?
4. **Determine action** — what (if anything) should be done?

### 4. Present and triage

Follow the shared triage pattern at [docs/triage-pattern.md](../../docs/triage-pattern.md):

1. **Present** all comments as a numbered list in chat. Use these field labels (PR-comment specific):

   ```
   ### [N]. [file:line] — [one-line summary of the concern]

   **Reviewer:** @username
   **Comment:** [full comment text from the PR, verbatim — do not summarise or paraphrase]
   **My assessment:** [agree/disagree/partially agree — with brief reasoning]
   **Suggested action:** [specific fix / no action needed / needs discussion]
   ```

   Tally:
   - X comments to action
   - X comments to dismiss or discuss
   - X comments already resolved by current code

2. **Triage** via batched `AskUserQuestion` (up to 4 per call). Use a binary option set: **Address it** / **Don't address it**. Collect ALL decisions before actioning anything.

The action phase is skill-specific — see steps 5–7 below.

### 5. Action approved comments

For each comment the user chose to **address**:
1. Make the code change
2. Reply to the GitHub comment explaining what was done, using this format:

```
[Brief description of the change made]

---
Posted by AI Luke Harrison ([WebDevLuke](https://github.com/WebDevLuke)) 🤖
```

3. Resolve the thread **only if the original commenter is a bot** (see "Identifying bot vs human commenters" below). If the commenter is a human, leave the thread unresolved so the reviewer can resolve it themselves after reading the reply.

### 6. Handle dismissed comments

For each comment the user chose to **not address**:
1. Draft a brief reply explaining why the comment isn't being actioned (based on your assessment from step 3)
2. Post the reply to the PR thread
3. Resolve the thread **only if the original commenter is a bot**. If the commenter is a human, leave the thread unresolved — dismissals from a human reviewer especially need the reviewer to acknowledge the reply before the thread closes.

### Identifying bot vs human commenters

Treat the original commenter as a **bot** (and auto-resolve) if any of these apply:
- `user.type` is `Bot` (REST API) or `author.__typename` is `Bot` (GraphQL)
- `user.login` ends with `[bot]` (e.g. `dependabot[bot]`, `github-actions[bot]`)
- `user.login` is `Copilot` or `copilot-pull-request-reviewer`

Otherwise treat as **human** — post the reply but do not call the `resolveReviewThread` GraphQL mutation. In the final summary, mention which threads were left unresolved so the user knows what's still pending reviewer acknowledgement.

### 7. Print Slack review request

Once all comments have been handled (actioned, dismissed, or there were none to begin with), run the `/review-request` skill to generate a Slack message for the PR(s) reviewed in step 1.

## Edge Cases

- **Stale comments** — if the referenced code has changed significantly since the comment was made, flag this: "This comment may be outdated — the code it references has changed."
- **Conflicting comments** — if two reviewers disagree, flag the conflict and present both positions.
- **Nitpicks vs blockers** — distinguish between style suggestions and functional concerns in your assessment.
