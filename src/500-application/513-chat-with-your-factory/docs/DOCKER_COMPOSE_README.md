---
title: Docker Compose Guide
description: Local development and runtime guide for Chat With Factory using Docker Compose
ms.date: 2026-05-06
ms.topic: how-to
---

## Overview

Use Docker Compose for local development and smoke testing without a Kubernetes cluster.
The compose file builds the service image from
`services/chat-with-your-factory/Dockerfile`, loads configuration from `.env`,
and exposes port `3978`.

## Prerequisites

* Docker Engine with Compose v2
* Access to the repository workspace
* A valid `.env` file in the component root

## Quick Start

From `src/500-application/513-chat-with-your-factory/` run:

```bash
docker compose up --build
```

Open the app at:

```text
http://localhost:3978
```

Stop the stack:

```bash
docker compose down
```

## Configuration

The compose service reads:

* `.env` via `env_file`
* `SERVICE_PORT` for host port mapping (defaults to `3978`)
* `REGISTRY`, `APPLICATION`, and `BUILD_ID` for image naming

Common local development defaults:

* `SKIP_AUTH=true` for standalone mode
* `AGENT_BACKEND=copilotstudio` or `foundry` based on your environment

## Common Commands

Rebuild after source changes:

```bash
docker compose up --build --force-recreate
```

View logs:

```bash
docker compose logs -f chat-with-your-factory
```

Remove containers, network, and local anonymous volumes:

```bash
docker compose down -v
```

## Troubleshooting

### Port already in use

If `3978` is in use, set another host port:

```bash
SERVICE_PORT=4078 docker compose up --build
```

### App starts but requests fail with 401

For local standalone development, confirm `.env` includes one of:

* `SKIP_AUTH=true`
* `AUTH_REQUIRED=false`

### Build fails at TypeScript or esbuild step

Ensure required files exist in the service directory:

* `tsconfig.json`
* `tsconfig.server.json`
* `src/client/index.tsx`
* `src/server/index.ts`

### Environment values not applied

Regenerate `.env` from defaults if needed:

```bash
./scripts/generate-env-config.sh
```
