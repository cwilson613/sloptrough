---
name: chronos
description: Authoritative date context from system clock. Use before any date calculations, weekly reporting, or relative date references to eliminate AI calculation errors.
---

# Chronos — System Clock Date Context

Eliminates AI date calculation errors by providing authoritative date context from the system.

## Problem

LLMs frequently make errors when calculating:
- Day of week from a date
- Week boundaries (Monday-Friday)
- Relative dates ("last Tuesday", "this Friday")
- Year boundaries (especially Dec/Jan)

## Solution

Run the `chronos` script (path provided at session start) to get authoritative date information. **Never calculate dates manually.**

## Usage

```bash
# The absolute path to chronos.sh is printed at session start.
# Look for "chronos:" in the session-start hook output and use that path.
/path/to/chronos.sh
```

### Output Format

```
DATE_CONTEXT:
  TODAY: 2025-01-25 (Saturday)
  CURR_WEEK_START: 2025-01-20 (Monday)
  CURR_WEEK_END: 2025-01-24 (Friday)
  CURR_WEEK_RANGE: Jan 20 - Jan 24, 2025
  PREV_WEEK_START: 2025-01-13 (Monday)
  PREV_WEEK_END: 2025-01-17 (Friday)
  PREV_WEEK_RANGE: Jan 13 - Jan 17, 2025
```

## When to Use

Invoke this skill before any operation involving:
- Weekly reporting or logging
- Scheduling references ("this week", "last week")
- Date-stamped entries
- Any relative date calculations

## Why a Script

Inline markdown instructions ("run `date +%Y-%m-%d`") are fragile — Claude may paraphrase, skip steps, or recombine commands incorrectly. A deterministic script:
- Produces identical output every time
- Handles cross-platform differences (BSD vs GNU date) in one place
- Is testable outside of Claude
- Can't be "hallucinated around"

## Platform Support

Cross-platform: macOS (BSD date) and Linux (GNU date).

## Key Principle

**External source of truth > internal calculation.**

The system clock is authoritative. Use it.
