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

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- `jq` on PATH (required by statusline and scripts)

## Installation

### Quick Start (fork + local install)

The intended workflow: fork this repo to your org, clone it, symlink it in. `git pull` updates the plugin instantly — no reinstall.

**1. Fork and clone**

```bash
# Fork on GitHub first, then:
git clone https://github.com/<your-org>/sloptrough ~/sloptrough
```

**2. Symlink into Claude Code plugins**

```bash
mkdir -p ~/.claude/plugins/marketplaces/sloptrough
ln -s ~/sloptrough/.claude-plugin ~/.claude/plugins/marketplaces/sloptrough/.claude-plugin
```

**3. Register the marketplace**

Add to `~/.claude/plugins/known_marketplaces.json`:

```json
{
  "sloptrough": {
    "source": {
      "source": "local",
      "path": "/Users/<you>/sloptrough"
    },
    "installLocation": "/Users/<you>/.claude/plugins/marketplaces/sloptrough",
    "lastUpdated": "2026-04-21T00:00:00.000Z"
  }
}
```

**4. Register the plugin**

Add to `~/.claude/plugins/installed_plugins.json` under `"plugins"`:

```json
{
  "sloptrough@sloptrough": [
    {
      "scope": "user",
      "installPath": "/Users/<you>/.claude/plugins/marketplaces/sloptrough",
      "version": "0.1.0",
      "installedAt": "2026-04-21T00:00:00.000Z",
      "lastUpdated": "2026-04-21T00:00:00.000Z"
    }
  ]
}
```

**5. Enable the plugin**

Add to `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "sloptrough@sloptrough": true
  }
}
```

**6. Restart Claude Code** — skills should appear in the `/` command menu.

### Statusline (optional)

Context fill bar with identity, git status, and model info:

```
● you@host in myrepo ✓ | Opus 4.6 (1M context) | ▓▓▓▓░░░░░░░░░░░░░░░░ 20%
```

Green <50%, yellow 50-75%, red >=75%.

```bash
ln -sf ~/sloptrough/.claude-plugin/scripts/statusline.sh ~/.claude/statusline.sh
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

### Verify

After restart, confirm the plugin loaded:

```bash
# Session-start hook should print script paths:
#   sloptrough v0.1.0 — scripts available:
#     chronos: /Users/<you>/.claude/plugins/marketplaces/sloptrough/.claude-plugin/claude/skills/chronos/chronos.sh
#     identity: /Users/<you>/.claude/plugins/marketplaces/sloptrough/.claude-plugin/claude/skills/identity/identity.sh

# Test skills are available:
/chronos
/identity
/distill
```

## Script Discovery

Skills that include scripts (`chronos`, `identity`) need their absolute paths resolved at runtime — plugin directories aren't on `PATH`. A `SessionStart` hook runs automatically and prints the resolved script paths into Claude's context, so Claude knows where to find them.

This is intentional: deterministic scripts > inline markdown commands. A script produces identical output every time, handles cross-platform differences in one place, and can be tested outside of Claude. Inline instructions get paraphrased, skipped, or hallucinated around.

## Updating

Because the plugin is symlinked from your local clone:

```bash
cd ~/sloptrough && git pull
```

That's it. Next Claude Code session picks up the changes automatically.

## Provenance

- **cleave, distill, iterator, visualizer, helm-operations, chronos, identity** — adapted from [recro/coe-agent](https://github.com/recro/coe-agent) (recro-tools v1.5.1)
- **rust, typescript, security** — ported from [styrene-lab/omegon-pi](https://github.com/styrene-lab/omegon-pi) skills

## Customization

Each skill is a directory under `.claude-plugin/claude/skills/<name>/` containing:
- `SKILL.md` — the skill definition (YAML frontmatter + markdown instructions)
- Optional scripts and templates

To add a new skill, create a new directory with a `SKILL.md` file. The `name` and `description` in the YAML frontmatter control how Claude Code discovers and triggers the skill.
