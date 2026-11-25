---
title: Security Scanning & Supply Chain Hardening
description: Comprehensive security scanning, supply chain hardening, and vulnerability assessment for the Edge AI Accelerator CI/CD pipelines.
author: Edge AI Team
ms.date: 2026-11-24
ms.topic: concept
keywords:
  - security scanning
  - supply chain security
  - sha pinning
  - workflow security
  - checkov
  - terraform security
  - bicep security
  - vulnerability assessment
  - slsa
  - stepSecurity
  - ossf scorecard
estimated_reading_time: 8
---

The Edge AI Accelerator implements comprehensive security scanning and supply chain hardening to ensure infrastructure security, identify vulnerabilities, maintain compliance, and protect against supply chain attacks.

## Overview

### Security Layers

- **Supply Chain Security**: Immutable dependency pinning, runtime monitoring, SLSA compliance
- **Infrastructure as Code**: Terraform and Bicep security validation
- **Dependencies**: Package and library vulnerability assessment with automated updates
- **Container Images**: Docker image vulnerability scanning with Grype
- **Container Configuration**: Docker and Kubernetes configuration scanning with SHA pinning
- **Language-Specific**: .NET, Rust, Node.js, Python dependency audits
- **Configuration**: CI/CD and secret management validation
- **Runtime Security**: Egress filtering, network monitoring, and runtime attestation

### Integration Points

- **Matrix Builds**: Security scanning integrated into application build matrix
- **Pull Requests**: Security checks block non-compliant changes
- **GitHub Actions**: Automated scanning, hardening, and monitoring
- **Azure DevOps**: Enterprise security validation with full template parity
- **Security Gate**: Centralized security gate enforcement
- **Local Development**: Pre-commit security validation and SHA pinning

## Supply Chain Security

### Committed Dependency Lockfiles

All dependency lockfiles MUST be committed to version control and validated in CI/CD pipelines.

#### Policy Requirements

**Required lockfiles**:

- **Rust**: `Cargo.lock` (per-service for microservices)
- **Node.js**: `package-lock.json`
- **Python**: `requirements.txt` with pinned versions
- **Go**: `go.sum`

**Rationale**:

1. **NIST SP 800-161 Compliance**: Satisfies supply chain risk management requirements for component inventory (C-SCRM-1), integrity verification (C-SCRM-5), and provenance tracking (C-SCRM-6)
2. **TOCTOU Prevention**: Eliminates dependency confusion, version hijacking, registry compromise, and build non-reproducibility attacks
3. **Consistency with SHA Pinning**: Extends immutable dependency pinning to application-level dependencies

#### Rust Cargo.lock Architecture

**Per-Service Lockfiles (Microservices Pattern)**:

All Rust microservices maintain independent `Cargo.lock` files:

```text
src/500-application/
├── 501-rust-telemetry/services/
│   ├── sender/Cargo.lock      # 265 packages, azure_iot_operations_* v0.9.0
│   └── receiver/Cargo.lock    # 265 packages, independent dependency tree
├── 502-rust-http-connector/services/
│   ├── broker/Cargo.lock      # 332 packages, includes jsonschema, reqwest
│   └── subscriber/Cargo.lock  # 154 packages, minimal dependencies
└── 503-media-capture-service/services/
    └── media-capture-service/Cargo.lock  # OpenCV, ffmpeg-next dependencies
```

**Benefits of per-service lockfiles**:

- **Microservices independence**: Different deployment lifecycles and scaling characteristics
- **Docker build alignment**: Lockfile in service directory matches `COPY ./Cargo.lock` commands
- **Isolated security impact**: CVE in one service doesn't trigger false positives in others
- **Targeted CI/CD**: Change detection and rebuilds only for affected services
- **Component-level SBOM**: Each deployable artifact has exact dependency manifest

See Cargo Workspace Removal ADR for architectural rationale.

**Registry-Aware Build Strategy**:

- **Local builds** (developers):
  - Use committed `Cargo.lock` as-is
  - No network access to private registry required
  - Reproducible builds from locked dependencies

- **CI/CD builds** (with private `aio-sdks` registry):
  - Detect private registry in `Cargo.toml`: `registry = "aio-sdks"`
  - Regenerate `Cargo.lock` with `cargo generate-lockfile`
  - Ensures access to latest private Azure IoT Operations SDKs
  - Committed lockfile serves as baseline

