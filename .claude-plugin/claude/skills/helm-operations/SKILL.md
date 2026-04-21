---
name: helm-operations
description: Helm chart templating, values management, and debugging. Use when working with helm charts, troubleshooting template rendering, or managing values files.
---

# Helm Operations

Helm chart management, templating, and debugging workflows.

## Core Commands

### Template Rendering

```bash
# Render templates locally (no cluster needed)
helm template <release-name> <chart-path-or-repo/chart>

# With custom values
helm template my-app ./chart -f values.yaml -f values-override.yaml

# Render specific template
helm template my-app ./chart -s templates/deployment.yaml

# Show computed values (after merges)
helm template my-app ./chart --debug --dry-run
```

### Validation

```bash
# Lint chart for errors
helm lint ./chart

# Lint with values
helm lint ./chart -f values.yaml

# Dry-run install (validates against cluster)
helm install my-app ./chart --dry-run --debug
```

### Debugging

```bash
# Show all computed values
helm get values <release-name>

# Show values including defaults
helm get values <release-name> --all

# Show manifest as deployed
helm get manifest <release-name>

# Show chart metadata
helm show chart <repo/chart>

# Show default values from chart
helm show values <repo/chart>
```

### Diff

```bash
# Install helm-diff plugin
helm plugin install https://github.com/databus23/helm-diff

# Diff against deployed release
helm diff upgrade <release-name> <chart> -f values.yaml

# Three-way diff (deployed vs proposed)
helm diff upgrade <release-name> <chart> -f values.yaml --three-way-merge
```

## Chart Structure

```
chart/
├── Chart.yaml          # Chart metadata (name, version, dependencies)
├── values.yaml         # Default values
├── templates/          # Template files
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── _helpers.tpl   # Template helpers/functions
│   └── NOTES.txt      # Post-install notes
└── charts/             # Dependency charts (if vendored)
```

### _helpers.tpl Patterns

```yaml
{{/* Common labels */}}
{{- define "myapp.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/* Selector labels */}}
{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Fullname with release */}}
{{- define "myapp.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
```

## Values Management

### Values Precedence (Lowest to Highest)

1. Chart's `values.yaml` (defaults)
2. Parent chart's `values.yaml` (if subchart)
3. User-supplied values files (`-f values-1.yaml -f values-2.yaml`)
4. Individual parameters (`--set key=value`)

### Values Files Pattern

**Base values** (`values.yaml`):
```yaml
replicaCount: 1

image:
  repository: myapp
  tag: "1.0.0"
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

**Environment overlay** (`values-prod.yaml`):
```yaml
replicaCount: 3

image:
  tag: "1.2.5"

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### --set Syntax

```bash
# Simple value
--set replicaCount=3

# Nested value
--set image.tag="2.0.0"

# Array
--set ingress.hosts[0]=app.example.com

# Set from file
--set-file config=path/to/file.txt

# Set string (prevents type coercion)
--set-string port="8080"
```

## Type Coercion Gotchas

| YAML Input | Interpreted As | Type |
|------------|----------------|------|
| `port: 8080` | `8080` | int |
| `port: "8080"` | `"8080"` | string |
| `enabled: true` | `true` | bool |
| `version: 1.20` | `1.2` | float (loses precision!) |
| `version: "1.20"` | `"1.20"` | string |

**Always quote:** version numbers, port numbers meant as strings, boolean-looking strings.

## Template Debugging

### Common Issues

**Whitespace and indentation:**
```yaml
# Wrong - extra newline breaks YAML
labels:
{{ include "myapp.labels" . }}

# Right - use dash to trim whitespace
labels:
  {{- include "myapp.labels" . | nindent 2 }}
```

**Nil pointer dereference:**
```yaml
# Unsafe - crashes if image.tag undefined
image: {{ .Values.image.tag }}

# Safe - provides default
image: {{ .Values.image.tag | default "latest" }}

# Safe - conditional rendering
{{- if .Values.image.tag }}
image: {{ .Values.image.tag }}
{{- end }}
```

**Required values:**
```yaml
# Fail fast if required value missing
apiKey: {{ required "apiKey is required" .Values.apiKey }}
```

## Integration with ArgoCD

### valuesObject vs valueFiles

| Pattern | Use When |
|---------|----------|
| `valuesObject` | Simple configs, few values, single-source apps |
| `valueFiles` | Complex configs, multiple environments, GitOps workflow |

### Helm Hooks vs ArgoCD Sync Waves

| Feature | Helm Hooks | ArgoCD Sync Waves |
|---------|------------|-------------------|
| Scope | Single chart | Across all resources in Application |
| Phases | pre-install, post-install, pre-upgrade, etc. | Numeric waves (-5 to +5, etc.) |
| Best for | Chart-internal ordering | Cross-resource dependencies |

**Recommendation**: Use ArgoCD sync waves for multi-resource ordering, helm hooks for chart-specific lifecycle.

## Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| "mapping values are not allowed" | Indentation error, unquoted colon | Check YAML indentation, quote strings with `:` |
| "nil pointer evaluating interface" | Accessing undefined value | Use `default`, `if`, or `required` |
| Value not overriding | Wrong key path, precedence | Check values structure, use `--debug` |
| Template not rendering | Wrong path in `-s` flag | Use exact path: `templates/file.yaml` |

## Best Practices

1. **Always lint before commit**: `helm lint ./chart -f values.yaml`
2. **Quote version strings**: `version: "1.20"` not `version: 1.20`
3. **Use required for critical values**: `{{ required "msg" .Values.key }}`
4. **Provide sensible defaults**: Don't require values that have obvious defaults
5. **Document values**: Add comments in `values.yaml` explaining each field
6. **Use _helpers.tpl**: Define reusable templates for labels, names, selectors
7. **Test locally first**: `helm template` before applying to cluster
8. **Keep templates simple**: Complex logic belongs in application code, not templates
9. **Pin dependency versions**: Don't use version ranges in production
