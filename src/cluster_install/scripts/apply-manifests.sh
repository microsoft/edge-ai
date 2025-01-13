#!/bin/bash

# Set error handling to continue on errors
set +e

# Function to clean up resources
cleanup() {
    echo "Cleaning up..."
    [ -f "$kube_config_file" ] && rm "$kube_config_file" && echo "Deleted kubeconfig file"

    # Kill the proxy main process and its children
    kill -TERM $PID
    echo "Killed proxy process $PID and sleep for 20 seconds to terminate processes"
    sleep 20

    # Look for the process id of the proxy, seems to still run under the name arcProxyLinux1
    arc_proxy_process=$(pgrep arcProxyLinux1)
    [ -n "$arc_proxy_process" ] && kill "$arc_proxy_process" && echo "Killed proxy process $arc_proxy_process"

    echo "Sleep for 30 seconds to allow the proxy process to die/exit"
    sleep 30

    echo "Cleanup done"
}
# Trap any error or exit to cleanup
trap cleanup EXIT

# Use a custom kubeconfig file to ensure the current user's context is not affected
kube_config_file="./$TF_CONNECTED_CLUSTER_NAME-kubeconfig.temp"
touch "$kube_config_file"
chmod 600 "$kube_config_file"
az connectedk8s proxy -n "$TF_CONNECTED_CLUSTER_NAME" -g "$TF_RESOURCE_GROUP_NAME" --port 9800 --file "$kube_config_file" >/dev/null &
PID=$!

# Wait for the proxy to start
sleep 15

# Check for errors
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
    echo "Error starting the proxy"
    set -e
    exit 1
fi

# echo "Preparing cluster for customer managed trust (deploying YAML files directly within KUBECONFIG remote context)"
# Create SA and namespace for SSE manual extension setup
for file in aio-namespace.yaml sa.yaml; do
    until sed <"$TF_MODULE_PATH/yaml/$file" "s/__AIO_OPERATIONS_NAMESPACE__/$TF_AIO_NAMESPACE/g" | kubectl apply -f - --kubeconfig "$kube_config_file"; do
        echo "Error applying $file, retrying in 5 seconds"
        sleep 5
    done
done

# Create SPC object and replace placeholders with actual values
until sed <"$TF_MODULE_PATH/yaml/spc.yaml" "s/__AIO_OPERATIONS_NAMESPACE__/$TF_AIO_NAMESPACE/g" | sed "s/__USER_ASSIGNED_CLIENT_ID__/$TF_SSE_USER_ASSIGNED_CLIENT_ID/g" | sed "s/__KEYVAULT_NAME__/$TF_KEY_VAULT_NAME/g" | sed "s/__AZURE_TENANT_ID__/$TF_AZURE_TENANT_ID/g" | kubectl apply -f - --kubeconfig "$kube_config_file"; do
    echo "Error applying spc.yaml, retrying in 5 seconds"
    sleep 5
done

for file in secretsync.yaml bundle.yaml customer-issuer.yaml; do
    until sed <"$TF_MODULE_PATH/yaml/$file" "s/__AIO_OPERATIONS_NAMESPACE__/$TF_AIO_NAMESPACE/g" | sed "s/__BUNDLE_NAME__/$TF_AIO_CONFIGMAP_NAME/g" | kubectl apply -f - --kubeconfig "$kube_config_file"; do
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
