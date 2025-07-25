#!/bin/bash
# shellcheck disable=SC2154

# Enterprise Script for Cluster A
# This script sets up MQTT broker with authentication and TLS certificates

set -e

echo "Starting enterprise script deployment..."

echo "Using Key Vault synced certificates..."

# Wait for secret sync to complete
echo "Waiting for certificates to be synced from Key Vault..."
kubectl wait --for=condition=ready pod -l app=secret-sync-controller -n azure-iot-operations --timeout=300s || true

# Check if the synced secret exists
if kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations >/dev/null 2>&1; then
    echo "Certificates found, extracting from synced secret: ${synced_certificates_secret_name}"

    # Extract certificate content into variable
    client_root_ca_cert=$(kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath="{.data['client-root-ca-crt']}" | base64 -d)

    echo "Executing enterprise configuration with Key Vault certificates..."

    # Execute the main enterprise logic using certificate variable
    kubectl create configmap "${enterprise_client_ca_configmap_name}" -n azure-iot-operations \
      --from-literal=client_ca.pem="${client_root_ca_cert}"

    echo "Enterprise script execution completed successfully."
else
    echo "ERROR: ${synced_certificates_secret_name} secret not found. Secret sync may not be working properly."
    echo "Available secrets in azure-iot-operations namespace:"
    kubectl get secrets -n azure-iot-operations --no-headers -o custom-columns=":metadata.name" | head -10
    exit 1
fi

echo "Enterprise script deployment completed."
