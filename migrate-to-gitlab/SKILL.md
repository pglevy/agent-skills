---
name: migrate-to-gitlab
description: Migrate an existing local git repository to a GitLab instance by creating a new remote repo and updating the origin. Use when a user wants to publish or move a project to GitLab (e.g., gitlab.example.com), create a new GitLab repo from an existing local repo, or update the git remote origin to point to GitLab instead of GitHub or another host.
---

# Migrate Repo to GitLab

## Prerequisites

- `glab` CLI installed and authenticated to the target GitLab host
- Existing local git repo with commits

## Check Auth

```bash
glab auth status
```

Look for `✓ Logged in to <hostname> as <username>`. If the token is expired:

```bash
glab auth login --hostname <gitlab-host>
```

## Create the Remote Repo

Use the `<namespace>/<repo-name>` path syntax with `GITLAB_HOST` env var. The `--skipGitInit` flag is required — without it, glab interactively prompts whether to create a local folder, blocking the command from completing.

```bash
GITLAB_HOST=<gitlab-host> glab repo create <namespace>/<repo-name> --private --skipGitInit
```

Example:
```bash
GITLAB_HOST=gitlab.example.com glab repo create your-username/your-repo --private --skipGitInit
```

Visibility flags: `--private`, `--public`, or `--internal`.

## Update Remote Origin

Switch origin from the old remote to the new GitLab SSH URL:

```bash
git remote set-url origin git@<gitlab-host>:<namespace>/<repo-name>.git
```

Example:
```bash
git remote set-url origin git@gitlab.example.com:your-username/your-repo.git
```

Verify:
```bash
git remote -v
```

## Push

```bash
git push -u origin main
```

## Notes

- `--hostname` flag does NOT exist on `glab repo create` — use `GITLAB_HOST=<host>` env var instead
- `--namespace` flag does NOT exist — use `<namespace>/<repo-name>` as the path argument
- `--no-clone` flag does NOT exist — use `--skipGitInit` to avoid reinitializing git
- If the repo has branch protection on `main` and you need to replace an initial commit, see the branch rename workaround in the gitlab-pages power
