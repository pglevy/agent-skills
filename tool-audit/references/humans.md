---
description: Check that your machine and workspace have the right CLI tools and MCP servers configured for working with Kiro
---

# Tool Audit

This skill checks your setup and tells you what's installed, what's missing, and what to do about it. Think of it as a health check for your development tools.

## Who this is for

Any designer using Kiro who wants to make sure their machine is set up correctly — especially after getting a new laptop, joining the team, or if something feels "off" with their tools.

## When to use this

- You just set up a new machine and want to verify everything's in place
- MCP servers aren't connecting or tools aren't behaving as expected
- You're starting a new project and want to make sure workspace config is right
- You want to know what's recommended vs. what you actually have

## What the agent will do

The agent scans your machine for required and recommended CLI tools (like `gh`, `glab`, `pnpm`), reads your global and workspace MCP configurations, checks registry settings, and produces a clear report. It flags what's missing or misconfigured and offers to fix things for you.

## What gets checked

- **CLI tools:** brew, git, node, pnpm, gh (GitHub), glab (GitLab), jq
- **MCP servers:** workspace-level configs for Chrome DevTools, Playwright, and others
- **Registry:** whether `.npmrc` is set up so MCP servers can fetch packages from the right place

## How this fits into our process

This is a maintenance skill in the Ops category. Run it any time — there's no wrong moment. It pairs well with the Setup Sailwind skill (which gets you from zero to running) by verifying that everything *stayed* correct over time.

