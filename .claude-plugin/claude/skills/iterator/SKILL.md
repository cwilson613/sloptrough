---
name: iterator
description: Systematic troubleshooting feedback loop. Use when debugging any issue - visual (screenshots), behavioral (logs/errors), or functional (test failures). Invoke with /iterator.
---

# Iterator - Troubleshooting Feedback Loop

A systematic approach to iterative debugging that converges on root cause through disciplined observation and intervention.

## Trigger

Use `/iterator` when:
- User provides evidence of a problem (screenshot, error message, log snippet, test failure)
- User says "reproduced", "still broken", "same error", "not working", or similar
- Continuing an active debugging cycle
- Any troubleshooting task that may require multiple attempts

## First Contact: Establish Context

On initial invocation, assess what's known and unknown:

| Question | If Unknown |
|----------|------------|
| **What is the symptom?** | Ask user to describe what they observed |
| **What is the expected behavior?** | Ask what should have happened |
| **Where are the logs/diagnostics?** | Search common locations, ask if not found |
| **Is this reproducible?** | Ask user to confirm they can trigger it again |
| **What changed recently?** | Check git status/log, ask user |

Only ask questions that can't be inferred from context. If user provided a screenshot with an error message, don't ask "what's the error?"

## Protocol

### Phase 1: Gather Evidence

Collect available diagnostic information:

**For visual issues (screenshots/UI):**
- Note exact error text, UI state, visual anomalies
- Identify the component/screen affected

**For behavioral issues (logs/errors):**
- Locate recent logs: `ls -lt` in common locations (`~/.{app}/logs/`, `./logs/`, `/tmp/`)
- Extract relevant timeframe: `tail -100`, grep for timestamps near incident
- Find stack traces, error codes, exception details

**For functional issues (test failures/incorrect output):**
- Run the failing test/command to capture current output
- Compare expected vs actual results
- Identify the specific assertion or check that fails

**For performance issues:**
- Capture timing data, resource usage
- Identify the slow path or bottleneck

### Phase 2: Analyze

1. **Trace the error path** - Follow from symptom back to source
2. **Identify the failure point** - Where exactly does it go wrong?
3. **Determine confidence level:**
   - **High confidence**: Clear stack trace pointing to specific code, obvious logic error
   - **Low confidence**: Intermittent, unclear error, multiple possible causes

### Phase 3: Decide

Every iteration MUST result in exactly ONE of:

| Outcome | When | Action |
|---------|------|--------|
| **FIX** | Root cause is clear (high confidence) | Implement the fix directly |
| **INSTRUMENT** | Root cause unclear (low confidence) | Add logging/debugging to catch it next run |
| **ISOLATE** | Multiple possible causes | Create minimal reproduction or bisect |

**Never** do more than one in the same iteration.
**Never** do none - always make forward progress.

### Phase 4: Execute

**If FIX:**
1. Implement the minimal fix for the identified issue
2. Verify syntax/compilation: `cargo check`, `npm run build`, `tsc --noEmit`, etc.
3. Run relevant tests if available
4. Summarize what was fixed and why

**If INSTRUMENT:**
1. Add targeted logging/debugging at suspected failure points
2. Capture:
   - Input values and state at failure point
   - Full exception details (including nested exceptions)
   - Timing/sequence for async or race conditions
   - Return values and intermediate state
3. Verify syntax/compilation
4. Summarize what instrumentation was added and what it will reveal

**If ISOLATE:**
1. Create minimal reproduction case, OR
2. Bisect to narrow down (disable components, simplify input, binary search commits)
3. Document what was isolated and what remains

### Phase 5: Report

Always end with a clear status block:

```
## Iteration [N] Complete

**Evidence reviewed:** [What diagnostic info was analyzed]
**Analysis:** [Brief root cause hypothesis or uncertainty]
**Action taken:** [FIX | INSTRUMENT | ISOLATE]
**What changed:** [Specific changes made]
**Files modified:** [List with paths]
**Next step:** [What user should do - test, reproduce, provide more info]
```

## Instrumentation Patterns

### Rust - Tracing
```rust
use tracing::{debug, error, instrument};

#[instrument(skip(self))]
fn process_request(&self, req: &Request) -> Result<Response> {
    debug!(?req, "processing request");
    // ... operation ...
    debug!(?response, "request complete");
    Ok(response)
}
```

### Rust - Error Context
```rust
use anyhow::Context;

fn load_config(path: &Path) -> anyhow::Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read config from {}", path.display()))?;
    toml::from_str(&content)
        .with_context(|| format!("failed to parse config from {}", path.display()))
}
```

### TypeScript - State Capture
```typescript
console.debug(`[${funcName}] entry:`, { arg1, arg2 });
// ... operation ...
console.debug(`[${funcName}] exit:`, { result });
```

### Shell - Command Tracing
```bash
set -x  # Enable command tracing
# ... commands ...
set +x  # Disable
```

### General - Checkpoint Logging
```
logger.info(f"CHECKPOINT {n}: reached {location}, state={relevant_state}")
```

## Anti-Patterns

- **Shotgun debugging**: Making multiple changes hoping one works
- **Premature optimization**: Fixing before understanding
- **Instrument + Fix**: Doing both muddies cause and effect
- **Log spam**: Logging everything obscures the signal
- **Skipping verification**: Not checking that changes compile/run
- **Removing instrumentation early**: Keep it until bug is confirmed fixed
- **Guessing**: Making changes without evidence

## Convergence

Each iteration should narrow the possibility space:

```
Iteration 1: "Something fails with multiline input"
Iteration 2: "Error raised in transport layer"
Iteration 3: "ConnectionError when transport.write() called after close()"
Iteration 4: FIX - Handle transport state before write
```

If iterations aren't converging, step back and reconsider the approach:
- Is the reproduction reliable?
- Are we looking at the right logs?
- Is this actually multiple bugs?

## Session Continuity

When resuming an iterator session:
1. Review previous iteration reports
2. Check if user tested and what happened
3. Continue from current state, don't restart

Track iteration count via todo list or mention in reports.
