---
name: token-policy-standard
description: Analyze a frontend codebase for design token discrepancies against Sailwind tokens, generate a TPS report, apply fixes, and create a PR for human review. Use this skill when asked to audit design tokens, align styles with the design system, or create a TPS report. Works with Less, CSS, and TSX/JSX files.
metadata:
   abbreviation: TPS
   prompt: "Did you get the memo?"
   compliance_level: "High"
---

# Token Wand

Audit a frontend component against Sailwind design tokens, fix what's fixable, flag what isn't, and optionally open a merge request.

## Prerequisites

- `glab` CLI must be authenticated for MR creation (only needed for Phase 6)
- Target directory must contain `.less`, `.css`, `.tsx`, or `.jsx` files with style values

## Inputs

The user provides:
- A target directory (e.g., `service-components/composer-chat`)
- Optionally, a scope filter (e.g., only color, only spacing)
- Optionally, a base branch (defaults to current branch)
- Optionally, `local-only` mode — skip push/MR, just produce the branch + report locally

Before creating any commits, ask the user if they have a ticket number for the commit prefix (e.g., `COMPOSER-123`). If they provide one, use `<TICKET>: <message>` format. If not, use `spike: <message>` as the prefix. Store this as `commit_prefix` for all commits in the workflow.

## Workflow

### Phase 1: Gather tokens

1. Fetch the Sailwind tokens from the versioned CDN:
   ```
   https://cdn.jsdelivr.net/gh/pglevy/sailwind@latest/public/tokens.json
   ```
2. Capture the resolved version from the `x-jsd-version` response header (e.g., `0.10.2`). Store this as `resolved_version` for use in the report.
3. Parse the JSON to build a lookup map of token paths → resolved values
4. Resolve all aliases (tokens whose `$value` references another token like `{color.blue.500}`) to their final concrete values

If the CDN fetch fails, fall back to the `mint` CLI (see `#mint-cli` skill):
```bash
mint tokens --category color --json
mint tokens --category spacing --json
mint tokens --category typography --json
```
When using the mint CLI fallback, run `mint --version` to capture the version and use that instead.

### Phase 2: Scan source files

1. Find all `.less`, `.css`, `.tsx`, `.jsx`, and `.ts` files in the target directory (exclude `node_modules`, `dist`, `build`)
2. For each file, extract hardcoded style values:
   - Hex colors: `#xxx`, `#xxxxxx`, `#xxxxxxxx`
   - RGB/RGBA: `rgb(...)`, `rgba(...)`
   - Pixel values in style contexts: `Npx` (padding, margin, gap, border-radius, font-size, width, height)
   - Font families in quotes or as values
   - Font weights as numbers
   - Font sizes as px/rem values
3. For each extracted value, attempt to match it against the token lookup map:
   - Exact match (value already matches a token as-is, no changes needed) → skip entirely, this value is compliant
   - Normalizable match (value matches a token after normalization, e.g., shorthand hex `#eee` → `#eeeeee`, case difference `#FFF` → `#fff`) → record as "auto-fix" since the source code will change
   - Close match (within a small delta for colors, or nearest token for spacing) → record as "needs review"
   - No match → record as "no token equivalent"

### Phase 3: Classify discrepancies

For each discrepancy, classify it into one of:

- **Auto-fix**: The hardcoded value maps to a token but requires a source code change to get there — the value in the file is not byte-for-byte identical to the token value
  - Shorthand hex that expands to a token match (e.g., `#eee` → `#eeeeee`)
  - Case difference (e.g., `#FFF` → `#fff` to match token casing)
  - Pixel value that exactly matches a spacing/radius token but is expressed differently
  - Font size that exactly matches a typography token but needs format normalization
  - Note: if the value in the source already matches a token exactly (no change needed), it is compliant — do NOT report it or touch it
- **Needs review**: The value is close to a token but not exact — a human should decide
  - Color within ~10% distance of a token but not exact
  - Spacing value between two tokens (e.g., `12px` between `8px` and `16px`)
  - Font weight with no token but a reasonable default exists
