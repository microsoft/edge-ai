# History — Scribe

## Project Learnings (from import)

- **Project:** Edge AI — Leak Detection Accelerator for Oil & Gas / Energy
- **User:** Carlos Sardo (carlos.sardo@gmail.com)

## Learnings

### 2025-07-25: Logged ACR and Dockerfile deployment challenges

**Requested by:** Carlos Sardo

Carlos explicitly flagged these challenges as important to record. Created session log documenting two critical deployment issues during leak-detection blueprint edge application deployment:

1. **ACR Firewall Blocking Build Agent** — `az acr build` fails when ACR has `publicNetworkAccess: "Disabled"` because Microsoft-hosted build agents are outside the VNet. Solution: `acr_public_network_access_enabled=true`.
2. **507 Dockerfile Incompatible with ACR Build** — `FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx` causes ACR Build dependency scanner failure (static analysis, no build-arg substitution). Solution: removed cross-compilation scaffolding.

**Files created:**
- `.ai-team/log/2025-07-25-acr-dockerfile-deployment-challenges.md`
- `.ai-team/decisions/inbox/scribe-acr-dockerfile-challenges.md`

**History propagated to:** Parker (Dockerfile changes), Ripley (ACR infrastructure)

