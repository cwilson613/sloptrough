---
name: security
description: Security checklist for code review and implementation. Covers input escaping, injection prevention, path traversal, process safety, dependency integrity, and secrets management. Load when working on user-facing code, template rendering, or process spawning.
---

# Security Skill

Defensive coding practices. Apply these checks during implementation and review.

## Input Escaping

### Never interpolate user input into templates, scripts, or SQL

```rust
// Bad: XSS
let js = format!("var id = '{}';", user_input);

// Good: escape special characters
fn escape_js_string(s: &str) -> String {
    s.replace('\\', "\\\\")
     .replace('\'', "\\'")
     .replace('"', "\\\"")
     .replace('<', "\\x3c")
     .replace('>', "\\x3e")
     .replace('\n', "\\n")
     .replace('\r', "\\r")
}
let js = format!("var id = '{}';", escape_js_string(user_input));
```

```typescript
// Bad
const html = `<div>${userInput}</div>`;

// Good
function escapeHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;")
          .replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
const html = `<div>${escapeHtml(userInput)}</div>`;
```

### Context matters — escape for the target language

| Context | Escape | Characters |
|---------|--------|------------|
| HTML body | HTML entities | `& < > "` |
| HTML attribute | HTML entities + quote | `& < > " '` |
| JavaScript string | JS escapes | `\ ' " < > \n \r` |
| URL parameter | `encodeURIComponent` | All non-unreserved |
| SQL | Parameterized queries | Never interpolate |
| Shell command | Avoid if possible | Use `spawn(cmd, [args])` not `exec(string)` |

## Path Traversal

### Validate that resolved paths stay within the expected root

```typescript
// Bad
const filePath = join(rootDir, userInput);

// Good
const resolved = resolve(rootDir, userInput);
if (!resolved.startsWith(resolve(rootDir) + sep) && resolved !== resolve(rootDir)) {
  throw new Error("Path traversal attempt");
}
```

```rust
// Bad
let path = root.join(&user_path);

// Good
let canonical = path.canonicalize()?;
if !canonical.starts_with(&root.canonicalize()?) {
    return Err("Path traversal".into());
}
```

### Reject suspicious path components

- `..` segments
- Null bytes (`%00`, `\0`)
- Absolute paths when relative expected
- Symlinks that escape the root (use `canonicalize`/`realpath`)

## Process Spawning

### Use `spawn` with argument arrays, never shell interpolation

```typescript
// Bad
execSync(`grep ${userInput} file.txt`);

// Good
spawn("grep", [userInput, "file.txt"], { stdio: "pipe" });
```

### Set timeouts on child processes

```typescript
const child = spawn("cmd", args);
const timer = setTimeout(() => {
  child.kill("SIGTERM");
}, 300_000); // 5 min timeout
child.on("exit", () => clearTimeout(timer));
```

## Dependency Integrity

### Pin CDN resources with Subresource Integrity (SRI)

```html
<!-- Bad -->
<script src="https://cdn.example.com/lib.js"></script>

<!-- Good -->
<script src="https://cdn.example.com/lib.js"
        integrity="sha384-abc123..."
        crossorigin="anonymous"></script>
```

### Prefer bundling over CDN for offline-first tools

```rust
// Bundle at compile time
const JS: &str = include_str!("../static/lib.min.js");
```

## Secrets Management

- **Never hardcode secrets** — use environment variables or secret managers.
- **Never log secrets** — mask or omit sensitive values from log output.
- **Never commit secrets** — use `.gitignore` and pre-commit hooks.
- **Rotate on exposure** — if a secret appears in a commit, rotate immediately.

## TOCTOU (Time-of-Check to Time-of-Use)

```typescript
// Bad — TOCTOU
if (existsSync(path)) {
  const data = readFileSync(path);
}

// Good — try and handle error
try {
  const data = readFileSync(path);
} catch (err) {
  if ((err as NodeJS.ErrnoException).code === "ENOENT") {
    // handle gracefully
  } else throw err;
}
```

## Checklist

Before submitting code that handles external input:

- [ ] All user/external input is escaped for its target context
- [ ] File paths are validated against a root directory
- [ ] Child processes use argument arrays, not shell strings
- [ ] CDN resources have SRI hashes or are bundled locally
- [ ] No secrets in source code or logs
- [ ] Error messages don't leak internal paths or stack traces to end users
- [ ] Timeouts set on all network requests and child processes