- **No token**: The value has no reasonable token equivalent
  - Unique brand colors not in the palette
  - Custom sizes for specific UI elements (avatars, icons)
  - Rgba values with opacity

### Phase 4: Create branch and apply fixes

1. Create a new git branch: `token-wand/<target-dir-name>`
2. For **auto-fix** items only:
   - In `.less` files: replace hardcoded values with Less variables that reference tokens, or with the token value directly if no variable layer exists
   - In `.tsx`/`.jsx` files: replace inline hardcoded hex values with the token value (since JS files can't reference Less variables directly, use the canonical token hex value and add a comment noting the token name)
   - Preserve existing variable indirection — if a file already imports `variables.less` and uses `@var-name`, update the variable definition rather than each usage
3. Commit the fixes: `git add . && git commit -m "<commit_prefix> token-wand auto-fix design token discrepancies"`

### Phase 5: Generate report

Create a markdown report at `.kiro/scratch/token-wand-report.md` with:

```markdown
# Token Wand Report — <target>

Generated: <date>
Tokens version: <resolved_version> (via `x-jsd-version` header)
Tokens source: https://cdn.jsdelivr.net/gh/pglevy/sailwind@<resolved_version>/public/tokens.json

## Summary

- Files scanned: N
- Total discrepancies: N
- Auto-fixed: N
- Needs review: N  
- No token equivalent: N

## Auto-Fixed Changes

| File | Line | Old Value | New Value | Token |
|------|------|-----------|-----------|-------|
| ... | ... | ... | ... | ... |

## Needs Review

| File | Line | Current Value | Closest Token | Token Value | Delta |
|------|------|---------------|---------------|-------------|-------|
| ... | ... | ... | ... | ... | ... |

## No Token Equivalent

| File | Line | Value | Context | Recommendation |
|------|------|-------|---------|----------------|
| ... | ... | ... | ... | ... |

## Open Questions

- List any systemic issues (e.g., "12px appears 10+ times with no token — consider adding a token")
- List any architectural concerns (e.g., "TaskCard.less has no variable imports at all")
- List any values that might be intentionally different from tokens
```

Commit the report to the branch as well: `git add . && git commit -m "<commit_prefix> token-wand report"`

### Phase 6: Push and create MR (skip in local-only mode)

If the user requested `local-only` mode, stop here. The branch and report exist locally for review.

Otherwise:

1. Push the branch: `git push -u origin token-wand/<target-dir-name>`
2. Create an MR using `glab mr create` with:
   - Title: `Token Wand: Align <target> with Sailwind design tokens`
   - Description: Include the summary section from the report
   - Draft mode: `--draft` (so it's clearly for review, not auto-merge)
3. Report the MR URL to the user

## Rules

- NEVER auto-fix a value classified as "needs review" — those go in the report only
- NEVER delete or restructure code — only replace values in-place
- NEVER add new imports or dependencies unless the file already has a pattern for it (e.g., if a `.less` file already imports `variables.less`, you can add new variables there)
- Preserve all existing comments
- When a file uses a variables layer (like `variables.less`), prefer fixing the variable definition over fixing each usage site
- For inline styles in TSX/JSX, add a `/* token: <token-name> */` comment next to the replacement value
- Default to `local-only` mode unless the user explicitly asks to push/create an MR

## Color matching

When comparing colors:
- Normalize to lowercase 6-digit hex before comparing
- Expand shorthand: `#eee` → `#eeeeee`, `#fee` → `#ffeeee`
- For "close match" detection, compare RGB channel-by-channel; if all channels are within 20 of the token value, flag as "needs review"
- Exact match means identical hex after normalization

## Spacing matching

Use the spacing, padding, and radius tokens from the CDN response (Phase 1) as the source of truth. Do NOT use hardcoded px equivalents — always derive them from the fetched tokens.

Values that exactly match a token → auto-fix (if source code changes). Values between tokens (e.g., 12px) → needs review.

## Typography matching

Use the text-size, font-family, and font-weight tokens from the CDN response (Phase 1) as the source of truth. Do NOT use hardcoded values — always derive them from the fetched tokens.
