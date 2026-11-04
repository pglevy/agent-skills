---
name: export-workflows
description: >
  Export Kiro workflow runs (every subagent step session, including thinking, tool calls and
  results) for the current workspace to readable markdown. Use when the user asks where workflow
  or subagent session content is stored, or wants to read, review, archive or export workflow runs.
metadata:
  title: Export Workflow Runs
  prompt: "Export the workflow runs for this workspace"
  tags:
    - Ops
---

# Export Workflow Runs

Kiro stores each workflow step as its own session under `~/.kiro/sessions/<workspace-hash>/sess_<uuid>/messages.jsonl`.
`workflows/wf_<id>/sessions.json` maps each workflow node to its session. This skill converts all runs for a workspace to markdown.

## Steps

1. Run from the workspace root (or pass its path):
   `python3 ~/.kiro/skills/export-workflows/export_kiro_workflows.py [workspace-path] [out-dir] [--max-tool-chars N]`
2. Default output is `<workspace>/gitignore/kiro-workflow-export/` (the globally git-ignored `gitignore` folder). Only use another out-dir if the user asks, e.g. the Obsidian vault.
3. Output is one folder per run (`wf_<id>-<name>/`) with `INDEX.md` and one `NN-<node-path>.md` per step. Thinking is in collapsed `<details>` blocks; tool output is clipped to 2000 chars unless `--max-tool-chars` is raised.
4. Report the counts the script prints and point to the INDEX.md files. Do not paste transcripts into chat.
