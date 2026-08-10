---
title: Request Body Secret
description: Manual prerequisite for creating the Kubernetes Secret that supplies the Akri HTTP POST Connector's request.bodySecretAlias content
author: Edge AI Team
ms.date: 2026-08-04
ms.topic: how-to
keywords:
  - rust
  - azure iot operations
  - akri connector
  - http post
  - kubernetes secrets
estimated_reading_time: 4
---

## Request Body Secret

The connector's dataset configuration contract does not accept an inline request body.
`request.bodySecretAlias` names a secret that the connector resolves at runtime, reading it from
the Akri operator's connector-template secrets mount using only local file reads (no Kubernetes API
client, and no additional RBAC grant beyond what the Akri operator already requires).

Secrets are registered once, in the `secrets` list on the **connector template**
(`custom_akri_connectors[].secrets`), not on the individual asset or dataset; the Azure IoT
Operations asset schema has no secrets field of its own. Every asset and dataset served by that
connector template shares the same `secrets` list, but each entry has its own `secret_alias`, so
multiple assets can reference distinct secrets by adding one list entry per alias and pointing each
dataset's `request.bodySecretAlias` at the alias it needs. See
[Adding multiple secrets for multiple assets](#adding-multiple-secrets-for-multiple-assets).

> **Temporary workaround, not permanent design**: This manual `kubectl create secret generic` step
> exists only because Azure Resource Manager (ARM) enforces a 512-character limit on
> `datasetConfiguration`, which is too small to hold a request body directly. It is not a
> general-purpose secret-management feature of this connector. See
> [WI-10 in the planning log](../../../.copilot-tracking/plans/logs/2026-08-03/akri-rust-rest-post-connector-log.md)
> for the follow-on work item to replace this workaround once a first-class solution exists.

## Creating the secret

Create a Kubernetes Secret in the same namespace as the Azure IoT Operations instance
(`azure-iot-operations` by default), with a data key holding the exact request body bytes:

```bash
kubectl create secret generic http-post-field-selection-body \
  --namespace azure-iot-operations \
  --from-literal=body='{"field_ids": ["temp-celsius-01", "humidity-pct-01"]}'
```

For a request body too large for a single `--from-literal` argument, write it to a file first and
use `--from-file` instead, naming the data key explicitly so it matches `secret_key` in the
Terraform `secrets` entry (`body` in the example below):

```bash
kubectl create secret generic http-post-field-selection-body \
  --namespace azure-iot-operations \
  --from-file=body=./long-field-selection-request.json
```

## Wiring the secret into the connector template

Reference the secret from the `secrets` list on the connector's `custom_akri_connectors` entry, and
reference its `secret_alias` from the dataset's `request.bodySecretAlias`:

```hcl
custom_akri_connectors = [
  {
    name                          = "akri-http-post-connector"
    type                          = "custom"
    custom_endpoint_type          = "EdgeAi.HttpPost"
    custom_endpoint_version       = "1.0"
    custom_image_name             = "<acr_name>.azurecr.io/akri-http-post-connector"
    custom_connector_metadata_ref = "<acr_name>.azurecr.io/akri-http-post-connector-metadata:<metadata_tag>"
    registry                      = "<acr_name>.azurecr.io"
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

```json
{
  "schemaVersion": 2,
  "request": {
    "bodySecretAlias": "field-selection-body",
    "contentType": "application/json"
  },
  "samplingIntervalMs": 15000
}
```

`secret_alias` must match the value dataset configurations reference through
`request.bodySecretAlias`; it must contain only `[A-Za-z0-9_.-]` characters and be at most 253
characters, matching the Kubernetes object-name convention. `secret_ref` is the Kubernetes Secret's
name; `secret_key` is the data key within that secret holding the request body content.

## Adding multiple secrets for multiple assets

Add one `secrets` list entry per alias to register additional request bodies for other assets or
datasets served by the same connector; each dataset then names the alias it needs through
`request.bodySecretAlias`. Aliases must be unique within the list, but multiple entries can
reference the same `secret_ref` with different `secret_key` values if the bodies live in one
Kubernetes Secret's data.

```hcl
secrets = [
  {
    secret_alias = "field-selection-body"
    secret_key   = "body"
    secret_ref   = "http-post-field-selection-body"
  },
  {
    secret_alias = "pump-station-body"
    secret_key   = "body"
    secret_ref   = "http-post-pump-station-body"
  }
]
```

```json
{
  "schemaVersion": 2,
  "request": {
    "bodySecretAlias": "pump-station-body",
    "contentType": "application/json"
  },
  "samplingIntervalMs": 15000
}
```

Adding, removing, or renaming an alias requires updating the connector template's `secrets` list
(a Terraform/ARM change); only the dataset's `request.bodySecretAlias` value differs per asset, so
no code or image change is required to onboard another asset that reuses an existing alias.

See
[`akri-http-post-connector-assets.tfvars.example`](../../../blueprints/full-multi-node-cluster/terraform/akri-http-post-connector-assets.tfvars.example)
for the full working example this page describes.
