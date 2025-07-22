#!/bin/bash
# shellcheck disable=SC2154

# Site Script for Cluster B
# This script sets up MQTT client endpoints with certificate-based authentication

set -e

echo "Starting site script deployment..."

if [ "${use_generated_certificates}" = "true" ]; then
    echo "Using Terraform-generated certificates..."

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

    echo "Executing site configuration with generated certificates..."

    # Execute the main site logic using generated certificates
    kubectl create secret generic "${site_client_secret_name}" -n azure-iot-operations \
      --from-file=client_cert.pem="$CERT_FOLDER/client-leaf-ca.crt" \
      --from-file=client_key.pem="$CERT_FOLDER/client-leaf-ca.key" \
      --from-file=client_intermediate_certs.pem="$CERT_FOLDER/client-intermediate-ca.crt"

    kubectl create configmap "${site_tls_ca_configmap_name}" --from-file "$CERT_FOLDER/server-root-ca.crt" -n azure-iot-operations

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
        kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath='{.data.client-leaf-ca-crt}' | base64 -d > /tmp/client-leaf-ca.crt
        kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath='{.data.client-leaf-ca-key}' | base64 -d > /tmp/client-leaf-ca.key
        kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath='{.data.client-intermediate-ca-crt}' | base64 -d > /tmp/client-intermediate-ca.crt
        kubectl get secret "${synced_certificates_secret_name}" -n azure-iot-operations -o jsonpath='{.data.server-root-ca-crt}' | base64 -d > /tmp/server-root-ca.crt

        echo "Executing site configuration with Key Vault certificates..."

        # Execute the main site logic using synced certificates
        kubectl create secret generic "${site_client_secret_name}" -n azure-iot-operations \
          --from-file=client_cert.pem=/tmp/client-leaf-ca.crt \
          --from-file=client_key.pem=/tmp/client-leaf-ca.key \
          --from-file=client_intermediate_certs.pem=/tmp/client-intermediate-ca.crt

        kubectl create configmap "${site_tls_ca_configmap_name}" --from-file /tmp/server-root-ca.crt -n azure-iot-operations

        # Clean up temporary files
        rm -f /tmp/client-leaf-ca.crt /tmp/client-leaf-ca.key /tmp/client-intermediate-ca.crt /tmp/server-root-ca.crt
    else
        echo "ERROR: ${synced_certificates_secret_name} secret not found. Secret sync may not be working properly."
        echo "Available secrets in azure-iot-operations namespace:"
        kubectl get secrets -n azure-iot-operations --no-headers -o custom-columns=":metadata.name" | head -10
        exit 1
    fi
fi

echo "Site script execution completed successfully."
echo "Cleanup completed."
