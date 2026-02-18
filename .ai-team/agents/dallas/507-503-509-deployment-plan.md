# Edge Application Deployment Plan — 509, 507, 503

**Author:** Dallas (Lead Architect)
**Date:** 2025-07-25
**Status:** PROPOSED
**Scope:** Single `terraform apply` deploys all Azure infrastructure AND builds+deploys all three edge applications (509-sse-connector, 507-ai-inference, 503-media-capture-service)

---

## 1. Architecture Decision — Grouped Deployment

**Decision:** Use two `terraform_data` resources — one for ACR image builds, one for edge cluster deployment — rather than six separate resources (one build + one deploy per app).

**Rationale:**

* The Arc proxy (`az connectedk8s proxy`) must run for any kubectl/kustomize/helm operation against the edge cluster. Starting it once for all three deployments avoids three separate proxy lifecycle management cycles (each taking 15-30s for startup, connection, cleanup).
* `init-scripts.sh` already manages the proxy lifecycle (race condition fix, cleanup on exit/interrupt, namespace creation). Reusing it once per `terraform apply` is the correct pattern.
* ACR builds are independent of the edge cluster — they run in ACR's compute. Grouping all three `az acr build` calls in a single `terraform_data` keeps the dependency chain clean: builds complete → then deploy.
* This matches the existing `apply-scripts` pattern in `110-iot-ops/terraform/modules/apply-scripts/` where a single `terraform_data` sources `init-scripts.sh` and then executes a deployment script.

**Structure:**

```text
terraform_data.acr_image_builds     →  Builds all 3 images in ACR (no proxy needed)
terraform_data.edge_app_deployment  →  Starts Arc proxy once, deploys all 3 apps, stops proxy
```

---

## 2. New Files Required

### Blueprint-level scripts (new directory)

```text
blueprints/leak-detection/scripts/
├── build-app-images.sh           # Builds 509, 507, 503 images via az acr build
└── deploy-edge-apps.sh           # Sources init-scripts.sh, deploys 509 (kubectl), 507 (kustomize), 503 (ACSA + Helm)
```

### 509-sse-connector Kubernetes manifests (new — none exist today)

```text
src/500-application/509-sse-connector/charts/
├── kustomization.yaml            # Kustomize base referencing deployment + service
├── base/
│   ├── deployment.yaml           # Deployment: sse-server, port 8080, health /health, SAT + trust-bundle volumes
│   └── service.yaml              # ClusterIP Service: port 8080 → 8080
└── gen-patch.sh                  # Generates patch-containers.yaml (ACR_NAME, IMAGE_NAME, IMAGE_VERSION, NAMESPACE)
```

**Design notes for 509 manifests:**

* Follow the same Kustomize pattern as 507 (not Helm) — simpler for a stateless single-container service
* Deployment mounts SAT token volume (`aio-internal` audience, 86400s expiry) and trust bundle ConfigMap (`azure-iot-operations-aio-ca-trust-bundle`) — same pattern as 507 and 503
* Namespace: `azure-iot-operations` (matches 507, 503, and all AIO workloads)
* The SSE server exposes port 8080 with a health endpoint at `/health` (from Dockerfile HEALTHCHECK)
* No PVC needed — 509 is stateless

### ACSA Terraform resources for 503 (new module in blueprint)

```text
blueprints/leak-detection/terraform/modules/
└── acsa-storage/
    ├── main.tf                   # azurerm_storage_container + azurerm_role_assignment + kubectl yaml
    ├── variables.tf              # storage_account_id, acsa_extension_principal_id, etc.
    └── outputs.tf                # storage_container_name
```

---

## 3. Blueprint Changes

### 3.1 `variables.tf` additions

New variables (all with defaults — no breaking change to existing deployments):

```hcl
variable "should_deploy_edge_applications" {
  type        = bool
  default     = false
  description = "Whether to build and deploy edge applications (509, 507, 503) as part of this blueprint apply"
}

variable "should_include_acr_registry_endpoint" {
  # ALREADY EXISTS, default: false
  # Must be set to true when should_deploy_edge_applications = true
}

variable "app_image_version" {
  type        = string
  default     = "latest"
  description = "Image tag for all edge application container images built during deployment"
}
```

