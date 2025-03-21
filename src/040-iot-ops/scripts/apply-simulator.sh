#!/bin/bash

kube_config_file=${kube_config_file:-}
if [ -z "$kube_config_file" ]; then
  echo "ERROR: missing kube_config_file parameter, required 'source init-script.sh'"
  exit 1
fi

# Set error handling to continue on errors
set +e

# Deploy the current latest opc-plc-deployment.yaml from https://github.com/Azure-Samples/explore-iot-operations.
# This is to prevent breaking changes from the explore-iot-operations repo impacting this repo.
# To update to the latest version, a new hard-link to a specific sha will be required after full testing and verification.
until kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/explore-iot-operations/b11625fc6314a0ee4d61ab7bbcc9e9315c139dab/samples/quickstarts/opc-plc-deployment.yaml --kubeconfig "$kube_config_file"; do
  echo "Error applying, retrying in 5 seconds"
  sleep 5
done

# Set error handling back to normal
set -e

echo "All manifests applied successfully"
