#!/usr/bin/env bash

# ==============================================================================
# Basic Inference Workload Orchestration Setup
# ==============================================================================
# This script sets up workload orchestration for the Basic Inference application
# using Kalypso. It leverages the basic-inference-cicd.sh script for repository
# setup and then configures Kalypso for multi-cluster orchestration.
#
# Prerequisites:
#   - Azure CLI installed and authenticated
#   - GitHub CLI installed and authenticated
#   - kubectl configured with access to target clusters
#   - Required environment variables: TOKEN, AZURE_CREDENTIALS_SP
#
# Usage:
#   ./basic-inference-workload.sh --org <org> --cluster <cluster> --rg <resource-group>
#   ./basic-inference-workload.sh --cleanup --org <org> --cluster <cluster> --rg <resource-group>
# ==============================================================================

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
CICD_SCRIPT="${WORKSPACE_ROOT}/src/501-ci-cd/basic-inference-cicd/basic-inference-cicd.sh"

# Default values
PROJECT_NAME="basic-inference-orchestration"
CLEANUP_MODE=false
KALYPSO_LOCATION="westus2"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# Utility Functions
# ==============================================================================

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Setup or cleanup workload orchestration for the Basic Inference Application
using Kalypso across multiple Kubernetes clusters.

Required Options:
    -o, --org ORG                       GitHub organization name

    # Azure Arc Cluster (existing - for application deployment)
    -c, --arc-cluster CLUSTER           Azure Arc-enabled cluster name
    -r, --arc-rg RESOURCE_GROUP         Resource group for Arc cluster

    # AKS Cluster (for Kalypso control plane)
    -k, --kalypso-cluster CLUSTER       AKS cluster name for Kalypso scheduler
    -g, --kalypso-rg RESOURCE_GROUP     Resource group for Kalypso AKS cluster

Optional Options:
    -p, --project PROJECT               Project name (default: basic-inference-orchestration)
    -l, --kalypso-location LOCATION     Azure region for Kalypso cluster (default: eastus)
    --cleanup                           Cleanup mode - removes all resources

Environment Variables (required):
    TOKEN                               GitHub personal access token
    AZURE_CREDENTIALS_SP                Azure service principal credentials JSON

Examples:
    # Setup workload orchestration
    $0 --org mycompany \\
       --arc-cluster my-arc-cluster --arc-rg rg-arc \\
       --kalypso-cluster my-kalypso-aks --kalypso-rg rg-kalypso

    # Cleanup resources
    $0 --cleanup --org mycompany \\
       --arc-cluster my-arc-cluster --arc-rg rg-arc \\
       --kalypso-cluster my-kalypso-aks --kalypso-rg rg-kalypso

EOF
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

parse_arguments() {
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
        # Azure Arc cluster parameters
        -c | --arc-cluster)
            ARC_CLUSTER_NAME="$2"
            shift 2
            ;;
        -r | --arc-rg)
            ARC_RESOURCE_GROUP="$2"
            shift 2
            ;;
        # Kalypso AKS cluster parameters
        -k | --kalypso-cluster)
            KALYPSO_CLUSTER_NAME="$2"
            shift 2
            ;;
        -g | --kalypso-rg)
            KALYPSO_RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l | --kalypso-location)
            KALYPSO_LOCATION="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP_MODE=true
            shift
            ;;
        -h | --help)
            print_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
        esac
    done

    # Validate required parameters
    if [[ -z "${GITHUB_ORG:-}" ]]; then
        print_error "GitHub organization is required"
        print_usage
        exit 1
    fi

    if [[ -z "${ARC_CLUSTER_NAME:-}" ]]; then
        print_error "Azure Arc cluster name is required (--arc-cluster)"
        print_usage
        exit 1
    fi

    if [[ -z "${ARC_RESOURCE_GROUP:-}" ]]; then
        print_error "Azure Arc resource group is required (--arc-rg)"
        print_usage
        exit 1
    fi

    if [[ -z "${KALYPSO_CLUSTER_NAME:-}" ]]; then
        print_error "Kalypso AKS cluster name is required (--kalypso-cluster)"
        print_usage
        exit 1
    fi

    if [[ -z "${KALYPSO_RESOURCE_GROUP:-}" ]]; then
        print_error "Kalypso resource group is required (--kalypso-rg)"
        print_usage
        exit 1
    fi

    # Display configuration
    if [[ "$CLEANUP_MODE" == "true" ]]; then
        print_header "Configuration (CLEANUP MODE)"
    else
        print_header "Configuration"
    fi
    print_info "  GitHub Org: ${GITHUB_ORG}"
    print_info "  Project Name: ${PROJECT_NAME}"
    print_info ""
    print_info "  Azure Arc Cluster (for applications):"
    print_info "    Name: ${ARC_CLUSTER_NAME}"
    print_info "    Resource Group: ${ARC_RESOURCE_GROUP}"
    print_info ""
    print_info "  Kalypso AKS Cluster (control plane):"
    print_info "    Name: ${KALYPSO_CLUSTER_NAME}"
    print_info "    Resource Group: ${KALYPSO_RESOURCE_GROUP}"
    print_info "    Location: ${KALYPSO_LOCATION}"
}

