---
name: accessibility
description: WCAG 2.1 AA guidelines. Use when writing or reviewing UI/frontend code — HTML, React components, CSS, or form elements.
---

# Accessibility

Aspire to meet WCAG 2.1 AA standards where possible when writing UI code.

## Colour Contrast

- Normal text: minimum 4.5:1 contrast ratio against its background
- Large text (14pt/18.66px+ bold or 18pt/24px+ regular): minimum 3:1
- UI components and graphical objects (icons, borders, focus indicators): minimum 3:1
- Avoid conveying information through colour alone — pair with text, icons, or patterns

## Images and Media

- Provide meaningful `alt` text that describes the image's purpose, not just its appearance
- Decorative images should use `alt=""` or be applied via CSS backgrounds
- Complex images (charts, diagrams) need a longer text alternative nearby
- Video content should have captions; audio content should have transcripts

## Keyboard and Focus

- All interactive elements must be operable via keyboard alone
- Maintain a logical tab order that follows visual reading order
- Provide visible focus indicators — never use `outline: none` without a replacement style
- Avoid keyboard traps — users must be able to navigate away from any component
- Skip-to-content links for pages with repeated navigation

## Semantic HTML and ARIA

- Use native HTML elements over ARIA where possible (`<button>` over `<div role="button">`)
- Landmarks: use `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>` to define page regions
- Headings: use a logical hierarchy (`h1` → `h2` → `h3`) — don't skip levels
- ARIA attributes should supplement, not replace, semantic HTML
- Use `aria-live` regions for dynamic content updates (e.g. toast notifications, form validation)
- Set `aria-expanded`, `aria-selected`, `aria-checked` states on interactive widgets

## Forms

- Every input must have a visible `<label>` associated via `for`/`id`
- Group related fields with `<fieldset>` and `<legend>`
- Error messages should be programmatically associated with their inputs using `aria-describedby`
- Provide clear instructions before forms and inline validation feedback
- Don't rely solely on placeholder text as a label

## Motion and Timing

- Respect `prefers-reduced-motion` — disable or reduce animations for users who opt out
- Avoid content that flashes more than 3 times per second
- If time limits exist, allow users to extend, adjust, or turn them off

## Touch Targets

- Minimum touch target size of 44x44 CSS pixels for interactive elements
- Provide adequate spacing between adjacent targets to prevent mis-taps

## Content and Readability

- Use clear, simple language where possible
- Ensure text can be resized up to 200% without loss of content or functionality
- Don't use `user-select: none` on content users may need to copy
- Maintain a readable line length (roughly 45–80 characters)

## Finding format

When reporting findings — both during independent triage and when invoked by `/full-review` — present each finding as a structured markdown block separated by `---`:

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

Severity is relative to this category (CRITICAL accessibility ≠ CRITICAL security). For file-level findings with no discrete snippet (e.g. "split this file"), omit the Before/After blocks and put the full detail in the Fix paragraph. If no issues are found, output exactly: `No findings.`
