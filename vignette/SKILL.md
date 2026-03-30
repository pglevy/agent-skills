---
name: mint-cli
description: Guide for querying Sailwind design tokens using the Mint CLI. Use when looking up colors, typography, or spacing tokens for UI components in this project.
---

# Mint Design Token CLI

Mint is a globally-installed CLI tool that fetches and queries Sailwind design tokens directly from the published token source. Use it to look up colors, typography, and spacing tokens when building UI components.

## Installation

Clone the repo and install globally via npm link:

```bash
git clone https://github.com/pglevy/mint.git
cd mint
npm install
npm run build
npm link
```

After linking, the `mint` command is available anywhere in your terminal.

## How to invoke

Once installed, run from any directory:

```bash
mint <command> [options]
```

Tokens are fetched automatically from the published Sailwind token source — no local source path needed.

## Commands

### List tokens

Show all tokens grouped by category, or filter by category:

```bash
mint list
mint list --category color
mint list --category typography
mint list --category spacing
```

### Query tokens as DTCG JSON

Get structured JSON output, with optional category and family filters:

```bash
mint tokens
mint tokens --category color --family red
mint tokens --category spacing
```

### Export tokens

Export the full token set or a filtered subset as DTCG JSON:

```bash
mint export
mint export --category color --out color-tokens.json
```

### MCP schema

Output the MCP tool definition schema:

```bash
mint mcp-schema
```

## Token categories

- **color** — Aurora color palette (red, orange, yellow, green, teal, sky, blue, purple, pink, gray) plus aliases (black, white)
- **typography** — Font family, font weight, and text sizes
- **spacing** — Spacing scale and border radius values

## When to use

- When you need the exact hex value for a color (e.g., "what's the hex for red-500?")
- When building a component and need to know available spacing or typography tokens
- When you need to understand the full token set available in Sailwind

## JSON output

Add `--json` to any command for machine-readable output. The `tokens` and `export` commands always output DTCG JSON.