# ==============================================================================
# Prerequisites Validation
# ==============================================================================

validate_prerequisites() {
    print_header "Validating Prerequisites"

    # Check for CI/CD script
    if [[ ! -f "$CICD_SCRIPT" ]]; then
        print_error "CI/CD script not found at: ${CICD_SCRIPT}"
        exit 1
    fi
    print_success "CI/CD script found"

    # Check required commands
    local required_commands=("az" "gh" "kubectl" "helm" "git" "jq")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            print_error "Required command not found: $cmd"
            exit 1
        fi
    done
    print_success "All required commands available"

    # Check environment variables
    if [[ -z "${TOKEN:-}" ]]; then
        print_error "TOKEN environment variable not set"
        print_info "Please set: export TOKEN='ghp_xxxxxxxxxxxxxxxxxxxx'"
        exit 1
    fi
    print_success "GitHub token is set"

    if [[ "$CLEANUP_MODE" == "false" ]]; then
        if [[ -z "${AZURE_CREDENTIALS_SP:-}" ]]; then
            print_warning "AZURE_CREDENTIALS_SP not set (optional for cleanup)"
        else
            print_success "Azure credentials are set"
        fi
    fi

    # Verify Azure login
    if ! az account show &>/dev/null; then
        print_error "Not logged in to Azure CLI"
        print_info "Please run 'az login'"
        exit 1
    fi
    print_success "Azure CLI is logged in"

    # Verify GitHub login
    if ! gh auth status &>/dev/null; then
        print_error "Not logged in to GitHub CLI"
        print_info "Please run 'gh auth login'"
        exit 1
    fi
    print_success "GitHub CLI is authenticated"
}

# ==============================================================================
# Main Setup Functions
# ==============================================================================

setup_cicd_repositories() {
    print_header "Step 1: Setting up CI/CD Repositories (without Flux)"

    print_info "Running basic-inference-cicd.sh with --skip-flux..."
    print_info "This will create GitHub repositories and CI/CD workflows"
    print_info "Target Arc cluster: ${ARC_CLUSTER_NAME} (${ARC_RESOURCE_GROUP})"

    if bash "$CICD_SCRIPT" \
        --org "$GITHUB_ORG" \
        --project "$PROJECT_NAME" \
        --cluster "$ARC_CLUSTER_NAME" \
        --rg "$ARC_RESOURCE_GROUP" \
        --skip-flux; then
        print_success "CI/CD repositories and workflows created successfully"
    else
        print_error "Failed to set up CI/CD repositories"
        exit 1
    fi
}

