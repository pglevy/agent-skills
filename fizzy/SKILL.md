---
name: fizzy
description: Work the user's Fizzy kanban board as an agent. Invoked as /fizzy (or "check the board", "check Fizzy", "work the queue", "see what's assigned to you"), it looks at the "Work" board for cards assigned to the Work Horse user, does the tasks, and reports back through comments, column moves, and reassignment. Also use when the user pastes a Fizzy card URL (containing /cards/<number>) and asks you to look at or handle it, or asks you to post an update, move a card to review/done, or hand a card back.
---

# Fizzy

The Fizzy board is the user's interface to you. They assign cards to the
**Work Horse** user instead of opening a chat and describing the task. You are
Work Horse: you pick up cards, do the work, and answer *on the card*, so the
user finds out through Fizzy's own notifications without you saying anything
in chat.

**Invoked with no arguments (`/fizzy`), run the board sweep and keep going
until it's done. Don't ask what to do.** If the user passes a card URL or
number, skip the listing and handle that card.

## Quick start

```sh
scripts/fizzy.sh inbox
```

- Empty output: nothing needs you. Say so in one line and stop. Don't invent
  work.
- Otherwise, each line is a card that needs you, then follow "The loop" below.

Credentials are in `~/.config/fizzy/credentials`; working context (where
projects live, conventions) is in `~/.config/fizzy/context.md`. If the script says it's
missing or has placeholders, stop and tell the user what's missing (see
Setup). Never print the token or put it in a comment, only refer to it by
name.

## Working context

You're meant to act like a colleague who already knows how the user works, not
someone who has to search the machine for every request. Before the first
card of a run, read `~/.config/fizzy/context.md` if it exists. It holds where
projects live, how to find one named in a card, what a "status update" means,
and the user's working conventions. Follow it. If it's missing, work without
it, and when a card names a project you can't locate in a couple of obvious
places, ask on the card instead of searching the whole machine.

When you learn something on a card that a new colleague would want to know
next time (a project's location, a convention, a preference the user states
in a comment), tell the user in your wrap-up and suggest adding it to the
context file. Don't edit that file yourself unless asked.

## The loop

### 1. Find the work

```sh
scripts/fizzy.sh inbox
```

`inbox` lists open cards on the board assigned to you where **the ball is in
your court**: nobody has commented yet, or the last comment is from someone
other than you. A card where your own comment is last stays out of the inbox
until the user replies, which is how you avoid redoing finished work and how a
reply from the user brings a card back. (`assigned-cards` lists everything
assigned to you, whether or not it needs attention, if you want the full
picture.)

Cards sitting in "Maybe?"/"Not Now" (no column), and closed cards, are
skipped on purpose.

Single card: take the number from the end of the URL (`.../cards/42` → `42`).

### 2. Read each card fully

```sh
scripts/fizzy.sh card <number>
scripts/fizzy.sh comments <number>
```

Read the description, steps, and the whole comment thread. Later comments
often change what "done" means. Note the card's current column and who created
it (`creator`): that's who you report to.

### 3. Handle more than one card

One card: do it inline. Several: if your environment has a way to delegate
work in parallel — sub-agents, tasks, workflows, whatever your harness calls
it — use it, one delegate per card. Give each the card number, the path to
`scripts/fizzy.sh`, and the instructions from steps 4 and 5, and have each one
write back to its own card directly rather than reporting to you to relay.
If nothing like that is available, work the cards yourself one at a time
instead; don't force parallelism the environment doesn't support.

### 4. Do the work, then write back to the card

Do what the card describes, using your normal tools, in the current working
directory unless the card names a project or path (find it as the context file
describes). If the card needs a repo, file, or access you can't find, that's a
blocker: ask on the card, don't guess.

**Be careful with outward-facing and hard-to-undo actions** (sending messages,
pushing, deploying, deleting, spending money). Do them only if the card
clearly asks for them. Otherwise do the work up to that point and ask on the
card.

Then close the loop. Pick the outcome that's true:

**Done, ready for review.** Comment a short summary of what you did and
anything worth knowing (files changed, decisions, where the output is), move
the card to the review-type column, and make the creator the **only** assignee
(add them, then unassign yourself) so it lands in their queue and the card stays
clean:

```sh
scripts/fizzy.sh comment <number> "**Done:** <summary>"   # multi-line: use - and a heredoc, see below
scripts/fizzy.sh columns                      # find the review-like column
scripts/fizzy.sh triage <number> "<column name or id>"
scripts/fizzy.sh assign <number> "<creator name>"
scripts/fizzy.sh unassign <number> "Work Horse"
```

