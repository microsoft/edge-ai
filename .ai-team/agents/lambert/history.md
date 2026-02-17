# History — Lambert

## Project Learnings (from import)

- **Project:** Edge AI — Leak Detection Accelerator for Oil & Gas / Energy
- **User:** Carlos Sardo (carlos.sardo@gmail.com)
- **Stack:** Terraform, Bicep, Rust, Azure IoT Operations, Azure Arc, K3s
- **Goal:** Validate the leak detection accelerator: unit tests, integration tests, edge-to-cloud flow tests, notification delivery, failure/retry.
- **Testing approach:** Rust tests (cargo test), Terraform tests (command = plan only), edge-to-cloud validation

## Learnings

📌 Team update (2025-07-17): 511-teams-notification implemented (12 files) with composite dedup key (camera_id, event_id), raw TcpListener health — decided by Parker
📌 Team update (2025-07-17): leak-detection Terraform blueprint created (14 modules, 6 files) — decided by Ripley
📌 Test plan created (2025-07-17): 124 test cases across 11 categories (56 P0, 45 P1, 23 P2) covering Rust service + Terraform blueprint → `.ai-team/agents/dallas/test-plan.md`
📌 Design deviation: rate limiter drops alerts when tokens exhausted (no queue) — PERF-03 documents this behavior
📌 Design deviation: health endpoints are /healthz and /readyz (raw TcpListener), not /health and /readiness (axum) as in design proposal
📌 Design deviation: dedup key is composite (camera_id, event_id) not single (event_id) — improves cross-camera isolation
📌 Team update (2025-07-16): DLQ policy is DROP — rate-limited alerts are silently dropped, no DLQ. Lambert's open question resolved; PERF-03 drop behavior is confirmed intended — decided by Dallas (Carlos directed)
📌 Team update (2025-07-24): 511 Rust service superseded by Azure Logic App. Test strategy needs updating: no Rust unit/integration tests for 511, replace with Logic App integration tests (Event Hub trigger → Adaptive Card delivery). 13 Parker Rust tasks → 8 Ripley IaC tasks — decided by Dallas
📌 Team update (2025-07-24): 509-sse-connector confirmed retained — complementary to 508 Media Connector. Existing test cases for 509 remain valid — decided by Dallas

