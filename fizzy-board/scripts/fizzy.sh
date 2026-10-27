#!/usr/bin/env bash
# Thin curl+jq wrapper around the Fizzy API, scoped to the single board this
# skill watches. See ../SKILL.md and ../references/api-reference.md for how
# and why this is used.
set -euo pipefail

CONFIG_DIR="${FIZZY_CONFIG_DIR:-$HOME/.config/fizzy}"
CONFIG_FILE="$CONFIG_DIR/credentials"

ensure_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<'EOF'
FIZZY_BASE_URL="https://fizzy.example.com"   # self-hosted install or https://fizzy.do
FIZZY_ACCOUNT_SLUG="/0000000"                # includes the leading slash, from GET /my/identity
FIZZY_TOKEN="put-personal-access-token-here" # needs write permission to comment/triage/assign
FIZZY_BOARD_ID=""                            # the one board this skill watches
FIZZY_KIRO_USER_ID=""                        # resolved once via `fizzy.sh whoami-kiro`, cached here
EOF
    echo "No config found. Created a template at $CONFIG_FILE — fill it in and re-run." >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"

  local missing=()
  [[ "$FIZZY_BASE_URL" == "https://fizzy.example.com" || -z "${FIZZY_BASE_URL:-}" ]] && missing+=(FIZZY_BASE_URL)
  [[ "$FIZZY_ACCOUNT_SLUG" == "/0000000" || -z "${FIZZY_ACCOUNT_SLUG:-}" ]] && missing+=(FIZZY_ACCOUNT_SLUG)
  [[ "$FIZZY_TOKEN" == "put-personal-access-token-here" || -z "${FIZZY_TOKEN:-}" ]] && missing+=(FIZZY_TOKEN)
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Config at $CONFIG_FILE still has placeholder/missing values: ${missing[*]}" >&2
    echo "Fill those in before using this skill." >&2
    exit 1
  fi
}

require_jq() {
  command -v jq >/dev/null 2>&1 || { echo "jq is required (brew install jq)." >&2; exit 1; }
}

api() {
  # api METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local url="${FIZZY_BASE_URL}${FIZZY_ACCOUNT_SLUG}${path}"
  if [[ -n "$body" ]]; then
    curl -sS -X "$method" \
      -H "Authorization: Bearer ${FIZZY_TOKEN}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d "$body" \
      "$url"
  else
    curl -sS -X "$method" \
      -H "Authorization: Bearer ${FIZZY_TOKEN}" \
      -H "Accept: application/json" \
      "$url"
  fi
}

cmd_whoami_kiro() {
  require_jq
  api GET "/users" | jq -c '.[] | select(.name | test("kiro"; "i")) | {id, name}'
}

cmd_columns() {
  require_jq
  : "${FIZZY_BOARD_ID:?Set FIZZY_BOARD_ID in $CONFIG_FILE first}"
  api GET "/boards/${FIZZY_BOARD_ID}/columns" | jq -c '.[] | {id, name}'
}

cmd_assigned_cards() {
  require_jq
  : "${FIZZY_BOARD_ID:?Set FIZZY_BOARD_ID in $CONFIG_FILE first}"
  : "${FIZZY_KIRO_USER_ID:?Set FIZZY_KIRO_USER_ID in $CONFIG_FILE first (see whoami-kiro)}"
  local candidates
  candidates=$(api GET "/cards?board_ids[]=${FIZZY_BOARD_ID}&assignee_ids[]=${FIZZY_KIRO_USER_ID}" | jq -c '.[].number')
  for number in $candidates; do
    local detail
    detail=$(api GET "/cards/${number}")
    # Only surface cards that are open and triaged into a real column
    # (i.e. not closed, and not sitting in Maybe?/Not Now where `column` is absent).
    if echo "$detail" | jq -e '(.closed != true) and (.column != null)' >/dev/null; then
      echo "$detail" | jq -c '{number, title, column: .column.name, url}'
    fi
  done
}

cmd_card() {
  require_jq
  local number="${1:?card number required}"
  api GET "/cards/${number}" | jq '.'
}

cmd_comments() {
  require_jq
  local number="${1:?card number required}"
  api GET "/cards/${number}/comments" | jq -c '.[] | {creator: .creator.name, body: .body.plain_text, created_at}'
}

cmd_comment() {
  local number="${1:?card number required}" body="${2:?comment body required}"
  local json
  json=$(jq -nc --arg b "$body" '{comment: {body: $b}}')
  api POST "/cards/${number}/comments" "$json" >/dev/null
  echo "Commented on card ${number}."
}

cmd_triage() {
  local number="${1:?card number required}" column_id="${2:?column id required}"
  local json
  json=$(jq -nc --arg c "$column_id" '{column_id: $c}')
  api POST "/cards/${number}/triage" "$json" >/dev/null
  echo "Moved card ${number} to column ${column_id}."
}

cmd_assign() {
  local number="${1:?card number required}" user_id="${2:?user id required}"
  local json
  json=$(jq -nc --arg u "$user_id" '{assignee_id: $u}')
  api POST "/cards/${number}/assignments" "$json" >/dev/null
  echo "Toggled assignment of ${user_id} on card ${number}."
}

ensure_config

case "${1:-}" in
  whoami-kiro)      shift; cmd_whoami_kiro "$@" ;;
  columns)          shift; cmd_columns "$@" ;;
  assigned-cards)   shift; cmd_assigned_cards "$@" ;;
  card)             shift; cmd_card "$@" ;;
  comments)         shift; cmd_comments "$@" ;;
  comment)          shift; cmd_comment "$@" ;;
  triage)           shift; cmd_triage "$@" ;;
  assign)           shift; cmd_assign "$@" ;;
  *)
    cat >&2 <<EOF
Usage: fizzy.sh <command> [args]

  whoami-kiro                  Find the Kiro user's id (to fill FIZZY_KIRO_USER_ID)
  columns                      List columns on the configured board
  assigned-cards                List open cards assigned to Kiro on the configured board
  card <number>                 Full detail for a card
  comments <number>             List comments on a card
  comment <number> <body>       Post a comment
  triage <number> <column_id>   Move a card into a column
  assign <number> <user_id>     Toggle a user's assignment on a card
EOF
    exit 1
    ;;
esac