Don't assume a column is literally named "Review". Match by intent (a column
meaning "needs a human look": Review, QA, Done?, etc.). If nothing like that
exists, just comment and leave the card where it is.

**Blocked, or you have a question.** Comment exactly what's blocking you and
what you need. Leave the card in its column (don't move it to review, which
would misrepresent its state) and add the creator as an assignee so they get
pinged. Because your comment is now last, the card drops out of your inbox
until they reply.

**Not yours / out of scope / needs a human decision.** Comment why, then
reassign: `assign` the right person and `unassign` yourself
(`scripts/fizzy.sh unassign <number> "Work Horse"`).

**Fully finished and nothing to review.** Comment, then `close <number>` only
if the card or board conventions say finished work gets closed. When in
doubt, move to review instead; closing is the user's call.

Assignment in Fizzy is a list, not a single owner, so a card can have you and
the user both on it. `assign` and `unassign` are idempotent (they check first,
since the underlying API only toggles). Cards in Review are assigned to the
user only: unassign yourself when handing off for review. Since `inbox` only
lists cards assigned to you, the user reassigns Work Horse (or moves the card
back to a work column) when they want more done. For blocked/question
handoffs, stay assigned so a reply brings the card back to your inbox.

Keep comments short and concrete: what you did, what you need, nothing else.
No narration of your process.

**Project shorthand.** Cards name projects as `<host>/<project>`, e.g.
`github/agent-skills` or `gitlab/dotfiles`. That is shorthand for the local
checkout at `~/Documents/GitHub/<project>` or `~/Documents/GitLab/<project>`.
Resolve it there; don't ask where the project is. (Same convention as the
context file.)

**Include clickable links.** Whenever the work produces something that lives
at a URL, put the full link in the comment so Philip can click straight
through from the card instead of hunting for it: PR/MR links (open the PR/MR
with `gh pr create` / `glab mr create` when the card asks for one, or give the
"new MR" link if told not to open it), branch or commit links, issues you
opened, deployed pages, and the card's own URL when handing off. Link text
should say what it is (`MR !2`, not a bare hash). Skip links only when there
is genuinely nothing linkable, e.g. a pure answer or question.

**Writing comments.** Fizzy comments are rich text, so write the body in
Markdown and `comment` converts it to HTML for you. Pass multi-line bodies on
stdin with `-` rather than as a quoted argument; it avoids shell-quoting
problems with backticks and `$`:

```sh
scripts/fizzy.sh comment <number> - <<'EOF'
**Done:** renamed the three config files.

- `config/a.yml`: updated
- `config/b.yml`: updated

Needs a look: `b.yml` also has an old key I left alone.
EOF
```

What renders well: short paragraphs, `-` bullet lists, `**bold**` for a lead-in
label, backticks for commands, paths and placeholders (write `card <n>` inside
backticks, never bare, because bare `<angle brackets>` get eaten as HTML
tags), fenced code blocks, links, and simple tables. Lead with the outcome
(`**Done:**`, `**Blocked:**`, `**Question:**`), then details. Skip headings
and keep it scannable: it's read in a card thread, not a document. Use
`--html` as a third argument only if you need raw HTML.

### 5. Wrap up

After a sweep, give the user a short chat summary: each card picked up and its
outcome (done / blocked / handed off / skipped). The comments are the
authoritative record, but they asked you to check the board, so they
shouldn't have to reread every card.

### Leaving feedback as new cards

Don't assume Philip reads the terminal output after a run. If you have
feedback at the end of a sweep (context-file suggestions, tooling quirks,
follow-ups, bugs in the skill, ideas), file each as a new card instead of
only saying it in chat:

```sh
scripts/fizzy.sh create "Short title" - <<'EOF'
Details in Markdown.
EOF
```

- New cards land in "Maybe?" (no column), which is where Philip looks. Leave
  them there: don't triage them into a work column and don't assign yourself.
- One card per topic, titled so it makes sense at a glance.
- Examples: "the web-tools repo is checked out at `~/Documents/GitHub/tools`
  (folder name differs from repo name)", or "`invoke_sub_agent` needs a
  `prompt` even for `semantic_reviewer`; use the dedicated tool".
- Still give the short chat summary; the cards are the durable record.

## Commands

