---
name: migrate-to-gitlab
description: >
  Migrate an existing GitHub repository to gitlab.appian-stratus.com. Mirrors all
  commits, branches, and tags to a new internal GitLab repo in the user's personal
  namespace, then updates the local git remote to point to GitLab. Use this skill when
  someone says "move my repo to GitLab", "migrate from GitHub", "I need my project on
  GitLab", "how do I get off GitHub", or wants to consolidate repos onto our internal
  GitLab instance.
metadata:
  title: Migrate to GitLab
  prompt: "Help me migrate this repo to GitLab: "
  tags:
    - Ops
  human-reviewer: Philip Levy
  last-reviewed: 2026-06-05
---

# Migrate to GitLab

Mirror an existing GitHub repository to gitlab.appian-stratus.com — preserving full git history, branches, and tags — and update the local remote so future work goes to GitLab.

The target user may be a designer with limited terminal experience. Explain what's happening at each step without assuming git expertise.

## Inputs

Ask the user for:
1. The GitHub repo URL (e.g. `https://github.com/org/my-repo`)
2. Optionally, a different GitLab namespace to create the repo under (defaults to their own username)

## Prerequisites

Before running the migration script, check that the following are in place. If anything is missing, handle it first.

**glab installed and authenticated:**
```bash
which glab && glab --version || echo "glab needed"
GITLAB_HOST=gitlab.appian-stratus.com glab api user 2>/dev/null | jq -r '.username'
```

If glab is missing: `brew install glab`

If not authenticated (empty output or error): make sure the user is on VPN, then:
```bash
glab auth login --hostname gitlab.appian-stratus.com
```
Follow the prompts — requires a personal access token with `api` and `write_repository` scopes. If they don't have one: https://gitlab.appian-stratus.com/-/user_settings/personal_access_tokens

**SSH key added to GitLab:**
The script pushes via SSH. If the user hasn't added their SSH key to GitLab yet:
1. Check if they have a key: `cat ~/.ssh/id_ed25519.pub || cat ~/.ssh/id_rsa.pub`
2. If none exists: `ssh-keygen -t ed25519 -C "your-email"`
3. Add the public key at: https://gitlab.appian-stratus.com/-/user_settings/ssh_keys

**jq installed** (used to parse the GitLab API response):
```bash
which jq || brew install jq
```

**VPN connected** — gitlab.appian-stratus.com is not reachable without it.

## Instructions

### Step 1 — Confirm inputs

Confirm with the user:
- The GitHub URL of the repo to migrate
- Whether to use their own GitLab namespace (default) or a different one

### Step 2 — Run the migration script

Locate `scripts/migrate-to-gitlab.sh` within the global skills directory where this skill is installed and run it:

```bash
bash <path-to-skill>/scripts/migrate-to-gitlab.sh <github-repo-url> [gitlab-namespace]
```

The script will:
1. Clone the GitHub repo as a bare mirror (captures all branches, tags, and history)
2. Create a new internal repo on gitlab.appian-stratus.com under the specified namespace
3. Push everything to GitLab
4. Update the `origin` remote in the current local repo to point to GitLab

The whole thing typically takes under a minute for most repos.

### Step 3 — Verify

Confirm with the user:
- The GitLab URL printed at the end is accessible in their browser (check VPN if not)
- The repo has the expected branches and history

Tell the user: "Your project is now on GitLab. Any future commits and pushes will go there."

### Step 4 — Clean up GitHub (optional)

The script prints a reminder link to the GitHub repo settings. If the user wants to delete the GitHub repo, direct them there — it's under the "Danger Zone" section at the bottom of the Settings page.

> **Don't delete the GitHub repo on their behalf.** This is irreversible and should be a conscious decision by the repo owner.

## Troubleshooting

### "command not found: glab"
Install with `brew install glab`, then restart the terminal or run `source ~/.zshrc`.

### glab not authenticated / "401 Unauthorized"
Run `glab auth login --hostname gitlab.appian-stratus.com`. Make sure VPN is connected first.

### SSH push fails / "Permission denied (publickey)"
The user's SSH key isn't added to GitLab.
- Check for existing key: `cat ~/.ssh/id_ed25519.pub`
- Generate one if missing: `ssh-keygen -t ed25519 -C "your-email"`
- Add at: https://gitlab.appian-stratus.com/-/user_settings/ssh_keys

### "Could not create GitLab repo"
Two likely causes:
- Not on VPN — `gitlab.appian-stratus.com` isn't reachable from outside the network
- glab not authenticated — run `glab auth login --hostname gitlab.appian-stratus.com`

### "Clone failed"
- Check that the GitHub URL is correct and the repo is accessible
- If it's a private GitHub repo, make sure `gh` is authenticated: `gh auth login`

### Repo already exists on GitLab
The script will error if a repo with that name already exists in the namespace. Either use a different project name or migrate into a different namespace.

## Quick Reference

```bash
glab --version                                    # Check glab
GITLAB_HOST=gitlab.appian-stratus.com glab api user | jq -r '.username'  # Check auth
jq --version                                      # Check jq
cat ~/.ssh/id_ed25519.pub                         # Check SSH key
```
