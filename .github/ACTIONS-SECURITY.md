# Actions Security Policy

## SHA Pinning Policy

All third-party GitHub Actions must be pinned to full 40-character commit SHAs. Tag-only references (e.g., `@v4`) are not permitted. SHA pinning ensures immutable references immune to tag reassignment or repository compromises.

## Version Comment Format

Every `uses:` directive must include a `# vX.Y.Z` version comment after the SHA:

```yaml
uses: owner/repo@abc123...def456 # vX.Y.Z
```

This makes it human-readable which version each SHA corresponds to.

The comment must name one exact release tag, such as `v4.2.2`, and that tag must point at the pinned commit in the publisher's repository. Moving tags such as `v4` or `v4.2` are not accepted, because they can move to another commit while the pin stays the same. When a publisher has no exact release at the pinned commit, record a tracked exception as described in [Security Scanning](../docs/build-cicd/security-scanning.md#requesting-a-tracked-exception).

## Runner Labels

Every job that selects a runner must use a dated GitHub-hosted Ubuntu label, such as `ubuntu-24.04` or `ubuntu-24.04-arm`. Floating labels such as `ubuntu-latest` move to a new OS release without a reviewed change.

## Binary Download Verification

All binary tool downloads in workflow steps must include SHA256 checksum verification before extraction:

* Download to `/tmp/`
* Verify with `sha256sum --check --strict`
* Extract only after verification passes

Currently verified binaries: Gitleaks, Grype, Syft, TFLint.

## Permission Scoping

Workflow-level permissions default to read-only (`contents: read`). Write permissions are scoped to individual jobs that require them via per-job `permissions:` blocks, following the principle of least privilege.

## Dependabot Integration

`.github/dependabot.yml` is configured for the `github-actions` ecosystem with weekly update cadence. Dependabot automatically creates PRs to update SHA pins when new action versions are released.

## Compliance Verification

Verify all actions comply with this policy:

```bash
# Verify no tag-only pins (except local workflow refs)
grep -rn "uses:" .github/workflows/ | grep -v "uses:.*\./" | grep -v "@[a-f0-9]\{40\}"

# Verify all SHA pins have version comments
grep -rn "uses:.*@[a-f0-9]\{40\}" .github/workflows/ | grep -v "#"
```

Both commands should return empty output.

CI enforces these rules with the workflow security scans that `PR Validation Gate` requires:

```bash
# Pins and version comments, checked against each publisher's tags
pwsh ./scripts/security/Test-ActionPinProvenance.ps1

# Dated runner labels
pwsh ./scripts/security/Test-WorkflowRunner.ps1

# Inputs and event values interpolated into scripts
pwsh ./scripts/security/Test-DangerousWorkflow.ps1
```
