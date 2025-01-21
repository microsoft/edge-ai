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

until kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/explore-iot-operations/main/samples/quickstarts/opc-plc-deployment.yaml --kubeconfig "$kube_config_file"; do
    echo "Error applying, retrying in 5 seconds"
    sleep 5
done

# Set error handling back to normal
set -e

echo "All manifests applied successfully"
