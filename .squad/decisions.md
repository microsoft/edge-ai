# Decisions

> Team decisions that all agents must respect. Append-only — never edit existing entries.

### 2025-07-16: Repository analysis — architecture direction for Leak Detection Accelerator

**By:** Dallas (Lead)

**What:** After exhaustive analysis of the Edge AI repository (30+ components, 11 application services, 16+ infrastructure modules, blueprints), the following architecture direction was established:

1. Adopt the existing SSE connector (509) as the primary leak event source — ALERT_DLQC events already defined
2. Implement 511-teams-notification using the 501 AIO SDK pattern (Rust, MqttConnectionSettingsBuilder → Session → telemetry::Receiver)
3. Wire 507-ai-inference for leak detection models (dual-backend ONNX/Candle)
4. Use 503-media-capture-service for evidence capture triggered by ALERT_DLQC MQTT events
5. Reuse 130-messaging dataflows for edge-to-cloud transport (EventHub and EventGrid)
6. Create a dedicated leak-detection blueprint composing the relevant subset of components

**Why:** ~80% of infrastructure already exists. The SSE connector's ALERT_DLQC event type proves this use case was anticipated. 511-teams-notification scaffold is the single largest gap.

**Delegation:** Parker → 511 service, Ripley → Blueprint/IaC, Lambert → Test plan

**Status:** PROPOSED

---

### 2025-07-16: Formal design proposal for Leak Detection Accelerator

**By:** Dallas (Lead)

**What:** Produced a 12-section design proposal at `.ai-team/agents/dallas/design-proposal.md` specifying: full architecture with data flow diagrams, detailed 511-teams-notification design (Rust code samples, Adaptive Card format, dedup/rate-limiting, health endpoints), reuse plan for 5 existing components, ALERT_DLQC canonical event schema (18 fields), MQTT topic architecture, leak detection Terraform blueprint composition, asset definitions, security/observability patterns, three-phase implementation plan with delegation matrix, risk register (9 risks), and end-to-end verification guide.

**Why:** Parker, Ripley, and Lambert need a concrete, actionable specification to begin parallel implementation. Eliminates ambiguity with exact schemas, code patterns, file paths, and acceptance criteria.

**Status:** PROPOSED

---

### 2026-02-16: 511-teams-notification implementation

**By:** Parker (App Dev)

**What:** Implemented the complete 511-teams-notification Rust microservice. Used raw `tokio::net::TcpListener` for health endpoints instead of axum. Dedup key is `(camera_id, event_id)` tuple instead of `event_id` alone. No `azure_iot_operations_services` crate needed. Removed `futures`, `async-trait`, `chrono`, `uuid` deps from design proposal since they aren't used.

**Why:** Axum adds unnecessary binary size and dependency surface for two trivial HTTP routes. Composite dedup key prevents cross-camera event_id collisions. Unused dependencies violate minimal dependency conventions.

**Status:** PROPOSED

---

### 2025-07-17: Created leak-detection Terraform blueprint

**By:** Ripley (Infra Dev)

**What:** Created a complete Terraform blueprint at `blueprints/leak-detection/terraform/` composing 14 existing component modules into a deployment-ready stamp. Files: versions.tf, main.tf, variables.tf, outputs.tf, leak-detection-assets.tfvars.example, README.md. Modules: resource_group, networking, security_identity, observability, data, messaging, vm_host, acr, cncf_cluster, arc_extensions, iot_ops, assets, edge_observability, edge_messaging. Excluded: AKS, AzureML, AI Foundry, Fabric.

**Why:** Design proposal §3.4 specifies a leak detection blueprint reusing existing IaC. SSE connector always enabled (hardcoded). EventGrid dataflows disabled — only EventHub routes telemetry to cloud.

**Status:** PROPOSED

---

### 2025-07-16: DLQ policy — DROP rate-limited alerts

