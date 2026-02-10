#!/usr/bin/env bash

# End-to-end CI/CD Setup Script for the Basic Inference application
# This script sets up a complete GitOps CI/CD pipeline
# for the Basic Inference application using Microsoft's Kalypso framework
# on an Azure Arc-enabled Kubernetes cluster.

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
APPLICATION_SOURCE_PATH="${WORKSPACE_ROOT}/src/500-application/500-basic-inference"
DEFAULT_PROJECT_NAME="${PROJECT_NAME:-basic-inference-pipeline}"

# Global environments array - defines the CI/CD pipeline environments
ENVIRONMENTS=("dev" "qa")

parse_arguments() {
  # Initialize flags
  CLEANUP_MODE=false
  CONFIGURE_FLUX=true

  while [[ $# -gt 0 ]]; do
    case $1 in
      -o | --org)
        GITHUB_ORG="$2"
        shift 2
        ;;
      -p | --project)
        PROJECT_NAME="$2"
        shift 2
        ;;
      -c | --cluster)
        CLUSTER_NAME="$2"
        shift 2
        ;;
      -r | --rg)
        RESOURCE_GROUP="$2"
        shift 2
        ;;
      --skip-flux | --no-flux)
        CONFIGURE_FLUX=false
        shift
        ;;
      --cleanup | --delete)
        CLEANUP_MODE=true
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  # Set defaults
  PROJECT_NAME="${PROJECT_NAME:-"$DEFAULT_PROJECT_NAME"}"
  APPLICATION_SOURCE_REPO=${GITHUB_ORG}/${PROJECT_NAME}
  APPLICATION_CONFIGS_REPO=${GITHUB_ORG}/${PROJECT_NAME}-configs
  APPLICATION_GITOPS_REPO=${GITHUB_ORG}/${PROJECT_NAME}-gitops

  # Validate required parameters
  if [[ -z "$GITHUB_ORG" ]]; then
    print_error "GitHub organization is required. Use --org option or set GITHUB_ORG environment variable."
    usage
    exit 1
  fi

  # For cleanup mode, we still need cluster and resource group for Flux cleanup
  if [[ -z "$CLUSTER_NAME" ]]; then
    print_error "Cluster name is required. Use --cluster option or set CLUSTER_NAME environment variable."
    usage
    exit 1
  fi

  if [[ -z "$RESOURCE_GROUP" ]]; then
    print_error "Resource group is required. Use --rg option or set RESOURCE_GROUP environment variable."
    usage
    exit 1
  fi

  if [[ "$CLEANUP_MODE" == "true" ]]; then
    print_info "Configuration (CLEANUP MODE):"
  else
    print_info "Configuration:"
  fi
  print_info "  GitHub Org: ${GITHUB_ORG}"
  print_info "  Project Name: ${PROJECT_NAME}"
  print_info "  Cluster Name: ${CLUSTER_NAME}"
  print_info "  Resource Group: ${RESOURCE_GROUP}"
  if [[ "$CLEANUP_MODE" == "false" ]]; then
    print_info "  Application Source: ${APPLICATION_SOURCE_PATH}"
    print_info "  Configure Flux: ${CONFIGURE_FLUX}"
  fi
}

print_header() {
  echo -e "${BLUE}===========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}===========================================${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

This script sets up a complete GitOps CI/CD pipeline for the Basic Inference Application
on Azure Arc-enabled Kubernetes clusters.

OPTIONS:
    -o, --org GITHUB_ORG        GitHub organization name (required)
    -p, --project PROJECT_NAME  Project name (default: basic-inference-pipeline)
    -c, --cluster CLUSTER_NAME  Azure Arc-enabled Kubernetes cluster name (required)
    -r, --rg RESOURCE_GROUP     Azure resource group containing the Arc cluster (required)
    --skip-flux, --no-flux      Skip Flux configuration on the cluster (default: configure Flux)
    --cleanup, --delete         Delete all created resources (repositories and Flux configurations)
    -h, --help                  Show this help message

CLEANUP MODE:
    When --cleanup or --delete is specified, the script will remove:
    - GitHub repositories (source, config, gitops)
    - Flux configurations from the Arc cluster
    - Kubernetes namespaces (dev, qa)

ENVIRONMENT VARIABLES:
    TOKEN              GitHub personal access token with required scopes (required)
                       Classic: repo, workflow, write:packages, delete:packages, read:org, delete_repo
                       Fine-grained: Actions (R/W), Administration (R/W), Commit statuses (R/W),
                                   Contents (R/W), Metadata (RO), Pull requests (R/W),
                                   Secrets (R/W), Variables (R/W), Workflows (R/W)
    AZURE_CREDENTIALS_SP  Azure service principal credentials
                       Format: '{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}'
                       If not provided, setup.sh will create a new service principal

PREREQUISITES:
    - Azure Arc-enabled Kubernetes cluster (connected to Azure)
    - Azure CLI login (az login) must be performed before running this script
    - kubectl configured with access to the target cluster
    - kubectl context must be set to the target cluster

REQUIRED TOOLS:
    - git, gh (GitHub CLI), az (Azure CLI), kubectl

EOF
}

