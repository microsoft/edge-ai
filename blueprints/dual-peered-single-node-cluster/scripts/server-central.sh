#!/bin/sh

CERT_FOLDER="$1"
RESOURCES_FOLDER="$2"

kubectl create configmap client-ca -n azure-iot-operations \
  --from-file=client_ca.pem="${CERT_FOLDER}/l4-client-root-ca.crt"

kubectl create secret tls broker-server-cert -n azure-iot-operations \
  --cert "${CERT_FOLDER}/l4-server-leaf-ca.crt" --key "${CERT_FOLDER}/l4-server-leaf-ca.key"

kubectl apply -f ${RESOURCES_FOLDER}/server-central-mqtt-broker-authentication.yaml

kubectl apply -f ${RESOURCES_FOLDER}/server-central-mqtt-broker-listener.yaml
#kubectl patch brokerlistener default -n azure-iot-operations --type='json' -p='[{"op": "add", "path": "/spec/ports/-", "value": {"authenticationRef": "default", "port": 8883, "protocol": "WebSockets", "tls": {"mode": "Manual", "manual": {"secretRef": "broker-server-cert"}}}}]'