### 3.2 `main.tf` additions

Append after the existing `module "edge_messaging"` block:

```hcl
// ── ACSA Storage for 503 ────────────────────────────────────

module "acsa_storage" {
  source = "./modules/acsa-storage"
  count  = var.should_deploy_edge_applications ? 1 : 0

  depends_on = [module.edge_arc_extensions]

  storage_account_id             = module.cloud_data.storage_account.id
  storage_account_name           = module.cloud_data.storage_account.name
  storage_account_blob_endpoint  = module.cloud_data.storage_account.primary_blob_endpoint
  acsa_extension_principal_id    = module.edge_arc_extensions.container_storage_extension_principal_id
  resource_group_name            = module.cloud_resource_group.resource_group.name
}

// ── Edge Application Builds ─────────────────────────────────

resource "terraform_data" "acr_image_builds" {
  count = var.should_deploy_edge_applications ? 1 : 0

  depends_on = [module.cloud_acr]

  triggers_replace = [var.app_image_version]

  provisioner "local-exec" {
    command     = "${path.module}/../scripts/build-app-images.sh"
    interpreter = ["bash", "-c"]
    environment = {
      TF_ACR_NAME       = module.cloud_acr.acr.name
      TF_IMAGE_VERSION  = var.app_image_version
      TF_APP_509_PATH   = "${path.module}/../../../src/500-application/509-sse-connector"
      TF_APP_507_PATH   = "${path.module}/../../../src/500-application/507-ai-inference"
      TF_APP_503_PATH   = "${path.module}/../../../src/500-application/503-media-capture-service"
    }
  }
}

// ── Edge Application Deployment ─────────────────────────────

resource "terraform_data" "edge_app_deployment" {
  count = var.should_deploy_edge_applications ? 1 : 0

  depends_on = [
    terraform_data.acr_image_builds,
    module.edge_iot_ops,
    module.acsa_storage,
  ]

  triggers_replace = [var.app_image_version]

  provisioner "local-exec" {
    command     = "source ${local.iot_ops_path}/scripts/init-scripts.sh && ${path.module}/../scripts/deploy-edge-apps.sh"
    interpreter = ["bash", "-c"]
    environment = {
      TF_CONNECTED_CLUSTER_NAME = module.edge_cncf_cluster.arc_connected_cluster.name
      TF_RESOURCE_GROUP_NAME    = module.cloud_resource_group.resource_group.name
      TF_AIO_NAMESPACE          = module.edge_iot_ops.aio_namespace
      TF_MODULE_PATH            = path.module
      TF_ACR_NAME               = module.cloud_acr.acr.name
      TF_IMAGE_VERSION          = var.app_image_version
      TF_APP_509_PATH           = "${path.module}/../../../src/500-application/509-sse-connector"
      TF_APP_507_PATH           = "${path.module}/../../../src/500-application/507-ai-inference"
      TF_APP_503_PATH           = "${path.module}/../../../src/500-application/503-media-capture-service"
      TF_STORAGE_ACCOUNT_ENDPOINT = module.cloud_data.storage_account.primary_blob_endpoint
    }
  }
}
```

### 3.3 `outputs.tf` additions

```hcl
output "edge_applications" {
  description = "Edge application deployment status."
  value = var.should_deploy_edge_applications ? {
    deployed      = true
    image_version = var.app_image_version
    applications  = ["509-sse-connector", "507-ai-inference", "503-media-capture-service"]
  } : {
    deployed      = false
    image_version = null
    applications  = []
  }
}
```

---

## 4. ACSA Storage — Terraform Resources vs. Script

**Answer: YES — use Terraform resources for role assignments and storage container. Use `terraform_data` only for the EdgeSubvolume and PVC (which have no Terraform provider).**

### What becomes native Terraform

| Resource | Terraform Type | Current Location |
|----------|---------------|------------------|
| Storage container `media` | `azurerm_storage_container` | Step 4 in `deploy-media-capture-service.sh` |
| ACSA → Storage Blob Data Owner | `azurerm_role_assignment` | Step 3 in `deploy-media-capture-service.sh` |

