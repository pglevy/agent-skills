#!/bin/bash
# Structural checks for the browser-harness skill and its Appian reference.
# Usage: ./browser-harness/tests/test_skill.sh   (needs jq)
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL="$ROOT/browser-harness"
fail=0

check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"; fail=1
  fi
}

frontmatter_name() { awk '/^---$/{n++; next} n==1 && /^name:/{print $2; exit}' "$SKILL/SKILL.md"; }

check "SKILL.md exists" test -f "$SKILL/SKILL.md"
check "frontmatter name is browser-harness" test "$(frontmatter_name)" = "browser-harness"
check "Appian reference exists and is non-empty" test -s "$SKILL/references/appian-sail.md"
check "SKILL.md points to references/appian-sail.md" grep -q 'references/appian-sail.md' "$SKILL/SKILL.md"
check "SKILL.md has an Appian / SAIL section" grep -q '^## Appian / SAIL' "$SKILL/SKILL.md"
check "SKILL.md names Appian trigger terms" grep -qi 'appiancloud.com' "$SKILL/SKILL.md"
check "Appian reference has no YAML frontmatter (not a standalone skill)" test "$(head -1 "$SKILL/references/appian-sail.md")" != "---"
check "Appian reference covers fresh position queries" grep -qi 'fresh' "$SKILL/references/appian-sail.md"
check "Appian reference covers React typing verification" grep -qi 'React' "$SKILL/references/appian-sail.md"
for f in bh start-browser.sh stop-browser.sh; do
  check "scripts/$f exists and is executable" test -x "$SKILL/scripts/$f"
  check "scripts/$f passes bash -n" bash -n "$SKILL/scripts/$f"
done
check "SKILL.md documents the launch scripts" grep -q '^## Isolated Chrome' "$SKILL/SKILL.md"
check "stop-browser.sh supports --all" grep -q -- "--all" "$SKILL/scripts/stop-browser.sh"
check "browser-harness is not in skills-sync.json" test "$(jq -r '.sources | has("browser-harness")' "$ROOT/skills-sync.json")" = "false"
check "evals.json is valid JSON" jq -e . "$SKILL/evals/evals.json"
check "evals.json skill_name matches" test "$(jq -r .skill_name "$SKILL/evals/evals.json")" = "browser-harness"
check "every eval has id, name, prompt, expectations" \
  jq -e '.evals | length > 0 and all(.[]; has("id") and has("name") and has("prompt") and (.expectations | length > 0))' "$SKILL/evals/evals.json"
check "eval ids are unique" jq -e '[.evals[].id] | length == (unique | length)' "$SKILL/evals/evals.json"

exit $fail
