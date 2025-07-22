#!/bin/bash
# shellcheck disable=SC2154

# Enterprise Script for Cluster A
# This script sets up MQTT broker with authentication and TLS certificates

set -e

echo "Starting enterprise script deployment..."

# Create temporary directories
CERT_FOLDER="/tmp/certs"
mkdir -p "$CERT_FOLDER"

echo "Setting up certificates and resources..."

# Decode and save certificates
echo "${server_root_ca_cert}" | base64 -d >"$CERT_FOLDER/server-root-ca.crt"
echo "${server_intermediate_ca_cert}" | base64 -d >"$CERT_FOLDER/server-intermediate-ca.crt"
echo "${server_leaf_ca_cert}" | base64 -d >"$CERT_FOLDER/server-leaf-ca.crt"
echo "${server_leaf_ca_key}" | base64 -d >"$CERT_FOLDER/server-leaf-ca.key"
echo "${client_root_ca_cert}" | base64 -d >"$CERT_FOLDER/client-root-ca.crt"

echo "Executing enterprise configuration..."

# Execute the main enterprise logic
kubectl create configmap "${enterprise_client_ca_configmap_name}" -n azure-iot-operations \
  --from-file=client_ca.pem="$CERT_FOLDER/client-root-ca.crt"

kubectl create secret tls "${enterprise_broker_server_cert_secret_name}" -n azure-iot-operations \
  --cert "$CERT_FOLDER/server-leaf-ca.crt" --key "$CERT_FOLDER/server-leaf-ca.key"

echo "Enterprise script execution completed successfully."

# Clean up temporary files
rm -rf "$CERT_FOLDER" "$RESOURCES_FOLDER"

echo "Cleanup completed."