**By:** Dallas (resolving Lambert's test-plan question)

**What:** Rate-limited alerts are silently dropped. No dead-letter queue (DLQ) or persistence layer is required. The current `TeamsError::RateLimited` return path in `send_card()` is the intended behavior.

**Why:** Carlos directed "drop" when presented with the DLQ question. The leak-detection notification service is advisory — missed alerts are acceptable given the token-bucket rate limiter refills within 60 s. Adding a DLQ would increase infrastructure cost and complexity without meaningful safety benefit for this use case.

**Status:** ACCEPTED

---

### 2025-07-17: Lambert test plan for leak detection accelerator

**By:** Lambert (Tester)

**What:** Comprehensive test plan created covering 511-teams-notification Rust service and leak-detection Terraform blueprint. 124 test cases across unit tests, integration tests, Terraform validation, security, performance, and acceptance criteria.

**Artifacts:** `.ai-team/agents/dallas/test-plan.md`

**Embedded decisions:**
1. Rate limiter drop behavior documented as PERF-03 — validates current drop behavior as intended, not a defect.
2. Integration test stack uses docker-compose — local mosquitto + mock webhook for reproducible E2E testing.
3. Terraform tests restricted to plan-only — per project conventions.

**Open questions resolved:** DLQ question answered by Dallas (DROP policy, see above).

**Status:** PROPOSED

---

### 2026-02-17: 509 SSE Connector retained — complementary to 508 Media Connector

**By:** Dallas (Lead)

**What:** After architecture review, the 509-sse-connector is confirmed as a required component. SSE and Media are separate AIO portal connector types serving different data types:

* **509-sse-connector** uses `Microsoft.SSE` endpoint type for structured JSON event data (ALERT_DLQC with 18+ fields: confidence, flow rate, mass, location, weather)
* **508-media-connector** uses the Media connector type for RTSP binary data (snapshots, video clips, camera streams)

These are two of five distinct AIO connector types (ONVIF, Media, HTTP/REST, SSE, MQTT) and cannot substitute for each other. The leak detection pipeline requires both: SSE for event ingestion and Media for evidence capture.

**Why:** There was a question about whether 509 duplicated the purpose of 508. Analysis of the AIO connector framework and the data types involved shows they are complementary. ALERT_DLQC events are structured JSON — SSE is the correct ingestion protocol. RTSP binary streams cannot carry structured event metadata, and SSE cannot carry binary video data.

**Impact:** No changes required. 509 remains in the architecture, blueprint, and design proposal as originally specified. Design proposal §3.1.1 updated with a "Protocol distinction" paragraph documenting this rationale.

**Status:** PROPOSED

---

### 2026-02-17: 511-teams-notification replaced with Azure Logic App

**By:** Dallas (Lead)

**What:** The `511-teams-notification` Rust microservice is replaced by an Azure Logic App (Consumption or Standard) running in the cloud. The Logic App is triggered by Event Hub (which already receives ALERT_DLQC events via the 130-messaging dataflow) and posts Adaptive Cards to Microsoft Teams via Incoming Webhook.

**Why:** The 130-messaging dataflow already routes ALERT_DLQC events from the edge MQTT broker to Event Hub. A cloud-side Logic App subscribes to that Event Hub — no new edge-to-cloud plumbing is needed. Benefits:

* No edge container to build, deploy, or maintain (eliminates Rust build pipeline, Dockerfile, Helm chart, ACR image)
* Built-in retry and error handling via Logic App retry policies
* Native Teams connector with webhook support
* Azure Monitor integration (run history, diagnostic logs, alerts out of the box)
* Managed identity authentication to Event Hub and Key Vault
* Simpler operational model — fewer moving parts on the edge

**Architecture changes:**

* Design proposal updated to Revision 2 (all 12 sections modified)
* Edge fan-out reduced from 3 to 2 subscribers (503-media-capture and 130-messaging only)
* §3.2 rewritten from Rust microservice design (~350 lines) to Logic App workflow design (~120 lines)
* MQTT topic hierarchy: `notifications/` tree removed
* Security: Logic App system-assigned managed identity replaces edge SAT-based auth; two new RBAC roles added (Event Hubs Data Receiver, Key Vault Secrets User)
* Observability: edge OTel spans for 511 removed; replaced with Azure Monitor / Logic App run history
* Implementation plan Phase 1: 13 Parker Rust tasks replaced with 8 Ripley IaC tasks
* Delegation: Logic App work assigned to Ripley (IaC), not Parker (App Dev)

**Disposition of `src/500-application/511-teams-notification/`:** The existing directory and implemented Rust service are retained but no longer part of the architecture. No blueprint module references it. Disposition deferred to Carlos.

**Status:** PROPOSED

---

### 2025-07-25: Logic App notification component created at 045-notification

**By:** Ripley
**What:** Created src/000-cloud/045-notification/terraform/ with 6 files (main.tf, variables.core.tf, variables.deps.tf, variables.tf, outputs.tf, versions.tf) plus CI config. Updated leak-detection blueprint (main.tf, variables.tf, outputs.tf) to include cloud_notification module.
**Why:** Implements §3.2 of the design proposal — Azure Logic App for Teams leak detection notifications, replacing the previously planned 511 Rust service. Logic App uses SystemAssigned managed identity with Event Hubs Data Receiver and Key Vault Secrets User roles.

---

### 2025-07-25: 507-ai-inference automation gaps identified

**By:** Parker (Edge Developer)

**What:** Deep analysis of `src/500-application/507-ai-inference/` revealed the service is fully implemented (dual ONNX/Candle backends, AIO SDK integration, Kustomize manifests, deploy script) but not wired into the leak-detection blueprint or any automated deployment path. The `industrial-safety.yaml` model config includes `"leak"` as a class label, confirming alignment with leak detection.

**Gaps identified:**

1. Blueprint integration — 507 not referenced in `blueprints/leak-detection/terraform/main.tf` (High)
2. Helm vs Kustomize inconsistency — 507 is the only app using Kustomize; recommend conversion to Helm (Medium)
3. Health probes disabled in `deployment.yaml` — commented out for debugging (High)
4. Base image modernization — CBL-Mariner 2.0 should migrate to Azure Linux 3.0 (Medium)
5. Model provisioning not automated (Medium)
6. Hardcoded ACR references (Low)

**Delegation:** Blueprint integration → Ripley (High), Helm chart conversion → Parker (Medium), Health probes → Parker (High), Base image migration → Parker (Medium), Model provisioning → Ripley + Parker (Medium), ACR parameterization → Parker (Low).

**Status:** PROPOSED

---

### 2025-07-25: 507 AI inference edge deployment automation — Hybrid approach recommended

**By:** Dallas (Lead Architect)

**What:** The leak-detection blueprint deploys 15 Terraform modules but stops short of deploying the 507 AI inference workload. A "last mile" gap exists between Terraform-provisioned infrastructure and the running application. Evaluated 4 options:

- **Option A (CI/CD Pipeline):** Build/push/deploy via pipeline after `terraform apply`. Clean separation but requires pipeline infrastructure.
- **Option B (Terraform local-exec):** `terraform_data` with `local-exec` runs build/push/deploy during apply. Single command but slow and fragile.
- **Option C (Arc GitOps/Flux):** `azurerm_kubernetes_flux_configuration` for declarative sync. Self-healing but heavyweight and still needs separate build/push.
- **Option D (Hybrid — Recommended):** CI/CD pipeline handles Docker build and ACR push. Blueprint Terraform adds a `terraform_data` provisioner for Kustomize deploy via Arc proxy, reusing the existing `apply-scripts` pattern.

**Key technical details:** Private ACR pull already wired via AIO registry endpoints. Arc proxy for kubectl access solved in `init-scripts.sh`. Blueprint gains `should_deploy_ai_inference` feature flag (default: `false`).

**Status:** PROPOSED

---

### 2025-07-25: Infrastructure analysis for 507 application deployment

**By:** Ripley (Infra Dev)

**What:** Comprehensive infrastructure analysis for deploying leak detection containers to the edge K3s cluster. Covered 7 areas: dependency chain (14 modules), ACR configuration (Premium SKU, private endpoints, SystemAssignedManagedIdentity auth), Key Vault access (RBAC + Secret Sync Extension), networking (single VNet, private DNS zones), existing build/push patterns (all standalone bash scripts), Terraform execution patterns (`terraform_data`/`local-exec` and `helm_release`), and CI/CD patterns (Kalypso/Flux GitOps).

**Decisions proposed:**

- D1: Use `terraform_data` + `local-exec` for image build/push (follows `apply-scripts` pattern)
- D2: Use `helm_release` for edge Helm deployments (follows `arc-agents` pattern)
- D3: Set `should_include_acr_registry_endpoint = true` for leak detection (required for custom image pulls)
- D4: Existing secret sync mechanism is sufficient — no additional IaC needed
- D5: Document private ACR network prerequisites for Terraform executor

**Status:** PROPOSED

---

### 2026-02-19: ACR and Dockerfile Deployment Challenges

**By:** Carlos Sardo (user directive)

**What:** ACR public network access required for `az acr build` workflows. When using `az acr build` (server-side builds), the ACR must have public network access enabled. The leak-detection blueprint defaults `acr_public_network_access_enabled=false` (secure-by-default). The Microsoft-hosted ACR Build agent runs outside the VNet and cannot reach a private-only ACR endpoint. The deploy used `-var 'acr_public_network_access_enabled=true'` to unblock.

Additionally, the 507-ai-inference Dockerfile cross-compilation scaffolding was removed for ACR Build compatibility. The `FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx` stage and related directives were removed. ACR Build's dependency scanner cannot parse `--platform=$BUILDPLATFORM` variable syntax in FROM lines (it performs static analysis, not runtime evaluation). The cross-compilation scaffolding was for future multi-architecture support but is not functionally needed for ACR Build on amd64.

**Why:** ACR Build limitation and static analysis constraint. Removing it enables ACR Build compatibility with no functional impact.

**Status:** PROPOSED

---

### 2026-02-19: Switch from ACR Build to local Docker builds + push

**By:** Parker (Edge Developer)

**What:** Replaced `az acr build` (server-side) workflow with a two-stage local approach: (1) `build-app-images-local.sh` builds all 3 edge application Docker images locally via `docker build` targeting `linux/amd64`, and (2) `build-app-images.sh` (modified) tags and pushes pre-built local images to ACR via `docker tag` + `docker push`. Image names unchanged: `sse-server`, `ai-edge-inference`, `media-capture-service`.

ACR Build has constrained server-side environment. The 503-media-capture-service image compiles FFmpeg, OpenCV, and Rust — a build that takes ~30 minutes and exceeds ACR Build's resource limits, causing layer eviction (503 errors). Local builds use the developer's own compute and have no such constraints.

**Impact:** Terraform has no structural changes. `build-app-images.sh` is still invoked by Terraform's `local-exec`; it now only pushes (faster, no build). CI/CD pipeline runners must have Docker available. The local build script is self-contained.

**Status:** PROPOSED

---

### 2026-02-19: E2E Edge Application Deployment — Consolidated Findings

**By:** Dallas (Lead), consolidating team work

**What:** Consolidated record of all fixes and findings from the E2E deployment of leak detection edge applications (503-media-capture-service, 507-ai-inference, 509-sse-connector) to an Arc-connected K3s cluster running Azure IoT Operations.

**Fixes applied:** (1) init-scripts.sh unbound variable crash — added default empty strings, (2) Missing kustomization.yaml for 509-sse-connector — created the file, (3) Arc proxy connection drops (operationally fragile), (4) gen-patch.sh ACR name extraction bug — corrected logic, (5) ACR 401 Unauthorized (ImagePullBackOff) — enabled anonymous pull, (6) Wrong ACR URL in patch files — corrected reference, (7) PVC StorageClass mismatch — used cloud-backed-sc, (8) ai-edge-inference CrashLoopBackOff (model file missing) — changed init container to curlimages/curl and fixed paths, (9) ACR Build resource limits exceeded — see Parker's local Docker builds decision.

**Lessons learned:** Use `${VAR:-}` defaults in `set -u` scripts; validate Kustomize directories; init containers must match workload; ACR image references are a multi-point failure requiring single source of truth; StorageClass names vary by cluster; Arc proxy requires monitoring; server-side builds have hard limits; model provisioning needs first-class automation.

**Status:** ACCEPTED

---

### 2026-02-20: 507-ai-inference Automation Gaps Identified

**By:** Parker (Edge Developer)

**What:** Deep technical analysis of `src/500-application/507-ai-inference/` revealed the service is fully implemented (dual ONNX/Candle backends, AIO SDK integration, Kustomize manifests, deploy script) but not wired into the leak-detection blueprint or any automated deployment path. The `industrial-safety.yaml` model config includes `"leak"` as a class label, confirming alignment with leak detection.

**Gaps identified:**

1. Blueprint integration — 507 not referenced in `blueprints/leak-detection/terraform/main.tf` (High priority)
2. Helm vs Kustomize inconsistency — 507 is the only app using Kustomize; recommend conversion to Helm (Medium)
3. Health probes disabled in `deployment.yaml` — commented out for debugging (High)
4. Base image modernization — CBL-Mariner 2.0 should migrate to Azure Linux 3.0 (Medium)
5. Model provisioning not automated (Medium)
6. Hardcoded ACR references (Low)

**Delegation:** Blueprint integration → Ripley (High), Helm chart conversion → Parker (Medium), Health probes → Parker (High), Base image migration → Parker (Medium), Model provisioning → Ripley + Parker (Medium), ACR parameterization → Parker (Low).

**Status:** PROPOSED

---

### 2026-02-20: 507 AI Inference Edge Deployment Automation — Hybrid approach recommended

**By:** Dallas (Lead Architect)

**What:** The leak-detection blueprint deploys 15 Terraform modules but stops short of deploying the 507 AI inference workload. Evaluated 4 options: (A) CI/CD Pipeline, (B) Terraform local-exec, (C) Arc GitOps/Flux, (D) Hybrid (CI/CD build + Terraform deploy).

**Recommendation:** Option D (Hybrid) — CI/CD pipeline handles Docker build and ACR push. Blueprint Terraform adds a `terraform_data` provisioner for Kustomize deploy via Arc proxy, reusing the existing `apply-scripts` pattern. The blueprint gains a `should_deploy_ai_inference` feature flag (default: `false`), variables for `ai_inference_image_tag` and `ai_inference_acr_name`, a deploy module that sources `init-scripts.sh`, generates Kustomize patches with correct ACR/image, and runs `kubectl apply -k`. The `should_include_acr_registry_endpoint` defaults to `true` when `should_deploy_ai_inference` is `true`.

**Key technical details:** Private ACR pull already wired via AIO registry endpoints. Arc proxy for kubectl access solved in `init-scripts.sh`. Blueprint gains feature flag.

**Status:** PROPOSED

---

### 2026-02-20: Migrate 045-notification to Teams API Connection

**By:** Ripley (Infra Dev)

**Requested by:** Carlos Sardo

**What:** Updated the `045-notification` Azure Logic App component to use Teams API Connection (OAuth connector) instead of Key Vault + HTTP webhook approach, implementing the exported logic-app-notification-code.json provided by Carlos.

**Changes:**
- Replaced `azapi_resource.keyvault_connection` with `azapi_resource.teams_connection`
- Teams connection uses OAuth (no parameterValueSet), requires user consent post-deployment
- Updated Logic App workflow definition to reference `teams` instead of `keyvault`
- Changed recurrence from `frequency = "Minute", interval = 1` to `frequency = "Second", interval = 5`
- Removed severity calculation and Key Vault retrieval actions
- Added direct Teams message posting via `teams_post_message` action
- Removed Key Vault RBAC assignment; retained Event Hubs Data Receiver
- Removed `variable "key_vault"` from `variables.deps.tf`
- Removed `variable "teams_webhook_secret_name"` from `variables.tf`
- Added `variable "teams_recipient_id"` (required) and `variable "teams_post_location"` (default: `"Group chat"`)
- Updated CI config with mock `teams_recipient_id = "19:mock-thread-id@thread.v2"`
- Updated blueprint with new variables

**Why:** Simpler architecture eliminates Key Vault dependency for notification workflow. OAuth security replaces webhook secrets. Faster polling (5 seconds vs 1 minute) enables near-real-time notifications. Proven pattern exported from working Azure Portal deployment.

**Implementation notes:** Teams connection requires OAuth consent after Terraform deployment. Teams recipient ID format: `19:xxxxx@thread.v2` (Teams thread ID). Logic App expressions preserved as literal strings in jsonencode.

**Files modified:** src/000-cloud/045-notification/terraform/{main.tf, variables.deps.tf, variables.tf}, src/000-cloud/045-notification/ci/terraform/main.tf, blueprints/leak-detection/terraform/{main.tf, variables.tf}.

**Status:** ACCEPTED — Validated via end-to-end deployment and test

---

### 2026-02-23: 045-notification end-to-end deployment validated

**By:** Ripley (Infra Dev), validated by Carlos Sardo

**What:** The 045-notification Logic App component was deployed to Azure subscription `casard-juniper-crew-shared-internal` using Terraform (azurerm v4.61.0, azapi v2.8.0). All 9 resources were successfully provisioned and imported into state. The full event pipeline was validated end-to-end.

**Deployment details:**
- Resource group: `rg-fullleakdet-dev-001` (eastus2)
- Logic App: `la-fullleakdet-leak-notify-dev-001` with SystemAssigned managed identity
- EventHub API Connection: `apicon-evhub-fullleakdet-dev-001` (Managed Identity auth, status: Ready)
- Teams API Connection: `apicon-teams-fullleakdet-dev-001` (OAuth, status: Connected)
- RBAC: Azure Event Hubs Data Receiver assigned to Logic App identity on namespace

**Post-deployment steps validated:**
1. EventHub connection authorized via "Logic Apps Managed Identity" in Azure Portal
2. Teams connection authorized via OAuth user consent in Azure Portal
3. Test event sent to `evh-aio-sample` on namespace `evhns-fullleakdet-aio-dev-001` using Python SDK (`azure-eventhub` + `DefaultAzureCredential`)
4. Logic App run confirmed Succeeded (trigger: `When_events_are_available_in_Event_Hub`, 2026-02-23T12:13:22Z)

**Lesson learned:** `az eventhubs eventhub send-event` CLI command does not exist. Event Hub namespaces with `disableLocalAuth=true` reject connection-string-based sends. Use Python SDK with `DefaultAzureCredential` and ensure the sender has "Azure Event Hubs Data Sender" RBAC role.

**Status:** ACCEPTED
