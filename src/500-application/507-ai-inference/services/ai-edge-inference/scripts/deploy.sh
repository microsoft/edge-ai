#!/usr/bin/env bash
set -euo pipefail

################################################################################
# AI Edge Inference Service - Deployment Script
################################################################################
#
# DESCRIPTION:
#   Complete deployment automation for the AI Edge Inference service.
#   Handles Docker image building, Azure Container Registry push, and
#   Kubernetes manifest deployment with Kustomize patches.
#
# USAGE:
#   ./deploy.sh
#
# ENVIRONMENT VARIABLES:
#   ACR_NAME       - Azure Container Registry name (default: youracr)
#   IMAGE_NAME     - Container image name (default: ai-edge-inference)
#   IMAGE_VERSION  - Image version tag (default: latest)
#   NAMESPACE      - Kubernetes namespace (default: azure-iot-operations)
#
# DEPLOYMENT FLOW:
#   1. Prerequisite validation (docker, az, kubectl, kustomize)
#   2. Azure authentication and ACR login
#   3. Docker image build (multi-arch support)
#   4. Image push to Azure Container Registry
#   5. Kustomize patch generation
#   6. Kubernetes manifest application
#   7. Deployment verification and health checks
#
# PREREQUISITES:
#   - Azure CLI (az) installed and authenticated
#   - Docker daemon running
#   - kubectl configured with cluster access
#   - Kustomize installed
#   - Appropriate Azure RBAC permissions for ACR
#
# EXAMPLES:
#   # Deploy with defaults
#   ./deploy.sh
#
#   # Deploy with custom ACR and version
#   export ACR_NAME=\"myacr\"
#   export IMAGE_VERSION=\"v1.2.3\"
#   ./deploy.sh
#
# NOTES:
#   - Script validates all prerequisites before deployment
#   - Supports both amd64 and arm64 architectures
#   - Automatically creates Kustomize patches
#   - Monitors deployment rollout status
#
################################################################################