- **Fallback** (missing lockfile):
  - Generate lockfile automatically
  - Log warning (should not occur in normal operation)
  - CI/CD security gate fails validation

Implementation: `scripts/build/application-builder.ps1` lines 233-297

#### Lockfile Validation

**Script**: `scripts/security/Test-DependencyPinning.ps1`

```powershell
# Validate all lockfiles
pwsh Test-DependencyPinning.ps1 -IncludeTypes rust-cargo,npm,pip,go-mod -FailOnUnpinned

# Validate specific language
pwsh Test-DependencyPinning.ps1 -IncludeTypes rust-cargo
```

**Validation rules**:

- Every `Cargo.toml` MUST have corresponding `Cargo.lock` in same directory
- Every `package.json` MUST have corresponding `package-lock.json`
- Every `go.mod` MUST have corresponding `go.sum`
- All lockfiles MUST be committed (not in `.gitignore`)

**CI/CD integration**:

- GitHub Actions: `.github/workflows/application-matrix-builds.yml`
- Azure DevOps: `.azdo/templates/application-build-template.yaml`
- Fails build immediately if validation fails (before building container images)

**Security gate configuration** (`.security-gate.yml`):

```yaml
dependencies:
  lockfiles:
    enforce_lockfile_commits: true
    fail_on_missing: true
    types: [rust-cargo, npm, pip, go-mod]
```

#### Developer Workflow

**Adding dependencies**:

```bash
# Navigate to service directory
cd src/500-application/*/services/*/

# Add dependency (Cargo automatically updates Cargo.lock)
cargo add <crate-name>

# Commit both files
git add Cargo.toml Cargo.lock
git commit -m "feat(app): add <crate-name> dependency"
```

**Updating dependencies**:

```bash
# Update specific dependency
cargo update -p <crate-name>

# Update all dependencies
cargo update

# Commit updated lockfile
git add Cargo.lock
git commit -m "chore(deps): update Rust dependencies"
```

**Never ignore lockfiles**:

```gitignore
# ❌ WRONG - defeats supply chain security
Cargo.lock
package-lock.json
go.sum

# ✅ CORRECT - lockfiles must be committed
# (no .gitignore entries for lockfiles)
```

### SHA Pinning & Dependency Management

The Edge AI Accelerator implements comprehensive SHA pinning for immutable dependencies across all CI/CD workflows.

#### GitHub Actions SHA Pinning

**Script**: `./scripts/security/Update-ActionSHAPinning.ps1`

```powershell
# Pin all GitHub Actions to SHA hashes
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -WhatIf

# Apply SHA pinning with build warnings
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -OutputFormat "BuildWarning"

# Generate JSON output for CI/CD
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -OutputFormat "JSON"
```

#### Docker Image SHA Pinning

**Script**: `./scripts/security/Update-DockerSHAPinning.ps1`

```powershell
# Pin Docker images in Dockerfiles and Compose files
./scripts/security/Update-DockerSHAPinning.ps1 -Path "src/" -WhatIf

# Apply with structured security issue output
./scripts/security/Update-DockerSHAPinning.ps1 -Path "src/" -OutputFormat "BuildWarning"
```

#### Shell Script Dependency Tracking

**Script**: `./scripts/security/Update-ShellScriptSHAPinning.ps1`

```powershell
# Analyze shell script dependencies for pinning opportunities
./scripts/security/Update-ShellScriptSHAPinning.ps1 -Path "src/" -OutputFormat "BuildWarning"
```

### SHA Staleness Monitoring

**Script**: `./scripts/security/Test-SHAStaleness.ps1`

Monitors pinned dependencies for security updates and generates build warnings for outdated SHAs.

```powershell
# Check for stale SHA pins with build warnings
./scripts/security/Test-SHAStaleness.ps1 -Path ".github/workflows" -OutputFormat "BuildWarning"

# Generate JSON report for CI/CD integration
./scripts/security/Test-SHAStaleness.ps1 -Path ".github/workflows" -OutputFormat "JSON"

# Update stale SHA pins and re-scan
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -UpdateStale
```

### Workflow Security Scans

