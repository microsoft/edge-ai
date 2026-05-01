---
title: ClusterFuzzLite Polyglot Fuzzing Containers
description: Architecture, language toolchains, and troubleshooting for the polyglot ClusterFuzzLite builder image used by edge-ai fuzz harnesses (Rust, Python, JavaScript)
author: Edge AI Team
ms.date: 2026-04-30
ms.topic: how-to
keywords:
  - clusterfuzzlite
  - cflite
  - fuzzing
  - libfuzzer
  - atheris
  - jazzer.js
  - cargo-fuzz
estimated_reading_time: 8
---

This page describes the ClusterFuzzLite (CFLite) builder containers used by
the [`fuzz-pr.yml`](https://github.com/microsoft/edge-ai/blob/main/.github/workflows/fuzz-pr.yml)
workflow and how to add or troubleshoot a fuzz harness in any of the three
supported languages.

## Overview

CFLite runs each fuzz target inside a container built from a single
`Dockerfile` at the project root (`.clusterfuzzlite/Dockerfile`). The
`build_fuzzers` action does not expose a `dockerfile-path` input, so
`edge-ai` uses a polyglot pattern: one Dockerfile parameterized by an
`ARG LANGUAGE` build-arg, paired with a top-level `build.sh` dispatcher that
hands off to a per-language `build_<lang>.sh` script.

```text
language: <lang>          (workflow job input)
        |
        v
ARG LANGUAGE              (passed by the action as --build-arg)
        |
        v
FROM gcr.io/oss-fuzz-base/base-builder-${LANGUAGE}
        |
        v
build.sh   --case-->   build_rust.sh | build_python.sh | build_js.sh
```

Issue [#459](https://github.com/microsoft/edge-ai/issues/459) introduced the
polyglot pattern; the previous Rust-only scaffolding came from issue
[#150](https://github.com/microsoft/edge-ai/issues/150).

## Language toolchains

### Rust (cargo-fuzz, libFuzzer)

Driven by `build_rust.sh`. Each Cargo workspace member with a `fuzz/`
sub-crate produces one binary per harness, copied into `$OUT`.

### Python (Atheris, PyInstaller)

Driven by `build_python.sh`. Each harness is bundled with
`pyinstaller --onefile` into a self-contained executable. A short bash
wrapper sets the ASAN options expected by the fuzzing engine and execs the
PyInstaller binary.

Atheris 3.0.0 pins Python 3.11; the CFLite base image upgrade tracked in
issue [#454](https://github.com/microsoft/edge-ai/issues/454) is gated on
either an Atheris 3.12 wheel or a replacement Python fuzzing engine.

Harness `506-ros2` is excluded from the Python harness list because `rclpy`
(ROS 2 Python bindings) is not installable from PyPI; see issue
[#459](https://github.com/microsoft/edge-ai/issues/459) for the deferral
rationale.

### JavaScript (Jazzer.js)

Driven by `build_js.sh`. The harness service's npm dependencies are installed
with `npm ci` (falling back to `npm install` when no lockfile is present),
and a small wrapper invokes `npx jazzer <harness>`. `@jazzer.js/core` is
preinstalled globally inside `base-builder-javascript`.

## Adding a harness

See [`.clusterfuzzlite/README.md`](https://github.com/microsoft/edge-ai/blob/main/.clusterfuzzlite/README.md)
for the per-language step-by-step. In short:

1. Drop the harness file under `tests/fuzz/` in the target service.
2. Append the harness entry to the matching `build_<lang>.sh` HARNESSES array.
3. Add a new `fuzz-<lang>-<NNN>` flag entry in
   [`codecov.yml`](https://github.com/microsoft/edge-ai/blob/main/codecov.yml)
   if the component number is new.

## Troubleshooting

### `bad_build_check` fails with `GLIBC_2.32 not found`

The Dockerfile pinned a newer base-image tag (e.g. `:ubuntu-24-04`). The
CFLite runner is Ubuntu 20.04 / glibc 2.31. Remove the tag pin to fall back
to the default tag, which tracks the runner's glibc.

### `pyinstaller: command not found` during a Python build

`build_python.sh` installs PyInstaller on demand via `command -v pyinstaller`.
If the installation fails, `pip3 install --no-cache-dir pyinstaller` will
report the underlying error in the action log; usually a transient PyPI
outage. Re-run the workflow.

### `Cannot find module '@jazzer.js/core'` during a JS build

`@jazzer.js/core` is preinstalled globally in `base-builder-javascript`. If
the error appears at fuzz time (not build time), confirm the harness service
declares `@jazzer.js/core` in `devDependencies` and that `npm ci` ran
successfully (check the build log for an `EUSAGE` lockfile-mismatch error).

### Workflow job stays skipped after enabling the gate

`fuzz-python` and `fuzz-js` only run when the change-detection job emits a
non-empty `changedFuzz<Lang>Folders` matrix. Touch a file under the relevant
component (e.g. any file under `src/500-application/513-*/`) and re-push.

### `LANGUAGE` env-var ignored locally

Local repro of `build.sh` defaults to `rust`. Export the env var explicitly:

```bash
LANGUAGE=python bash .clusterfuzzlite/build.sh
```
