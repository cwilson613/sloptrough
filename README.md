# sloptrough — Claude Code Plugin

Engineering tools, development conventions, and workflow automation for platform teams.

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
| **chronos** | Authoritative date context from system clock — eliminates AI date calculation errors |
| **identity** | Auth status across dev tools (git, GitHub, AWS, Azure, K8s, OCI, Cloudflare, GCP, npm) |

## Installation

### From GitHub

```bash
# In Claude Code, run:
/plugins install cwilson613/sloptrough
```

### Manual (local development)

1. Clone this repo
2. Symlink into the Claude Code plugins directory:

```bash
mkdir -p ~/.claude/plugins/marketplaces/sloptrough
ln -s /path/to/this/repo/.claude-plugin ~/.claude/plugins/marketplaces/sloptrough/.claude-plugin
```

### Statusline (optional)

Context fill bar with identity, git status, and model info:

```
● cwilson@host in myrepo ✓ | Opus 4.6 (1M context) | ▓▓▓▓░░░░░░░░░░░░░░░░ 20%
```

Symlink and configure:

```bash
ln -sf /path/to/this/repo/.claude-plugin/scripts/statusline.sh ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## Script Discovery

Skills that include scripts (`chronos`, `identity`) need their absolute paths resolved at runtime — plugin directories aren't on `PATH`. A `SessionStart` hook runs automatically and prints the resolved script paths into Claude's context, so Claude knows where to find them.

This is intentional: deterministic scripts > inline markdown commands. A script produces identical output every time, handles cross-platform differences in one place, and can be tested outside of Claude. Inline instructions get paraphrased, skipped, or hallucinated around.

## Provenance

- **cleave, distill, iterator, visualizer, helm-operations, chronos, identity** — adapted from [recro/coe-agent](https://github.com/recro/coe-agent) (recro-tools v1.5.1)
- **rust, typescript, security** — ported from [styrene-lab/omegon-pi](https://github.com/styrene-lab/omegon-pi) skills

## Customization

Each skill is a directory under `.claude-plugin/claude/skills/<name>/` containing:
- `SKILL.md` — the skill definition (YAML frontmatter + markdown instructions)
- Optional scripts and templates

To add a new skill, create a new directory with a `SKILL.md` file. The `name` and `description` in the YAML frontmatter control how Claude Code discovers and triggers the skill.
