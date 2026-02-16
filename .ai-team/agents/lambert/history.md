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

