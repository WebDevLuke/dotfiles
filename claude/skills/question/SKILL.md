---
name: question
description: Format and present a multi-option question to the user via the AskUserQuestion tool. Use whenever you are about to present 2+ options for the user to choose from — design decisions, triage actions, implementation approaches, confirmations with alternatives, naming, or scoping.
---

# Question

**Always use the `AskUserQuestion` tool** when presenting 2+ options for the user to choose from — design decisions, triage actions, implementation approaches, confirmations with alternatives, naming, scoping, clarifying intent. Never write selectable options as plain text in the response body; the tool provides a native selection UI where the user clicks to choose.

For simple yes/no confirmations, just ask inline — no need for the tool.

## Format

Every question presented to the user MUST follow this exact format:

- **2-4 options per question** (tool limit). Each option has:
  - A short `label` (1-5 words)
  - A `description` explaining the implications of choosing it
- **Be opinionated** — put your recommended option first and append `(Recommended)` to its label.
- **The last option must always be `Other`** — so the user can answer more specifically when none of the suggested options fit. Do not rely on any tool-provided default; include `Other` explicitly as the final option every time.
- **Short `header` tag** (max 12 chars) categorising the question — e.g. `Scope`, `Auth`, `Layout`, `Data source`, `Priority`, `UX flow`.
- **Full context before the tool call** — the message preceding the `AskUserQuestion` call must contain everything the user needs to make an informed decision. The option labels and descriptions are short by necessity, so the surrounding context has to carry the substance. Do **not** duplicate the question itself as plain text in the response body; the tool renders the question. The context block must include:
  - **Problem statement** — one or two bold lines stating what's being asked and why it matters. No throat-clearing, no preamble.
  - **Current state** — when the question is about existing code, data, config, or a tool's raw output, quote the exact excerpt with a markdown `file:line` link so the user can verify rather than trust your summary. For lint/advisor/test findings, paste the relevant raw output.
  - **Non-obvious tradeoffs** — severity, blast radius, mitigating factors ("this is INVOKER not DEFINER so risk is smaller"), prior intent ("docs/X.md treats this as deliberate"). Anything that should change the answer if the user hadn't already considered it.
  - **Sequential counter** — when the question is one of many in a triage / walk-through, prefix the heading with `N/M` so the user knows where they are in the sequence.
- After the user selects, briefly acknowledge their choice (one line max) before moving on.

## When to use

- Choosing between options (design, implementation, scope)
- Providing a name, description, or other input
- Clarifying ambiguous requirements or intent
- Triaging review findings or fix priorities

## When NOT to use

- Simple yes/no confirmations — ask inline
- Single-option "shall I proceed?" prompts — just proceed (or, in auto mode, skip the prompt entirely on low-risk actions)

## Example

> ## 3/12 — `public.set_updated_at` mutable search_path
>
> **The warning**: `public.set_updated_at` is a trigger function with no fixed `search_path`. An attacker who can create objects in a schema earlier in the caller's search_path could shadow built-ins like `now()` and execute arbitrary code in the trigger's context.
>
> **Current definition** ([supabase/migrations/20260520000000_init_schema.sql:3-11](supabase/migrations/20260520000000_init_schema.sql#L3-L11)):
>
> ```sql
> create or replace function public.set_updated_at()
> returns trigger
> language plpgsql
> as $$
> begin
>   new.updated_at = now();
>   return new;
> end;
> $$;
> ```
>
> It's `SECURITY INVOKER` (the default), so the risk is real but smaller than a `DEFINER` function would be — the trigger runs as the table's writer, not as a privileged role.
>
> _AskUserQuestion call with:_
> - header: `Fix style`
> - options:
>   - `Pin search_path on the function (Recommended)` — add `SET search_path = pg_catalog, pg_temp` to the function definition. Standard Supabase remediation; makes the function fully self-contained.
>   - `Schema-qualify every reference` — replace `now()` with `pg_catalog.now()` inside the body. Same protection without changing search_path, but only one call site here.
>   - `Suppress / accept the warning` — leave as-is and document the trade-off. Reasonable only if the threat model is genuinely acceptable.
>   - `Other` — describe a different approach.
