---
description: Move an existing GitHub repo to our internal GitLab instance
---

# Migrate to GitLab

This skill moves an existing GitHub repository to gitlab.appian-stratus.com — preserving the full git history, branches, and tags — and updates your local project so future work goes to GitLab instead of GitHub.

## Who this is for

Anyone on the team with a project currently living on GitHub who wants to move it to our internal GitLab. You don't need to know git deeply — the agent handles the migration and explains what's happening.

## When to use this

- You have an existing project on GitHub and want it on our internal GitLab
- Your team is consolidating repos away from GitHub
- You've been asked to move a project off GitHub

## What the agent will do

The agent checks that the required tools are set up (glab, SSH key, jq), then runs the migration script. The script clones your GitHub repo as a full mirror, creates a new internal repo on GitLab, pushes everything over, and updates your local remote. When it's done, it gives you the GitLab URL and optionally guides you to delete the GitHub repo.

## Requirements

- VPN access (required to reach gitlab.appian-stratus.com)
- glab authenticated to gitlab.appian-stratus.com
- SSH key added to your GitLab account
- Personal access token with `api` and `write_repository` scopes

## How this fits into our process

GitLab is our internal home for project repos. This skill is a transitional tool — it exists to make it easy to move existing projects over. Once everything is on GitLab, new projects are created there from the start using the setup-sailwind skill.
