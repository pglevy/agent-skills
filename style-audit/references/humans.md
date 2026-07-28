---
description: Review design system token inconsistencies and optionally create a merge request
---

# Style Audit

A style audit checks your component's CSS against the Sailwind design tokens to catch hardcoded colors, spacing, and typography values that should be using tokens instead. It's a quality gate before shipping — making sure what's in code matches what's in the design system.

## When to use this

- You're about to ship a component and want to verify token compliance
- You've inherited code that might have drifted from the design system
- You want a quick health check on a directory of styles

## What you'll need to provide

- The target directory containing your component's style files (`.less`, `.css`, `.tsx`, `.jsx`)
- Optionally, a scope filter if you only care about colors or spacing
- Optionally, a ticket number for commit messages

## What you'll get back

A report classifying every hardcoded value as:
- **Auto-fixed** — the value maps to a token and was corrected in place
- **Needs review** — the value is close to a token but a human should decide
- **No token equivalent** — the value has no reasonable token match

The agent creates a branch with fixes applied and the report committed. You review the diff and decide what to keep.

## Tips for a clean audit

- Run this on a focused directory (one component or feature), not your entire codebase
- Check the "Needs Review" section carefully — these are judgment calls only you can make
- If you see the same unmatched value appearing many times, it might be worth proposing a new token
