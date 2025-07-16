#!/bin/sh

CERT_FOLDER="$1"
SAN="$2"

step certificate create "AIO Root CA" \
  "${CERT_FOLDER}/l4-server-root-ca.crt" "${CERT_FOLDER}/l4-server-root-ca.key" \
  --profile root-ca \
  --no-password --insecure

# create an server intermediate key and certificate
step certificate create "AIO Intermediate CA 1" \
  "${CERT_FOLDER}/l4-server-intermediate-ca.crt" "${CERT_FOLDER}/l4-server-intermediate-ca.key" \
  --profile intermediate-ca \
  --ca "${CERT_FOLDER}/l4-server-root-ca.crt" --ca-key "${CERT_FOLDER}/l4-server-root-ca.key" \
  --no-password --insecure

# create endpoint key and certificate for the TLS handshake (notice the external IP address)
step certificate create mqtts-endpoint \
  "${CERT_FOLDER}/l4-server-leaf-ca.crt" "${CERT_FOLDER}/l4-server-leaf-ca.key" \
  --profile leaf \
  --ca "${CERT_FOLDER}/l4-server-intermediate-ca.crt" --ca-key "${CERT_FOLDER}/l4-server-intermediate-ca.key" \
  --bundle \
  --san "${SAN}" \
  --not-after 2400h --no-password --insecure

step certificate create --profile root-ca "Client Root CA" \
  "${CERT_FOLDER}/l4-client-root-ca.crt" "${CERT_FOLDER}/l4-client-root-ca.key" \
  --no-password --insecure

# create an client intermediate key and certificate
step certificate create "Client Intermediate CA 1" \
  "${CERT_FOLDER}/l4-client-intermediate-ca.crt" "${CERT_FOLDER}/l4-client-intermediate-ca.key" \
  --profile intermediate-ca \
  --ca "${CERT_FOLDER}/l4-client-root-ca.crt" --ca-key "${CERT_FOLDER}/l4-client-root-ca.key" \
  --no-password --insecure

# create key and certificate for client
step certificate create client \
  "${CERT_FOLDER}/l4-client-leaf-ca.crt" "${CERT_FOLDER}/l4-client-leaf-ca.key" \
  --ca "${CERT_FOLDER}/l4-client-intermediate-ca.crt" --ca-key "${CERT_FOLDER}/l4-client-intermediate-ca.key" \
  --bundle --not-after 2400h --no-password --insecure
