---
description: 'Required registration of Rust crates under src/500-application for CI test/coverage and Codecov reporting - Brought to you by microsoft/edge-ai'
applyTo: '**/src/500-application/**/Cargo.toml,**/.github/workflows/rust-tests.yml,**/codecov.yml'
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

Add the crate's repo-relative path to `jobs.coverage.strategy.matrix.crate`:

```yaml
jobs:
  coverage:
    strategy:
      matrix:
        crate:
          - src/500-application/503-media-capture-service
          - src/500-application/507-ai-inference
          - src/500-application/507-ai-inference/ai-edge-inference-crate
          - src/500-application/NNN-your-new-crate   # <-- add here
```

The path MUST be the directory containing the crate's `Cargo.toml`.

### 2. `.github/workflows/rust-tests.yml` triggers

Add a glob covering the crate to **both** `on.pull_request.paths` and `on.push.paths`. The two arrays MUST stay in sync:

```yaml
on:
  pull_request:
    paths:
      - "src/500-application/503-media-capture-service/**"
      - "src/500-application/507-ai-inference/**"
      - "src/500-application/NNN-your-new-crate/**"   # <-- add here
      - "Cargo.toml"
      - ".github/workflows/rust-tests.yml"
      - "codecov.yml"
  push:
    branches: [main, dev]
    paths:
      - "src/500-application/503-media-capture-service/**"
      - "src/500-application/507-ai-inference/**"
      - "src/500-application/NNN-your-new-crate/**"   # <-- add here
      - "Cargo.toml"
      - ".github/workflows/rust-tests.yml"
      - "codecov.yml"
```

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
  - "src/500-application/501-rust-telemetry/**"
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

For a hypothetical new crate at `src/500-application/520-example-service`, the registration diff is:

```diff
 # .github/workflows/rust-tests.yml
   pull_request:
     paths:
       - "src/500-application/503-media-capture-service/**"
       - "src/500-application/507-ai-inference/**"
+      - "src/500-application/520-example-service/**"
       - "Cargo.toml"
       - ".github/workflows/rust-tests.yml"
       - "codecov.yml"
   push:
     branches: [main, dev]
     paths:
       - "src/500-application/503-media-capture-service/**"
       - "src/500-application/507-ai-inference/**"
+      - "src/500-application/520-example-service/**"
       - "Cargo.toml"
       - ".github/workflows/rust-tests.yml"
       - "codecov.yml"
   matrix:
     crate:
       - src/500-application/503-media-capture-service
       - src/500-application/507-ai-inference
       - src/500-application/507-ai-inference/ai-edge-inference-crate
+      - src/500-application/520-example-service
```

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

To opt out instead, omit both diffs above and add a single `ignore` entry to `codecov.yml`.

<!-- </rust-crate-registration-instructions> -->