**Pattern references:**

* `azurerm_storage_container` — used in `030-data/modules/data-lake/main.tf` and `030-data/modules/schema-registry/main.tf`
* `azurerm_role_assignment` — used in `010-security-identity/modules/key-vault/main.tf`

### Gap: ACSA extension principal_id not exposed

The ACSA extension (`109-arc-extensions/modules/container-storage/main.tf`) has `identity { type = "SystemAssigned" }` but neither the module nor the parent component exposes `identity[0].principal_id` in outputs.

**Required changes (prerequisite):**

1. **`src/100-edge/109-arc-extensions/terraform/modules/container-storage/outputs.tf`** — Add:

    ```hcl
    output "extension_principal_id" {
      description = "The principal ID of the container storage extension's system-assigned managed identity"
      value       = azurerm_arc_kubernetes_cluster_extension.container_storage.identity[0].principal_id
    }
    ```

2. **`src/100-edge/109-arc-extensions/terraform/outputs.tf`** — Add:

    ```hcl
    output "container_storage_extension_principal_id" {
      description = "The principal ID of the Azure Container Storage extension's system-assigned managed identity."
      value       = try(module.container_storage_extension[0].extension_principal_id, null)
    }
    ```

### What stays in the deploy script (kubectl applies)

* `cloudBackedPVC.yaml` — PVC resource, no Terraform provider for in-cluster PVC creation via Arc
* `mediaEdgeSubvolume.yaml` — Custom `EdgeSubvolume` CRD, no Terraform provider

These are applied in `deploy-edge-apps.sh` via `kubectl apply` through the Arc proxy, after the Terraform-managed role assignment and storage container are already in place.

### `modules/acsa-storage/main.tf` sketch

```hcl
resource "azurerm_storage_container" "media" {
  name                 = "media"
  storage_account_id   = var.storage_account_id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "acsa_blob_data_owner" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.acsa_extension_principal_id
  principal_type       = "ServicePrincipal"
}
```

---

## 5. 509-sse-connector Kubernetes Manifests

509 currently has NO Kubernetes manifests. The following must be created:

### `base/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sse-server
  namespace: azure-iot-operations
  labels:
    app: sse-server
    component: sse-connector
    part-of: edge-ai-leak-detection
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sse-server
  template:
    metadata:
      labels:
        app: sse-server
        component: sse-connector
        part-of: edge-ai-leak-detection
    spec:
      serviceAccountName: default
      containers:
        - name: sse-server
          image: PLACEHOLDER_ACR.azurecr.io/sse-server:latest
          ports:
            - containerPort: 8080
              protocol: TCP
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 30
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "500m"
          volumeMounts:
            - name: mq-sat
              mountPath: /var/run/secrets/tokens
              readOnly: true
            - name: aio-ca-trust-bundle
              mountPath: /var/run/certs
              readOnly: true
      volumes:
        - name: mq-sat
          projected:
            sources:
              - serviceAccountToken:
                  audience: aio-internal
                  expirationSeconds: 86400
                  path: mq-sat
        - name: aio-ca-trust-bundle
          configMap:
            name: azure-iot-operations-aio-ca-trust-bundle
```

### `base/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sse-server
  namespace: azure-iot-operations
  labels:
    app: sse-server
spec:
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  selector:
    app: sse-server
```

### `kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: azure-iot-operations
resources:
  - base/deployment.yaml
  - base/service.yaml
patches:
  - path: patch-containers.yaml
    target:
      kind: Deployment
      name: sse-server
