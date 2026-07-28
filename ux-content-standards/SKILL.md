---
name: ux-content-standards
description: >
  Apply Appian's UX content standards when writing or reviewing UI copy in mockups and
  prototypes. Use this skill when generating UI strings — buttons, labels, dialogs, errors,
  tooltips, placeholders, confirmations, banners — or when auditing existing copy against
  Appian content guidelines. Always activate this skill alongside quick-mockup or any
  sailwind-based prototype when the output includes user-facing text. Also trigger when
  the user asks to review, fix, or validate UI copy, strings, or content in any mockup
  or prototype, even if the word "standards" isn't mentioned.
metadata:
  title: UX Content Standards
  prompt: "Review this mockup copy against the UX content standards: "
  tags:
    - Define
    - Deliver
  human-reviewer: Philip Levy
  last-reviewed: 2026-06-12
---

# UX Content Standards

Apply these rules whenever you are generating or reviewing user-facing UI strings —
buttons, labels, dialogs, error messages, tooltips, placeholders, and any other copy
in a mockup or prototype.

These are the canonical rules. Read them once at the start and apply them passively
throughout generation. Don't run through this as a post-generation checklist on every
iteration — internalize the rules and write correctly the first time.

## Fetching the ruleset

At the start of every activation, fetch the current ruleset from the source of truth using the `glab` CLI (which handles authentication automatically):

```bash
glab api --hostname gitlab.appian-stratus.com "projects/appian%2Fprod%2Finfodev-ai-tools/repository/files/.kiro%2Fsteering%2Finfodev%2Freference%2Fux-content-standards.md/raw?ref=main"
```

Strip the YAML frontmatter block (everything from the opening `---` through the closing `---`) before reading the content. The rules begin after that block.

Apply the fetched content as the authoritative ruleset. Do not proceed if the command fails — report the error to the user.