Three scanners check GitHub Actions workflows on every pull request, merge group, and push to `main`. Each runs as a reusable workflow, writes SARIF, and passes its results through the SARIF threshold gate. Every run scans all of `.github/workflows`, and the provenance scan also reads composite actions under `.github/actions`.

| Scan                      | Script                                          | Reusable workflow                                  | SARIF category          |
|---------------------------|-------------------------------------------------|----------------------------------------------------|-------------------------|
| **Expression injection**  | `scripts/security/Test-DangerousWorkflow.ps1`   | `.github/workflows/dangerous-workflow-scan.yml`    | `dangerous-workflow`    |
| **Runner labels**         | `scripts/security/Test-WorkflowRunner.ps1`      | `.github/workflows/workflow-runner-scan.yml`       | `workflow-runner`       |
| **Action pin provenance** | `scripts/security/Test-ActionPinProvenance.ps1` | `.github/workflows/action-pin-provenance-scan.yml` | `action-pin-provenance` |

The scans currently run in report-only mode (`soft-fail: true`): unexcused results appear as warnings and in the Security tab, but do not fail pull requests. A scanner or gate error fails the job in either mode.

#### Expression Injection Rules

The scanner reports `${{ }}` expressions inside a step `run:` or `with.script:` value, because GitHub expands them into the script text before the shell runs it.

| Rule                                               | Reported when the expression references                                                                                                                 |
|----------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| `dangerous-workflow/input-interpolation`           | A `workflow_call` or `workflow_dispatch` input that is not declared `boolean`, an undeclared input, or the whole `inputs` object                        |
| `dangerous-workflow/untrusted-event-interpolation` | An event value an external contributor controls, such as a pull request title or body, a comment body, a commit message or author, or `github.head_ref` |

Fix a finding by passing the value through a step-level `env:` entry and reading the quoted variable:

```yaml
- name: Use a caller input
  env:
    TARGET_PATH: ${{ inputs.path }}
  run: ./scripts/build.sh --path "${TARGET_PATH}"
```

In PowerShell steps read `$env:TARGET_PATH`, and in `actions/github-script` read `process.env.TARGET_PATH`.

#### Runner Label Rules

`workflow-runner/undated-label` reports any job whose `runs-on` is not a dated GitHub-hosted Ubuntu label such as `ubuntu-24.04` or `ubuntu-24.04-arm`. Floating labels such as `ubuntu-latest` move to a new OS release without a reviewed change. Jobs that call a reusable workflow are not checked; the reusable workflow's own jobs are. Dated labels fix the OS release only; GitHub still updates the image's tools weekly.

#### Action Pin Provenance Rules

Every remote `uses:` must be pinned to a 40-character commit SHA with a comment naming the exact `vX.Y.Z` release tag that points at that commit in the publisher's repository. Tags are read from the publisher's repository with `git ls-remote`, so a commit that exists only in a fork never passes.

| Rule                              | Meaning and fix                                                                                                   |
|-----------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `action-pin/not-sha-pinned`       | The ref is a tag or branch. Pin the commit SHA.                                                                   |
| `action-pin/upstream-unavailable` | The publisher's tags could not be read after 3 attempts. Rerun the job; this cannot be excepted.                  |
| `action-pin/tag-object`           | The SHA is an annotated tag object. Pin the commit the message names.                                             |
| `action-pin/untagged-commit`      | No publisher tag points at the commit. Pin a commit from a release.                                               |
| `action-pin/comment-missing`      | Add the `# vX.Y.Z` comment the message suggests.                                                                  |
| `action-pin/comment-not-release`  | The comment is a moving tag such as `v1` or `v1.2`. Use the exact release the message lists.                      |
| `action-pin/comment-mismatch`     | The named tag points at another commit. Correct the comment; changing only the comment changes nothing that runs. |

#### Running the Scans Locally

The injection and runner scanners need the `powershell-yaml` module at the version pinned in `scripts/security/ps-module-versions.json`.

