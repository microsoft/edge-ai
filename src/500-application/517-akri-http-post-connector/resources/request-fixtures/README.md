---
title: Akri HTTP POST Connector Request Fixtures
description: Sample POST request-body fixtures for the Akri HTTP POST Connector, including a fixture exceeding 10,000 characters
author: Edge AI Team
ms.date: 2026-08-04
ms.topic: reference
keywords:
  - rust
  - azure iot operations
  - akri connector
  - http post
  - fixtures
estimated_reading_time: 3
---

## Akri HTTP POST Connector Request Fixtures

This directory contains sample JSON request bodies that a `namespaced_assets` dataset's
`dataset_configuration.request.body` field can carry. These fixtures exercise the byte-fidelity
proof gate required before version 1.0 POST support can be claimed: the encoded body must reach the
connector runtime unchanged after ARM projection and Akri allocation.

## Fixtures

### `long-field-selection-request.json`

A `field_ids` selection request whose encoded JSON body is longer than 10,000 characters,
representative of a dataset query that exceeds the practical 2,000-character URI length limit.

| Property                                             | Value                                                              |
|------------------------------------------------------|--------------------------------------------------------------------|
| File byte length (including trailing newline)        | 10516                                                              |
| File SHA-256                                         | `ee54e1fb745aa8cfa706d1de7a3e518be31c61bfa7eaaf805c8d4b99cb3bab9b` |
| Body byte length (file content, no trailing newline) | 10515                                                              |
| Body SHA-256 (no trailing newline)                   | `82c7cc2c586e840e4bff75c43fecf30f9113709e91cf0235b7b3fa13b0448051` |

The "body" values are the ones that matter for the fidelity proof: the connector receives exactly
the file content without a trailing newline when the file is embedded as a `request.body` string
(for example through `jsonencode(file(...))` in Terraform or `loadTextContent()` in Bicep).

These values were computed with:

```bash
python3 - <<'EOF'
import hashlib

path = "src/500-application/517-akri-http-post-connector/resources/request-fixtures/long-field-selection-request.json"
with open(path, "rb") as f:
    file_bytes = f.read()

body_bytes = file_bytes.rstrip(b"\n")

print("file_bytes_length:", len(file_bytes))
print("file_sha256:", hashlib.sha256(file_bytes).hexdigest())
print("body_bytes_length (no trailing newline):", len(body_bytes))
print("body_sha256 (no trailing newline):", hashlib.sha256(body_bytes).hexdigest())
EOF
```

Re-run this command after editing the fixture and update the table above; do not hand-calculate the
hash or length.

## Using a Fixture in the Byte-Fidelity Proof

1. Deploy the connector template, namespaced device, and namespaced asset with a dataset
   `dataset_configuration` whose `request.body` embeds this fixture's content (see
   [akri-http-post-connector-assets.tfvars.example](../../../../../blueprints/full-multi-node-cluster/terraform/akri-http-post-connector-assets.tfvars.example)).
2. Confirm Akri allocates the connector and the runtime observes the projected dataset
   configuration.
3. Capture the body the connector actually sends and compare its SHA-256 hash against the recorded
   `body_sha256` value above. A mismatch is a proof-gate failure and blocks claiming POST support.
