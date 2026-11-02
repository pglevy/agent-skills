#!/usr/bin/env bash
# Thin curl+jq wrapper around the Fizzy API, scoped to the single board this
# skill watches and to the agent's own user (the one its token belongs to).
# See ../SKILL.md and ../references/api-reference.md for how and why this is used.
set -euo pipefail

CONFIG_DIR="${FIZZY_CONFIG_DIR:-$HOME/.config/fizzy}"
CONFIG_FILE="$CONFIG_DIR/credentials"

ensure_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<'EOF'
FIZZY_BASE_URL="https://fizzy.example.com"   # self-hosted install or https://fizzy.do
FIZZY_ACCOUNT_SLUG="/0000000"                # includes the leading slash, from GET /my/identity
FIZZY_TOKEN="put-personal-access-token-here" # the agent's own token; needs write permission
FIZZY_BOARD_NAME="Work"                      # the one board this skill watches
FIZZY_BOARD_ID=""                            # optional: overrides FIZZY_BOARD_NAME
EOF
    chmod 600 "$CONFIG_FILE"
    echo "No config found. Created a template at $CONFIG_FILE — fill it in and re-run." >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"

  local missing=()
  [[ "${FIZZY_BASE_URL:-}" == "https://fizzy.example.com" || -z "${FIZZY_BASE_URL:-}" ]] && missing+=(FIZZY_BASE_URL)
  [[ "${FIZZY_ACCOUNT_SLUG:-}" == "/0000000" || -z "${FIZZY_ACCOUNT_SLUG:-}" ]] && missing+=(FIZZY_ACCOUNT_SLUG)
  [[ "${FIZZY_TOKEN:-}" == "put-personal-access-token-here" || -z "${FIZZY_TOKEN:-}" ]] && missing+=(FIZZY_TOKEN)
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

# The agent's own user id in the configured account, from the token's identity.
agent_user_id() {
  curl -sS -H "Authorization: Bearer ${FIZZY_TOKEN}" -H "Accept: application/json" \
    "${FIZZY_BASE_URL}/my/identity" \
    | jq -er --arg slug "$FIZZY_ACCOUNT_SLUG" '.accounts[] | select(.slug == $slug) | .user.id'
}

# The watched board's id: FIZZY_BOARD_ID if set, otherwise looked up by FIZZY_BOARD_NAME.
board_id() {
  if [[ -n "${FIZZY_BOARD_ID:-}" ]]; then
    echo "$FIZZY_BOARD_ID"
    return
  fi
  local name="${FIZZY_BOARD_NAME:-Work}" id
  id=$(api GET "/boards" | jq -r --arg n "$name" '[.[] | select(.name | ascii_downcase == ($n | ascii_downcase))][0].id // empty')
  if [[ -z "$id" ]]; then
    echo "No board named \"$name\" that the agent can access. Create it in Fizzy (and give Work Horse access, or make it all-access), or set FIZZY_BOARD_ID." >&2
    exit 1
  fi
  echo "$id"
}

# Resolve a user id from either an id or a (case-insensitive) name.
resolve_user() {
  local who="$1" id
  id=$(api GET "/users" | jq -r --arg w "$who" '[.[] | select(.id == $w or (.name | ascii_downcase) == ($w | ascii_downcase))][0].id // empty')
  [[ -n "$id" ]] || { echo "No user matching \"$who\". Run: fizzy.sh users" >&2; exit 1; }
  echo "$id"
}

cmd_whoami() {
  require_jq
  curl -sS -H "Authorization: Bearer ${FIZZY_TOKEN}" -H "Accept: application/json" \
    "${FIZZY_BASE_URL}/my/identity" \
    | jq -c --arg slug "$FIZZY_ACCOUNT_SLUG" '.accounts[] | select(.slug == $slug) | .user | {id, name, role}'
}

cmd_users() {
  require_jq
  api GET "/users" | jq -c '.[] | select(.role != "system") | {id, name, role}'
}

cmd_board() {
  require_jq
  local id
  id=$(board_id)
  api GET "/boards/${id}" | jq -c '{id, name}'
}