```

### `gen-patch.sh`

Same pattern as 507, generating `patch-containers.yaml` with envsubst for `ACR_NAME`, `IMAGE_NAME`, `IMAGE_VERSION`, `NAMESPACE`.

---

## 6. Dependency Chain

```text
                      ┌──────────────────┐
                      │ Cloud Foundation │
                      │ (RG, Net, KV,    │
                      │  Storage, ACR,   │
                      │  Messaging, VM)  │
                      └────────┬─────────┘
                               │
                      ┌────────▼─────────┐
                      │ Edge Foundation  │
                      │ (CNCF, Arc Ext) │
                      └───┬─────────┬────┘
                          │         │
              ┌───────────▼──┐  ┌───▼──────────────┐
              │ IoT Ops      │  │ ACSA Storage     │
              │ (edge_iot_ops│  │ (azurerm_storage │
              │  + assets +  │  │  _container +    │
              │  observ +    │  │  azurerm_role    │
              │  messaging)  │  │  _assignment)    │
              └───────┬──────┘  └───────┬──────────┘
                      │                 │
              ┌───────▼─────────────────▼──────────┐
              │      ACR Image Builds              │
              │ (terraform_data.acr_image_builds)  │
              │  509: az acr build (sse-server)    │
              │  507: az acr build (ai-inference)  │
              │  503: az acr build (media-capture) │
              └───────────────┬────────────────────┘
                              │
              ┌───────────────▼────────────────────┐
              │    Edge App Deployment             │
              │ (terraform_data.edge_app_deploy)   │
              │  1. Start Arc proxy (once)         │
              │  2. kubectl: 509 (kustomize)       │
              │  3. kubectl: 507 (kustomize)       │
              │  4. kubectl: 503 ACSA PVC+Subvol   │
              │  5. helm:    503 (media-capture)   │
              │  6. kubectl: model-downloader job  │
              │  7. Stop Arc proxy                 │
              └────────────────────────────────────┘
```

**Key ordering constraints:**

* ACR builds depend on `module.cloud_acr` (ACR must exist) — no proxy needed
* Edge deployment depends on ACR builds (images must exist in registry)
* Edge deployment depends on IoT Ops (AIO namespace, broker, custom locations must exist)
* Edge deployment depends on ACSA storage module (storage container + role assignment must be in place before PVC and EdgeSubvolume are applied)
* The model-downloader Job (507) depends on `ai-models-pvc` PVC already existing (from kustomize apply), so it runs last within the deploy script

---

## 7. `az acr build` Contexts

`az acr build` runs the Docker build inside ACR's compute, eliminating the need for `docker login` or local Docker daemon access. It also bypasses private networking restrictions (ACR has no public access in this blueprint).

### 509-sse-connector

```bash
az acr build \
  --registry "${TF_ACR_NAME}" \
  --image "sse-server:${TF_IMAGE_VERSION}" \
  --file "${TF_APP_509_PATH}/services/sse-server/Dockerfile" \
  "${TF_APP_509_PATH}/services/sse-server"
```

* **Dockerfile:** `services/sse-server/Dockerfile`
* **Build context:** `services/sse-server/` (Python app, self-contained — `requirements.txt`, `sse_server.py`, `events_simulator.py` all in same dir)

### 507-ai-inference

```bash
az acr build \
  --registry "${TF_ACR_NAME}" \
  --image "ai-edge-inference:${TF_IMAGE_VERSION}" \
  --file "${TF_APP_507_PATH}/services/ai-edge-inference/Dockerfile" \
  "${TF_APP_507_PATH}/services"
```

* **Dockerfile:** `services/ai-edge-inference/Dockerfile`
* **Build context:** `services/` (PARENT directory — required because `Dockerfile` references sibling `ai-edge-inference-crate/` for shared Rust crate in workspace)
* **Note:** The existing `deploy.sh` does `cd .. && docker build -f ai-edge-inference/Dockerfile .` which confirms the parent `services/` dir is the context

### 503-media-capture-service

```bash
az acr build \
  --registry "${TF_ACR_NAME}" \
  --image "media-capture-service:${TF_IMAGE_VERSION}" \
  --file "${TF_APP_503_PATH}/services/media-capture-service/Dockerfile" \
  "${TF_APP_503_PATH}"
