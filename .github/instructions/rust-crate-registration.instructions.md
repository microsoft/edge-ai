---
description: 'Required registration of Rust crates under src/500-application for CI test/coverage and Codecov reporting - Brought to you by microsoft/edge-ai'
applyTo: '**/src/500-application/**/Cargo.toml,**/.github/workflows/rust-tests.yml,**/.github/workflows/pr-validation.yml,**/scripts/build/Detect-Folder-Changes.ps1,**/codecov.yml'
---

# Rust Crate Registration Instructions

These rules govern how Rust application crates under `src/500-application/**` are registered with CI and Codecov. They complement the broader Rust guidance in [.github/instructions/rust.instructions.md](.github/instructions/rust.instructions.md) ("Workspace Architecture" section) and are enforced by an automated CI gate (see "CI Gate" below).

Every Rust crate under `src/500-application/**` MUST be either:

1. **Registered for coverage** in all three locations described in [Required Registration](#required-registration), OR
2. **Explicitly opted out** via the [Coverage Opt-Out](#coverage-opt-out) path in `codecov.yml`.

There is no third option. PRs that add or restructure a Rust crate without satisfying one of the above will fail the `validate-rust-registration` CI gate.

<!-- <rust-crate-registration-instructions> -->

## Required Registration

When a Rust crate participates in coverage, it MUST be registered in **all three** of the following locations. Missing any one of them is a CI failure.

### 1. `.github/workflows/rust-tests.yml` matrix

Add the crate as an `include:` entry under `jobs.coverage.strategy.matrix`. Each entry is an object with a `crate` path and optional `system_deps` for extra apt packages:

```yaml
jobs:
  coverage:
    strategy:
      matrix:
        include:
          - crate: src/500-application/503-media-capture-service/services/media-capture-service
            system_deps: ffmpeg   # optional: extra apt packages installed before build
          - crate: src/500-application/507-ai-inference/services/ai-edge-inference
          - crate: src/500-application/507-ai-inference/services/ai-edge-inference-crate
          - crate: src/500-application/NNN-your-new-crate/services/your-service   # <-- add here
```

The `crate` value MUST be the directory containing the crate's `Cargo.toml`. When adding an entry, also bump the `vuln-scan` job's `matrix.index` array so its length matches the number of `include:` entries (zero-based indices).

### 2. `scripts/build/Detect-Folder-Changes.ps1` change-detection regex

`rust-tests.yml` is a reusable workflow (`on: workflow_call`) and has no path triggers of its own. It is invoked by the `rust-tests` job in `pr-validation.yml`, which is gated by the `changesInRust` output of the shared `matrix-changes` job (the reusable `matrix-folder-check.yml` workflow). That output is computed by `scripts/build/Detect-Folder-Changes.ps1`, which matches the diffed PR file list against this regex:

```text
^src/500-application/    # any path under this prefix
^Cargo\.toml$
^Cargo\.lock$
^\.github/workflows/rust-tests\.yml$
^\.github/workflows/pr-validation\.yml$
^codecov\.yml$
```

Any crate located under `src/500-application/` is already covered by the `^src/500-application/` prefix and requires **no change** to this filter. Only extend the filter when a crate lives outside that prefix; in that case add a matching condition to the `$rustChangeFiles` block in `scripts/build/Detect-Folder-Changes.ps1` (for example `$_ -match '^src/600-other-area/'`).

### 3. `codecov.yml` rust flag paths

Add a glob covering the crate to `flags.rust.paths` so Codecov associates uploaded coverage with the `rust` flag:

```yaml
flags:
  rust:
    paths:
      - "src/500-application/503-media-capture-service/**"
      - "src/500-application/507-ai-inference/**"
      - "src/500-application/NNN-your-new-crate/**"   # <-- add here
    carryforward: true
```

## Coverage Opt-Out

Crates that are intentionally excluded from coverage (for example, experimental scaffolding, WASM operators with no host-side test surface, or crates pending refactor) MUST be listed in `codecov.yml` under `ignore`:

```yaml
ignore:
  - "src/500-application/512-avro-to-json/**"
  - "src/500-application/NNN-your-new-crate/**"   # <-- opt out here
  - "target/**"
```

When a crate is listed under `ignore`, it MUST NOT appear in the `rust-tests.yml` matrix or in `flags.rust.paths`. The CI gate treats ignored crates as fully satisfying the registration requirement.

## CI Gate

The workflow `.github/workflows/validate-rust-registration.yml` runs the script `scripts/Validate-RustCrateRegistration.ps1` on every PR that touches `src/500-application/**`, `.github/workflows/rust-tests.yml`, `codecov.yml`, or the validator itself. The gate fails the build with an itemized report when any crate under `src/500-application/**` is neither fully registered (all three locations) nor explicitly opted out.

## Local Validation

Run before opening a PR:

```pwsh
pwsh ./scripts/Validate-RustCrateRegistration.ps1
```

Tests live in `scripts/Validate-RustCrateRegistration.Tests.ps1` and are gated by `.github/workflows/validate-rust-registration.yml` on PR.

## Example: Adding a New Crate

For a hypothetical new crate at `src/500-application/520-example-service` (under the existing `src/500-application/` prefix), only the matrix and the Codecov flag paths need updating; the `pr-validation.yml` regex already matches:

```diff
 # .github/workflows/rust-tests.yml
   matrix:
     include:
       - crate: src/500-application/503-media-capture-service/services/media-capture-service
         system_deps: ffmpeg
       - crate: src/500-application/507-ai-inference/services/ai-edge-inference
       - crate: src/500-application/507-ai-inference/services/ai-edge-inference-crate
+      - crate: src/500-application/520-example-service/services/example
```

Also bump the `vuln-scan` job's `matrix.index` array length to match the new `include:` entry count.

```diff
 # codecov.yml
 flags:
   rust:
     paths:
       - "src/500-application/503-media-capture-service/**"
       - "src/500-application/507-ai-inference/**"
+      - "src/500-application/520-example-service/**"
     carryforward: true
```

If a future crate lives outside `src/500-application/`, also extend the rust-change filter in `scripts/build/Detect-Folder-Changes.ps1` so its path triggers the `rust-tests` job via the `matrix-changes` `changesInRust` output.

To opt out instead, omit both diffs above and add a single `ignore` entry to `codecov.yml`.

<!-- </rust-crate-registration-instructions> -->
