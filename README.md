# Skills

My collection of borrowed and homegrown agent skills

- **[create-mcp-app](./create-mcp-app):** Provides comprehensive guidance for building MCP Apps with interactive UIs (Source: [modelcontextprotocol/ext-apps](https://github.com/modelcontextprotocol/ext-apps/tree/main/plugins/mcp-apps/skills/create-mcp-app))
- **[frontend-design](./frontend-design):** Create distinctive, production-grade frontend interfaces with high design quality (Source: [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design))
- **[higher-ed-fred-analysis](./higher-ed-fred-analysis):** Experiment to create sophisticated economic data analyses and visualizations for higher education stakeholders using FRED (Federal Reserve Economic Data)
- **[migrate-to-gitlab](./migrate-to-gitlab):** Migrate an existing local git repository to a GitLab instance by creating a new remote repo and updating the origin (Source: gitlab.appian-stratus.com/docs/ux-manual)
- **[quick-mockup](./quick-mockup):** Generate UI mockups as standalone HTML pages using the Sailwind design token system (Source: gitlab.appian-stratus.com/docs/ux-manual)
- **[skill-creator](./skill-creator):** Guide for creating effective skills (Source: [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator))
- **[spec-driven-dev](./spec-driven-dev):** Guide for spec-based agent-driven development similar to Kiro, but for use with other agents
- **[style-audit](./style-audit):** Analyze a frontend codebase for design token discrepancies against Sailwind tokens, generate a TPS report, apply fixes, and optionally open a merge request (Source: gitlab.appian-stratus.com/docs/ux-manual)
- **[tool-audit](./tool-audit):** Audit the current machine and workspace for recommended CLI tools and MCP server configurations (Source: gitlab.appian-stratus.com/docs/ux-manual)
- **[usability-testing](./usability-testing):** Guide designers through prepping, running, and synthesizing usability tests (Source: gitlab.appian-stratus.com/docs/ux-manual)
- **[ux-content-standards](./ux-content-standards):** Apply UX content standards when writing or reviewing UI copy in mockups and prototypes (Source: gitlab.appian-stratus.com/docs/ux-manual)
- **[vignette](./vignette):** Create animated product vignettes — short, cinematic HTML demos that showcase a product feature or workflow (Source: gitlab.appian-stratus.com/docs/ux-manual)

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
