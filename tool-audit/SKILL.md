---
name: tool-audit
description: >
  Audit the current machine and workspace for recommended CLI tools and MCP servers.
  Produces a status report with what's installed, what's missing, and how to fix gaps.
  Use this skill when a designer says "check my tools", "am I set up right",
  "what MCP servers should I have", "audit my config", or "what tools am I missing".
metadata:
  title: Tool Audit
  prompt: "Audit my tool setup: "
  tags:
    - Ops
  human-reviewer: Philip Levy
  last-reviewed: 2026-06-04
---

# Tool Audit

Audit the current machine and workspace for recommended CLI tools and MCP server configurations. Produce a clear status report and actionable next steps.

## Inputs

None — the skill auto-detects installed tools and reads existing configuration files.

## Communication Style

- Report findings in a clear table or checklist format
- Use ✅ for installed/configured, ⚠️ for outdated or misconfigured, ❌ for missing
- Explain *why* each tool is recommended (one sentence)
- Provide install commands for anything missing
- Don't overwhelm — group by priority (required → recommended → optional)

## Instructions

### Step 1 — Check CLI tools

Run diagnostic commands to assess which recommended CLI tools are installed:

```bash
echo "=== CLI Tool Audit ==="
echo ""

echo "--- Required ---"
echo -n "brew: "; which brew && brew --version | head -1 || echo "NOT FOUND"
echo -n "git: "; which git && git --version || echo "NOT FOUND"
echo -n "node: "; which node && node --version || echo "NOT FOUND"
echo -n "pnpm: "; which pnpm && pnpm --version || echo "NOT FOUND"

echo ""
echo "--- Recommended ---"
echo -n "gh (GitHub CLI): "; which gh && gh --version | head -1 || echo "NOT FOUND"
echo -n "glab (GitLab CLI): "; which glab && glab version || echo "NOT FOUND"

echo ""
echo "--- Optional ---"
echo -n "jq: "; which jq && jq --version || echo "NOT FOUND"
```

Present findings in a table:

| Tool | Status | Purpose |
|------|--------|---------|
| `brew` | ✅/❌ | Package manager — installs everything else |
| `git` | ✅/❌ | Version control |
| `node` | ✅/❌ | JavaScript runtime (v20+ expected) |
| `pnpm` | ✅/❌ | Package manager for projects |
| `gh` | ✅/❌ | GitHub CLI — preferred over GitHub MCP for repo operations |
| `glab` | ✅/❌ | GitLab CLI — preferred over GitLab MCP for repo operations |
| `jq` | ✅/❌ | JSON processor — useful for inspecting configs |

### Step 2 — Check global Kiro MCP configuration

Read the user-level MCP config:

```bash
echo "=== Global MCP Config (~/.kiro/settings/mcp.json) ==="
if [ -f ~/.kiro/settings/mcp.json ]; then
  cat ~/.kiro/settings/mcp.json
else
  echo "No global MCP config found"
fi
```

**Global MCP guidance:**
- Global configs apply to every workspace. Only put servers here if you want them *everywhere*.
- Jira MCP is recommended globally if you use Jira across multiple projects (see recommended config below).
- Before enabling, ask the user: "Jira MCP adds project context to every workspace. This uses context window space even in sessions where you don't need Jira. Want it enabled globally, or would you prefer to add it per-workspace?"
- If they're unsure, suggest starting with it **disabled** globally (present but `"disabled": true`) so it's easy to flip on when needed without re-configuring.

**What to check:**
- If Jira MCP is present: is it enabled or disabled? Remind user of context window tradeoff.
- If Jira MCP is missing: offer to add it (disabled by default).

### Step 3 — Check workspace MCP configuration

Read the workspace-level MCP config:

```bash
echo "=== Workspace MCP Config (.kiro/settings/mcp.json) ==="
if [ -f .kiro/settings/mcp.json ]; then
  cat .kiro/settings/mcp.json
else
  echo "No workspace MCP config found"
fi
```

Compare against the recommended workspace MCP setup for prototyping projects (sailwind-starter pattern):

| Server | Expected | Purpose |
|--------|----------|---------|
| `chrome-devtools` | Enabled | Inspect and debug pages in Chrome from the agent |
| `playwright` | Disabled (available) | Automated browser testing when needed |

### Step 4 — Check registry configuration

```bash
echo "=== Registry Configuration ==="
echo -n "Workspace .npmrc: "
if [ -f .npmrc ]; then
  cat .npmrc
else
  echo "Not found"
fi
echo ""
echo -n "User .npmrc: "
if [ -f ~/.npmrc ]; then
  cat ~/.npmrc
else
  echo "Not found"
fi
```

**Registry guidance:**
- Our machines use an internal registry by default. Projects like sailwind-starter include a workspace `.npmrc` that pins `registry=https://registry.npmjs.org/` — this is what makes MCP servers work out of the box.
- If MCP servers fail with 404 or auth errors, check that `.npmrc` is still present and contains the correct registry. Someone may have accidentally deleted or overwritten it.
- As a belt-and-suspenders approach, the recommended MCP configs below also include `--registry=https://registry.npmjs.org` in their `npx` args. This way, even if `.npmrc` is missing, MCP servers will still resolve packages correctly.