```powershell
# Install the pinned modules
./scripts/security/Install-PSModules.ps1

# Run each scanner; exit code 0 means no findings, 1 means findings, 2 means an error
./scripts/security/Test-DangerousWorkflow.ps1 -OutputPath logs/dangerous-workflow.sarif
./scripts/security/Test-WorkflowRunner.ps1 -OutputPath logs/workflow-runner.sarif
./scripts/security/Test-ActionPinProvenance.ps1 -OutputPath logs/action-pin-provenance.sarif

# Gate a SARIF file against the tracked exceptions
./scripts/security/Test-SarifThreshold.ps1 -SarifPath logs/workflow-runner.sarif
```

#### SARIF Threshold Gate

**Script**: `./scripts/security/Test-SarifThreshold.ps1`

The gate allows zero unexcused results. It counts every SARIF result regardless of level and ignores inline SARIF suppressions.

| Exit code | Meaning                                                                                    |
|-----------|--------------------------------------------------------------------------------------------|
| `0`       | Every result is excused and every exception for a scanned tool still matches               |
| `1`       | Unexcused results, an exception whose count differs from the results, or a stale exception |
| `2`       | Missing, unreadable, or empty SARIF, or a malformed exceptions file                        |

`PR Validation Gate` requires all three scan jobs to succeed, so a skipped or failed scan blocks the merge.

#### Requesting a Tracked Exception

Fix findings whenever possible. Add an exception only when the finding cannot be fixed in the pull request, such as an action whose publisher has no `vX.Y.Z` release at the pinned commit. Exceptions live in `scripts/security/workflow-scan-exceptions.json`:

```json
{
  "exceptions": [
    {
      "tool": "Test-ActionPinProvenance",
      "rule": "action-pin/comment-not-release",
      "path": ".github/workflows/fuzz-pr.yml",
      "count": 6,
      "reason": "google/clusterfuzzlite publishes only a moving v1 tag; no vX.Y.Z release exists at the pinned commit.",
      "issue": "https://github.com/microsoft/edge-ai/issues/941"
    }
  ]
}
```

- Every entry needs `tool` (the scanner name), `rule`, `path`, `count`, and `reason`. `issue` is optional, and no other fields are allowed.
- An exception covers one rule in one file and must equal that file's result count, so a new finding in the same file still fails.
- An exception that no longer matches any result fails the gate; remove it when its findings are fixed.
- `action-pin/upstream-unavailable` cannot be excepted, because an unverified pin is not a passing pin.
- SARIF is uploaded unfiltered, so excepted results stay visible as code scanning alerts. Maintainers may dismiss them in the Security tab with the exception's reason.

The gate summary lists every excused result with its reason. Reviewers should treat any change to the exceptions file as a security decision.

### Automated Dependency Management

#### Dependabot Configuration

**File**: `.github/dependabot.yml`

Automated dependency updates for eight ecosystems, each on a weekly schedule (Monday 09:00 US/Pacific) with one grouped pull request per ecosystem:

- GitHub Actions
- npm packages
- Cargo (Rust) crates
- Python packages (pip)
- Docker images
- NuGet packages
- Terraform providers and modules
- Go modules (gomod)

#### Azure DevOps Dependency Scanning

Enterprise-grade dependency scanning integrated with Azure DevOps Security Center for comprehensive vulnerability assessment and automated remediation.

#### OSSF Scorecard Integration

Automated supply chain security analysis using OpenSSF Scorecard for comprehensive security posture assessment.

**GitHub Actions**:

```yaml
- name: OSSF Scorecard
  uses: ossf/scorecard-action@0864cf19026789058feabb7e87baa5f140aac736 # v2.3.1
  with:
    results_file: results.sarif
    results_format: sarif
```

## Traditional Security Scanning

### Grype - Container Image Vulnerability Scanning

**Primary Tool**: [Grype][grype-tool] for container image vulnerability assessment
**Script**: `./scripts/security/Invoke-ContainerSecurityScan.ps1`

#### Grype Capabilities

- **Multi-Registry Support**: Docker Hub, Azure Container Registry, private registries
- **Comprehensive Databases**: CVE, Alpine SecDB, Debian Security Tracker
- **Multiple Output Formats**: SARIF, JSON, table, template formats
- **Language Support**: Java, Python, Ruby, .NET, Go, Rust, JavaScript

#### Grype Usage Examples