cmd_columns() {
  require_jq
  api GET "/boards/$(board_id)/columns" | jq -c '.[] | {id, name}'
}

# Open cards on the board assigned to the agent. With "attention" only the ones
# where the ball is in the agent's court: nobody has commented yet, or the last
# *substantive* comment came from someone else. System comments (triage moves,
# assignments) are side effects of the agent's own actions, not a reply from a
# person, so they're ignored when finding the last commenter — otherwise the
# agent's own "assign the creator" step after reporting would immediately make
# its own card look unanswered again.
list_cards() {
  require_jq
  local mode="$1" board me candidates
  board=$(board_id)
  me=$(agent_user_id)
  candidates=$(api GET "/cards?board_ids[]=${board}&assignee_ids[]=${me}" | jq -c '.[].number')
  for number in $candidates; do
    local detail last
    detail=$(api GET "/cards/${number}")
    # Only open cards triaged into a real column (not closed, not in Maybe?/Not Now
    # where `column` is absent).
    echo "$detail" | jq -e '(.closed != true) and (.column != null)' >/dev/null || continue
    last=$(api GET "/cards/${number}/comments" \
      | jq -c '[.[] | select(.creator.role != "system")] | if length == 0 then null else .[-1].creator.id end')
    echo "$detail" | jq -c --argjson last "$last" --arg me "$me" '
      {number, title, column: .column.name, url,
       created_by: .creator.name,
       last_commenter_is_agent: ($last == $me),
       needs_attention: ($last != $me)}' \
      | { if [[ "$mode" == "attention" ]]; then jq -c 'select(.needs_attention)'; else cat; fi; }
  done
}

cmd_inbox()          { list_cards attention; }
cmd_assigned_cards() { list_cards all; }

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

# Fizzy comments are rich text (HTML), not Markdown: sent as-is, lists, backticks
# and line breaks come out as literal text, and anything in <angle brackets> is
# swallowed as a tag. So take Markdown and convert it. pandoc if available, else
# a plain-text fallback (escaped, paragraphs and line breaks preserved).
md_to_html() {
  if command -v pandoc >/dev/null 2>&1; then
    pandoc -f gfm-gfm_auto_identifiers -t html --wrap=none
  else
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' \
      | awk 'BEGIN{p=0} /^$/{if(p){print "</p>"; p=0}; next} {if(!p){printf "<p>"; p=1} else printf "<br>\n"; printf "%s", $0} END{if(p) print "</p>"}'
  fi
}

cmd_comment() {
  # comment <number> <markdown|-> [--html]    ("-" reads the body from stdin)
  local number="${1:?card number required}" body="${2:?comment body required (or - for stdin)}" raw_html="${3:-}"
  [[ "$body" == "-" ]] && body=$(cat)
  [[ -n "$body" ]] || { echo "Empty comment body." >&2; exit 1; }
  if [[ "$raw_html" != "--html" ]]; then
    body=$(printf '%s\n' "$body" | md_to_html)
  fi
  local json
  json=$(jq -nc --arg b "$body" '{comment: {body: $b}}')
  api POST "/cards/${number}/comments" "$json" >/dev/null
  echo "Commented on card ${number}."
}

cmd_triage() {
  local number="${1:?card number required}" column="${2:?column id or name required}" id
  # Accept a column name as well as an id.
  id=$(api GET "/boards/$(board_id)/columns" | jq -r --arg c "$column" '[.[] | select(.id == $c or (.name | ascii_downcase) == ($c | ascii_downcase))][0].id // empty')
  [[ -n "$id" ]] || { echo "No column matching \"$column\". Run: fizzy.sh columns" >&2; exit 1; }
  api POST "/cards/${number}/triage" "$(jq -nc --arg c "$id" '{column_id: $c}')" >/dev/null
  echo "Moved card ${number} to column ${id}."
}

