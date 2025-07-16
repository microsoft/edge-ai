#!/bin/sh

CERT_FOLDER="$1"
RESOURCES_FOLDER="$2"

kubectl create secret generic client-secret -n azure-iot-operations \
  --from-file=client_cert.pem="${CERT_FOLDER}/l4-client-leaf-ca.crt" \
  --from-file=client_key.pem="${CERT_FOLDER}/l4-client-leaf-ca.key" \
  --from-file=client_intermediate_certs.pem="${CERT_FOLDER}/l4-client-intermediate-ca.crt"

kubectl create configmap tls-ca-configmap --from-file "${CERT_FOLDER}/l4-server-root-ca.crt" -n azure-iot-operations

kubectl apply -n azure-iot-operations -f ${RESOURCES_FOLDER}/client-technology-mqtt-broker-listener.yaml
kubectl apply -n azure-iot-operations -f ${RESOURCES_FOLDER}/client-technology-mqtt-endpoint.yaml
kubectl apply -n azure-iot-operations -f ${RESOURCES_FOLDER}/server-central-mqtt-endpoint-cert-auth.yaml
kubectl apply -n azure-iot-operations -f ${RESOURCES_FOLDER}/technology-central-route-cert-auth.yaml