```powershell
# Scan container image
./scripts/security/Invoke-ContainerSecurityScan.ps1 -ImageName "myapp:latest" -OutputFormat "sarif"

# Scan with custom severity threshold
./scripts/security/Invoke-ContainerSecurityScan.ps1 -ImageName "myapp:latest" -FailOnSeverity "high"

# Generate detailed report
grype myregistry.azurecr.io/myapp:latest -o json > vulnerability-report.json
```

### Language-Specific Security Audits

**Integrated Audits**: Built into application build matrix

#### Supported Languages

- **.NET**: `dotnet list package --vulnerable`
- **Rust**: `cargo audit`
- **Node.js**: `npm audit`
- **Python**: `pip-audit`

#### Build Integration

```powershell
# Run language-specific security audit
./scripts/build/application-builder.ps1 -ApplicationPath "src/500-application/myapp" -Language "dotnet" -SecurityScan
```

### Checkov - Infrastructure Security

**Tool**: [Checkov][checkov-tool] for Infrastructure as Code scanning
**Script**: `./scripts/Run-Checkov.ps1`

#### Checkov Capabilities

- **Multi-Platform**: Terraform, Bicep, Docker, Kubernetes, ARM
- **Policy Libraries**: CIS benchmarks, NIST, SOC2, custom policies
- **Remediation**: Actionable fix recommendations

#### Checkov Usage Examples

```powershell
# Scan Terraform files
./scripts/Run-Checkov.ps1 -Path "src/" -Framework "terraform"

# Scan Bicep templates
./scripts/Run-Checkov.ps1 -Path "src/" -Framework "bicep"

# Scan specific file
checkov -f src/000-cloud/010-security-identity/terraform/main.tf
```

### Security Gate Enforcement

**Script**: `./scripts/security/Invoke-SecurityGate.ps1`
**Purpose**: Centralized security gate evaluation and enforcement

#### Gate Capabilities

- **Multi-Tool Integration**: Grype, Checkov, language-specific audits
- **Configurable Thresholds**: Per-tool severity and count limits
- **Report Aggregation**: SARIF, JUnit XML, JSON output formats
- **Failure Handling**: Configurable gate behavior (fail/warn/info)

#### Security Gate Usage Examples

```powershell
# Run security gate with default configuration
./scripts/security/Invoke-SecurityGate.ps1 -ConfigPath "./security-config.json"

# Custom severity thresholds
./scripts/security/Invoke-SecurityGate.ps1 -GrypeSeverityThreshold "medium" -CheckovSeverityThreshold "high"

# Generate reports only (no gate enforcement)
./scripts/security/Invoke-SecurityGate.ps1 -ReportOnly
```

## CI/CD Security Integration

### Matrix Build Integration

Security scanning is automatically integrated into application matrix builds:

```yaml
- name: Application Security Scan
  run: |
    ./scripts/build/application-builder.ps1 \
      -ApplicationPath "${{ matrix.application.path }}" \
      -Language "${{ matrix.application.language }}" \
      -SecurityScan
```

### GitHub Actions Workflows

All workflows include comprehensive security monitoring:

#### CodeQL and Gitleaks Code Scanning Integration

- **CodeQL (`.github/workflows/codeql.yml`)**: Runs as one dedicated workflow on `push` to `main`, `pull_request` to `main`, weekly `schedule`, and `workflow_dispatch` across `javascript-typescript`, `python`, `csharp`, and `rust` using `build-mode: none`. Keeping CodeQL in one workflow ensures `main` and pull requests share a single analysis configuration and avoids duplicate extractor or missing `on.push` warnings.
- **Gitleaks (`.github/workflows/security-scan.yml`)**: Uploads `security-results/gitleaks-report.sarif` under explicit `category: gitleaks` so pull-request scans diff cleanly against the `main` baseline, while skipping uploads on `merge_group` and fork pull requests.

#### Main Workflow Security Steps

```yaml
jobs:
  security-monitoring:
    runs-on: ubuntu-24.04
    steps:
      - name: Security Monitoring
        uses: step-security/secure-repo@f0aa4c52c23e5cdcc8d5088bd60badb2a08c24c4 # v1.0.0

      - name: SHA Staleness Check
        run: |
          ./scripts/security/Test-SHAStaleness.ps1 -Path ".github/workflows" -OutputFormat "BuildWarning"
```

#### Container Image Security Scanning