| Command | What it does |
| --- | --- |
| `inbox` | Open assigned cards that need your attention |
| `assigned-cards` | All open assigned cards |
| `card <n>` / `comments <n>` | Read a card / its thread |
| `comment <n> <markdown or ->` | Post a comment (Markdown; `-` reads stdin) |
| `columns` | List the board's columns |
| `create <title> [markdown or -]` | New card on the board (lands in Maybe?), for feedback/issues |
| `triage <n> <column>` | Move a card (column name or id) |
| `users` | List users, to find who to assign to |
| `assign <n> <user>` / `unassign <n> <user>` | Add/remove an assignee (name or id) |
| `close <n>` / `reopen <n>` | Close / reopen a card |
| `whoami` / `board` | Confirm which user and board you're acting as |
| `login-code` | Local install only: print the newest sign-in code (no credentials needed) |

## Setup (one-time, per machine)

Credentials live in `~/.config/fizzy/credentials`, a shell-sourceable file
that `scripts/fizzy.sh` reads (created as a template on first run if missing):

```sh
FIZZY_BASE_URL="http://fizzy.localhost"   # self-hosted install, or https://fizzy.do
FIZZY_ACCOUNT_SLUG="/1"                   # includes the leading slash, from GET /my/identity
FIZZY_TOKEN="..."                         # Work Horse's own token, with write permission
FIZZY_BOARD_NAME="Work"                   # the one board this skill watches
FIZZY_BOARD_ID=""                         # optional: overrides FIZZY_BOARD_NAME
```

Your user id and the board id are looked up from the token and the board name
on each run, so there's nothing else to keep in sync. The `Work Horse` user
needs access to the board: make the board all-access when you create it, or
add Work Horse to it under the board's access settings. The script says so if
it can't see the board.

The token must belong to Work Horse's own identity, not the user's. Tokens act
as the identity they belong to, so reusing yours would make your comments and
moves show up under your name.

### Local install (Docker / ONCE at `fizzy.localhost`)

A local install has no SMTP server, so magic-link emails never arrive (the
mail job logs `Connection refused ... localhost port 25`). The code is still
saved, so read it from the container:

```sh
scripts/fizzy.sh login-code
```

Request a sign-in in the browser first, then run this and type the 6-character
code into the form. Codes expire after about 15 minutes; if it says EXPIRED,
request a new one. It finds the container by name (`once-app-fizzy*`) since
the suffix changes between installs. By hand it's:

```sh
docker exec <container> bin/rails runner 'puts MagicLink.order(:created_at).last.code' 2>&1 | tail -1
```

Passkeys are the other sign-in option, but they didn't work with a work
YubiKey, so don't count on them.

### Creating the Work Horse user (local install)

A local install can't email an invite, so create the user from the Rails
console in the container. Run this once; it prints nothing secret and writes
the token to a file for you to move into the credentials file:

```sh
C=$(docker ps --filter name=once-app-fizzy --format '{{.Names}}' | head -1)
docker exec $C bin/rails runner '
account  = Account.first
identity = Identity.find_or_create_by!(email_address: "workhorse@fizzy.localhost")
identity.join(account, name: "Work Horse", role: :member, verified_at: Time.current)
tok = identity.access_tokens.create!(description: "Work Horse agent", permission: :write,
        oauth_client: Oauth::Client.personal_access_issuer)
File.write("/tmp/wh_token", tok.raw_token)
puts "slug: #{account.slug}"
'
docker exec $C cat /tmp/wh_token; docker exec $C rm /tmp/wh_token
```

`workhorse@fizzy.localhost` can't receive mail, which is fine: the token is
what the agent uses, and `login-code` covers signing in as it in a browser if
you ever need to. On a hosted install, invite a separate email address from
the account's people settings, sign in as it, and create a personal access
token from its profile/API settings (write permission).

If you recreate the container or wipe its data, rerun this and update
`FIZZY_TOKEN`.

## Gotchas worth knowing before you call the API directly

- Cards, comments, and triage are addressed by the card's short `number` (the
  trailing integer in its URL), not its long id. Columns, boards, and users
  use long ids everywhere.
- The assignment endpoint (`POST .../assignments`) toggles: it adds the user
  if absent and removes them if present, and there's no "set assignees" call.
  Use `assign`/`unassign`, which check first.
- The plain `GET /cards` list doesn't reliably include `closed` or `column`,
  so `inbox` fetches full detail per candidate card to decide what's open.
- A new board has no columns until someone adds them, and cards with no
  column are in triage ("Maybe?"). The sweep skips those, so if `inbox`
  stays empty but the user says they assigned something, check that the card
  has been moved into a column.
- See `references/api-reference.md` for the condensed endpoint list, and the
  upstream docs at https://github.com/basecamp/fizzy/blob/main/docs/api/ for
  anything beyond it (tags, steps, reactions, etc.).
