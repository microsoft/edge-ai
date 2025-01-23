#!/bin/bash

kube_config_file=${kube_config_file:-}
if [ -z "$kube_config_file" ]; then
  echo "ERROR: missing kube_config_file parameter, required 'source init-script.sh'"
  exit 1
fi

# Set error handling to continue on errors
set +e

for file in sa.yaml spc.yaml secretsync.yaml bundle.yaml customer-issuer.yaml; do
  until envsubst <"$TF_MODULE_PATH/yaml/trust/$file" | kubectl apply -f - --kubeconfig "$kube_config_file"; do
    echo "Error applying $file, retrying in 5 seconds"
    sleep 5
  done
done

# wait for configmap to be created from the Bundle CR
until kubectl get configmap "$TF_AIO_CONFIGMAP_NAME" -n "$TF_AIO_NAMESPACE" --kubeconfig "$kube_config_file"; do
  echo "Waiting for configmap to be created"
  sleep 5
done

# Set error handling back to normal
set -e

echo "All manifests applied successfully"
