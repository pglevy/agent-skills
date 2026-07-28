#!/usr/bin/env bash
# migrate-to-gitlab.sh — Mirror a GitHub repo to gitlab.appian-stratus.com
#
# Usage:
#   ./migrate-to-gitlab.sh <github-repo-url> [gitlab-namespace]
#
# Examples:
#   ./migrate-to-gitlab.sh https://github.com/org/my-repo
#   ./migrate-to-gitlab.sh https://github.com/org/my-repo other.user
#
# Requirements: git, glab (authenticated to gitlab.appian-stratus.com), SSH key added to GitLab
# Note: Requires VPN access to gitlab.appian-stratus.com

set -euo pipefail

GITLAB_HOST="gitlab.appian-stratus.com"
GITHUB_URL=""
NAMESPACE=""

for arg in "$@"; do
  case "$arg" in
    http*) GITHUB_URL="$arg" ;;
    *) NAMESPACE="$arg" ;;
  esac
done

if [[ -z "$GITHUB_URL" ]]; then
  echo "Usage: $0 <github-repo-url> [gitlab-namespace]"
  exit 1
fi

[[ -z "$NAMESPACE" ]] && NAMESPACE=$(GITLAB_HOST=$GITLAB_HOST glab api user 2>/dev/null | jq -r '.username' || echo "")

REPO_NAME=$(basename "$GITHUB_URL" .git)
GITHUB_REPO=$(echo "$GITHUB_URL" | sed 's|https://github.com/||;s|\.git$||')
DESCRIPTION=$(gh repo view "$GITHUB_REPO" --json description -q '.description' 2>/dev/null || echo "")

echo "→ Cloning $GITHUB_URL (bare)..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

git clone --bare "$GITHUB_URL" "$TMPDIR/$REPO_NAME" || {
  echo "✗ Clone failed. Check your GitHub access and repo URL."
  exit 1
}

echo "→ Creating GitLab repo $NAMESPACE/$REPO_NAME..."
GITLAB_HOST=$GITLAB_HOST glab repo create "$NAMESPACE/$REPO_NAME" --internal ${DESCRIPTION:+-d "$DESCRIPTION"} 2>&1 || {
  echo "✗ Could not create GitLab repo. Are you on VPN? Is glab authenticated to $GITLAB_HOST?"
  exit 1
}

echo "→ Pushing all refs to GitLab..."
cd "$TMPDIR/$REPO_NAME"
git push "git@$GITLAB_HOST:$NAMESPACE/$REPO_NAME.git" --mirror 2>&1 | grep -v "deny updating a hidden ref" || true
cd - > /dev/null

echo "→ Updating origin remote to GitLab..."
if git -C . remote get-url origin &>/dev/null; then
  git remote set-url origin "git@$GITLAB_HOST:$NAMESPACE/$REPO_NAME.git"
else
  git remote add origin "git@$GITLAB_HOST:$NAMESPACE/$REPO_NAME.git"
fi

echo "✓ Done: https://$GITLAB_HOST/$NAMESPACE/$REPO_NAME"
echo "  To delete the GitHub repo, visit: $GITHUB_URL/settings (scroll to Danger Zone)"