```yaml
- name: Container Security Scan
  run: |
    ./scripts/security/Invoke-ContainerSecurityScan.ps1 \
      -ImageName "${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.TAG }}" \
      -OutputFormat "sarif" \
      -FailOnSeverity "high"

- name: Upload Security Results
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: grype-results.sarif
```

#### Infrastructure Security Validation

```yaml
- name: Infrastructure Security Scan
  run: |
    ./scripts/Run-Checkov.ps1 -Path "src/" -Output "sarif"

- name: Upload Infrastructure Security Results
  uses: github/codeql-action/upload-sarif@0b21cf2492b6b02c465a3e5d7c473717ad7721ba # v3
  with:
    sarif_file: checkov-results.sarif
```

#### Language-Specific Dependency Audits

```yaml
# .NET packages
- name: .NET Security Audit
  run: dotnet list package --vulnerable --include-transitive

# Rust packages
- name: Rust Security Audit
  run: cargo audit

# npm packages
- name: NPM Security Audit
  run: npm audit --audit-level=moderate

# Python packages
- name: Python Security Scan
  run: pip-audit --requirement requirements.txt
```

### Azure DevOps Pipeline Integration

**Main Pipeline**: `azure-pipelines.yml`

Security templates integrated:

```yaml
- template: .azdo/templates/security-monitoring-template.yml
- template: .azdo/templates/security-scorecard-template.yml
- template: .azdo/templates/security-staleness-check.yml
```

#### Security Template Examples

**Staleness Monitoring**: `.azdo/templates/security-staleness-check.yml`

#### Application Build Template Security

```yaml
- task: PowerShell@2
  displayName: 'Application Security Scan'
  inputs:
    filePath: './scripts/build/application-builder.ps1'
    arguments: '-ApplicationPath "$(ApplicationPath)" -Language "$(Language)" -SecurityScan'

- task: PowerShell@2
  displayName: 'Security Gate Evaluation'
  inputs:
    filePath: './scripts/security/Invoke-SecurityGate.ps1'
    arguments: '-ConfigPath "$(SecurityGateConfig)"'
```

#### Infrastructure Security Scanning

```yaml
- task: PowerShell@2
  displayName: 'SHA Staleness Check'
  inputs:
    filePath: './scripts/security/Test-SHAStaleness.ps1'
    arguments: '-Path "$(Build.SourcesDirectory)/.github/workflows" -OutputFormat "BuildWarning"'
```

## Troubleshooting

### Common Issues

#### SHA Pinning Problems

**Symptoms**: Missing SHA mappings, dependencies that cannot be pinned, API rate limits

**Solutions**:

- Check GitHub API rate limits and authentication
- Use manual SHA mapping for actions without releases
- Review build warnings for dependencies that cannot be pinned
- Configure appropriate timeout values for API calls

#### Tool Configuration Problems

**Symptoms**: Configuration errors, policy failures

**Solutions**:

- Validate configuration files
- Update security policies
- Check tool version compatibility
- Verify environment dependencies

#### False Positives

**Symptoms**: Valid configurations flagged as issues

**Solutions**:

- Customize policies for organization requirements
- Configure exceptions for valid use cases
- Update policies based on analysis

#### Performance Issues

**Symptoms**: Slow scanning, timeouts

**Solutions**:

- Optimize scanning scope
- Implement parallel execution
- Use result caching
- Allocate more resources

#### Workflow Security Scan Findings

**Symptoms**: A workflow security scan job fails, or warns in report-only mode, with `dangerous-workflow/*`, `workflow-runner/*`, or `action-pin/*` results

**Solutions**:

- Read the annotation on the reported line; each message names the fix
- Move interpolated inputs and event values into a step-level `env:` entry
- Replace floating runner labels with `ubuntu-24.04`
- Correct the version comment to the release tag the message lists

#### Upstream Unavailable

**Symptoms**: `action-pin/upstream-unavailable` results, or the scan log reports unavailable repositories

**Solutions**:

- Rerun the job; the scanner already retries each repository 3 times
- Confirm the action repository still exists and is public
- Do not add an exception; the gate rejects exceptions for this rule

#### Stale or Mismatched Code Scanning Configurations

