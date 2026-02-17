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

## 2025-07-25: Created Logic App Notification Component (045-notification)

### What

Created `src/000-cloud/045-notification/terraform/` with 6 files:

- **main.tf** — Logic App workflow with SystemAssigned identity, Event Hubs Data Receiver and Key Vault Secrets User role assignments
- **variables.core.tf** — environment, resource_prefix (with regex validation), instance (default "001")
- **variables.deps.tf** — resource_group, eventhub_namespace, key_vault dependency objects
- **variables.tf** — should_assign_roles, tags, teams_webhook_secret_name optional vars
- **outputs.tf** — logic_app output (id, name, identity_principal_id)
- **versions.tf** — azurerm >= 4.51.0, azapi >= 2.3.0, terraform >= 1.9.8 < 2.0

Created CI config at `src/000-cloud/045-notification/ci/terraform/main.tf` with mock resource IDs and `should_assign_roles = false`.

Updated `blueprints/leak-detection/terraform/`:
- **main.tf** — Added `module "cloud_notification"` after `cloud_messaging`, gated by `should_create_teams_notification`
- **variables.tf** — Added `should_create_teams_notification` bool (default true)
- **outputs.tf** — Added `notification` output section with `logic_app_name` and `logic_app_id`

### Key Patterns

- Followed 040-messaging file structure and naming conventions exactly
- Logic App resource name: `la-${var.resource_prefix}-leak-notify-${var.environment}-${var.instance}`
- Infrastructure-first approach: workflow shell + identity + roles; trigger/actions configured later
- Role assignments gated by `should_assign_roles` count pattern
- Blueprint uses `should_create_teams_notification` to gate role assignments (Logic App always created for workflow presence)

