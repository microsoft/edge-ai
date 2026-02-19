# Decision: Switch from ACR Build to local Docker builds + push

**By:** Parker (Edge Developer)
**Date:** 2026-02-19

## What

Replaced `az acr build` (server-side) workflow with a two-stage local approach:

1. **`build-app-images-local.sh`** — builds all 3 edge application Docker images locally via `docker build` targeting `linux/amd64`
2. **`build-app-images.sh`** (modified) — tags and pushes pre-built local images to ACR via `docker tag` + `docker push`

Image names unchanged: `sse-server`, `ai-edge-inference`, `media-capture-service`.

## Why

ACR Build has a constrained server-side environment. The 503-media-capture-service image compiles FFmpeg, OpenCV, and Rust — a build that takes ~30 minutes and exceeds ACR Build's resource limits, causing layer eviction (503 errors). Local builds use the developer's own compute and have no such constraints.

## Impact

- **Terraform:** No structural changes. `build-app-images.sh` is still invoked by Terraform's `local-exec`; it now only pushes (faster, no build).
- **CI/CD:** Pipeline runners must have Docker available and enough disk/memory for local builds. The local build script is self-contained (derives paths from its own location).
- **Developer workflow:** Developers run `build-app-images-local.sh` once (or when code changes), then Terraform handles push on apply.
- **Environment variables:** `TF_APP_*_PATH` vars are no longer validated by the push script. `TF_ACR_NAME` and `TF_IMAGE_VERSION` remain required for push. `TF_IMAGE_VERSION` defaults to `latest` for local builds.

## Status

PROPOSED
