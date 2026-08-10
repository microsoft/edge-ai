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

This component provides the Rust connector crate, its container image, the connector metadata
contract, and ARM-based sample inputs; see [Building and Publishing](#building-and-publishing) for
the end-to-end steps that take the crate from source to a deployable Akri connector template.

## Contract and Scope (v1.0)

The connector publishes its endpoint type as `EdgeAi.HttpPost`, version `1.0`. This namespace was
selected deliberately to avoid the `Microsoft.` prefix, because a repository-owned connector must not
imply Microsoft publisher ownership.

Version 1.0 supports:

* HTTP `POST` only; there is no configurable request method.
* Textual request bodies only, including JSON and other text-based MIME types.
* A configurable request `Content-Type`, owned by the Akri dataset configuration.
* A dataset-configuration schema version 2 contract: `request.bodySecretAlias` names a Kubernetes
  Secret resolved through the Akri operator's connector-template secrets mount, rather than an
  inline request body. See [`docs/request-body-secret.md`](docs/request-body-secret.md) for the
  manual `kubectl create secret generic` prerequisite this requires.

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

* Rust toolchain (stable channel) for building and testing the connector crate
  (`services/akri-http-post-connector`).
* Docker, for local build and test support only. Compose does **not** deploy the Akri runtime to a
  cluster; production deployment always goes through the ARM-based Terraform or Bicep components
  referenced above.
* [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az`), for authenticating to
  an Azure Container Registry (ACR).
* [ORAS CLI](https://oras.land/docs/installation), for publishing `connector-metadata.json` as an
  OCI artifact.
* A [registry endpoint](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-configure-registry-endpoint)
  on the Azure IoT Operations instance, pointing at the ACR above. Azure IoT Operations pulls the
  connector's runtime image through this registry endpoint rather than anonymously, so it must use
  an authenticated method (for example `SystemAssignedManagedIdentity` with `AcrPull` granted to the
  instance's Arc extension identity). Configure it via the `registry_endpoints` variable on
  `src/100-edge/110-iot-ops` / `blueprints/full-multi-node-cluster`, the Azure portal, or
  `az iot ops registry create`.

```bash
# Navigate to the component directory
cd src/500-application/517-akri-http-post-connector

# Local build/test support only - not a cluster deployment
docker compose build
```

## Building and Publishing

Deploying this connector to a live environment requires two artifacts in the environment's ACR: the
connector's container image and the `connector-metadata.json` OCI artifact referenced by
`custom_connector_metadata_ref`. Both are produced by scripts under `scripts/`.

### Step 1: Build and push the connector image

```bash
./scripts/build-and-push-image.sh <acr_name> [image_tag]
```

* `<acr_name>` is the ACR name without the `.azurecr.io` domain suffix (for example, `acrkd0805dev001`).
* `[image_tag]` defaults to the crate version declared in
  `services/akri-http-post-connector/Cargo.toml`.
* The script builds `services/akri-http-post-connector/Dockerfile`, authenticates via
  `az acr login`, and pushes `<acr_name>.azurecr.io/akri-http-post-connector:<image_tag>`.

### Step 2: Publish the connector metadata artifact

```bash
./scripts/publish-connector-metadata.sh <acr_name> [metadata_tag]
```

* `[metadata_tag]` also defaults to the crate version in `Cargo.toml`.
* The script authenticates via `az acr login`, then runs `oras push` from `connector-metadata/`,
  publishing `<acr_name>.azurecr.io/akri-http-post-connector-metadata:<metadata_tag>` with artifact
  type `application/vnd.microsoft.akri-connector.v1+json`.

### Step 3: Wire the connector into Terraform

Reference the published image and metadata artifact from the environment's `custom_akri_connectors`,
`namespaced_devices`, and `namespaced_assets` variables (`src/100-edge/110-iot-ops` /
`blueprints/full-multi-node-cluster`). `blueprints/full-multi-node-cluster/terraform/akri-http-post-connector-assets.tfvars.example`
demonstrates the full pattern, including the explicit `custom_connector_metadata_ref` and an
HCL-escaped JSON `dataset_configuration` string (Terraform `.tfvars` files reject `file()` and
`jsonencode()`; the JSON body must be a literal escaped string).

```hcl
custom_akri_connectors = [
  {
    name                          = "akri-http-post-connector"
    type                          = "custom"
    custom_endpoint_type          = "EdgeAi.HttpPost"
    custom_endpoint_version       = "1.0"
    custom_image_name             = "<acr_name>.azurecr.io/akri-http-post-connector"
    custom_connector_metadata_ref = "<acr_name>.azurecr.io/akri-http-post-connector-metadata:<metadata_tag>"
    registry_endpoint_ref         = "<registry_endpoint_name>"
    image_tag                     = "<image_tag>"
    secrets = [
      {
        secret_alias = "field-selection-body"
        secret_key   = "body"
        secret_ref   = "http-post-field-selection-body"
      }
    ]
  }
]
```

`registry_endpoint_ref` must name a registry endpoint (see Prerequisites) whose `host` matches the
ACR above; omitting it falls back to the `registry` field, which pulls anonymously and fails with
`ImagePullBackOff` against a private ACR.

`secrets` declares the Kubernetes Secret aliases dataset configurations reference through
`request.bodySecretAlias`; see [`docs/request-body-secret.md`](docs/request-body-secret.md) for the
manual `kubectl create secret generic` prerequisite this requires.

### Verifying byte-fidelity with the sample request fixture

`resources/request-fixtures/long-field-selection-request.json` is a 10,516-byte fixture (10,515-byte
body, excluding the trailing newline) used to prove that the request body content resolved from a
dataset's `request.bodySecretAlias` is forwarded to the target endpoint without truncation or
re-encoding. Recorded reference hashes:

| Value                | Bytes  | SHA-256                                                            |
|----------------------|--------|----------------------------------------------------------------------|
| File (incl. newline) | 10,516 | `ee54e1fb745aa8cfa706d1de7a3e518be31c61bfa7eaaf805c8d4b99cb3bab9b` |
| Body (excl. newline) | 10,515 | `82c7cc2c586e840e4bff75c43fecf30f9113709e91cf0235b7b3fa13b0448051` |

To re-verify byte-fidelity after a live deployment observes the request:

1. Extract the exact secret content referenced by the target dataset's `request.bodySecretAlias`
   (for example, `kubectl get secret <secret_ref> -o jsonpath='{.data.<secret_key>}' | base64 -d`;
   see [`docs/request-body-secret.md`](docs/request-body-secret.md) for the secret's `.tfvars`
   wiring).
2. Compute its SHA-256 and byte length.
3. Compare against the table above; matching values confirm the body reached the endpoint unmodified.

```python
import hashlib

body = open("resources/request-fixtures/long-field-selection-request.json", "rb").read().rstrip(b"\n")
print(len(body), hashlib.sha256(body).hexdigest())
```

A live simulator may still reject this fixture's synthetic `field_ids` with a non-`200` response;
that is expected and does not indicate a byte-fidelity failure, since the proof only concerns exact
receipt and parsing of the request body, not a successful sensor read.

## References

* [Use the HTTP connector](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-use-http-connector)
* [Akri services overview](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/overview-akri)
* [Develop Akri connectors](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-akri-connectors)
* [src/500-application/505-akri-rest-http-connector](../505-akri-rest-http-connector/README.md) - the
  official GET-only connector's development environment and shared sensor-simulator fixture.
