---
title: Akri HTTP POST Connector Scripts
description: Non-deployment helper scripts for local validation and metadata packaging for the Akri HTTP POST Connector
author: Edge AI Team
ms.date: 2026-08-04
ms.topic: reference
keywords:
  - rust
  - azure iot operations
  - akri connector
estimated_reading_time: 2
---

## Akri HTTP POST Connector Scripts

This directory holds non-deployment helper scripts, such as local validation commands and connector
metadata packaging, added alongside the Rust service crate in a later implementation phase.

This application does not include a deployment script here; the Akri operator is the sole runtime
deployer, and deployment goes through the ARM-based Terraform/Bicep components in
`src/100-edge/110-iot-ops` and `src/100-edge/111-assets`.