validate_prerequisites() {
  print_header "Validating Prerequisites"

  # Check if application source exists
  if [[ "$CLEANUP_MODE" == "false" ]]; then
    if [[ ! -d "$APPLICATION_SOURCE_PATH" ]]; then
      print_error "Basic inference application source not found at: ${APPLICATION_SOURCE_PATH}"
      exit 1
    fi
    print_success "Basic inference application source found"
  fi

  # Check for GitHub token
  if [[ -z "$TOKEN" ]]; then
    print_error "GitHub personal access token is required."
    print_info "Please set the TOKEN environment variable:"
    print_info "  export TOKEN='ghp_xxxxxxxxxxxxxxxxxxxx'"
    print_info ""
    print_info "Get a token from: https://github.com/settings/tokens"
    print_info ""
    print_info "Required permissions:"
    print_info "  Classic tokens: repo, workflow, write:packages, delete:packages, read:org, delete_repo"
    print_info ""
    print_info "  Fine-grained tokens:"
    print_info "    - Actions: Read/Write"
    print_info "    - Administration: Read/Write"
    print_info "    - Commit statuses: Read/Write"
    print_info "    - Contents: Read/Write"
    print_info "    - Metadata: Read Only"
    print_info "    - Pull requests: Read/Write"
    print_info "    - Secrets: Read/Write"
    print_info "    - Variables: Read/Write"
    print_info "    - Workflows: Read/Write"
    exit 1
  fi
  print_success "GitHub token is set"

  # Check for Azure credentials (only required for setup, not cleanup)
  if [[ "$CLEANUP_MODE" == "false" ]]; then
    if [[ -z "$AZURE_CREDENTIALS_SP" ]]; then
      print_error "AZURE_CREDENTIALS_SP not set"
      print_info "Please set the AZURE_CREDENTIALS_SP environment variable to use Azure service principal authentication."
      print_info "  export AZURE_CREDENTIALS_SP='{\"clientId\":\"...\",\"clientSecret\":\"...\",\"subscriptionId\":\"...\",\"tenantId\":\"...\"}'"
    else
      print_success "Azure credentials are set"
    fi
  fi

  # Check required tools
  local tools=("git" "gh" "az" "kubectl")
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      print_warning "$tool is not installed. Please install it first."
    else
      print_success "$tool is available"
    fi
  done

  # Check kubectl cluster context (required when configuring Flux or during cleanup)
  if [[ "$CONFIGURE_FLUX" == "true" || "$CLEANUP_MODE" == "true" ]]; then
    print_info "Checking kubectl cluster context..."
    if kubectl cluster-info &>/dev/null; then
      local current_context
      current_context=$(kubectl config current-context 2>/dev/null || echo "none")
      print_success "kubectl is configured with context: $current_context"

      # Verify we can access the cluster
      if kubectl get namespaces &>/dev/null; then
        print_success "kubectl can successfully access the cluster"
      else
        print_error "kubectl cannot access the cluster. Please check your cluster connection."
        print_info "Ensure kubectl is configured to access your Azure Arc cluster:"
        print_info "  kubectl config get-contexts"
        print_info "  kubectl config use-context <your-cluster-context>"
        exit 1
      fi
    else
      print_error "kubectl is not configured or cannot connect to cluster."
      print_info "Please configure kubectl to access your Azure Arc cluster:"
      print_info "  kubectl config get-contexts"
      print_info "  kubectl config use-context <your-cluster-context>"
      exit 1
    fi
  else
    print_info "Skipping kubectl validation (Flux configuration disabled)"
  fi

  # Check Azure login status
  print_info "Checking Azure CLI login status..."
  if ! az account show &>/dev/null; then
    print_error "Azure CLI is not logged in."
    print_info "Please run 'az login' before executing this script."
    exit 1
  fi
  print_success "Azure CLI is logged in"

  # Validate Azure Arc cluster connectivity (required when configuring Flux or during cleanup)
  if [[ "$CONFIGURE_FLUX" == "true" || "$CLEANUP_MODE" == "true" ]]; then
    if [[ -n "$CLUSTER_NAME" && -n "$RESOURCE_GROUP" ]]; then
      print_info "Validating Azure Arc cluster connectivity..."
      if az connectedk8s show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        print_success "Azure Arc cluster '${CLUSTER_NAME}' found and connected"
      else
        print_error "Azure Arc cluster '${CLUSTER_NAME}' not found in resource group '${RESOURCE_GROUP}'"
        print_info "Ensure your cluster is connected to Azure Arc with:"
        print_info "  az connectedk8s connect --name ${CLUSTER_NAME} --resource-group ${RESOURCE_GROUP}"
        exit 1
      fi
    fi
  else
    print_info "Skipping Azure Arc cluster validation (Flux configuration disabled)"
  fi

}