# Environment configuration with defaults
export ACR_NAME="${ACR_NAME:-youracr}"
export IMAGE_NAME="${IMAGE_NAME:-ai-edge-inference}"
export IMAGE_VERSION="${IMAGE_VERSION:-latest}"
export NAMESPACE="${NAMESPACE:-azure-iot-operations}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_prerequisites() {
  log_info "Checking prerequisites..."

  local tools=("docker" "az" "kubectl" "kustomize")
  local missing_tools=()

  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      missing_tools+=("$tool")
    fi
  done

  if [ ${#missing_tools[@]} -ne 0 ]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    log_error "Please install the missing tools and try again."
    exit 1
  fi

  log_success "All prerequisites are installed"
}

# Function to build the Docker image
build_image() {
  log_info "Building container image: $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION"

  # Build from parent directory to include ai-edge-inference-crate in context
  cd ..
  if docker build \
    --no-cache \
    -f ai-edge-inference/Dockerfile \
    -t "$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION" \
    .; then
    cd ai-edge-inference
    log_success "Container image built successfully"

    # Show image details
    docker images "$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
  else
    log_error "Failed to build container image"
    exit 1
  fi
}

# Function to authenticate with Azure Container Registry
authenticate_acr() {
  log_info "Authenticating with Azure Container Registry..."

  # Check if ACR exists and authenticate
  az acr login --name "$ACR_NAME" || {
    log_error "Failed to authenticate with Azure Container Registry '$ACR_NAME'"
    log_error "Please ensure you have access to the registry and are logged in to Azure CLI"
    exit 1
  }

  log_success "Successfully authenticated with ACR: $ACR_NAME.azurecr.io"
}

# Function to push the image to ACR
push_image() {
  log_info "Pushing container image to ACR..."

  if docker push "$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION"; then
    log_success "Container image pushed successfully"
  else
    log_error "Failed to push container image"
    exit 1
  fi

  # Also tag as latest if this is a release version
  if [[ "$IMAGE_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_info "Tagging as latest..."
    docker tag "$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION" "$ACR_NAME.azurecr.io/$IMAGE_NAME:latest"
    docker push "$ACR_NAME.azurecr.io/$IMAGE_NAME:latest"
    log_success "Latest tag pushed"
  fi
}

# Function to generate deployment patches
generate_patches() {
  log_info "Generating deployment configuration..."

  if [ -f "deployment/gen-patch.sh" ]; then
    cd deployment
    ./gen-patch.sh
    cd ..
    log_success "Deployment patches generated"
  else
    log_warning "gen-patch.sh not found, using static configuration"
  fi
}

# Function to apply Kubernetes manifests
apply_manifests() {
  log_info "Applying Kubernetes manifests..."

  # Check if cluster is accessible
  if ! kubectl cluster-info &>/dev/null; then
    log_error "Cannot access Kubernetes cluster. Please check your kubeconfig."
    exit 1
  fi

  # Apply manifests using kustomize
  if kubectl apply -k deployment/; then
    log_success "Kubernetes manifests applied successfully"
  else
    log_error "Failed to apply Kubernetes manifests"
    exit 1
  fi
}

# Function to restart pods to pick up new image
restart_pods() {
  log_info "Restarting component pods to pick up new image..."

  kubectl delete pod -l app="$IMAGE_NAME" --namespace="$NAMESPACE" --ignore-not-found=true

  log_success "Pods restarted"
}

# Function to wait for deployment rollout
wait_for_rollout() {
  log_info "Waiting for deployment rollout to complete..."

  if kubectl rollout status deployment/"$IMAGE_NAME" --namespace="$NAMESPACE" --timeout=300s; then
    log_success "Deployment rollout completed successfully"
  else
    log_error "Deployment rollout failed or timed out"
    exit 1
  fi
}

# Function to verify deployment
verify_deployment() {
  log_info "Verifying deployment..."

  # Check if pods are running
  local ready_pods
  ready_pods=$(kubectl get pods -l app="$IMAGE_NAME" --namespace="$NAMESPACE" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)

  if [ "$ready_pods" -gt 0 ]; then
    log_success "Deployment verified: $ready_pods pod(s) running"

    # Show pod status
    kubectl get pods -l app="$IMAGE_NAME" --namespace="$NAMESPACE"

    # Show service endpoints
    log_info "Service endpoints:"
    kubectl get services -l app="$IMAGE_NAME" --namespace="$NAMESPACE"

  else
    log_error "No pods are running. Deployment may have failed."

    # Show pod logs for debugging
    log_info "Recent pod logs:"
    kubectl logs -l app="$IMAGE_NAME" --namespace="$NAMESPACE" --tail=20

    exit 1
  fi
}

# Function to show usage
show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --build-only     Build the container image only (don't deploy)"
  echo "  --deploy-only    Deploy existing image only (don't build)"
  echo "  --skip-restart   Don't restart pods after deployment"
  echo "  --help          Show this help message"
  echo ""
  echo "Environment Variables:"
  echo "  ACR_NAME         Azure Container Registry name (default: acrmodules01)"
  echo "  IMAGE_NAME       Docker image name (default: ai-edge-inference)"
  echo "  IMAGE_VERSION    Docker image version (default: latest)"
  echo "  NAMESPACE        Kubernetes namespace (default: azure-iot-operations)"
}

# Main deployment flow
main() {
  local build_only=false
  local deploy_only=false
  local skip_restart=false

  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --build-only)
        build_only=true
        shift
        ;;
      --deploy-only)
        deploy_only=true
        shift
        ;;
      --skip-restart)
        skip_restart=true
        shift
        ;;
      --help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  log_info "Starting AI Edge Inference Service deployment"
  log_info "ACR: $ACR_NAME | Image: $IMAGE_NAME:$IMAGE_VERSION | Namespace: $NAMESPACE"

  check_prerequisites

  if [ "$deploy_only" = false ]; then
    build_image
    authenticate_acr
    push_image
  fi

  if [ "$build_only" = false ]; then
    generate_patches
    apply_manifests

    if [ "$skip_restart" = false ]; then
      restart_pods
    fi

    wait_for_rollout
    verify_deployment
  fi

  log_success "AI Edge Inference Service deployment completed successfully!"

  if [ "$build_only" = false ]; then
    echo ""
    log_info "You can check the service status with:"
    echo "  kubectl get pods -l app=\"$IMAGE_NAME\" -n \"$NAMESPACE\""
    echo "  kubectl logs -l app=\"$IMAGE_NAME\" -n \"$NAMESPACE\""
    echo ""
    log_info "Access the service endpoints:"
    echo "  Health: kubectl port-forward svc/\"$IMAGE_NAME\" 8081:8081 -n \"$NAMESPACE\""
    echo "  Metrics: kubectl port-forward svc/\"$IMAGE_NAME\" 8080:8080 -n \"$NAMESPACE\""
  fi
}

# Run main function with all arguments
main "$@"
