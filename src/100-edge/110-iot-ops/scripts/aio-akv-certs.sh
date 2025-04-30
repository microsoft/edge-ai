#!/usr/bin/env bash

set -e

ROOT_CA_CERT="${ROOT_CA_CERT:-fill-me-in}"
CA_CERT_CHAIN="${CA_CERT_CHAIN:-fill-me-in}"
CA_KEY="${CA_KEY:-fill-me-in}"

if [[ ! $AKV_NAME ]]; then
  echo "Error: AKV_NAME environment variables must be set"
  echo "Usage: ENABLE_SELF_SIGNED=<true> AKV_NAME=<keyVaultName> $0"
  exit 1
fi

if [[ $ENABLE_SELF_SIGNED ]]; then
  echo "Generating certificates for Azure IoT Operations..."

  # Generate root CA key
  openssl genrsa -out root-ca.key 4096

  # Generate root CA certificate
  openssl req -new -x509 -days 365 -key root-ca.key -out root-ca.crt -subj "/CN=Root CA for Azure IoT Operations"

  # Generate intermediate CA key
  openssl genrsa -out intermediate-ca.key 4096

  # Create intermediate CA CSR
  openssl req -new -key intermediate-ca.key -out intermediate-ca.csr -subj "/CN=Intermediate CA for Azure IoT Operations"

  # Create intermediate CA certificate signed by root CA
  openssl x509 -req -in intermediate-ca.csr -CA root-ca.crt -CAkey root-ca.key -CAcreateserial -out intermediate-ca.crt -days 365

  # Create the certificate chain
  cat intermediate-ca.crt root-ca.crt >ca-chain.crt

  # Read certificates and key into variables
  ROOT_CA_CERT=$(cat root-ca.crt)
  CA_CERT_CHAIN=$(cat ca-chain.crt)
  CA_KEY=$(cat intermediate-ca.key)
fi

echo "Uploading certificates and key to Azure Key Vault '$AKV_NAME' in resource group '$AKV_RESOURCE_GROUP_NAME'..."

# Upload root CA certificate to Key Vault
az keyvault secret set \
  --vault-name "$AKV_NAME" \
  --name "aio-root-ca-cert" \
  --value "$ROOT_CA_CERT" \
  --content-type "text/plain" \
  --output none

# Upload certificate chain to Key Vault
az keyvault secret set \
  --vault-name "$AKV_NAME" \
  --name "aio-ca-cert-chain" \
  --value "$CA_CERT_CHAIN" \
  --content-type "text/plain" \
  --output none

# Upload intermediate CA key to Key Vault
az keyvault secret set \
  --vault-name "$AKV_NAME" \
  --name "aio-ca-key" \
  --value "$CA_KEY" \
  --content-type "text/plain" \
  --output none

echo "Successfully uploaded certificates and key to Azure Key Vault."
echo "Secrets created:"
echo "  - aio-root-ca-cert"
echo "  - aio-ca-cert-chain"
echo "  - aio-ca-key"

# Clean up local files
rm -f root-ca.key root-ca.crt intermediate-ca.key intermediate-ca.csr intermediate-ca.crt ca-chain.crt root-ca.srl

echo "Local certificate files cleaned up."
