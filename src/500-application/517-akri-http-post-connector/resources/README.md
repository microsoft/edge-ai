---
title: Akri HTTP POST Connector Resources
description: Parent directory for connector metadata publishing assets and request fixtures for the Akri HTTP POST Connector
author: Edge AI Team
ms.date: 2026-08-04
ms.topic: reference
keywords:
  - rust
  - azure iot operations
  - akri connector
estimated_reading_time: 2
---

## Akri HTTP POST Connector Resources

This directory holds assets that accompany the connector metadata artifact at
[../connector-metadata/connector-metadata.json](../connector-metadata/connector-metadata.json):

* [metadata-publish/](metadata-publish/) - Guidance for publishing the metadata artifact as an OCI
  artifact.
* [request-fixtures/](request-fixtures/) - Sample POST request bodies, including a byte-fidelity
  proof fixture longer than 10,000 characters.

A sample Terraform configuration wiring this connector's `custom_akri_connectors`, namespaced
device, and namespaced asset is provided at the blueprint level, following the pattern used by
other application components, in
[akri-http-post-connector-assets.tfvars.example](../../../../blueprints/full-multi-node-cluster/terraform/akri-http-post-connector-assets.tfvars.example).

The Rust service crate that consumes this contract is added in a later implementation phase.