```

* **Dockerfile:** `services/media-capture-service/Dockerfile`
* **Build context:** Component root (`503-media-capture-service/`) — the existing `deploy-media-capture-service.sh` does `cd "${COMPONENT_ROOT}" && docker build -f "${COMPONENT_DIR}/Dockerfile" .` where `COMPONENT_ROOT` is the 503 component root and `COMPONENT_DIR` is `services/media-capture-service`
* **Warning:** This is a HEAVY build (Azure Linux 3.0 + x264 + FFmpeg + OpenCV compiled from source). Expect 15-30 minutes on ACR compute.

---

## 8. Script Behavior Specifications

### `build-app-images.sh`

```text
Input env vars: TF_ACR_NAME, TF_IMAGE_VERSION, TF_APP_509_PATH, TF_APP_507_PATH, TF_APP_503_PATH
Behavior:
  1. Validate all env vars are set
  2. az acr build for 509 (fastest — Python, ~1-2 min)
  3. az acr build for 507 (medium — Rust multi-stage, ~5-10 min)
  4. az acr build for 503 (slowest — Rust + FFmpeg + OpenCV, ~15-30 min)
  5. Exit 0 on success, non-zero on any build failure
Notes:
  - Builds run sequentially (ACR has limited concurrent build capacity by default)
  - No Arc proxy needed — builds execute in ACR compute
  - No docker login needed — az acr build uses Azure CLI auth
```

### `deploy-edge-apps.sh`

```text
Input env vars: TF_CONNECTED_CLUSTER_NAME, TF_RESOURCE_GROUP_NAME, TF_AIO_NAMESPACE,
                TF_MODULE_PATH, TF_ACR_NAME, TF_IMAGE_VERSION,
                TF_APP_509_PATH, TF_APP_507_PATH, TF_APP_503_PATH,
                TF_STORAGE_ACCOUNT_ENDPOINT
Precondition: init-scripts.sh already sourced (Arc proxy running, KUBECONFIG set)
Behavior:
  1. Deploy 509: Generate patch (gen-patch.sh), kubectl apply -k on 509 charts/
  2. Deploy 507: Generate patch (gen-patch.sh), kubectl apply -k on 507 charts/
  3. Deploy 503 ACSA: kubectl apply cloudBackedPVC.yaml, envsubst mediaEdgeSubvolume.yaml | kubectl apply
  4. Deploy 503 Helm: helm upgrade --install media-capture-service with --set overrides
  5. Deploy 507 models: kubectl apply model-downloader-job.yaml (if not already completed)
  6. Wait for rollouts (kubectl rollout status for each deployment)
Notes:
  - Arc proxy is managed by init-scripts.sh lifecycle (cleanup on exit)
  - Helm values override image.repository, image.tag, namespace, storage endpoint
  - 503 ACSA PVC and EdgeSubvolume must be applied BEFORE Helm install (pods need the PVC)
  - Model downloader is idempotent — Job will skip if already completed
```

---

## 9. Implementation Checklist

Priority order for implementation:

1. [ ] **Expose ACSA extension principal_id** — `109-arc-extensions` outputs (prerequisite for everything else)
2. [ ] **Create 509 Kustomize manifests** — `charts/` directory with deployment, service, kustomization, gen-patch
3. [ ] **Create `modules/acsa-storage`** — Blueprint-local module for storage container + role assignment
4. [ ] **Create `build-app-images.sh`** — ACR build script for all three images
5. [ ] **Create `deploy-edge-apps.sh`** — Edge deployment script (509 kustomize, 507 kustomize, 503 ACSA + Helm, model downloader)
6. [ ] **Update `main.tf`** — Add `module.acsa_storage`, `terraform_data.acr_image_builds`, `terraform_data.edge_app_deployment`
7. [ ] **Update `variables.tf`** — Add `should_deploy_edge_applications`, `app_image_version`
8. [ ] **Update `outputs.tf`** — Add `edge_applications` output
9. [ ] **Validate** — `terraform validate` + `tflint` on blueprint and `109-arc-extensions`

---

## 10. Out of Scope (Explicit Exclusions per Request)

* **Helm migration for 507** — Stays Kustomize, no conversion
* **Model management changes** — Model downloader Job stays as-is (public GitHub URLs)
* **CI/CD pipeline integration** — This plan covers `terraform apply` only; pipeline changes are separate
* **511-teams-notification** — Replaced by Logic App (045-notification), not part of this plan
* **Air-gapped model support** — Would require ACR-hosted model artifacts; deferred