setup_kalypso_orchestration() {
    print_header "Step 2: Setting up Kalypso Workload Orchestration"

    print_info "Bootstrapping Kalypso for multi-cluster orchestration"
    print_info "Target AKS cluster: ${KALYPSO_CLUSTER_NAME} (${KALYPSO_RESOURCE_GROUP})"

    # Create temporary directory for Kalypso
    local kalypso_tmp
    kalypso_tmp=$(mktemp -d)
    local KALYPSO_REPO_URL="https://github.com/microsoft/kalypso"
    local KALYPSO_REF="${KALYPSO_REF:-main}"

    print_info "Cloning Kalypso repository (${KALYPSO_REPO_URL}@${KALYPSO_REF})..."
    if git clone --depth 1 --branch "$KALYPSO_REF" "$KALYPSO_REPO_URL" "$kalypso_tmp/kalypso"; then
        print_success "Kalypso repository cloned"
    else
        print_error "Failed to clone Kalypso repository (ref: ${KALYPSO_REF})"
        rm -rf "$kalypso_tmp"
        exit 1
    fi

    # Navigate to bootstrap directory
    local bootstrap_dir="$kalypso_tmp/kalypso/scripts/bootstrap"
    if [[ ! -d "$bootstrap_dir" ]]; then
        print_error "Bootstrap directory not found at: $bootstrap_dir"
        rm -rf "$kalypso_tmp"
        exit 1
    fi

    pushd "$bootstrap_dir" > /dev/null || exit 1

    # Check if bootstrap script exists
    if [[ ! -x "./bootstrap.sh" ]]; then
        print_error "Bootstrap script not found or not executable"
        popd > /dev/null
        rm -rf "$kalypso_tmp"
        exit 1
    fi

    print_info "Running Kalypso bootstrap script..."
    print_info "  Cluster: ${KALYPSO_CLUSTER_NAME}"
    print_info "  Resource Group: ${KALYPSO_RESOURCE_GROUP}"
    print_info "  Location: ${KALYPSO_LOCATION}"
    print_info "  Control Plane Repo: kalypso-control-plane"
    print_info "  GitOps Repo: kalypso-platform-gitops"

    # Export required environment variable
    export GITHUB_TOKEN="${TOKEN}"

    # Run bootstrap script
    if ./bootstrap.sh \
        --cluster-name "$KALYPSO_CLUSTER_NAME" \
        --resource-group "$KALYPSO_RESOURCE_GROUP" \
        --location "$KALYPSO_LOCATION" \
        --create-cluster \
        --create-repos \
        --control-plane-repo "kalypso-control-plane" \
        --gitops-repo "kalypso-platform-gitops" \
        --github-org "$GITHUB_ORG" \
        --non-interactive; then
        print_success "Kalypso bootstrap completed successfully"
    else
        print_error "Kalypso bootstrap failed"
        popd > /dev/null
        rm -rf "$kalypso_tmp"
        exit 1
    fi

    popd > /dev/null

    # Cleanup temporary directory
    rm -rf "$kalypso_tmp"
    print_success "Kalypso orchestration configured"
}

setup_workload_manifest() {
    print_header "Step 3: Adding Workload Manifest to Source Repository"

    print_info "Cloning application source repository..."
    local tmp_dir
    tmp_dir=$(mktemp -d)

    if ! git clone "https://github.com/${GITHUB_ORG}/${PROJECT_NAME}.git" "$tmp_dir/source" 2>/dev/null; then
        print_error "Failed to clone source repository"
        rm -rf "$tmp_dir"
        exit 1
    fi
    print_success "Source repository cloned"

    pushd "$tmp_dir/source" > /dev/null || exit 1

    # Create workload directory
    print_info "Creating workload directory..."
    mkdir -p workload

    # Generate workload.yaml from template
    print_info "Generating workload.yaml from template..."
    local template_path="${SCRIPT_DIR}/templates/workload.yaml"

    if [[ ! -f "$template_path" ]]; then
        print_error "Template file not found: $template_path"
        popd > /dev/null
        rm -rf "$tmp_dir"
        exit 1
    fi

    # Substitute variables in template
    sed -e "s/\${PROJECT_NAME}/${PROJECT_NAME}/g" \
        -e "s/\${GITHUB_ORG}/${GITHUB_ORG}/g" \
        "$template_path" > workload/workload.yaml

    print_success "Workload manifest created"

    # Commit and push changes
    print_info "Committing workload manifest..."
    git config user.name "GitHub Actions"
    git config user.email "actions@github.com"
    git add workload/workload.yaml

    if git diff --staged --quiet; then
        print_info "No changes to commit (workload.yaml already exists)"
    else
        git commit -m "Add Kalypso workload manifest

This manifest defines the workload deployment targets for multi-cluster orchestration:
- dev environment: ${PROJECT_NAME}-gitops/dev branch
- qa environment: ${PROJECT_NAME}-gitops/qa branch

The workload can be deployed to target clusters using Kalypso scheduler."

        print_info "Pushing changes to repository..."
        if git push origin main 2>/dev/null; then
            print_success "Workload manifest pushed to main branch"
        else
            print_error "Failed to push changes"
            popd > /dev/null
            rm -rf "$tmp_dir"
            exit 1
        fi
    fi

    popd > /dev/null
    rm -rf "$tmp_dir"
    print_success "Workload manifest added to source repository"
}

