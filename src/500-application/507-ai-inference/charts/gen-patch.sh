#!/usr/bin/env bash
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

set -euo pipefail

################################################################################
# AI Edge Inference - Kustomize Patch Generator
################################################################################
#
# DESCRIPTION:
#   Generates Kustomize deployment patches for the AI Edge Inference service
#   based on current environment configuration. Creates patch files that modify
#   container images and namespace settings for Kubernetes deployments.
#
# USAGE:
#   ./gen-patch.sh
#
# ENVIRONMENT VARIABLES:
#   ACR_NAME       - Azure Container Registry name (default: acrmodules01)
#   IMAGE_NAME     - Container image name (default: ai-edge-inference)
#   IMAGE_VERSION  - Image version tag (default: latest)
#   NAMESPACE      - Kubernetes namespace (default: azure-iot-operations)
#
# OUTPUTS:
#   patch-containers.yaml - Kustomize JSON patch file for deployment
#
# EXAMPLES:
#   # Generate patch with defaults
#   ./gen-patch.sh
#
#   # Generate patch with custom ACR and version
#   export ACR_NAME="myacr"
#   export IMAGE_VERSION="v1.2.3"
#   ./gen-patch.sh
#
# NOTES:
#   - Output file is created in the current working directory
#   - Existing patch-containers.yaml will be overwritten
#   - Uses JSON Patch (RFC 6902) format for Kustomize
#
################################################################################

# Get environment variables or use defaults
ACR_NAME="${ACR_NAME:-acrmodules01}"
IMAGE_NAME="${IMAGE_NAME:-ai-edge-inference}"
IMAGE_VERSION="${IMAGE_VERSION:-latest}"
NAMESPACE="${NAMESPACE:-azure-iot-operations}"

usage() {
  echo "Usage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --acr-name <name>       ACR name (default: acrmodules01)"
  echo "  --image-name <name>     Image name (default: ai-edge-inference)"
  echo "  --image-version <tag>   Image tag (default: latest)"
  echo "  --namespace <ns>        K8s namespace (default: azure-iot-operations)"
  echo "  --help, -h              Show this help message"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --acr-name)
      if [[ -z "${2:-}" || "${2}" == --* ]]; then
        echo "Error: --acr-name requires a value" >&2
        usage
        exit 1
      fi
      ACR_NAME="${2}"
      shift 2
      ;;
    --image-name)
      if [[ -z "${2:-}" || "${2}" == --* ]]; then
        echo "Error: --image-name requires a value" >&2
        usage
        exit 1
      fi
      IMAGE_NAME="${2}"
      shift 2
      ;;
    --image-version)
      if [[ -z "${2:-}" || "${2}" == --* ]]; then
        echo "Error: --image-version requires a value" >&2
        usage
        exit 1
      fi
      IMAGE_VERSION="${2}"
      shift 2
      ;;
    --namespace)
      if [[ -z "${2:-}" || "${2}" == --* ]]; then
        echo "Error: --namespace requires a value" >&2
        usage
        exit 1
      fi
      NAMESPACE="${2}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# Create the container patch file
cat >patch-containers.yaml <<EOF
- op: replace
  path: /spec/template/spec/containers/0/image
  value: "${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_VERSION}"
- op: replace
  path: /metadata/namespace
  value: "${NAMESPACE}"
EOF

echo "Generated patch-containers.yaml with:"
echo "  Image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_VERSION}"
echo "  Namespace: ${NAMESPACE}"
