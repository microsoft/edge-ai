#!/bin/bash

# Server Central Script for Cluster A
# This script sets up MQTT broker with authentication and TLS certificates

set -e

echo "Starting server-central script deployment..."

# Create temporary directories
CERT_FOLDER="/tmp/certs"
RESOURCES_FOLDER="/tmp/resources"
mkdir -p "$CERT_FOLDER"
mkdir -p "$RESOURCES_FOLDER"

echo "Setting up certificates and resources..."

# Decode and save certificates
echo "${server_root_ca_cert}" | base64 -d >"$CERT_FOLDER/l4-server-root-ca.crt"
echo "${server_intermediate_ca_cert}" | base64 -d >"$CERT_FOLDER/l4-server-intermediate-ca.crt"
echo "${server_leaf_ca_cert}" | base64 -d >"$CERT_FOLDER/l4-server-leaf-ca.crt"
echo "${server_leaf_ca_key}" | base64 -d >"$CERT_FOLDER/l4-server-leaf-ca.key"
echo "${client_root_ca_cert}" | base64 -d >"$CERT_FOLDER/l4-client-root-ca.crt"

# Decode and save Kubernetes manifests
echo "${server_central_mqtt_broker_authentication}" | base64 -d >"$RESOURCES_FOLDER/server-central-mqtt-broker-authentication.yaml"
echo "${server_central_mqtt_broker_listener}" | base64 -d >"$RESOURCES_FOLDER/server-central-mqtt-broker-listener.yaml"

echo "Executing server-central configuration..."

# Execute the main server-central logic
kubectl create configmap client-ca -n azure-iot-operations \
  --from-file=client_ca.pem="$CERT_FOLDER/l4-client-root-ca.crt"

kubectl create secret tls broker-server-cert -n azure-iot-operations \
  --cert "$CERT_FOLDER/l4-server-leaf-ca.crt" --key "$CERT_FOLDER/l4-server-leaf-ca.key"

kubectl apply -f "$RESOURCES_FOLDER/server-central-mqtt-broker-authentication.yaml"

kubectl apply -f "$RESOURCES_FOLDER/server-central-mqtt-broker-listener.yaml"

echo "Server central script execution completed successfully."

# Clean up temporary files
rm -rf "$CERT_FOLDER" "$RESOURCES_FOLDER"

echo "Cleanup completed."
