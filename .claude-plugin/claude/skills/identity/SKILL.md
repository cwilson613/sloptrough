---
name: identity
description: Check login and authentication status across dev tools. Use when user asks "who am I logged in as", "what is my login status", "check my identity", or before commits, PRs, pushes, or any operation that records attribution.
---

# Identity Skill

Check authentication status and identity across development tools. Answers questions like "who am I logged in as?" and "what is my login status?" by running `identity.sh all`.

## Core Principle

**The human authors their work. AI tooling is an implementation detail, not a collaborator.**

Never include AI attribution in commits, PRs, code, or documentation. Verify identity before operations that publish, push, or persist under a name.

## Usage

Run the `identity` script (path provided at session start) with the desired domains. The absolute path to `identity.sh` is printed by the session-start hook — look for "identity:" in that output.

```bash
# Default: check git and GitHub
/path/to/identity.sh

# Check specific domains
/path/to/identity.sh git
/path/to/identity.sh docker aws

# Check all domains
/path/to/identity.sh all

# Sync git config from GitHub (sets user.name, user.email, credential helper)
/path/to/identity.sh sync
```

### Output Example

```
IDENTITY CHECK

Git
  ✓ Commits as: Chris Wilson <chris@example.com>

GitHub (gh)
  ✓ Authenticated as: cwilson
  Scopes: repo, read:org, write:packages
```

## Domains

| Domain | What It Checks |
|--------|----------------|
| `git` | `user.name` and `user.email` config |
| `gh` | GitHub CLI auth status and username |
| `oci` | OCI registry auth via podman (ghcr.io, docker.io) |
| `ecr` | AWS ECR registry auth (requires valid AWS session) |
| `k8s` | Kubernetes context, cluster, user, namespace |
| `aws` | STS caller identity (account, ARN) |
| `cloudflare` / `cf` | cloudflared tunnel auth status |
| `gcp` | Active account and project |
| `azure` | Current user and subscription |
| `npm` | npm whoami |

## When to Invoke

**User asks about login status:**
When the user asks "who am I logged in as?", "what's my identity?", "check my login status", or similar:
```bash
identity.sh all
```
Show the full output to the user.

**Before operations that record attribution:**
- Creating commits
- Pushing to remote
- Opening PRs
- Publishing packages
- Pushing container images
- Creating cloud resources

## Sync Command

The `sync` command derives git identity from GitHub:

1. Fetches your name and email from GitHub API
2. Falls back to noreply email if public email not set
3. Sets `git config --global user.name` and `user.email`
4. Configures `gh` as git credential helper

## Per-Repo Git Identity

For repos requiring different git identity:
```bash
cd /path/to/repo
git config --local user.email "you@example.com"
git config --local user.name "Your Name"
```

Local config overrides global. Check with `git config user.email` (shows effective value).

## Common Fixes

| Problem | Fix |
|---------|-----|
| Git not configured | `identity.sh sync` |
| Wrong git email | `git config user.email correct@email.com` |
| gh not authenticated | `gh auth login` |
| OCI push denied | `gh auth refresh -s write:packages` then re-login podman |
| Wrong AWS account | `export AWS_PROFILE=correct-profile` |
| Azure not authenticated | `az login` |

## Philosophy

Attribution persists. Git history, PR authorship, and published packages record who created them. Verify before these operations that:

1. You're operating as the **human's** identity
2. The identity shown is the one intended for this context
