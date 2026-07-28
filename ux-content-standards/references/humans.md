---
description: Apply Appian's UX content standards when writing or reviewing UI copy
---

# UX Content Standards

This skill applies Appian's UX content guidelines whenever the agent is generating or reviewing user-facing UI strings — buttons, labels, dialogs, error messages, tooltips, placeholders, confirmations, and banners.

## Who this is for

Designers and anyone working on mockups or prototypes who want UI copy to reflect Appian's content voice and standards without having to manually reference the guidelines on every iteration.

## When to use this

- You're generating UI strings for a mockup or prototype and want them to be standards-compliant from the start
- You have existing copy in a mockup you want audited or corrected
- You're reviewing a design and want a quick check of labels, error messages, or other UI text
- You're working alongside quick-mockup or any Sailwind-based prototype and the output includes user-facing text

## What the agent will do

At activation, the agent fetches the current UX content standards from the internal source of truth via `glab`. It then applies those rules passively throughout generation — writing correct copy the first time rather than running a post-generation checklist. If asked to audit, it reviews the provided strings against the fetched ruleset and surfaces any issues with suggested fixes.

## Requirements

- VPN access (required to reach the internal GitLab instance)
- `glab` authenticated to gitlab.appian-stratus.com

## How this fits into our process

UI copy quality is part of design quality. This skill makes it easy to hold that bar without extra manual effort — the standards travel with the agent rather than living in a separate document you have to remember to check.
