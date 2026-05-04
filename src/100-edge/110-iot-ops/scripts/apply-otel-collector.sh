#!/usr/bin/env bash
# This script installs the OpenTelemetry Collector using Helm
# and configures Azure Monitor integration

# Exit if any command fails
set -e

# Check for required tools
if ! command -v "helm" &>/dev/null; then
  echo "ERROR: helm required, follow instructions located at: https://helm.sh/docs/intro/install/" >&2
  exit 1
fi

if ! command -v "kubectl" &>/dev/null; then
  echo "ERROR: kubectl required" >&2
  exit 1
fi

# Check for required environment variables
kube_config_file=${kube_config_file:-}
if [ -z "$kube_config_file" ]; then
  echo "ERROR: missing kube_config_file parameter, required 'source init-script.sh'"
  exit 1
fi

# Constants
MAX_RETRIES=3
RETRY_INTERVAL=5
HELM_TIMEOUT="5m"

echo "Installing OpenTelemetry Collector..."

# Add OpenTelemetry Helm repository
echo "Adding OpenTelemetry Helm repository..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --kubeconfig "$kube_config_file"

helm repo update --kubeconfig "$kube_config_file"

# Install/upgrade OpenTelemetry Collector
echo "Installing OpenTelemetry Collector using Helm..."
retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
  if helm upgrade --install aio-observability open-telemetry/opentelemetry-collector \
    --version 0.125.0 \
    -f "$TF_MODULE_PATH/yaml/otel-collector/otel-collector-values.yaml" \
    --namespace "$TF_AIO_NAMESPACE" \
    --create-namespace \
    --timeout $HELM_TIMEOUT \
    --wait \
    --kubeconfig "$kube_config_file"; then

    echo "OpenTelemetry Collector installed successfully"
    break
  else
    retry_count=$((retry_count + 1))
    if [ $retry_count -lt $MAX_RETRIES ]; then
      echo "Error installing OpenTelemetry Collector, retrying in $RETRY_INTERVAL seconds (attempt $retry_count of $MAX_RETRIES)"
      sleep $RETRY_INTERVAL
    else
      echo "Failed to install OpenTelemetry Collector after $MAX_RETRIES attempts"
      exit 1
    fi
  fi
done

# Create ConfigMap for Azure Monitor
echo "Applying Azure Monitor Prometheus metrics configuration..."
retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
  if envsubst <"$TF_MODULE_PATH/yaml/otel-collector/ama-metrics-prometheus-config.yaml" | kubectl apply -f - --kubeconfig "$kube_config_file"; then
    echo "Azure Monitor Prometheus metrics configuration applied successfully"
    break
  else
    retry_count=$((retry_count + 1))
    if [ $retry_count -lt $MAX_RETRIES ]; then
      echo "Error applying Azure Monitor Prometheus metrics configuration, retrying in $RETRY_INTERVAL seconds (attempt $retry_count of $MAX_RETRIES)"
      sleep $RETRY_INTERVAL
    else
      echo "Failed to apply Azure Monitor Prometheus metrics configuration after $MAX_RETRIES attempts"
      exit 1
    fi
  fi
done

# Verify deployment
echo "Verifying OpenTelemetry Collector deployment..."
if kubectl rollout status deployment/aio-otel-collector --namespace "$TF_AIO_NAMESPACE" --timeout=60s --kubeconfig "$kube_config_file"; then
  echo "OpenTelemetry Collector is running correctly"
else
  echo "WARNING: OpenTelemetry Collector deployment verification failed. Check the deployment manually."
fi

echo "OpenTelemetry Collector setup completed successfully"
