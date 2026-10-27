---
name: fizzy-board
description: Check a Fizzy (fizzy.do) kanban board for cards assigned to the "Kiro" user, work through them, and report back via comments and column moves. Use whenever the user says things like "check the board", "check Fizzy", "see what's assigned to you", "look at my cards", "work the queue", or pastes a Fizzy card URL (e.g. containing /cards/<number>) and asks you to look at or handle it. Also use when asked to post a status update, update, or comment back to a Fizzy card, or to move a card to review/done.
---

# Fizzy Board

Fizzy is a kanban tool. The user manages their own work there and has added a
"Kiro" user to the board so they can assign cards directly to the agent instead
of opening a chat and describing the task by hand. This skill covers two entry
points:

1. **Board sweep** — "check the board" / "what's assigned to me" — list every
   open card assigned to Kiro and work through them.
2. **Single card** — the user pastes a card URL and asks you to act on it
   directly. Skip the listing step and go straight to fetching that card.

Both entry points converge on the same loop: read the card, do the work (or
figure out it's blocked), then write back to Fizzy so the user finds out
without you having to say anything in chat.

## Setup (one-time, per machine)

Credentials live in `~/.config/fizzy/credentials`, a shell-sourceable file
that `scripts/fizzy.sh` reads. Check it before anything else — if it doesn't
exist or still has placeholder values, stop and tell the user what's missing
rather than guessing a base URL or token.

```sh
FIZZY_BASE_URL="https://fizzy.example.com"   # self-hosted install or https://fizzy.do
FIZZY_ACCOUNT_SLUG="/0000000"                # includes the leading slash, from GET /my/identity
FIZZY_TOKEN="put-personal-access-token-here" # needs write permission to comment/triage/assign
FIZZY_BOARD_ID=""                            # the one board this skill watches
FIZZY_KIRO_USER_ID=""                        # resolved once via `fizzy.sh whoami-kiro`, cached here
```

A template gets created automatically by `scripts/fizzy.sh` the first time it
runs if the file is missing. Never print the token back to the user or into
logs — refer to it by name only.

## The loop

### 1. Find the work

Board sweep:

```sh
scripts/fizzy.sh assigned-cards
```

This lists open cards on the configured board assigned to the Kiro user,
already filtered down to ones that are actually actionable (not closed, not
in Maybe?/Not Now). If it's empty, say so and stop — don't invent work.

Single card: extract the number from the end of the pasted URL
(`.../cards/42` → `42`) and skip straight to step 2 with that number.

### 2. Read each card

```sh
scripts/fizzy.sh card <number>
scripts/fizzy.sh comments <number>
```

Read the description, any checklist steps, and the full comment thread —
earlier comments often contain clarifications or back-and-forth that change
what "done" means. Note the card's current column name; you'll need it in
step 4 to judge whether a move makes sense.

### 3. Decide how to handle multiple cards

One card: just do it inline in this session.

More than one: spin off one sub-agent per card in parallel rather than
working through them serially. Each sub-agent needs the card number, the
account slug, and a pointer to this skill's `scripts/fizzy.sh` so it can read
and write back independently. Give each one the same step 4/5 instructions
below — they should finish their own card's comment/column update themselves
rather than reporting results back to you to relay, since you may have
already moved on to other things by the time they finish.

### 4. Do the work, then report back

Do whatever the card actually describes — this is a normal task, use your
usual tools for it. The Fizzy-specific part is purely how you close the loop:

**Finished, ready for the user to look at:** post a comment summarizing what
you did (and anything worth knowing, like files changed or decisions made),
then move the card into a review-type column if the board has one:

```sh
scripts/fizzy.sh comment <number> "Done: <summary>"
scripts/fizzy.sh columns                      # find the review column's id
scripts/fizzy.sh triage <number> <column_id>
```

Don't assume the column is literally named "Review" — look at what's actually
on the board (`scripts/fizzy.sh columns`) and match by intent (a column that
represents "this needs a human look," often named Review, QA, Done?, etc). If
nothing like that exists, just comment and leave the card where it is — the
user will see the comment via Fizzy's own notifications, which is the signal
they asked for.

**Blocked or have a question:** post a comment describing exactly what's
blocking you and what you need from the user. Leave the card in its current
column (typically still "In Progress") rather than moving it — moving it to
review would misrepresent the state, and the user said they'll rely on the
comment notification to know something needs attention.

**Either way, decide assignment on a per-card basis, not reflexively.**
Assignment in Fizzy is a toggle on a list, not a single owner field — a card
can have both the Kiro user and the user assigned at once. Adding the user
as a second assignee (`scripts/fizzy.sh assign <number> <user_id>`) is a
reasonable way to signal "this needs you" on top of a column move or when the
board doesn't have a review column to lean on. Removing Kiro's own
assignment isn't usually necessary — the comment and column are what
actually carry the signal — but use judgment if the user's board conventions
suggest otherwise (e.g. if they mentioned unassigned-from-Kiro means "closed
the loop").

### 5. Wrap up

If you ran a board sweep across multiple cards, give the user a short summary
in chat of what got picked up and its outcome (done/blocked/skipped) — they
asked you to check the board so they shouldn't have to go reread every card
to find out what happened, even though the authoritative record now lives in
the comments.

## Gotchas worth knowing before you call the API directly

- Cards, comments, and triage are addressed by the card's short `number`
  (the trailing integer in its URL), not its long id. Columns, boards, and
  users use long ids everywhere.
- The toggle-style assignment endpoint (`POST .../assignments`) adds the user
  if they're not already assigned and removes them if they are — there's no
  "set assignees" call. Always check `card.assignees` first if you need to
  know which way a toggle will go.
- The plain `GET /cards` list endpoint doesn't reliably include `closed` or
  `column` in every response shape, so `assigned-cards` fetches full detail
  per candidate card to decide what's actually open — don't trust the list
  response alone if you're scripting something new.
- See `references/api-reference.md` for the condensed endpoint list this
  skill relies on, and the full upstream docs at
  https://github.com/basecamp/fizzy/blob/main/docs/api/ for anything beyond
  what's covered here (tags, steps, reactions, etc.).
