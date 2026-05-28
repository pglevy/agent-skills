#!/bin/bash
# sync-skills.sh — Pull latest versions of sourced skills from upstream repos.
# Reads skills-sync.json and overwrites local copies with upstream content.
#
# Requirements:
#   - jq (for parsing JSON config)
#   - gh CLI (for GitHub repos)
#   - glab CLI (for GitLab repos)
#
# Usage:
#   ./sync-skills.sh              # sync all sourced skills
#   ./sync-skills.sh skill-name   # sync a single skill

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/skills-sync.json"

if [ ! -f "$CONFIG" ]; then
  echo "Error: skills-sync.json not found at $CONFIG"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed. Install with: brew install jq"
  exit 1
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get list of skills to sync
if [ $# -gt 0 ]; then
  SKILLS=("$@")
else
  SKILLS=()
  while IFS= read -r line; do
    SKILLS+=("$line")
  done < <(jq -r '.sources | keys[]' "$CONFIG")
fi

echo "Syncing ${#SKILLS[@]} skill(s)..."
echo ""

SYNCED=0
FAILED=0

for SKILL in "${SKILLS[@]}"; do
  # Read config for this skill
  HOST=$(jq -r ".sources[\"$SKILL\"].host // \"github\"" "$CONFIG")
  REPO=$(jq -r ".sources[\"$SKILL\"].repo // empty" "$CONFIG")
  PATH_IN_REPO=$(jq -r ".sources[\"$SKILL\"].path // empty" "$CONFIG")
  BRANCH=$(jq -r ".sources[\"$SKILL\"].branch // \"main\"" "$CONFIG")
  GITLAB_HOST=$(jq -r ".sources[\"$SKILL\"].gitlabHost // empty" "$CONFIG")

  if [ -z "$REPO" ] || [ -z "$PATH_IN_REPO" ]; then
    echo -e "${YELLOW}⚠ Skipping $SKILL — missing repo or path in config${NC}"
    FAILED=$((FAILED + 1))
    continue
  fi

  echo -e "Syncing ${GREEN}$SKILL${NC} from $HOST:$REPO ($BRANCH)..."

  # Create a temp directory for the download
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT

  SUCCESS=false

  case "$HOST" in
    github)
      if ! command -v gh &> /dev/null; then
        echo -e "${RED}  ✗ gh CLI not installed, skipping${NC}"
        FAILED=$((FAILED + 1))
        continue
      fi

      # Download the directory contents as a tarball and extract
      if gh api "repos/$REPO/tarball/$BRANCH" > "$TMPDIR/archive.tar.gz" 2>/dev/null; then
        # Extract just the path we need
        tar -xzf "$TMPDIR/archive.tar.gz" -C "$TMPDIR" 2>/dev/null

        # Find the extracted directory (GitHub adds a prefix like owner-repo-sha/)
        EXTRACTED_DIR=$(find "$TMPDIR" -maxdepth 1 -type d ! -name "$(basename "$TMPDIR")" | head -1)

        if [ -n "$EXTRACTED_DIR" ] && [ -d "$EXTRACTED_DIR/$PATH_IN_REPO" ]; then
          # Remove existing local skill directory and replace
          rm -rf "$SCRIPT_DIR/$SKILL"
          cp -R "$EXTRACTED_DIR/$PATH_IN_REPO" "$SCRIPT_DIR/$SKILL"
          SUCCESS=true
        else
          echo -e "${RED}  ✗ Path '$PATH_IN_REPO' not found in archive${NC}"
        fi
      else
        echo -e "${RED}  ✗ Failed to download archive from GitHub${NC}"
      fi
      ;;

    gitlab)
      if ! command -v glab &> /dev/null; then
        echo -e "${RED}  ✗ glab CLI not installed, skipping${NC}"
        FAILED=$((FAILED + 1))
        continue
      fi

      # URL-encode the repo path for GitLab API
      ENCODED_REPO=$(echo "$REPO" | sed 's/\//%2F/g')

      # Build the glab command with optional host
      GLAB_FLAGS=""
      if [ -n "$GITLAB_HOST" ]; then
        GLAB_FLAGS="--hostname $GITLAB_HOST"
      fi

      # Download archive from GitLab
      if glab api $GLAB_FLAGS "projects/$ENCODED_REPO/repository/archive.tar.gz?sha=$BRANCH" > "$TMPDIR/archive.tar.gz" 2>/dev/null; then
        tar -xzf "$TMPDIR/archive.tar.gz" -C "$TMPDIR" 2>/dev/null

        # GitLab uses a prefix like repo-name-branch-sha/
        EXTRACTED_DIR=$(find "$TMPDIR" -maxdepth 1 -type d ! -name "$(basename "$TMPDIR")" | head -1)

        if [ -n "$EXTRACTED_DIR" ] && [ -d "$EXTRACTED_DIR/$PATH_IN_REPO" ]; then
          rm -rf "$SCRIPT_DIR/$SKILL"
          cp -R "$EXTRACTED_DIR/$PATH_IN_REPO" "$SCRIPT_DIR/$SKILL"
          SUCCESS=true
        else
          echo -e "${RED}  ✗ Path '$PATH_IN_REPO' not found in archive${NC}"
        fi
      else
        echo -e "${RED}  ✗ Failed to download archive from GitLab${NC}"
      fi
      ;;

    *)
      echo -e "${RED}  ✗ Unknown host type: $HOST${NC}"
      FAILED=$((FAILED + 1))
      continue
      ;;
  esac

  # Clean up temp dir
  rm -rf "$TMPDIR"
  trap - EXIT

  if [ "$SUCCESS" = true ]; then
    echo -e "  ${GREEN}✓ Synced successfully${NC}"
    SYNCED=$((SYNCED + 1))
  else
    FAILED=$((FAILED + 1))
  fi

  echo ""
done

echo "Done. Synced: $SYNCED, Failed: $FAILED"