setup_qa_environment() {
    print_header "Step 4: Configuring QA Environment in Kalypso"

    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Setup Control Plane Repository
    print_info "Cloning kalypso-control-plane repository..."
    if ! git clone "https://github.com/${GITHUB_ORG}/kalypso-control-plane.git" "$tmp_dir/control-plane" 2>/dev/null; then
        print_error "Failed to clone control-plane repository"
        rm -rf "$tmp_dir"
        exit 1
    fi
    print_success "Control-plane repository cloned"

    pushd "$tmp_dir/control-plane" > /dev/null || exit 1

    # Configure git
    git config user.name "GitHub Actions"
    git config user.email "actions@github.com"

    # Create QA branch from dev
    print_info "Creating qa branch from dev..."
    git checkout dev

    # Check if qa branch already exists remotely
    if git ls-remote --heads origin qa | grep -q qa; then
        print_info "QA branch already exists, checking it out..."
        git checkout qa
        git pull origin qa 2>/dev/null || true
    else
        print_info "Creating new qa branch..."
        git checkout -b qa
    fi

    # Remove dev-specific files
    print_info "Removing dev-specific files..."
    git rm -f cluster-types/dev.yaml 2>/dev/null || true
    git rm -f configs/dev-config.yaml 2>/dev/null || true
    git rm -f scheduling-policies/default-policy.yaml 2>/dev/null || true
    git rm -f scheduling-policies/dev-policy.yaml 2>/dev/null || true

    # Add QA cluster types
    print_info "Adding QA cluster types..."
    mkdir -p cluster-types

    # Copy cluster type templates
    cp "${SCRIPT_DIR}/templates/east-us.yaml" cluster-types/east-us.yaml
    cp "${SCRIPT_DIR}/templates/west-us.yaml" cluster-types/west-us.yaml

    # Add QA config
    print_info "Adding QA configuration..."
    mkdir -p configs
    cp "${SCRIPT_DIR}/templates/qa-config.yaml" configs/qa-config.yaml

    # Add scheduling policies README
    print_info "Adding scheduling policies README..."
    mkdir -p scheduling-policies
    cp "${SCRIPT_DIR}/templates/scheduling-policies-README.md" scheduling-policies/README.md

    # Update gitops-repo.yaml
    print_info "Updating gitops-repo.yaml..."
    if [[ -f "gitops-repo.yaml" ]]; then
        sed -i.bak 's/branch: dev/branch: qa/g' gitops-repo.yaml
        sed -i.bak 's/name: dev/name: qa/g' gitops-repo.yaml
        rm -f gitops-repo.yaml.bak
    fi

    # Commit QA branch changes
    git add .
    if git diff --staged --quiet; then
        print_info "No changes to commit (QA configuration already up to date)"
    else
        git commit -m "Configure QA environment

- Add east-us and west-us cluster types
- Add QA configuration
- Update gitops repo branch to qa
- Add scheduling policies documentation" || true
    fi

    print_info "Pushing qa branch..."
    if git push origin qa 2>&1; then
        print_success "QA branch created and pushed"
    elif git push -u origin qa 2>&1; then
        print_success "QA branch created and pushed"
    else
        print_warning "Failed to push qa branch, attempting force push..."
        if git push -f origin qa 2>&1; then
            print_success "QA branch force pushed successfully"
        else
            print_warning "Could not push qa branch (may require manual intervention)"
        fi
    fi

    # Switch to main branch and add qa.yaml environment
    print_info "Adding QA environment to main branch..."
    git checkout main
    git pull origin main 2>/dev/null || true

    # Create .environments directory and qa.yaml
    mkdir -p .environments
    cp "${SCRIPT_DIR}/templates/qa.yaml" .environments/qa.yaml

    # Substitute variables in qa.yaml
    sed -i.bak "s/\${GITHUB_ORG}/${GITHUB_ORG}/g" .environments/qa.yaml
    rm -f .environments/qa.yaml.bak

    # Commit and push qa.yaml to main branch
    git add .environments/qa.yaml
    if git diff --staged --quiet; then
        print_info "No changes to commit (qa.yaml already exists)"
    else
        git commit -m "Add QA environment definition" || true
        git push origin main 2>&1 || print_warning "Failed to push qa.yaml to main branch"
    fi

    # Switch to dev branch and add NEXT_ENVIRONMENT
    print_info "Configuring dev environment with NEXT_ENVIRONMENT variable..."
    git checkout dev

    if gh api --method PUT -H "Accept: application/vnd.github+json" repos/"${GITHUB_ORG}"/kalypso-control-plane/environments/dev 2>/dev/null; then
        print_info "Creating dev environment in kalypso-control-plane..."
        if gh api --method POST -H "Accept: application/vnd.github+json" repos/"${GITHUB_ORG}"/kalypso-control-plane/environments --field name="dev" 2>/dev/null; then
            print_success "Dev environment created in kalypso-control-plane"
        else
            print_warning "Failed to create dev environment (may already exist)"
        fi
    else
        print_info "Dev environment already exists in kalypso-control-plane"
    fi

    # Set NEXT_ENVIRONMENT variable (environment will be created automatically if it doesn't exist)
    if gh variable set NEXT_ENVIRONMENT -b "qa" --env dev -R "${GITHUB_ORG}/kalypso-control-plane" 2>/dev/null; then
        print_success "NEXT_ENVIRONMENT variable set to 'qa' in dev environment"
    else
        print_warning "Failed to set NEXT_ENVIRONMENT variable (may require manual configuration)"
    fi

    popd > /dev/null

    # Setup Platform GitOps Repository
    print_info "Cloning kalypso-platform-gitops repository..."
    if ! git clone "https://github.com/${GITHUB_ORG}/kalypso-platform-gitops.git" "$tmp_dir/platform-gitops" 2>/dev/null; then
        print_error "Failed to clone platform-gitops repository"
        rm -rf "$tmp_dir"
        exit 1
    fi
    print_success "Platform-gitops repository cloned"

    pushd "$tmp_dir/platform-gitops" > /dev/null || exit 1

    # Configure git
    git config user.name "GitHub Actions"
    git config user.email "actions@github.com"

    # Create QA branch from dev
    print_info "Creating qa branch in platform-gitops..."
    git checkout dev

    # Check if qa branch already exists remotely
    if git ls-remote --heads origin qa | grep -q qa; then
        print_info "QA branch already exists in platform-gitops, checking it out..."
        git checkout qa
        print_success "QA branch already exists in platform-gitops"
    else
        print_info "Creating new qa branch in platform-gitops..."
        git checkout -b qa

        print_info "Pushing qa branch to platform-gitops..."
        if git push origin qa 2>&1 || git push -u origin qa 2>&1; then
            print_success "QA branch created in platform-gitops"
        else
            print_warning "Failed to push qa branch to platform-gitops"
        fi
    fi

    popd > /dev/null

    # Cleanup
    rm -rf "$tmp_dir"
    print_success "QA environment configured successfully"
}

