---
title: Helm Chart Guide
description: Deployment and operations guide for Chat With Factory Helm chart in Kubernetes
ms.date: 2026-05-06
ms.topic: how-to
---

## Overview

The Helm chart in `charts/chat-with-your-factory/` deploys Chat With Factory to a
Kubernetes cluster with:

* Deployment (`apps/v1`)
* Service (`ClusterIP`)
* ConfigMap for non-secret environment values

Use this guide for cluster deployments after image build and push.

## Prerequisites

* Kubernetes cluster access (`kubectl` configured)
* Helm 3
* Container image available in ACR or another registry
* Namespace create permissions

## Chart Layout

```text
charts/chat-with-your-factory/
  Chart.yaml
  values.yaml
  templates/
    _helpers.tpl
    deployment.yaml
    service.yaml
    configmap.yaml
```

## Configure Values

Update or override these keys from `values.yaml`:

* `image.repository`
* `image.tag`
* `service.port` and `service.targetPort`
* `resources.requests` and `resources.limits`
* `env` map for runtime, non-secret settings

> [!IMPORTANT]
> Do not place secrets in `values.yaml` or ConfigMap-backed `env` values. Use
> Kubernetes Secrets and reference them from the deployment.

## Deploy

From `src/500-application/513-chat-with-your-factory/` run:

```bash
helm upgrade --install chat-with-your-factory ./charts/chat-with-your-factory \
  --namespace default \
  --create-namespace \
  --set image.repository=<registry>/chat-with-your-factory \
  --set image.tag=latest
```

## Validate Deployment

Check release status:

```bash
helm status chat-with-your-factory --namespace default
```

Check pods and service:

```bash
kubectl get pods,svc -n default -l app.kubernetes.io/name=chat-with-your-factory
```

Render templates locally before deploy:

```bash
helm template chat-with-your-factory ./charts/chat-with-your-factory
```

## Upgrade and Rollback

Upgrade by changing image tag and re-running `helm upgrade --install`.

Rollback to previous revision:

```bash
helm rollback chat-with-your-factory 1 --namespace default
```

## Uninstall

```bash
helm uninstall chat-with-your-factory --namespace default
```

## Troubleshooting

### Helm install succeeds but pod does not become ready

Describe the pod and inspect events:

```bash
kubectl describe pod -n default <pod-name>
```

Check logs:

```bash
kubectl logs -n default <pod-name>
```

### Image pull errors

Verify `image.repository`, `image.tag`, and pull secret:

* `imagePullSecrets[0].name` must exist in target namespace
* Registry credentials must grant pull access

### App returns 401 in cluster

Confirm runtime auth configuration in chart values:

* Set `env.AUTH_REQUIRED="false"` only for non-production scenarios
* Keep `env.AUTH_REQUIRED="true"` for production with valid identity flow