**Symptoms**: GitHub Code Scanning shows outdated configurations in **Security -> Code scanning -> Tool status**, or pull requests show `neutral: 1 configuration not found` (for example, when a workflow's SARIF category or filename changed)

**Solutions**:

- Ensure every reusable workflow that calls `github/codeql-action/upload-sarif` specifies a stable `category:` (such as `gitleaks`) and skips `merge_group` and fork pull requests
- Keep CodeQL in `.github/workflows/codeql.yml` rather than duplicating jobs across PR-only and `main`-only workflows
- After merging a workflow or category rename and confirming the new category has uploaded on `refs/heads/main`, remove the superseded configuration in **Security -> Code scanning -> Tool status -> `...` -> Delete analysis** (or via `DELETE /repos/{owner}/{repo}/code-scanning/analyses/{id}?confirm_delete=true`, following `confirm_delete_url` until `null`)

#### Stale or Mismatched Exceptions

**Symptoms**: The gate reports `stale exception` or `exception count mismatch`

**Solutions**:

- Remove exceptions whose findings were fixed
- Update `count` when results were added to or removed from the excepted file, after confirming each remaining result still qualifies
- Run `./scripts/security/Test-SarifThreshold.ps1` locally against fresh SARIF before pushing

### Debugging Commands

```powershell
# Test SHA pinning in WhatIf mode
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -WhatIf

# Check SHA staleness with detailed output
./scripts/security/Test-SHAStaleness.ps1 -Path ".github/workflows" -OutputFormat "JSON"

# Run a workflow security scanner and gate its SARIF
./scripts/security/Test-WorkflowRunner.ps1 -OutputPath logs/workflow-runner.sarif
./scripts/security/Test-SarifThreshold.ps1 -SarifPath logs/workflow-runner.sarif

# Verbose Checkov output
./scripts/Run-Checkov.ps1 -Path "src/" -Verbose

# List available policies
checkov --list

# Test specific policy
checkov --check CKV_AZURE_1 -f terraform-file.tf
```

## Security Report Management

### Report Compression

Security scan results are automatically compressed to optimize artifact storage:

**Script**: `./scripts/security/Invoke-SecurityReportCompression.ps1`

#### Compression Features

- **Multi-Format Support**: SARIF, JSON, JUnit XML, text reports
- **Metadata Preservation**: Maintains scan context and timestamps
- **Size Optimization**: Reduces artifact storage by 60-80%
- **Validation**: Ensures compression integrity

#### Usage Example

```powershell
# Compress all security reports in directory
./scripts/security/Invoke-SecurityReportCompression.ps1 -InputPath "./security-reports" -OutputPath "./compressed-reports"

# Compress specific report types
./scripts/security/Invoke-SecurityReportCompression.ps1 -InputPath "./reports" -FilePattern "*.sarif,*.json"
```

### Artifact Retention

Security reports follow optimized retention policies:

- **Security Reports**: 30 days retention with maximum compression
- **SARIF Results**: Uploaded to GitHub Security tab for long-term tracking
- **Build Artifacts**: Standard retention based on build type

## Best Practices

### Supply Chain Best Practices

- **Immutable Pinning**: Always pin dependencies to SHA hashes, not tags
- **Regular Updates**: Monitor and update pinned dependencies regularly
- **Automated Monitoring**: Use staleness monitoring for proactive security management
- **Graceful Degradation**: Handle dependencies that cannot be pinned with structured tracking
- **Build Integration**: Integrate security checks into CI/CD with appropriate warnings

### Scanning Best Practices

- **Early Integration**: Scan early in development workflow
- **Matrix Build Integration**: Leverage application matrix for comprehensive coverage
- **Incremental Scanning**: Only scan changed files for efficiency
- **Fast Feedback**: Provide quick security feedback to developers
- **Baseline Tracking**: Establish security baseline and track changes
- **Actionable Results**: Include clear remediation guidance
- **Report Compression**: Use compression for large security datasets
- **Language-Specific Audits**: Include dependency scanning for all supported languages

## Related Documentation

- [GitHub Actions Workflows](github-actions/) - GitHub Actions security integration
- [Azure DevOps Pipelines](azure-pipelines/) - Azure DevOps security integration

<!-- Reference Links -->
[grype-tool]: https://github.com/anchore/grype
[checkov-tool]: https://www.checkov.io/

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
