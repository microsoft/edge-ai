#!/bin/bash
set -euo pipefail

##############################################################################
# SSE Connector - Kustomize Patch Generator
##############################################################################
#
# DESCRIPTION:
#   Generates Kustomize deployment patches for the SSE Connector service
#   based on current environment configuration. Creates patch files that
#   modify container images and namespace settings for Kubernetes
#   deployments.
#
# USAGE:
#   ./gen-patch.sh [OPTIONS]
#
# OPTIONS:
#   --acr-name <name>       ACR name (default: acrmodules01)
#   --image-name <name>     Image name (default: sse-server)
#   --image-version <tag>   Image tag (default: latest)
#   --namespace <ns>        K8s namespace (default: azure-iot-operations)
#
# ENVIRONMENT VARIABLES (fallback when no flags provided):
#   ACR_NAME       - Azure Container Registry name
#   IMAGE_NAME     - Container image name
#   IMAGE_VERSION  - Image version tag
#   NAMESPACE      - Kubernetes namespace
#
# OUTPUTS:
#   patch-containers.yaml - Kustomize JSON patch file for deployment
#
# EXAMPLES:
#   ./gen-patch.sh
#   ./gen-patch.sh --acr-name myacr --image-version v1.0.0
#
# NOTES:
#   - Output file is created in the script's directory
#   - Existing patch-containers.yaml will be overwritten
#   - Uses JSON Patch (RFC 6902) format for Kustomize
#
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults from environment or hard-coded fallbacks
ACR_NAME="${ACR_NAME:-acrmodules01}"
IMAGE_NAME="${IMAGE_NAME:-sse-server}"
IMAGE_VERSION="${IMAGE_VERSION:-latest}"
NAMESPACE="${NAMESPACE:-azure-iot-operations}"

# Parse command-line flags (override env vars)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --acr-name)
      ACR_NAME="$2"
      shift 2
      ;;
    --image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --image-version)
      IMAGE_VERSION="$2"
      shift 2
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

cat >"${SCRIPT_DIR}/patch-containers.yaml" <<EOF
- op: replace
  path: /spec/template/spec/containers/0/image
  value: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_VERSION}
- op: replace
  path: /metadata/namespace
  value: ${NAMESPACE}
EOF

echo "Generated patch-containers.yaml with:"
echo "  Image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_VERSION}"
echo "  Namespace: ${NAMESPACE}"
