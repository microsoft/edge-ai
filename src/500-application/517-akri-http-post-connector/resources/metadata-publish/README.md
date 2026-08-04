---
title: Akri HTTP POST Connector Metadata Publishing
description: How to package and publish the connector metadata artifact as an OCI artifact
author: Edge AI Team
ms.date: 2026-08-04
ms.topic: reference
keywords:
  - rust
  - azure iot operations
  - akri connector
  - oci artifact
  - oras
estimated_reading_time: 4
---

## Akri HTTP POST Connector Metadata Publishing

The connector metadata document at
[../../connector-metadata/connector-metadata.json](../../connector-metadata/connector-metadata.json)
must be published as an independent OCI artifact so `custom_connector_metadata_ref` (Terraform) and
`customConnectorMetadataRef` (Bicep) can reference it directly, separate from the runtime container
image.

> This document is example-only. No registry credentials are available in this development
> environment, so nothing here has been published.

## Media Type

Publish the metadata artifact using the Akri connector metadata config media type:

```text
application/vnd.microsoft.akri-connector.v1+json
```

## Example: Publish with `oras`

```bash
# Install oras if not already available: https://oras.land/docs/installation
REGISTRY="example.azurecr.io"
ARTIFACT="${REGISTRY}/akri-http-post-connector-metadata:1.0.0"

oras push "${ARTIFACT}" \
  --config connector-metadata.json:application/vnd.microsoft.akri-connector.v1+json \
  --artifact-type application/vnd.microsoft.akri-connector.v1+json
```

Run this command from `src/500-application/517-akri-http-post-connector/connector-metadata/` so the
relative `connector-metadata.json` path resolves.

## Referencing the Published Artifact

Once published, pass the resulting reference as the explicit metadata reference so it takes
precedence over the internal module's derived `${registry}/${image_name}-metadata:${image_tag}`
naming convention:

```hcl
custom_connector_metadata_ref = "example.azurecr.io/akri-http-post-connector-metadata:1.0.0"
```

```bicep
customConnectorMetadataRef: 'example.azurecr.io/akri-http-post-connector-metadata:1.0.0'
```

See [../iac/README.md](../iac/README.md) for full sample Terraform and Bicep inputs.

## Versioning Guidance

* Treat the metadata artifact as an immutable version-1 contract; publish a new tag rather than
  mutating a published `1.0.0` artifact.
* Prefer digest references over mutable tags for release deployments once digest support is verified
  in the target Azure IoT Operations release; the schema itself was preview
  (`11.0-preview`) at the time this artifact was authored.
* Keep the metadata artifact's `$schema` reference and embedded `datasetConfigurationSchema` in sync
  with any runtime-side validation added to the connector crate in a later implementation phase.
