---
title: Akri HTTP POST Connector
description: POST-only Rust Akri custom connector for Azure IoT Operations with textual request bodies and configurable request content type
author: Edge AI Team
ms.date: 2026-08-04
ms.topic: reference
keywords:
  - rust
  - azure iot operations
  - akri connector
  - http post
  - edge computing
estimated_reading_time: 8
---

## Akri HTTP POST Connector

The Akri HTTP POST Connector is a custom Azure IoT Operations Akri connector that issues HTTP `POST`
requests carrying a textual request body to endpoints that cannot be queried through a URI alone. It
complements, rather than replaces, the official built-in HTTP/REST connector, which remains the
correct choice for `GET`-based polling.

This component currently provides the connector metadata contract and ARM-based sample inputs. The
Rust service crate and container image are added in a later implementation phase; see
[Implementation Status](#implementation-status).

## Contract and Scope (v1.0)

The connector publishes its endpoint type as `EdgeAi.HttpPost`, version `1.0`. This namespace was
selected deliberately to avoid the `Microsoft.` prefix, because a repository-owned connector must not
imply Microsoft publisher ownership.

Version 1.0 supports:

* HTTP `POST` only; there is no configurable request method.
* Textual request bodies only, including JSON and other text-based MIME types.
* A configurable request `Content-Type`, owned by the Akri dataset configuration.

Version 1.0 does not support:

* HTTP `GET`. Use the official [`Microsoft.Http` connector](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-use-http-connector)
  for `GET`-based polling scenarios.
* Custom request headers.
* Binary or multipart request bodies.
* Automatic redirect following.
* Proxy discovery.
* Replay of a non-idempotent `POST` request after a failure.

## Deployment Model

The Azure IoT Operations Akri operator is the sole runtime deployer of this connector. The
connector template, namespaced device, and namespaced asset are created through the existing
`src/100-edge/110-iot-ops` and `src/100-edge/111-assets` Terraform and Bicep components, using
Azure Resource Manager (ARM) rather than `kubectl` YAML.

> **Approved exception**: Unlike other applications under `src/500-application`, this component does
> not include a Helm chart or Kubernetes desired-state manifests. A second workload controller
> deploying the same runtime would conflict with Akri's own allocation and reconciliation of
> connector instances. This exception applies only to assets that would compete with the Akri
> operator; it does not change any other application convention.

## Security Model

* Request bodies are textual only in v1.0; no binary or multipart encoding is accepted.
* The connector does not follow HTTP redirects and does not perform proxy discovery.
* The connector does not forward custom request headers in v1.0.
* Secrets are never placed in the request body; authentication and trust material come from Device
  Registry-projected credentials, following the same model as the official connector.
* A failed non-idempotent `POST` is not automatically replayed.

## Local Development Prerequisites

* Rust toolchain (stable channel) for building and testing the connector crate once it is added.
* Docker and Docker Compose, for local build and test support only. Compose does **not** deploy the
  Akri runtime to a cluster; production deployment always goes through the ARM-based Terraform or
  Bicep components referenced above.

```bash
# Navigate to the component directory
cd src/500-application/517-akri-http-post-connector

# Local build/test support only - not a cluster deployment
docker compose build
```

## Implementation Status

This directory contains the non-deployment application scaffold (environment template, ignore
rules, local Compose support), the `connector-metadata/connector-metadata.json` contract, and
application-owned Terraform/Bicep sample inputs and request fixtures under `resources/`. The Rust
service crate, container image, and CI/coverage registration are added in a later implementation
phase.

See the implementation plan and log for full status:

* [.copilot-tracking/plans/2026-08-03/akri-rust-rest-post-connector-plan.instructions.md](../../../.copilot-tracking/plans/2026-08-03/akri-rust-rest-post-connector-plan.instructions.md)
* [.copilot-tracking/plans/logs/2026-08-03/akri-rust-rest-post-connector-log.md](../../../.copilot-tracking/plans/logs/2026-08-03/akri-rust-rest-post-connector-log.md)

## References

* [Use the HTTP connector](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-use-http-connector)
* [Akri services overview](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/overview-akri)
* [Develop Akri connectors](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-akri-connectors)
* [src/500-application/505-akri-rest-http-connector](../505-akri-rest-http-connector/README.md) - the
  official GET-only connector's development environment and shared sensor-simulator fixture.
