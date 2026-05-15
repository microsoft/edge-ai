# Exclude `.terraform.lock.hcl` from Version Control

Date: **2026-05-10** [Format=YYYY-MM-DD]

## Status

- [ ] Draft
- [ ] Proposed
- [x] Accepted
- [ ] Deprecated
- [ ] Superseded by 0002

## Decision

Exclude the Terraform dependency lock file (`.terraform.lock.hcl`) from version
control across every Terraform component and blueprint in this repository, and
rely on explicit provider version constraints plus a fresh `terraform init` in
CI to guarantee reproducible builds.

## Context

The OSSF Scorecard Silver criterion [`build_repeatable`][ossf-build-repeatable]
requires that the project's build can be repeated by anyone, from a clean
checkout, without unstated environmental assumptions. Issue
[microsoft/edge-ai#166][issue-166] (`build_repeatable` — Terraform half) flagged
that the repository excludes `.terraform.lock.hcl` via `.gitignore` without a
recorded rationale and without a documented alternative for guaranteeing
reproducibility, which is the artifact that OSSF Silver expects to see.

This repository spans many independent Terraform components and blueprints
(`src/000-cloud/...`, `src/100-edge/...`, `blueprints/...`) and is consumed from
multiple operating systems and CI runners (Linux x86_64, macOS arm64/x86_64,
Windows x86_64, Linux arm64 dev containers). A single committed lock file
records provider package hashes only for the platforms that were initialized
when the file was generated. When a contributor on a different platform runs
`terraform init`, Terraform either rejects the run with `Failed to query
available provider packages` / `checksums previously recorded in the dependency
lock file` errors, or silently appends new hashes that then drift between
branches — both of which undermine repeatability rather than improve it.

Reproducibility for this repository is instead enforced through:

- Explicit provider version constraints in every component's `versions.tf`
  (or `providers.tf`) with pinned `required_providers { source, version }`
  blocks, so the resolved provider set is deterministic from the manifest
  alone.
- CI pipelines (`azure-pipelines.yml`, GitHub Actions) and the local validation
  scripts under `scripts/` always run `terraform init` from a clean working
  directory, so the provider plugins are re-fetched and re-verified against the
  registry on every build.
- The `npm run tf-validate` and `npm run tflint-fix-all` workflows referenced
  in `.github/copilot-instructions.md` exercise this clean-init path locally,
  matching CI behavior.

Recording this decision closes the documentation gap that `build_repeatable`
calls out without changing the existing `.gitignore` behavior or any working
contributor flow.

## Decision drivers

- OSSF Scorecard Silver `build_repeatable` requires a documented, repeatable
  build path; the existing `.gitignore` line for `.terraform.lock.hcl` had no
  accompanying rationale.
- Lock files contain platform-specific provider hashes; committing one
  generated on a single OS/arch breaks `terraform init` for contributors and CI
  runners on other platforms.
- The repository contains many independent Terraform working directories;
  managing a separate lock file per component multiplies the cross-platform
  hash maintenance burden.
- Provider versions are already pinned in each component's `versions.tf`,
  giving deterministic resolution without the lock file.
- CI consistently performs a fresh `terraform init` per run, so cached
  provider state from a committed lock file would not change CI behavior.

## Considered options

1. **Exclude `.terraform.lock.hcl` and rely on `versions.tf` pins (selected)**
    - Good, avoids cross-platform hash conflicts during `terraform init`.
    - Good, keeps the source of truth for provider versions in human-readable
      `versions.tf` files that already live next to each component.
    - Good, matches what CI already does (clean init every run).
    - Bad, does not record the exact provider package hashes that were used at
      a given commit; reproducibility depends on the registry continuing to
      serve the pinned versions.

1. **Commit a single `.terraform.lock.hcl` per component**
    - Good, captures exact provider hashes per component.
    - Bad, generated on one platform, breaks `terraform init` on others
      unless every contributor runs `terraform providers lock -platform=...`
      for the full matrix on every provider bump.
    - Bad, multiplies maintenance across dozens of components and blueprints.
    - Bad, increases churn in PRs unrelated to provider changes.

1. **Commit a multi-platform `.terraform.lock.hcl` per component**
    - Good, addresses the cross-platform hash problem from option 2.
    - Bad, requires every contributor (and CI) to run
      `terraform providers lock -platform=linux_amd64 -platform=linux_arm64
      -platform=darwin_amd64 -platform=darwin_arm64 -platform=windows_amd64`
      after any provider change in any component.
    - Bad, the maintenance cost scales with the number of components and the
      frequency of provider updates, with no observed benefit over option 1
      given that CI re-initializes every run.

1. **Pin providers via a private mirror or `dev_overrides`**
    - Good, gives full control over which provider artifacts CI consumes.
    - Bad, requires standing up and maintaining mirror infrastructure that the
      project does not currently operate.
    - Bad, out of scope for the `build_repeatable` gap this ADR addresses.

## Decision Conclusion

`.terraform.lock.hcl` remains excluded from version control via `.gitignore`.
Reproducibility is provided by pinned `required_providers` entries in each
component's `versions.tf` and by CI pipelines that always run a clean
`terraform init`. This ADR is the recorded rationale required by OSSF Silver
`build_repeatable`.

## Consequences

- The repository satisfies the documentation expectation behind
  `build_repeatable` for the Terraform portions of the codebase.
- Contributors do not need to regenerate or merge `.terraform.lock.hcl` files
  when working across operating systems or architectures.
- Bumping a provider version is a single edit to the relevant `versions.tf`
  followed by `terraform init` and validation; there is no lock-file step.
- If a pinned provider version is later yanked from the Terraform Registry,
  builds for that component will break until the pin is updated. This is an
  accepted trade-off; the registry's published immutability policy makes this
  rare in practice.
- Any future move to a stricter supply-chain posture (for example, OSSF Gold
  or a private provider mirror) would supersede this ADR with an option that
  records exact artifact hashes.

## References

- Issue: [microsoft/edge-ai#166][issue-166]
- OSSF Scorecard checks: [`Build-Repeatable`][ossf-build-repeatable]
- Terraform docs: [Dependency Lock File][tf-lock-docs]
- `.gitignore` entry: `.terraform.lock.hcl`

[issue-166]: https://github.com/microsoft/edge-ai/issues/166
[ossf-build-repeatable]: https://github.com/ossf/scorecard/blob/main/docs/checks.md#build-repeatable
[tf-lock-docs]: https://developer.hashicorp.com/terraform/language/files/dependency-lock
