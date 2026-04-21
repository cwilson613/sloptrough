# qrypt-tools — Claude Code Plugin

Engineering tools, development conventions, and workflow automation for the Qrypt platform team.

## Skills (10)

### Workflow
| Skill | Description |
|-------|-------------|
| **cleave** | Recursive task decomposition — splits complex directives into subtasks, executes in isolation, reunifies results |
| **distill** | Session handoff — creates portable summaries for bootstrapping fresh sessions (`/distill`) |
| **iterator** | Systematic debugging feedback loop — converges on root cause through disciplined observation (`/iterator`) |

### Development
| Skill | Description |
|-------|-------------|
| **rust** | Rust conventions: Cargo, clippy, rustfmt, error handling, async patterns, testing |
| **typescript** | TypeScript conventions: strict typing, async patterns, Node.js APIs, testing |
| **security** | Security checklist: input escaping, injection prevention, path traversal, process safety |

### Infrastructure
| Skill | Description |
|-------|-------------|
| **helm-operations** | Helm chart templating, values management, debugging, ArgoCD integration |
| **visualizer** | Mermaid diagrams — flowcharts, ER diagrams, sequence diagrams, with HTML rendering |

### Utilities
| Skill | Description |
|-------|-------------|
| **date-context** | Authoritative date context from system clock — eliminates AI date calculation errors |
| **identity** | Auth status across dev tools (git, GitHub, AWS, Azure, K8s, OCI, Cloudflare, GCP, npm) |

## Installation

### From GitHub (recommended)

Once this repo is pushed to a Qrypt GitHub org:

```bash
# In Claude Code, run:
/plugins install <org>/qrypt-tools
```

### Manual (local development)

1. Clone this repo
2. In Claude Code settings (`~/.claude/settings.json`), add the plugin path:

```json
{
  "enabledPlugins": {
    "qrypt-tools@local": true
  }
}
```

Or symlink into the Claude Code plugins directory:

```bash
mkdir -p ~/.claude/plugins/marketplaces/qrypt-plugins
ln -s /path/to/this/repo/.claude-plugin ~/.claude/plugins/marketplaces/qrypt-plugins/.claude-plugin
```

## Provenance

- **cleave, distill, iterator, visualizer, helm-operations, date-context, identity** — adapted from [recro/coe-agent](https://github.com/recro/coe-agent) (recro-tools v1.5.1)
- **rust, typescript, security** — ported from [styrene-lab/omegon-pi](https://github.com/styrene-lab/omegon-pi) skills

## Customization

Each skill is a directory under `.claude-plugin/claude/skills/<name>/` containing:
- `SKILL.md` — the skill definition (YAML frontmatter + markdown instructions)
- Optional scripts and templates

To add a new skill, create a new directory with a `SKILL.md` file. The `name` and `description` in the YAML frontmatter control how Claude Code discovers and triggers the skill.