configure_arc_flux_gitops() {
    print_header "Step 5: Configuring Flux GitOps on Azure Arc Cluster"

    print_info "Creating Flux configuration on Arc cluster: ${ARC_CLUSTER_NAME}"
    print_info "Repository: https://github.com/${GITHUB_ORG}/kalypso-platform-gitops"
    print_info "Branch: dev"
    print_info "Path: dev"

    # Delete existing Flux configuration if it exists
    print_info "Checking for existing Flux configuration..."
    if az k8s-configuration flux show \
        --name "platform-dev" \
        --cluster-name "${ARC_CLUSTER_NAME}" \
        --resource-group "${ARC_RESOURCE_GROUP}" \
        --cluster-type connectedClusters 2>/dev/null; then
        print_info "Deleting existing Flux configuration..."
        az k8s-configuration flux delete \
            --name "platform-dev" \
            --cluster-name "${ARC_CLUSTER_NAME}" \
            --resource-group "${ARC_RESOURCE_GROUP}" \
            --cluster-type connectedClusters \
            --yes 2>/dev/null || true
        print_success "Existing configuration removed"
        sleep 5
    fi

    # Create Flux configuration for Azure Arc cluster
    print_info "Creating Flux GitOps configuration..."
    if az k8s-configuration flux create \
        --name "platform-dev" \
        --cluster-name "${ARC_CLUSTER_NAME}" \
        --namespace flux-system \
        --https-user flux \
        --https-key "${TOKEN}" \
        --resource-group "${ARC_RESOURCE_GROUP}" \
        --url "https://github.com/${GITHUB_ORG}/kalypso-platform-gitops" \
        --scope cluster \
        --interval 10s \
        --cluster-type connectedClusters \
        --branch dev \
        --kustomization name="platform-dev" prune=true sync_interval=10s path=dev 2>&1; then
        print_success "Flux configuration created successfully"
    else
        print_warning "Flux configuration creation may have encountered issues (could be idempotent)"
    fi

    print_success "Arc cluster Flux GitOps configuration completed"
}

