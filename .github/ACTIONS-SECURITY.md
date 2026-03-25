# Actions Security Policy

## SHA Pinning Policy

All third-party GitHub Actions must be pinned to full 40-character commit SHAs. Tag-only references (e.g., `@v4`) are not permitted. SHA pinning ensures immutable references immune to tag reassignment or repository compromises.

## Version Comment Format

Every `uses:` directive must include a `# vX.Y.Z` version comment after the SHA:

```yaml
uses: owner/repo@abc123...def456 # vX.Y.Z
```

This makes it human-readable which version each SHA corresponds to.

## Binary Download Verification

All binary tool downloads in workflow steps must include SHA256 checksum verification before extraction:

* Download to `/tmp/`
* Verify with `sha256sum --check --strict`
* Extract only after verification passes

Currently verified binaries: Gitleaks, Grype, TFLint.

## Permission Scoping

Workflow-level permissions default to read-only (`contents: read`). Write permissions are scoped to individual jobs that require them via per-job `permissions:` blocks, following the principle of least privilege.

## Dependabot Integration

`.github/dependabot.yml` is configured for the `github-actions` ecosystem with weekly update cadence. Dependabot automatically creates PRs to update SHA pins when new action versions are released.

## Exceptions

* `slsa-framework/slsa-github-generator@v2.1.0` uses tag-based pinning because GitHub requires tag references for reusable workflow calls (`jobs.<id>.uses`). SHA pinning is not supported for this use case.

## Compliance Verification

Verify all actions comply with this policy:

```bash
# Verify no tag-only pins (except slsa-framework and local workflow refs)
grep -rn "uses:" .github/workflows/ | grep -v "uses:.*\./" | grep -v "@[a-f0-9]\{40\}" | grep -v "slsa-framework"

# Verify all SHA pins have version comments
grep -rn "uses:.*@[a-f0-9]\{40\}" .github/workflows/ | grep -v "#"
```

Both commands should return empty output.
