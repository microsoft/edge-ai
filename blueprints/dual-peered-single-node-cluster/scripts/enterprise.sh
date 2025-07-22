#!/bin/bash
# shellcheck disable=SC2154

# Enterprise Script for Cluster A
# This script sets up MQTT broker with authentication and TLS certificates

set -e

echo "Starting enterprise script deployment..."

if [ "${use_generated_certificates}" = "true" ]; then
    echo "Using Terraform-generated certificates..."

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

    echo "Executing enterprise configuration with generated certificates..."

    # Execute the main enterprise logic using generated certificates
    kubectl create configmap "${enterprise_client_ca_configmap_name}" -n azure-iot-operations \
      --from-file=client_ca.pem="$CERT_FOLDER/client-root-ca.crt"

    kubectl create secret tls "${enterprise_broker_server_cert_secret_name}" -n azure-iot-operations \
      --cert "$CERT_FOLDER/server-leaf-ca.crt" --key "$CERT_FOLDER/server-leaf-ca.key"

    # Clean up temporary files
    rm -rf "$CERT_FOLDER"

else
    echo "Using Key Vault synced certificates..."

    # Wait for secret sync to complete
    echo "Waiting for certificates to be synced from Key Vault..."
    kubectl wait --for=condition=ready pod -l app=secret-sync-controller -n azure-iot-operations --timeout=300s || true

    # Check if the synced secret exists
    if kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations >/dev/null 2>&1; then
        echo "Certificates found, extracting from synced secret: ${synced_certificates_secret_name}"

        # Extract certificates from the synced secret
        kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath='{.data.client-root-ca-crt}' | base64 -d > /tmp/client-root-ca.crt
        kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath='{.data.server-leaf-ca-crt}' | base64 -d > /tmp/server-leaf-ca.crt
        kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath='{.data.server-leaf-ca-key}' | base64 -d > /tmp/server-leaf-ca.key

        echo "Executing enterprise configuration with Key Vault certificates..."

        # Execute the main enterprise logic using synced certificates
        kubectl create configmap "${enterprise_client_ca_configmap_name}" -n azure-iot-operations \
          --from-file=client_ca.pem=/tmp/client-root-ca.crt

        kubectl create secret tls "${enterprise_broker_server_cert_secret_name}" -n azure-iot-operations \
          --cert /tmp/server-leaf-ca.crt --key /tmp/server-leaf-ca.key

        # Clean up temporary files
        rm -f /tmp/client-root-ca.crt /tmp/server-leaf-ca.crt /tmp/server-leaf-ca.key
    else
        echo "ERROR: ${synced_certificates_secret_name} secret not found. Secret sync may not be working properly."
        echo "Available secrets in azure-iot-operations namespace:"
        kubectl get secrets -n azure-iot-operations --no-headers -o custom-columns=":metadata.name" | head -10
        exit 1
    fi
fi

echo "Enterprise script execution completed successfully."
echo "Cleanup completed."
