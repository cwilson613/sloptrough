#!/bin/bash
# session-start.sh — expose plugin script paths to Claude's context
#
# Why this exists:
# Claude Code skills are markdown instructions that Claude reads. When a
# SKILL.md says "run chronos.sh", Claude needs the *absolute path* — bare
# names won't resolve because plugin dirs aren't on PATH.
#
# This hook runs at session start and prints the resolved paths to stdout,
# which lands in Claude's conversation context. The SKILL.md files reference
# these paths by the labels printed here.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="${PLUGIN_ROOT}/claude/skills"

echo "sloptrough v0.1.0 — scripts available:"

for script in "${SKILLS_DIR}"/*//*.sh; do
  [ -f "$script" ] || continue
  name="$(basename "$script" .sh)"
  echo "  ${name}: ${script}"
done
