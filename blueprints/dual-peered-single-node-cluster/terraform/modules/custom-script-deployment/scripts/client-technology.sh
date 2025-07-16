#!/bin/bash

# Client Technology Script for Cluster B
# This script sets up MQTT client endpoints with certificate-based authentication

set -e

echo "Starting client-technology script deployment..."

# Create temporary directories
CERT_FOLDER="/tmp/certs"
RESOURCES_FOLDER="/tmp/resources"
mkdir -p "$CERT_FOLDER"
mkdir -p "$RESOURCES_FOLDER"

echo "Setting up certificates and resources..."

# Decode and save certificates
echo "${client_root_ca_cert}" | base64 -d >"$CERT_FOLDER/l4-client-root-ca.crt"
echo "${client_intermediate_ca_cert}" | base64 -d >"$CERT_FOLDER/l4-client-intermediate-ca.crt"
echo "${client_leaf_ca_cert}" | base64 -d >"$CERT_FOLDER/l4-client-leaf-ca.crt"
echo "${client_leaf_ca_key}" | base64 -d >"$CERT_FOLDER/l4-client-leaf-ca.key"
echo "${server_root_ca_cert}" | base64 -d >"$CERT_FOLDER/l4-server-root-ca.crt"

# Decode and save Kubernetes manifests
echo "${client_technology_mqtt_broker_listener}" | base64 -d >"$RESOURCES_FOLDER/client-technology-mqtt-broker-listener.yaml"
echo "${client_technology_mqtt_endpoint}" | base64 -d >"$RESOURCES_FOLDER/client-technology-mqtt-endpoint.yaml"
echo "${server_central_mqtt_endpoint_cert_auth}" | base64 -d >"$RESOURCES_FOLDER/server-central-mqtt-endpoint-cert-auth.yaml"
echo "${technology_central_route_cert_auth}" | base64 -d >"$RESOURCES_FOLDER/technology-central-route-cert-auth.yaml"

echo "Executing client-technology configuration..."

# Execute the main client-technology logic
kubectl create secret generic client-secret -n azure-iot-operations \
  --from-file=client_cert.pem="$CERT_FOLDER/l4-client-leaf-ca.crt" \
  --from-file=client_key.pem="$CERT_FOLDER/l4-client-leaf-ca.key" \
  --from-file=client_intermediate_certs.pem="$CERT_FOLDER/l4-client-intermediate-ca.crt"

kubectl create configmap tls-ca-configmap --from-file "$CERT_FOLDER/l4-server-root-ca.crt" -n azure-iot-operations

kubectl apply -n azure-iot-operations -f "$RESOURCES_FOLDER/client-technology-mqtt-broker-listener.yaml"
kubectl apply -n azure-iot-operations -f "$RESOURCES_FOLDER/client-technology-mqtt-endpoint.yaml"
kubectl apply -n azure-iot-operations -f "$RESOURCES_FOLDER/server-central-mqtt-endpoint-cert-auth.yaml"
kubectl apply -n azure-iot-operations -f "$RESOURCES_FOLDER/technology-central-route-cert-auth.yaml"

echo "Client technology script execution completed successfully."

# Clean up temporary files
rm -rf "$CERT_FOLDER" "$RESOURCES_FOLDER"

echo "Cleanup completed."