### Step 5 — Produce the report

Summarize findings in three sections:

**1. Required actions** (blocking issues):
- Missing required CLI tools
- Registry misconfiguration that would prevent MCP servers from starting

**2. Recommended actions** (improve workflow):
- Missing recommended CLI tools
- MCP servers that should be added for the current workspace type

**3. Optional enhancements:**
- Nice-to-have tools
- Configuration tweaks for better ergonomics

For each action, provide the exact install or config command.

### Step 6 — Offer to fix

Ask the user if they'd like help with any of the identified gaps:
- "Want me to install the missing tools?"
- "Want me to add the recommended MCP config to this workspace?"

Only proceed with changes after confirmation.

## Install Commands Reference

### CLI Tools

```bash
# GitHub CLI
brew install gh

# GitLab CLI
brew install glab

# jq (JSON processor)
brew install jq
```

### Why CLI over MCP for Git hosting

For GitHub and GitLab operations (creating PRs/MRs, checking CI status, managing issues):
- **CLI tools (`gh`, `glab`) are preferred** because they're faster, work offline for local operations, integrate with shell scripts, and don't require a running MCP server.
- MCP servers for these platforms add overhead and another auth surface without clear benefit when the CLI already works well with Kiro's shell tool.
- The agent can run `gh pr create` or `glab mr create` directly — no MCP indirection needed.

## Recommended MCP Configuration

### Global config (~/.kiro/settings/mcp.json)

Jira MCP is the only recommended global server. It provides ticket context, sprint boards, and issue management across all workspaces.

```json
{
  "mcpServers": {
    "jira": {
      "command": "npx",
      "args": [
        "--registry=https://registry.npmjs.org",
        "-y",
        "mcp-remote",
        "https://mcp.atlassian.com/v1/sse"
      ],
      "timeout": 120000,
      "connectionTimeout": 30000,
      "disabled": true,
      "autoApprove": []
    }
  }
}
```

**Notes:**
- Starts **disabled** by default. Enable when you want Jira context available in your sessions.
- Uses Atlassian's hosted MCP endpoint — no local server to manage.
- `autoApprove` is empty intentionally — Jira operations (creating/updating tickets) should require explicit approval.
- **Context window impact:** When enabled, the Jira MCP server's tool definitions consume context space in every session. If you're working on something unrelated to Jira, consider keeping it disabled to preserve context for your actual task.

### Workspace config for prototyping projects

This is the recommended `.kiro/settings/mcp.json` for sailwind-starter and similar prototyping workspaces:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "--registry=https://registry.npmjs.org",
        "-y",
        "chrome-devtools-mcp@latest",
        "--no-usage-statistics"
      ],
      "timeout": 120000,
      "connectionTimeout": 30000,
      "disabled": false,
      "autoApprove": ["*"]
    },
    "playwright": {
      "command": "npx",
      "args": [
        "--registry=https://registry.npmjs.org",
        "-y",
        "@playwright/mcp@latest",
        "--browser",
        "chromium",
        "--headless"
      ],
      "timeout": 120000,
      "connectionTimeout": 30000,
      "disabled": true,
      "autoApprove": ["*"]
    }
  }
}
```

**Notes:**
- `--registry=https://registry.npmjs.org` ensures packages resolve from the public registry even on machines configured with an internal registry.
- `playwright` is disabled by default — enable it when you need automated browser interaction.
- `autoApprove: ["*"]` is appropriate for prototyping workspaces where speed matters more than per-tool approval.

## Troubleshooting

### MCP server fails to start with 404 or auth errors
The machine's default registry can't find the package. Check:
1. Is `.npmrc` present in the workspace with `registry=https://registry.npmjs.org/`? If someone deleted it, recreate it.
2. Do the MCP `npx` args include `--registry=https://registry.npmjs.org`? The recommended configs above include this as a fallback.
3. Try running the command manually: `npx --registry=https://registry.npmjs.org -y chrome-devtools-mcp@latest --no-usage-statistics`

### Jira MCP not connecting
- Run `npx --registry=https://registry.npmjs.org -y mcp-remote https://mcp.atlassian.com/v1/sse` manually to check auth flow.
- The first connection requires browser-based OAuth. Make sure you have a browser available.
- If behind a corporate proxy, the SSE connection may be blocked — check with your network team.

### `gh` or `glab` not authenticated
Run `gh auth login` or `glab auth login` to set up credentials. The CLI will walk you through the flow.

**Note for self-hosted GitLab (e.g., `gitlab.appian-stratus.com`):** The default OAuth browser flow may fail with a `client_id` error. Use token-based auth instead:
```bash
glab auth login --hostname gitlab.appian-stratus.com --token <your-token>
```
Create a personal access token at `https://gitlab.appian-stratus.com/-/user_settings/personal_access_tokens` with `api` and `write_repository` scopes.

### MCP server listed but tools don't appear
Check the MCP Servers panel in Kiro. If the server shows an error, try:
1. Verify the command runs manually in your terminal
2. Check `connectionTimeout` — increase if on a slow network
3. Restart the server from the MCP panel