prepare_application_source() {
  print_header "Preparing Application Source Code"

  local temp_dir
  temp_dir=$(mktemp -d)
  local source_repo_url="https://github.com/${APPLICATION_SOURCE_REPO}.git"

  print_info "Cloning source repository: $source_repo_url"

  # Clone the source repository
  if git clone "$source_repo_url" "$temp_dir/source"; then
    print_success "Source repository cloned"
  else
    print_error "Failed to clone source repository"
    exit 1
  fi

  # Copy application source to repository
  print_info "Copying basic inference application source..."

  pushd "$temp_dir/source"

  cp -r "$APPLICATION_SOURCE_PATH"/charts/. ./helm
  cp -r "$APPLICATION_SOURCE_PATH"/services/pipeline/* .
  cp -r "$APPLICATION_SOURCE_PATH"/tests .

  # Add and commit changes
  git add .
  git config user.name "Kalypso Setup"
  git config user.email "setup@kalypso.dev"
  git diff-index --quiet HEAD || git commit -m "Initial commit: Basic Inference Application

- Add .NET 9.0 inference pipeline application
- Include Helm chart for Kubernetes deployment
- Add MQTT broker subchart configuration
- Configure CI/CD workflows for automated deployment"

  # Push to repository
  print_info "Pushing application source to repository..."
  if git push origin main; then
    print_success "Application source pushed successfully"
  else
    print_error "Failed to push application source"
    exit 1
  fi

  gh api --method PUT -H "Accept: application/vnd.github+json" repos/"$APPLICATION_SOURCE_REPO"/environments/dev
  gh variable set NEXT_ENVIRONMENT -e dev -b qa -R "$APPLICATION_SOURCE_REPO"

  popd
  # Cleanup
  rm -rf "$temp_dir"
}

prepare_application_config() {
  print_header "Preparing Application Configuration"
  ENVIRONMENT=$1

  local temp_dir
  temp_dir=$(mktemp -d)

  local config_repo_url="https://github.com/${APPLICATION_CONFIGS_REPO}.git"

  print_info "Cloning config repository: $config_repo_url"

  # Clone the config repository ENVIRONMENT branch
  if git clone --branch "$ENVIRONMENT" "$config_repo_url" "$temp_dir/config"; then
    print_success "Config repository cloned"
  else
    print_error "Failed to clone config repository"
    exit 1
  fi

  # Copy application config to repository
  print_info "Copying basic inference application config..."

  pushd "$temp_dir/config"

  cat <<EOF >"$PROJECT_NAME"/values.yaml
namespace: $ENVIRONMENT-$PROJECT_NAME
replicaCount: 1
resources:
  limits:
    cpu: 50m
    memory: 256Mi
  requests:
    cpu: 20m
    memory: 128Mi
EOF

  # Add and commit changes
  git add .
  git config user.name "Kalypso Setup"
  git config user.email "setup@kalypso.dev"
  git diff-index --quiet HEAD || git commit -m "Initial commit: Basic Inference Application Config"

  # Push to repository
  print_info "Pushing application config to repository..."
  if git push origin "$ENVIRONMENT"; then
    print_success "Application config pushed successfully"
  else
    print_error "Failed to push application config"
    exit 1
  fi

  popd
  # Cleanup
  rm -rf "$temp_dir"
}

configure_flux() {
  ENVIRONMENT=$1
  print_header "Configuring Flux for GitOps on Azure Arc Cluster"

  # Create Flux configuration for Azure Arc-enabled cluster
  print_info "Creating Flux configuration for ${ENVIRONMENT} environment on Arc cluster '${CLUSTER_NAME}'..."
  az k8s-configuration flux create \
    --name "$PROJECT_NAME"-"$ENVIRONMENT" \
    --cluster-name "$CLUSTER_NAME" \
    --namespace flux-system \
    --https-user flux \
    --https-key "$TOKEN" \
    --resource-group "$RESOURCE_GROUP" \
    -u https://github.com/"$APPLICATION_GITOPS_REPO" \
    --scope cluster \
    --interval 10s \
    --cluster-type connectedClusters \
    --branch "$ENVIRONMENT" \
    --kustomization name="$PROJECT_NAME"-"$ENVIRONMENT" prune=true sync_interval=10s path="$PROJECT_NAME"

  print_success "Flux configuration completed successfully for ${ENVIRONMENT} environment"

  if kubectl create namespace "$ENVIRONMENT"-"$PROJECT_NAME" --dry-run=client -o yaml | kubectl apply -f -; then
    print_success "Namespace ${ENVIRONMENT}-${PROJECT_NAME} created successfully"
  else
    print_error "Failed to create namespace ${ENVIRONMENT}-${PROJECT_NAME}"
    exit 1
  fi

  if kubectl create secret docker-registry cr-secret \
    --docker-server=https://ghcr.io/"$APPLICATION_SOURCE_REPO" \
    --docker-username=ghcr \
    --docker-password="$TOKEN" \
    --namespace "$ENVIRONMENT"-"$PROJECT_NAME" \
    --dry-run=client -o yaml | kubectl apply -f -; then
    print_success "Docker secret cr-secret created successfully in namespace ${ENVIRONMENT}-${PROJECT_NAME}"
  else
    print_error "Failed to create docker secret cr-secret in namespace ${ENVIRONMENT}-${PROJECT_NAME}"
    exit 1
  fi

}

cleanup_flux_configurations() {
  print_header "Removing Flux Configurations"

  for env in "${ENVIRONMENTS[@]}"; do
    print_info "Removing Flux configuration for $env environment..."

    if az k8s-configuration flux delete \
      --name "${PROJECT_NAME}-$env" \
      --cluster-name "$CLUSTER_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --cluster-type connectedClusters \
      --yes &>/dev/null; then
      print_success "Flux configuration ${PROJECT_NAME}-$env removed"
    else
      print_warning "Flux configuration ${PROJECT_NAME}-$env not found or already removed"
    fi
  done
}

cleanup_kubernetes_resources() {
  print_header "Removing Kubernetes Resources"

  for env in "${ENVIRONMENTS[@]}"; do
    local ns="$env-${PROJECT_NAME}"
    print_info "Removing namespace $ns..."

    if kubectl delete namespace "$ns" --ignore-not-found=true; then
      print_success "Namespace $ns removed"
    else
      print_warning "Namespace $ns not found or already removed"
    fi
  done
}

cleanup_github_repositories() {
  print_header "Removing GitHub Repositories"

  local repos=("$APPLICATION_SOURCE_REPO" "$APPLICATION_CONFIGS_REPO" "$APPLICATION_GITOPS_REPO")

  for repo in "${repos[@]}"; do
    print_info "Removing repository ${repo}..."

    if gh repo delete "${repo}" --yes &>/dev/null; then
      print_success "Repository ${repo} removed"
    else
      print_warning "Repository ${repo} not found or already removed"
    fi
  done
}

confirm_cleanup() {
  print_header "Cleanup Confirmation"

  print_warning "This will DELETE the following resources:"
  print_info "  📁 GitHub Repositories:"
  print_info "    - ${APPLICATION_SOURCE_REPO}"
  print_info "    - ${APPLICATION_CONFIGS_REPO}"
  print_info "    - ${APPLICATION_GITOPS_REPO}"
  print_info "  ☸️  Flux Configurations:"
  for env in "${ENVIRONMENTS[@]}"; do
    print_info "    - ${PROJECT_NAME}-$env"
  done
  print_info "  🗂️  Kubernetes Namespaces:"
  for env in "${ENVIRONMENTS[@]}"; do
    print_info "    - $env-${PROJECT_NAME}"
  done

}

perform_cleanup() {
  print_header "Starting Cleanup Process"

  confirm_cleanup
  cleanup_flux_configurations
  cleanup_kubernetes_resources
  cleanup_github_repositories

  print_header "Cleanup Complete"
  print_success "All resources have been successfully removed!"

  print_info "Summary:"
  print_info "  ✅ GitHub repositories deleted"
  print_info "  ✅ Flux configurations removed"
  print_info "  ✅ Kubernetes namespaces deleted"

  echo
  print_info "The cleanup process is complete. You can now re-run the setup script to recreate the resources."
}

prepare_application_repositories() {
  # Clone Kalypso repo once for all environments
  local kalypso_tmp
  # Create a temporary directory for the Kalypso repo in the folder where the script is located

  kalypso_tmp=$(mktemp -d)
  local KALYPSO_REPO_URL="https://github.com/microsoft/kalypso"
  local KALYPSO_REF="${KALYPSO_REF:-main}"
  print_header "Cloning Kalypso repository (${KALYPSO_REPO_URL}@${KALYPSO_REF})..."
  if git clone --depth 1 --branch "$KALYPSO_REF" "$KALYPSO_REPO_URL" "$kalypso_tmp/kalypso"; then
    print_success "Kalypso repository cloned"
  else
    print_error "Failed to clone Kalypso repository (ref: ${KALYPSO_REF})"
    rm -rf "$kalypso_tmp"
    exit 1
  fi

  local setup_script="$kalypso_tmp/kalypso/cicd/setup.sh"
  if [[ ! -x "$setup_script" ]]; then
    print_error "Kalypso setup.sh not found or not executable at expected path: $setup_script"
    rm -rf "$kalypso_tmp"
    exit 1
  fi

  # Setup repositories and configurations for each environment
  for env in "${ENVIRONMENTS[@]}"; do
    pushd "$kalypso_tmp/kalypso/cicd" >/dev/null || exit 1
    print_header "Running Kalypso GitOps Setup for environment: $env"
    if ./setup.sh -o "$GITHUB_ORG" -r "$PROJECT_NAME" -e "$env"; then
      print_success "Kalypso setup completed successfully for environment $env"
    else
      print_error "Kalypso setup failed for environment $env"
      rm -rf "$kalypso_tmp"
      exit 1
    fi
    popd
    prepare_application_config "$env"
  done

  # Prepare application source (once for all environments)
  prepare_application_source

  # Cleanup Kalypso repo
  rm -rf "$kalypso_tmp"
}

prepare_flux_configurations() {
  if [[ "$CONFIGURE_FLUX" == "false" ]]; then
    print_header "Skipping Flux Configuration"
    print_info "Flux configuration disabled via --skip-flux flag"
    print_info "To configure Flux later, run the script again without --skip-flux"
    return 0
  fi

  print_header "Configuring Flux for Each Environment"

  for env in "${ENVIRONMENTS[@]}"; do
    configure_flux "$env"
  done

  print_success "Flux configurations completed for all environments"
}

main() {
  # Parse arguments first to determine mode
  parse_arguments "$@"

  if [[ "$CLEANUP_MODE" == "true" ]]; then
    print_header "Basic Inference Application CI/CD Cleanup"
    validate_prerequisites
    perform_cleanup
  else
    print_header "Basic Inference Application CI/CD Setup"
    validate_prerequisites
    prepare_application_repositories
    prepare_flux_configurations

    print_header "Setup Complete - Basic Inference CI/CD Pipeline Ready"
  fi
}

# Run main function with all arguments
main "$@"
