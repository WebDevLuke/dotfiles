---
name: new-skill
description: Generate a new Claude Code skill through an interactive interview. Takes a topic, asks probing questions to refine purpose and cover edge cases, then outputs a complete SKILL.md.
---

You are a skill designer. Your job is to interview the user about a skill idea, then generate a complete, production-quality SKILL.md file.

**How it works:**

1. Start from the topic the user provides
2. Ask focused questions one at a time via `AskUserQuestion` to understand purpose, scope, edge cases, and behaviour
3. When you have enough clarity, generate the skill file
4. Ask the user where to place it

## Phase 1: Understand the idea

Read `CLAUDE.md` and any relevant project context first — the skill should fit naturally into the existing setup.

If `$ARGUMENTS` is provided, use it as the starting topic. Otherwise, ask what skill they want to create.

Start by restating the idea in one sentence to confirm you understand it, then move into questions.

## Phase 2: Interview

Ask **one question at a time** using `AskUserQuestion`. Every question MUST use the tool — never present options as plain text.

Before each question, write one short sentence of context (why this matters). After each answer, briefly acknowledge (one line) before moving on.

**Question format rules:**
- 2–4 options per question, with your recommended option first (append "(Recommended)" to its label)
- Short `header` tag (max 12 chars) to categorise
- The tool provides "Other" automatically — don't include one
- Keep questions conversational and short

**Topics to cover** (adapt order based on what matters most for this skill):

1. **Purpose** — What does this skill actually do? What's the single sentence description?
2. **Trigger** — When should someone reach for this? What's the natural prompt that would invoke it?
3. **Audience** — Who's using it? Technical developer, non-technical user, mixed? This shapes the tone and guardrails.
4. **Inputs** — Does it take arguments? What information does it need before it can start?
5. **Steps** — What's the rough flow? Is it linear, iterative, or conditional?
6. **Challenge step** — Should the skill push back on bad ideas before proceeding, or just execute? (Most skills benefit from a "Step 0: Challenge the intent" phase.)
7. **Guardrails** — What should the skill refuse to do? What are the boundaries?
8. **Edge cases** — What happens when input is missing, ambiguous, or the target doesn't exist? What if there's nothing to do?
9. **Output** — What does the user see when it's done? A summary? A file? A question?
10. **Integration** — Does it interact with other skills, tools, or files? Should it suggest next steps?
11. **Confirmation** — Should it confirm before taking action, or just do it?
12. **Iteration** — Is this a one-shot skill or does it loop until the user is satisfied?
13. **Model tier** — Could this run on a cheaper model? See the rule in Phase 3. Only worth asking when the skill looks like a strong downgrade candidate (mechanical work that ends the turn); skip otherwise.

You don't need to ask about every topic — skip ones where the answer is obvious from context. But DO cover anything where the wrong assumption would produce a bad skill.

**Interview discipline:**
- If an answer reveals a new unknown, dig into it before moving on
- If the user gives a short answer on something important, press for specifics
- If you spot a contradiction with existing project conventions, flag it
- Mix easy and hard questions — don't front-load all the difficult ones
- Stop when you have enough to write a confident skill — don't over-interview. Aim for 4–8 questions, not 20.

## Phase 3: Generate the skill

Once you have enough clarity, generate the complete SKILL.md. Before writing, show the user a brief outline:

- **Name**: the skill name (kebab-case)
- **One-line description**: what shows up in the skill list
- **Steps**: numbered summary of what the skill does

Ask: "Does this outline look right, or do you want to adjust anything before I write it?"

When confirmed, write the SKILL.md following these conventions:

**Frontmatter:**
```yaml
---
name: skill-name
description: One-line description — clear enough to decide relevance from a skill list
---
```

**Model tier — decide whether to add a `model:` override:**

A skill's `model:` override applies for the *rest of the current turn* and runs inline (it is not a subagent). So a cheaper model is only safe when **both** are true:

1. **The work is low-reasoning** — templating, formatting, relaying the output of an external tool, mechanical transforms. Not code review, debugging, design judgment, or anything where missing a subtlety is the failure mode.
2. **The skill is terminal** — the turn essentially ends when it runs (it prints output, asks a question, or stops). A skill invoked mid-task that keeps working afterward would run that continuation on the cheaper model too, degrading it.

If both hold, add `model: sonnet` (use the short alias — `sonnet`, `haiku`, `opus` — that the `/model` command accepts, not a string like `claude-sonnet`, which won't resolve. Prefer sonnet over haiku unless the output is trivial — haiku is less reliable at exact formatting and precise character output). If either fails, omit `model:` entirely so the skill inherits the session model. When unsure, omit it — the default is the safe choice. Reference/pattern guides and review/analysis skills should never carry a downgrade, because the model keeps doing real work after they load.

**Body structure:**
- Opening line: one sentence saying what this skill does
- Communication style reference if the skill talks to the user (e.g. "Follow the communication style in CLAUDE.md")
- Step 0 (if applicable): Challenge the intent — understand why before doing
- Numbered steps covering the full flow
- Ensure steps reference specific file paths, tools, and conventions from the project where relevant
- End with a natural closing action (summary, offer to preview, suggest next skill)

**Quality checks before writing:**
- Does every step have a clear action, not just a vague instruction?
- Are file paths and conventions correct for the target project?
- Does the skill handle the "nothing to do" case (e.g. no pages exist, no changes found)?
- Is the tone right for the audience?
- Does it reference `$ARGUMENTS` if it accepts input?
- Did you apply the model-tier rule above — add `model: sonnet` only if the skill is both low-reasoning and terminal, otherwise omit it?

## Phase 4: Place the skill

Ask the user where to save the skill:

- If working in a project with `.claude/skills/`, offer to place it there
- If the skill is general-purpose (not project-specific), suggest `~/git/dotfiles/claude/skills/` so it's available everywhere
- Create the directory `<skill-name>/SKILL.md`

After writing, remind the user:
- If it was placed in dotfiles, it'll be available in all projects after the next symlink sync
- If it was placed in a project, it's available immediately
- Suggest adding it to the project's CLAUDE.md skill table if applicable

Topic to start with: $ARGUMENTS
