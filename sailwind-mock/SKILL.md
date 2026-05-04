---
name: sailwind-mock
description: Generate UI mockups as standalone HTML pages using the Sailwind design token system. Use this skill when asked to create mockups, prototypes, or HTML previews for an app or feature — given a text description (app spec, PRD, feature brief) and/or a reference screenshot/image. Produces coherent multi-page HTML mockups styled exclusively from the Sailwind design tokens (colors, typography, spacing, gradients). Do NOT use the frontend-design skill for these tasks.
---

# Sailwind Mock

Generate standalone HTML mockup pages for an app using the Sailwind design token system.

## Inputs

The user will provide one or both of:
- A text description / app spec / PRD (business context)
- A reference image or screenshot to match

## Workflow

1. Read the design tokens from the live source: https://cdn.jsdelivr.net/gh/pglevy/sailwind@main/public/tokens.json
   - Fetch this URL at the start of every generation to get the current token values
   - Do NOT copy or embed the token file — always reference it live

2. Determine which pages/screens to generate based on the input. If the spec describes multiple views, generate each as a separate HTML file.

3. Generate each page as a standalone HTML file following the rules below.

4. Save files into an `html/` subfolder within the current working directory (or wherever the user specifies).

5. After all HTML files are saved, run the icon validation script to check for invalid Font Awesome icon references. The script is located at `scripts/validate-icons.sh` within the global skills directory where this skill is installed. Run it from the project root. If any invalid icons are found, fix them in the HTML files before proceeding — replace with valid free alternatives suggested by the script, or choose a different icon from the free set.

6. After all icons are validated, run the screenshot script to sync the `screenshots/` folder. The script is located at `scripts/screenshot.sh` within the global skills directory where this skill is installed. Locate and run it from there — do not copy it into the project.

## HTML Generation Rules

- Each file must be fully self-contained (no external CSS files, no shared stylesheets)
- Derive ALL styles directly from the token values you fetched — colors, typography, spacing, radius, gradients
- DO NOT assume any CSS framework (no Tailwind, Bootstrap, etc.)
- DO NOT use the `frontend-design` skill
- Navigation between pages should use relative links

### Icons
Use Font Awesome — include this CDN link in every page:
```html
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.1/css/all.min.css">
```
Do NOT use emoji as icons.

### Charts
If the design calls for charts, use Chart.js:
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
```

### Token Usage
Resolve all token aliases (e.g. `{color.blue.500}`) to their actual values when writing CSS. Base all design decisions on what you find in the fetched file — do not guess or infer token values.

## Output

- One `.html` file per screen/page
- Files placed in `html/` subfolder
- Pages should be visually coherent as a set

## Icon Validation

A script at `scripts/validate-icons.sh` within this skill's global install location checks all HTML files for Font Awesome icon classes that don't exist in the free CDN CSS.

- Fetches the FA 7.0.1 free CSS and extracts valid icon names
- Scans all `fa-*` classes in HTML files (ignoring style prefixes and utility classes)
- Reports invalid icons with suggested alternatives when available
- Exits with code 1 if any invalid icons are found

Many icons that AI agents "guess" are actually Font Awesome Pro icons not available in the free tier. Always run this validation before presenting mockups.

## Screenshots

A script at `scripts/screenshot.sh` within this skill's global install location captures PNG screenshots of all HTML files.

- Screenshots are saved to a `screenshots/` folder at the project root
- Filename matches the HTML file without the `.html` extension
- Resolution: 1600×1000 at 2x (retina), resulting in 3200×2000px images
- Hooks auto-run this script whenever files are created or edited in `html/`

To run manually, locate `screenshot.sh` in the global skills directory where this skill is installed and run it from the project root. Do not copy the script into the project.

Requires `uv` to be installed (`brew install uv` or https://docs.astral.sh/uv/getting-started/installation/).
