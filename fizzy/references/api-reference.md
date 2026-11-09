# Fizzy API reference (condensed)

Full docs: https://github.com/basecamp/fizzy/blob/main/docs/api/

All requests: `Authorization: Bearer <token>`, `Accept: application/json`.
Base path for account-scoped endpoints: `<FIZZY_BASE_URL><FIZZY_ACCOUNT_SLUG>/...`
(the slug already includes its leading slash, e.g. `/0000000`).

## Identity / users

- `GET /my/identity` — accounts you have access to, with your user id/slug per
  account. Use once during setup to find `FIZZY_ACCOUNT_SLUG`.
- `GET /:account_slug/users` — list active users in the account (includes a
  `system` user; ignore it). Use to resolve a name to a user id for
  assigning.
- The token's own user in an account is `GET /my/identity` →
  `accounts[].user.id` (the account is matched by `slug`).

## Cards

- `GET /:account_slug/cards?board_ids[]=X&assignee_ids[]=Y` — list cards on a
  board assigned to a user. Does not reliably expose `closed`/`column`, so
  treat this as a candidate list and fetch detail on each.
- `GET /:account_slug/cards/:number` — full card detail: `title`,
  `description`, `description_html`, `tags`, `closed`, `column` (absent if the
  card is in Maybe?/Not Now/Done), `assignees`, `steps`, `comments_url`.
- `POST /:account_slug/boards/:board_id/cards` body
  `{"card": {"title": "...", "description": "<html>"}}` — create. New cards
  have no column (Maybe?).
- `POST /:account_slug/cards/:number/triage` body `{"column_id": "..."}` —
  move into a column.
- `DELETE /:account_slug/cards/:number/triage` — send back to triage
  (Maybe?/unsorted).
- `POST /:account_slug/cards/:number/assignments` body
  `{"assignee_id": "..."}` — **toggles** that user on/off the card's
  assignee list. 204 on success, no body.
- `POST /:account_slug/cards/:number/closure` / `DELETE .../closure` — close /
  reopen.

## Comments

- `GET /:account_slug/cards/:number/comments` — chronological (oldest first).
  Each has `body.plain_text` and `body.html`.
- `POST /:account_slug/cards/:number/comments` body `{"comment": {"body":
  "..."}}` — create. 201 Created, `Location` header points to it.

## Columns

- `GET /:account_slug/boards/:board_id/columns` — list columns with `id`,
  `name`, `color`, sorted by board position. Use to resolve a column name to
  an id before calling `triage`.

## Boards

- `GET /:account_slug/boards` — list boards you can access (useful if you
  ever need to confirm `FIZZY_BOARD_ID` is still right).

## Error shapes

- `401` — bad/missing token.
- `403` — token lacks permission (e.g. read-only token trying to comment).
- `404` — wrong account slug, board id, or card number.
- `422` — validation error, body has field-keyed messages.
