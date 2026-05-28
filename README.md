# Skills

My collection of borrowed and homegrown agent skills

- **[create-mcp-app](./create-mcp-app):** Provides comprehensive guidance for building MCP Apps with interactive UIs (Source: [Model Context Protocol](https://github.com/modelcontextprotocol/ext-apps/tree/main/plugins/mcp-apps/skills/create-mcp-app))
- **[frontend-design](./frontend-design):** Create distinctive, production-grade frontend interfaces with high design quality (Source: [Anthropic](https://github.com/anthropics/skills/tree/main/skills/frontend-design))
- **[higher-ed-fred-analysis](./higher-ed-fred-analysis):** Experiment to create sophisticated economic data analyses and visualizations for higher education stakeholders using FRED (Federal Reserve Economic Data)
- **[migrate-to-gitlab](./migrate-to-gitlab):** Migrate an existing local git repository to a GitLab instance by creating a new remote repo and updating the origin
- **[mint-cli](./mint-cli):** Guide for querying Sailwind design tokens using the Mint CLI
- **[pnpm-setup](./pnpm-setup):** Guide for installing and configuring pnpm, including migration from npm and troubleshooting common issues
- **[sailwind-mock](./sailwind-mock):** Generate UI mockups as standalone HTML pages using the Sailwind design token system
- **[skill-creator](./skill-creator):** Guide for creating effective skills (Source: [Anthropic](https://github.com/anthropics/skills/tree/main/skills/skill-creator))
- **[spec-driven-dev](./spec-driven-dev):** Guide for spec-based agent-driven development similar to Kiro, but for use with other agents
- **[token-policy-standard](./token-policy-standard):** Audit a frontend codebase for design token discrepancies against Sailwind tokens, generate a TPS report, apply fixes, and optionally open a merge request
- **[vignette](./vignette):** Create animated product vignettes — short, cinematic HTML demos that showcase a product feature or workflow

## Syncing Sourced Skills

Some skills are copied from upstream repos. To pull the latest versions:

```bash
# Sync all sourced skills
./sync-skills.sh

# Sync a single skill
./sync-skills.sh frontend-design
```

Sources are defined in `skills-sync.json`. To add a new sourced skill, add an entry:

```json
{
  "skill-name": {
    "host": "github",
    "repo": "owner/repo",
    "path": "path/to/skill/directory",
    "branch": "main"
  }
}
```

For internal GitLab repos, use `"host": "gitlab"` and add `"gitlabHost": "gitlab.example.com"`.

**Requirements:** `jq`, `gh` (for GitHub sources), `glab` (for GitLab sources)

## License

Apache License 2.0 unless otherwise indicated by individual skills