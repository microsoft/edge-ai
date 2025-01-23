#!/bin/bash

kube_config_file=${kube_config_file:-}
if [ -z "$kube_config_file" ]; then
  echo "ERROR: missing kube_config_file parameter, required 'source init-script.sh'"
  exit 1
fi

# Set error handling to continue on errors
set +e

until kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/explore-iot-operations/main/samples/quickstarts/opc-plc-deployment.yaml --kubeconfig "$kube_config_file"; do
  echo "Error applying, retrying in 5 seconds"
  sleep 5
done

# Set error handling back to normal
set -e

echo "All manifests applied successfully"
