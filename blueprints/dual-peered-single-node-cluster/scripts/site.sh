#!/bin/bash
# shellcheck disable=SC2154

# Site Script for Cluster B
# This script sets up MQTT client endpoints with certificate-based authentication

set -e

echo "Starting site script deployment..."

# Create temporary directories
CERT_FOLDER="/tmp/certs"
mkdir -p "$CERT_FOLDER"

echo "Setting up certificates and resources..."

# Decode and save certificates
echo "${client_root_ca_cert}" | base64 -d >"$CERT_FOLDER/client-root-ca.crt"
echo "${client_intermediate_ca_cert}" | base64 -d >"$CERT_FOLDER/client-intermediate-ca.crt"
echo "${client_leaf_ca_cert}" | base64 -d >"$CERT_FOLDER/client-leaf-ca.crt"
echo "${client_leaf_ca_key}" | base64 -d >"$CERT_FOLDER/client-leaf-ca.key"
echo "${server_root_ca_cert}" | base64 -d >"$CERT_FOLDER/server-root-ca.crt"

echo "Executing site configuration..."

# Execute the main site logic
kubectl create secret generic "${site_client_secret_name}" -n azure-iot-operations \
  --from-file=client_cert.pem="$CERT_FOLDER/client-leaf-ca.crt" \
  --from-file=client_key.pem="$CERT_FOLDER/client-leaf-ca.key" \
  --from-file=client_intermediate_certs.pem="$CERT_FOLDER/client-intermediate-ca.crt"

kubectl create configmap "${site_tls_ca_configmap_name}" --from-file "$CERT_FOLDER/server-root-ca.crt" -n azure-iot-operations

echo "Site script execution completed successfully."

# Clean up temporary files
rm -rf "$CERT_FOLDER" "$RESOURCES_FOLDER"

echo "Cleanup completed."