# ==============================================================================
# Cleanup Functions
# ==============================================================================

cleanup_kalypso_resources() {
    print_header "Cleaning up Kalypso Resources"

    # Remove Flux configurations from Arc cluster
    print_info "Removing Flux configurations from Arc cluster..."

    if az k8s-configuration flux delete \
        --name "platform-dev" \
        --cluster-name "${ARC_CLUSTER_NAME}" \
        --resource-group "${ARC_RESOURCE_GROUP}" \
        --cluster-type connectedClusters \
        --yes 2>/dev/null; then
        print_success "Flux configuration platform-dev removed from Arc cluster"
    else
        print_info "Flux configuration platform-dev not found on Arc cluster (already removed)"
    fi

    if az k8s-configuration flux delete \
        --name "platform-qa" \
        --cluster-name "${ARC_CLUSTER_NAME}" \
        --resource-group "${ARC_RESOURCE_GROUP}" \
        --cluster-type connectedClusters \
        --yes 2>/dev/null; then
        print_success "Flux configuration platform-qa removed from Arc cluster"
    else
        print_info "Flux configuration platform-qa not found on Arc cluster (already removed)"
    fi


    # Run Kalypso bootstrap cleanup
    print_info "Running Kalypso bootstrap cleanup..."
    local kalypso_tmp
    kalypso_tmp=$(mktemp -d)
    local KALYPSO_REPO_URL="https://github.com/microsoft/kalypso"
    local KALYPSO_REF="${KALYPSO_REF:-main}"

    if git clone --depth 1 --branch "$KALYPSO_REF" "$KALYPSO_REPO_URL" "$kalypso_tmp/kalypso" 2>/dev/null; then
        local bootstrap_dir="$kalypso_tmp/kalypso/scripts/bootstrap"
        if [[ -d "$bootstrap_dir" && -x "$bootstrap_dir/bootstrap.sh" ]]; then
            pushd "$bootstrap_dir" > /dev/null || exit 1

            export GITHUB_TOKEN="${TOKEN}"

            print_info "Running Kalypso bootstrap cleanup script..."
            if ./bootstrap.sh \
                --cluster-name "$KALYPSO_CLUSTER_NAME" \
                --resource-group "$KALYPSO_RESOURCE_GROUP" \
                --control-plane-repo "kalypso-control-plane" \
                --gitops-repo "kalypso-platform-gitops" \
                --github-org "$GITHUB_ORG" \
                --cleanup \
                --non-interactive 2>&1; then
                print_success "Kalypso bootstrap cleanup completed"
            else
                print_warning "Kalypso bootstrap cleanup encountered issues (may be partially cleaned)"
            fi

            popd > /dev/null
        else
            print_warning "Kalypso bootstrap script not found, performing manual cleanup"
        fi
    else
        print_warning "Failed to clone Kalypso repository, performing manual cleanup"
    fi

    rm -rf "$kalypso_tmp"

    print_success "Kalypso resources cleaned up"
}

