---
description: 'Deny-all top-level permissions baseline with per-job least-privilege scopes for GitHub Actions workflows'
applyTo: '.github/workflows/**/*.yml'
---
# Workflow Permissions Instructions

These instructions define the deny-all baseline convention enforced on every GitHub Actions workflow in this repository. They apply to all files under `.github/workflows/`.

## Convention

* Every workflow MUST declare a top-level `permissions: {}` block (deny-all baseline).
* Every job MUST declare its own `permissions:` block with the minimum scopes required.
* Granting scopes at the top level is NOT allowed; least privilege is expressed per job.
* Reusable workflows (`workflow_call`) follow the same rules — both the callee and the caller's invoking job declare their own minimum scopes.
* The default `GITHUB_TOKEN` permissions inherited from the repository are insufficient for OpenSSF Scorecard `Token-Permissions`; the deny-all top-level block plus per-job grants is the only accepted pattern.

## Enforcement

* CI runs `scripts/security/Test-WorkflowPermissions.ps1 -RequireDenyAll` against `.github/workflows/`.
* With `-RequireDenyAll`, the validator fails on any workflow whose top-level `permissions:` is missing or grants scopes (anything other than `{}`).
* The `workflow-permissions-scan.yml` workflow wires this into `pr-validation.yml` and `main.yml`, so a violation blocks the orchestrator job.

Run locally before pushing:

```bash
pwsh ./scripts/security/Test-WorkflowPermissions.ps1 \
  -Path ./.github/workflows \
  -RequireDenyAll
```

## Common job scopes

Grant only what the job uses. Common scopes:

| Scope             | Typical use                                         |
|-------------------|-----------------------------------------------------|
| `contents`        | `read` for checkout; `write` to push or tag         |
| `pull-requests`   | `write` to comment, label, or update PRs            |
| `issues`          | `write` to create or comment on issues              |
| `security-events` | `write` to upload SARIF to code scanning            |
| `id-token`        | `write` for OIDC federation (Azure login, Sigstore) |
| `attestations`    | `write` to produce build attestations               |
| `actions`         | `read` to query runs/artifacts; `write` to cancel   |
| `checks`          | `write` to publish check runs                       |
| `deployments`     | `write` to create deployments                       |
| `packages`        | `read`/`write` for GHCR                             |
| `statuses`        | `write` to set commit statuses                      |
| `pages`           | `write` to deploy GitHub Pages                      |

Reference: <https://docs.github.com/actions/security-for-github-actions/security-guides/automatic-token-authentication#permissions-for-the-github_token>.

## Examples

### Good — mapping form, per-job least privilege

```yaml
name: Code Quality Lint
on:
  workflow_call:

permissions: {}

jobs:
  lint:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          persist-credentials: false
      - run: npm ci && npx eslint .
```

### Good — multiple jobs, scoped grants only where needed

```yaml
permissions: {}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

  publish-sarif:
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: results.sarif
```

### Bad — missing top-level block (relies on repo default)

```yaml
# MISSING: permissions: {}
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
```

### Bad — top-level grants scopes instead of denying all

```yaml
permissions:
  contents: read
  pull-requests: write

jobs:
  build:
    runs-on: ubuntu-latest
    # Inherits top-level grants — violates least privilege per job.
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
```

### Bad — inline `read-all` or `write-all`

```yaml
permissions: read-all   # Disallowed: not a deny-all baseline.

jobs:
  build:
    runs-on: ubuntu-latest
    permissions: write-all   # Disallowed: violates least privilege.
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
```

## When a job needs no scopes

If a job genuinely needs no token scopes (for example, a pure compute step with no checkout), declare an empty job-level block explicitly:

```yaml
jobs:
  compute:
    runs-on: ubuntu-latest
    permissions: {}
    steps:
      - run: echo "no token access required"
```

This keeps intent explicit and survives future edits that might otherwise drift to inherited defaults.
