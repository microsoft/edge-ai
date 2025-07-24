#!/bin/bash
# shellcheck disable=SC2154

# Site Script for Cluster B
# This script sets up MQTT client endpoints with certificate-based authentication

set -e

echo "Starting site script deployment..."

echo "Using Key Vault synced certificates..."

# Wait for secret sync to complete
echo "Waiting for certificates to be synced from Key Vault..."
kubectl wait --for=condition=ready pod -l app=secret-sync-controller -n azure-iot-operations --timeout=300s || true

# Check if the synced secret exists
if kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations >/dev/null 2>&1; then
    echo "Certificates found, extracting from synced secret: ${synced_certificates_secret_name}"

    # Extract certificate content into variable
    server_root_ca_cert=$(kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath='{.data.server-root-ca-crt}' | base64 -d)

    echo "Executing site configuration with Key Vault certificates..."

    # Execute the main site logic using certificate variable
    kubectl create configmap "${site_tls_ca_configmap_name}" -n azure-iot-operations \
      --from-literal=server-root-ca.crt="${server_root_ca_cert}"

    echo "Site script execution completed successfully."
else
    echo "ERROR: ${synced_certificates_secret_name} secret not found. Secret sync may not be working properly."
    echo "Available secrets in azure-iot-operations namespace:"
    kubectl get secrets -n azure-iot-operations --no-headers -o custom-columns=":metadata.name" | head -10
    exit 1
fi

echo "Site script deployment completed."