cleanup_all() {
    print_header "Starting Cleanup Process"

    # Cleanup Kalypso resources first
    cleanup_kalypso_resources

    # Run CI/CD cleanup
    print_info "Running basic-inference-cicd.sh cleanup..."
    if bash "$CICD_SCRIPT" \
        --cleanup \
        --org "$GITHUB_ORG" \
        --project "$PROJECT_NAME" \
        --cluster "$ARC_CLUSTER_NAME" \
        --rg "$ARC_RESOURCE_GROUP"; then
        print_success "CI/CD resources cleaned up"
    else
        print_warning "CI/CD cleanup encountered issues"
    fi

    print_header "Cleanup Complete"
    print_success "All workload orchestration resources removed!"
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    parse_arguments "$@"
    validate_prerequisites

    if [[ "$CLEANUP_MODE" == "true" ]]; then
        cleanup_all
    else
        setup_cicd_repositories
        setup_kalypso_orchestration
        setup_workload_manifest
        setup_qa_environment
        configure_arc_flux_gitops

        print_header "Setup Complete - Workload Orchestration Ready!"
        print_success "All infrastructure has been created successfully!"
        echo ""

        print_header "📋 Created Resources Summary"
        echo ""

        print_info "${BLUE}AZURE RESOURCES:${NC}"
        print_info "  ${GREEN}Arc Cluster (Application Deployment):${NC}"
        print_info "    • Name: ${ARC_CLUSTER_NAME}"
        print_info "    • Resource Group: ${ARC_RESOURCE_GROUP}"
        print_info ""
        print_info "  ${GREEN}Kalypso Control Plane:${NC}"
        print_info "    • AKS Cluster: ${KALYPSO_CLUSTER_NAME}"
        print_info "    • Resource Group: ${KALYPSO_RESOURCE_GROUP}"
        print_info "    • Location: ${KALYPSO_LOCATION}"
        print_info "    • Status: Running with Flux and Kalypso Scheduler"
        echo ""

        print_info "${BLUE}GITHUB REPOSITORIES:${NC}"
        print_info "  ${GREEN}CI/CD Repositories:${NC}"
        print_info "    • Source Code: https://github.com/${GITHUB_ORG}/${PROJECT_NAME}"
        print_info "    • Configuration: https://github.com/${GITHUB_ORG}/${PROJECT_NAME}-configs"
        print_info "    • GitOps: https://github.com/${GITHUB_ORG}/${PROJECT_NAME}-gitops"
        print_info ""
        print_info "  ${GREEN}Kalypso Repositories:${NC}"
        print_info "    • Control Plane: https://github.com/${GITHUB_ORG}/kalypso-control-plane"
        print_info "    • Platform GitOps: https://github.com/${GITHUB_ORG}/kalypso-platform-gitops"
        echo ""

        print_header "🔄 Restarting Kalypso Scheduler"
        print_info "Restarting Kalypso Scheduler to ensure latest configuration is loaded..."

        # Switch to Kalypso cluster context
        az aks get-credentials --resource-group "${KALYPSO_RESOURCE_GROUP}" --name "${KALYPSO_CLUSTER_NAME}" --overwrite-existing > /dev/null 2>&1

        # Restart the Kalypso scheduler deployment
        if kubectl rollout restart deployment kalypso-scheduler-controller-manager -n kalypso-system > /dev/null 2>&1; then
            print_success "Kalypso Scheduler restart initiated"
            print_info "Waiting for deployment to be ready..."

            # Wait for the rollout to complete (with timeout)
            if kubectl rollout status deployment kalypso-scheduler-controller-manager -n kalypso-system --timeout=120s > /dev/null 2>&1; then
                print_success "Kalypso Scheduler restarted successfully"
            else
                print_warning "Kalypso Scheduler restart is taking longer than expected"
                print_info "Check status with: kubectl get pods -n kalypso-system"
            fi
        else
            print_warning "Could not restart Kalypso Scheduler (deployment may not exist yet)"
        fi
        echo ""

        print_header "🚀 Next Steps"
        print_info "1. Configure kubectl context for Arc cluster to verify GitOps:"
        print_info "   ${YELLOW}kubectl config use-context ${ARC_CLUSTER_NAME}${NC}"
        print_info "   ${YELLOW}kubectl get kustomizations -n flux-system${NC}"
        print_info ""
        print_info "2. Configure kubectl context for Kalypso cluster:"
        print_info "   ${YELLOW}az aks get-credentials --resource-group ${KALYPSO_RESOURCE_GROUP} --name ${KALYPSO_CLUSTER_NAME}${NC}"
        print_info ""
        print_info "3. Verify Kalypso Scheduler is running:"
        print_info "   ${YELLOW}kubectl get pods -n kalypso-system${NC}"
        print_info ""
        print_info "4. Configure deployment targets and scheduling policies in:"
        print_info "   ${YELLOW}https://github.com/${GITHUB_ORG}/kalypso-control-plane${NC}"
        echo ""
    fi
}

# Run main function
main "$@"
