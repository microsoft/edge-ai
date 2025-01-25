#!/bin/bash

if ! command -v "helm" &>/dev/null; then
  echo "ERROR: helm required, follow instructions located at: https://helm.sh/docs/intro/install/" >&2
  exit 1
fi

kube_config_file=${kube_config_file:-}
if [ -z "$kube_config_file" ]; then
  echo "ERROR: missing kube_config_file parameter, required 'source init-script.sh'"
  exit 1
fi

# Set error handling to continue on errors
set +e

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --kubeconfig "$kube_config_file"

helm repo update --kubeconfig "$kube_config_file"
helm upgrade --install aio-observability open-telemetry/opentelemetry-collector \
  -f "$TF_MODULE_PATH/yaml/otel-collector/otel-collector-values.yaml" \
  --namespace "$TF_AIO_NAMESPACE" \
  --wait \
  --kubeconfig "$kube_config_file"

# Creating ConfigMap for Azure Monitor (only used if Azure Monitor extensions is installed)
until envsubst <"$TF_MODULE_PATH/yaml/otel-collector/ama-metrics-prometheus-config.yaml" | kubectl apply -f - --kubeconfig "$kube_config_file"; do
  echo "Error applying ama-metrics-prometheus-config.yaml, retrying in 5 seconds"
  sleep 5
done

set -e

echo "All manifests applied successfully"