# Assignment is a toggle server-side, so check the current assignees first to make
# assign/unassign idempotent.
set_assignment() {
  local want="$1" number="${2:?card number required}" who="${3:?user id or name required}"
  local id assigned
  id=$(resolve_user "$who")
  assigned=$(api GET "/cards/${number}" | jq --arg u "$id" '[.assignees[].id] | index($u) != null')
  if [[ "$assigned" == "$want" ]]; then
    echo "Card ${number}: already $([[ "$want" == true ]] && echo assigned || echo unassigned) for ${who}."
    return
  fi
  api POST "/cards/${number}/assignments" "$(jq -nc --arg u "$id" '{assignee_id: $u}')" >/dev/null
  echo "Card ${number}: $([[ "$want" == true ]] && echo assigned || echo unassigned) ${who}."
}

cmd_assign()   { set_assignment true "$@"; }
cmd_unassign() { set_assignment false "$@"; }

cmd_close() {
  local number="${1:?card number required}"
  api POST "/cards/${number}/closure" >/dev/null
  echo "Closed card ${number}."
}

cmd_reopen() {
  local number="${1:?card number required}"
  api DELETE "/cards/${number}/closure" >/dev/null
  echo "Reopened card ${number}."
}

cmd_login_code() {
  # Local ONCE/Docker installs have no SMTP, so magic-link emails fail to send.
  # The code is still saved, so read the newest one straight from the container.
  # Doesn't need credentials (you run it before you have a token).
  command -v docker >/dev/null 2>&1 || { echo "docker is required." >&2; exit 1; }
  local container
  container=$(docker ps --filter name=once-app-fizzy --format '{{.Names}}' | head -1)
  [[ -n "$container" ]] || { echo "No running once-app-fizzy container found." >&2; exit 1; }
  docker exec "$container" bin/rails runner '
    ml = MagicLink.order(:created_at).last
    abort "No magic links yet. Request one in the browser first." unless ml
    puts "code:    #{ml.code}"
    puts "email:   #{ml.identity.email_address}"
    puts "purpose: #{ml.purpose}"
    puts "expires: #{ml.expires_at.utc}#{" (EXPIRED)" if ml.expires_at < Time.current}"
  ' 2>&1 | grep -vE '^[WI], \['
}

# Runs before ensure_config: no token exists yet when you need a login code.
if [[ "${1:-}" == "login-code" ]]; then
  cmd_login_code
  exit 0
fi

ensure_config

case "${1:-}" in
  whoami)           shift; cmd_whoami "$@" ;;
  users)            shift; cmd_users "$@" ;;
  board)            shift; cmd_board "$@" ;;
  columns)          shift; cmd_columns "$@" ;;
  inbox)            shift; cmd_inbox "$@" ;;
  assigned-cards)   shift; cmd_assigned_cards "$@" ;;
  card)             shift; cmd_card "$@" ;;
  comments)         shift; cmd_comments "$@" ;;
  comment)          shift; cmd_comment "$@" ;;
  triage)           shift; cmd_triage "$@" ;;
  assign)           shift; cmd_assign "$@" ;;
  unassign)         shift; cmd_unassign "$@" ;;
  close)            shift; cmd_close "$@" ;;
  reopen)           shift; cmd_reopen "$@" ;;
  *)
    cat >&2 <<EOF
Usage: fizzy.sh <command> [args]

  login-code                    Print the newest magic-link code from the local Docker container (no SMTP needed)
  whoami                        The agent's own user (id, name, role)
  users                         List users (id, name, role) — to find who to assign/hand off to
  board                         Show the watched board (resolved from FIZZY_BOARD_NAME)
  columns                       List columns on the board
  inbox                         Open cards assigned to the agent that need its attention
  assigned-cards                All open cards assigned to the agent, attention or not
  card <number>                 Full detail for a card
  comments <number>             List comments on a card
  comment <number> <md|->       Post a comment (Markdown, converted to HTML; "-" reads stdin; add --html for raw HTML)
  triage <number> <column>      Move a card into a column (id or name)
  assign <number> <user>        Assign a user (id or name); no-op if already assigned
  unassign <number> <user>      Unassign a user (id or name); no-op if not assigned
  close <number>                Close a card
  reopen <number>               Reopen a closed card
EOF
    exit 1
    ;;
esac
