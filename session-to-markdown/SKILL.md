---
name: session-to-markdown
description: >
  Convert an exported Kiro chat session (a sess_<uuid> folder containing messages.jsonl and
  session.json) into a readable markdown transcript. Use when the user hands over a session
  folder or messages.jsonl and wants it as markdown to read, review, archive or share.
metadata:
  title: Session to Markdown
  prompt: "Convert this session export to readable markdown: <path>"
  tags:
    - Ops
---

# Session to Markdown

Turns a single Kiro session export into one markdown file: title and metadata header, user
messages, assistant replies (streamed chunks merged), and tool calls with their results in
collapsed `<details>` blocks. Kiro reasoning blocks are redacted in exports, so they are
skipped by default.

For all workflow runs of a workspace, use `export-workflows` instead.

## Steps

1. Run the script with the session folder (or its `messages.jsonl`):
   `python3 -I <skill-dir>/session_to_markdown.py <session-dir> [out.md] [--max-tool-chars N] [--no-tools] [--thinking]`
2. Default output is `<session-dir>.md` next to the input. If the input is an untrusted download, pass an explicit `out.md` outside that folder.
3. Tool output is clipped to 1500 chars; raise with `--max-tool-chars`. Use `--no-tools` for a conversation-only view.
4. Report the output path and a one-line summary (title, turn count). Do not paste the transcript into chat.

## Input format

`messages.jsonl` has one JSON object per line with a `payload` whose `type` is one of `user`,
`assistant` (`operationType` `Say` or `Reasoning`), `tool_call`, `tool_result`, or housekeeping
(`turn_start`, `usage_summary`, `session_metadata`, …) which is ignored.
