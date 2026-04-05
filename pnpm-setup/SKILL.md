---
name: pnpm-setup
description: >
  Guide users through installing and configuring pnpm for the Sailwind project,
  including new project setup and migration from npm. Use this skill when users:
  (1) Ask how to install dependencies or set up the project,
  (2) Get errors related to missing pnpm or wrong package manager (ERR_PNPM_ errors,
  "This project is configured to use pnpm" warnings),
  (3) Say they're new to pnpm or ask about the switch from npm,
  (4) Have an existing project with a package-lock.json and want to migrate to pnpm,
  (5) Ask "how do I get started" or "how do I set this up"
---

# pnpm Setup

This project uses pnpm as its package manager. The `package.json` includes a `packageManager` field set to `pnpm@10.33.0`, which signals to tools like corepack and CI that pnpm should be used. The lockfile is `pnpm-lock.yaml`.

## Setup Workflow

### Step 1: Check if pnpm is installed

```bash
which pnpm
pnpm --version
```

If pnpm is found, skip to Step 3 (or Step 2 if migrating).

### Step 2: Install pnpm

Pick whichever fits the user's setup.

**Option A — Corepack (recommended if Node.js 16.13+ is installed):**

Corepack ships with Node.js and manages pnpm versions automatically based on the `packageManager` field in `package.json`.

```bash
corepack enable
corepack prepare pnpm@10.33.0 --activate
```

**Option B — Homebrew (macOS):**

```bash
brew install pnpm
```

**Option C — npm:**

```bash
npm install -g pnpm@10.33.0
```

**Verify installation:**

```bash
pnpm --version
```

Expected: `10.33.0` (or compatible version).

### Step 2b: Configure pnpm security policy

Set a minimum release age so pnpm only installs packages published for at least 7 days. This protects against supply chain attacks from newly-published malicious packages.

```bash
pnpm config set minimum-release-age 10080 --location user
```

The value `10080` is 7 days in minutes. On macOS this writes to `~/Library/Preferences/pnpm/rc`.

Verify: `pnpm config get minimum-release-age`

### Step 3: Detect new vs. existing project

```bash
ls package-lock.json 2>/dev/null
ls -d node_modules 2>/dev/null
```

- `package-lock.json` exists → existing project migrating from npm. Go to Step 4.
- Neither exists → fresh clone / new project. Skip to Step 5.

### Step 4: Migrate from npm to pnpm (existing projects only)

```bash
rm -rf node_modules
rm -f package-lock.json
```

Reassure the user that only npm artifacts are removed — code and configuration are untouched.

### Step 5: Install dependencies

```bash
pnpm install
```

### Step 6: Verify the setup

```bash
pnpm run build
```

### Step 7: Start developing

Ask the user if they already have a dev server running before starting one:

```bash
pnpm run dev
```

## Quick Reference

| Task | Command |
|------|---------|
| Install dependencies | `pnpm install` |
| Start dev server | `pnpm run dev` |
| Build for production | `pnpm run build` |
| Lint code | `pnpm run lint` |
| Preview production build | `pnpm run preview` |
| Check color palette | `pnpm run check:colors` |
| Add a package | `pnpm add <package>` |
| Add a dev dependency | `pnpm add -D <package>` |

## Troubleshooting

### "command not found: pnpm"

pnpm isn't installed or isn't in PATH. Follow Step 2. If using corepack, ensure `corepack enable` was run.

### "ERR_PNPM_LOCKFILE_MISSING" or lockfile errors

Run `pnpm install` to regenerate the lockfile from `package.json`.

### "This project is configured to use pnpm" (corepack warning)

Corepack detected the `packageManager` field but pnpm isn't activated:

```bash
corepack enable
corepack prepare pnpm@10.33.0 --activate
```

### Old `package-lock.json` or `node_modules` from npm

```bash
rm -rf node_modules
rm -f package-lock.json
pnpm install
```

### Global pnpm config conflicts (work machines)

If pnpm behaves unexpectedly (wrong registry, strict settings, etc.), a global or user-level `.npmrc` may be interfering. Create a project-level `.npmrc` to override:

```bash
touch .npmrc
```

Add only the settings you need to override, e.g.:

```ini
# Use default registry instead of a corporate one
registry=https://registry.npmjs.org/

# Override strict peer dependency settings
strict-peer-dependencies=false
```

pnpm resolves config in order: project `.npmrc` > user `~/.npmrc` > global, so project-level settings win. Only add this file if you're hitting issues — it's not required for most setups.

### Peer dependency warnings

pnpm is stricter about peer dependencies than npm. Most warnings are harmless for prototyping. If a package fails to install:

```bash
pnpm install --shamefully-hoist
```
