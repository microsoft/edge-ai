# ClusterFuzzLite Builder Containers

This directory configures the [ClusterFuzzLite][cflite] (CFLite) builder
containers and per-language fuzz harness build scripts for `edge-ai`.

## Architecture

CFLite expects a single `Dockerfile` and a single `build.sh` at the project
root (here, `.clusterfuzzlite/`). The `build_fuzzers` GitHub Action does not
expose a `dockerfile-path` input, so all three languages share one Dockerfile
parameterized by an `ARG LANGUAGE` build-arg that the action forwards from its
`language:` workflow input.

* `Dockerfile` — selects `gcr.io/oss-fuzz-base/base-builder-${LANGUAGE}` at
  build time. Default `LANGUAGE=rust` preserves the historical behavior.
* `build.sh` — top-level dispatcher. Inspects the `LANGUAGE` env var (also set
  by the action) and execs the matching `build_<lang>.sh`.
* `build_rust.sh` / `build_python.sh` / `build_js.sh` — per-language harness
  builders.

The base image tag is intentionally unpinned: the CFLite Action runner is
Ubuntu 20.04 (glibc 2.31), and pinning a newer tag (e.g. `:ubuntu-24-04`)
produces binaries linked against glibc >= 2.32 that fail `bad_build_check`
on the runner.

## Language toolchains

| Language     | Engine     | Build pattern                                         |
|--------------|------------|-------------------------------------------------------|
| `rust`       | cargo-fuzz | `cargo +nightly fuzz build` per harness, copy to OUT  |
| `python`     | Atheris    | `pyinstaller --onefile` + ASAN-aware bash wrapper     |
| `javascript` | Jazzer.js  | `npm ci` in the harness service + `npx jazzer` shim   |

## Adding a Python harness

1. Place the harness at `tests/fuzz/fuzz_<name>.py` inside the target service.
2. Append an entry to the `HARNESSES` array in [`build_python.sh`](./build_python.sh)
   in the form `<harness_name>:<service_dir>:<harness_rel_path>`.
3. Ensure the service ships a `requirements.txt` so transitive deps are
   installed before `pyinstaller` runs.
4. If a new top-level component number is introduced, add a matching
   `fuzz-py-<NNN>` flag to [`codecov.yml`](../codecov.yml).

## Adding a JavaScript harness

1. Place the harness at `tests/fuzz/fuzz_<name>.mjs` inside the target service.
2. Append an entry to the `HARNESSES` array in [`build_js.sh`](./build_js.sh).
3. Ensure the service has a committed `package-lock.json` so `npm ci` succeeds
   reproducibly.
4. Declare `@jazzer.js/core` in the service's `devDependencies` for local
   repro and editor IntelliSense (CFLite preinstalls it globally in the base
   image, but the manifest entry keeps repos buildable outside CFLite).

## Lint waivers

* `Dockerfile` carries a `# hadolint ignore=DL3006` directive on the
  `FROM gcr.io/oss-fuzz-base/base-builder-${LANGUAGE}` line. The base image
  tag is intentionally unpinned (see Architecture above); pinning to a
  specific Ubuntu release breaks `bad_build_check` on the CFLite runner.

## Known limitations

* The `506-ros2-connector` harness fuzzes the in-process message registry
  only (paho-mqtt + pure-Python typed accessors). Fuzzing the full ROS 2
  bridge is out of scope because `rclpy` is not installable from PyPI; that
  work would require a derived base image.
* Atheris 3.0.0 pins Python 3.11. Upgrading the CFLite base image to Ubuntu
  24.04 (issue [#454][i454]) cannot proceed without an Atheris 3.12 wheel or
  a replacement Python fuzzing engine.

[cflite]: https://google.github.io/clusterfuzzlite/
[i454]: https://github.com/microsoft/edge-ai/issues/454
