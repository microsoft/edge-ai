# History — Ripley

## Project Learnings (from import)

- **Project:** Edge AI — Leak Detection Accelerator for Oil & Gas / Energy
- **User:** Carlos Sardo (carlos.sardo@gmail.com)
- **Stack:** Terraform, Bicep, Rust, Azure IoT Operations, Azure Arc, K3s
- **Goal:** Provide IaC components and deployment artifacts for the leak detection accelerator.
- **Component structure:** Each component follows {grouping}/{000}-{component_name}/{framework}/ pattern
- **Key IaC patterns:** Cloud infra (000-cloud/), Edge infra (100-edge/), Components use decimal naming convention (010, 020, 030)
- **Blueprints:** Orchestrate multiple components, located in blueprints/ directory
## 2025-07-17: Created Leak Detection Terraform Blueprint

### What

Created the complete `blueprints/leak-detection/terraform/` blueprint with 6 files:

- **versions.tf** — Terraform >= 1.9.8 < 2.0, providers azurerm >= 4.51.0, azuread >= 3.0.2, azapi >= 2.3.0
- **main.tf** — 14 module calls orchestrating cloud and edge components with explicit dependency chain
- **variables.tf** — All relevant input parameters with complex types and validations (excluded AKS, AzureML, AI Foundry, PostgreSQL, Redis, VPN)
- **outputs.tf** — All relevant output groups including edge_messaging event_hub_dataflow
- **leak-detection-assets.tfvars.example** — SSE camera device and leak detection asset definitions per design proposal §3.3
- **README.md** — Full documentation with YAML frontmatter, module table, deployment instructions

### Key Design Decisions

- Hardcoded `should_enable_akri_sse_connector = true` — leak detection always requires SSE
- Set `should_create_eventgrid_dataflows = false` — only EventHub dataflows needed
- Set `should_create_eventhub_dataflows = true` — routes telemetry to cloud
- Omitted AKS, AzureML, AI Foundry, PostgreSQL, Redis, VPN modules — not needed for leak detection
- Based on `full-single-node-cluster` reference blueprint pattern
- 14 modules: resource_group, networking, security_identity, observability, data, messaging, vm_host, acr, cncf_cluster, arc_extensions, iot_ops, assets, edge_observability, edge_messaging

### Reference

- Design proposal: `.ai-team/agents/dallas/design-proposal.md` §3.4 (Blueprint Composition)
- Reference blueprint: `blueprints/full-single-node-cluster/terraform/`
## Learnings

📌 Team update (2025-07-17): 511-teams-notification implemented with raw TcpListener health (no axum), composite dedup key (camera_id, event_id), token-bucket rate limiter — decided by Parker
📌 Team update (2025-07-24): 511-teams-notification Rust service replaced with Azure Logic App (cloud-side). Implementation tasks changed: 13 Parker Rust tasks → 8 Ripley IaC tasks. Logic App triggered by Event Hub, posts Adaptive Cards to Teams. Ripley owns Logic App IaC — decided by Dallas
📌 Team update (2025-07-24): 509-sse-connector confirmed retained — complementary to 508 Media Connector. No blueprint changes needed — decided by Dallas

