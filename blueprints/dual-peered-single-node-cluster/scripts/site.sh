#!/usr/bin/env bash
# shellcheck disable=SC2154

# Site Script for Cluster A

kube_config_file=${kube_config_file:-}
if [ -z "$kube_config_file" ]; then
  echo "ERROR: missing kube_config_file parameter, required 'source init-script.sh'"
  exit 1
fi

# Set error handling to continue on errors
set +e

echo "Starting site script deployment..."

echo "Creating TrustBundle to build ConfigMap from Key Vault synced certificates..."

# Wait for secret sync to complete
echo "Waiting for certificates to be synced from Key Vault to be used via TrustBundle..."
kubectl get pods -A --kubeconfig "$kube_config_file"
# kubectl wait --for=condition=ready pod -l app=secret-sync-controller -n azure-iot-operations --timeout=300s --kubeconfig "$kube_config_file" || true

for file in spc-site.yaml secretsync-site.yaml bundle-site.yaml; do
  until envsubst <"$TF_LOCAL_MODULE_PATH/yaml/$file" | kubectl apply -f - --kubeconfig "$kube_config_file"; do
    echo "Error applying $file, retrying in 5 seconds"
    sleep 5
  done
done

# wait for configmap to be created from the Bundle CR
until kubectl get configmap "$SITE_TLS_CA_CONFIGMAP_NAME" -n azure-iot-operations --kubeconfig "$kube_config_file"; do
  echo "Waiting for configmap to be created"
  sleep 5
done

# Set error handling back to normal
set -e

echo "All manifests applied successfully"

echo "Site script deployment completed."
