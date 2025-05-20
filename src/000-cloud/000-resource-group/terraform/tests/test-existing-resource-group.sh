#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# Test script for validating "existing resource group" functionality
# -----------------------------------------------------------------------------
# This script creates a temporary resource group, tests the Terraform module
# with use_existing_resource_group=true, validates outputs, and cleans up.
# -----------------------------------------------------------------------------

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
NC="\033[0m" # No Color

# Configuration
TEMP_RG_PREFIX="temp-rg-test"
LOCATION="eastus"
MODULE_DIR="$(realpath "$(dirname "$0")/../")"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
TEMP_RG_NAME="${TEMP_RG_PREFIX}-${TIMESTAMP}"
TEMP_DIR="${MODULE_DIR}/test-tmp-${TIMESTAMP}"
LOG_FILE="${TEMP_DIR}/test-log.txt"

# Function to log messages
log() {
  local msg_type="$1"
  local message="$2"
  local color=""

  case "$msg_type" in
  "INFO") color="$BLUE" ;;
  "SUCCESS") color="$GREEN" ;;
  "ERROR") color="$RED" ;;
  "WARNING") color="$YELLOW" ;;
  *) color="$NC" ;;
  esac

  echo -e "${color}${BOLD}[$msg_type]${NC} $message" | tee -a "$LOG_FILE"
}

# Function to clean up resources
cleanup() {
  log "INFO" "Cleaning up resources..."

  # Delete temporary resource group if it exists
  if az group show --name "$TEMP_RG_NAME" &>/dev/null; then
    log "INFO" "Deleting resource group: $TEMP_RG_NAME"
    az group delete --name "$TEMP_RG_NAME" --yes --no-wait
  fi

  # Remove temporary directory
  log "INFO" "Removing temporary directory: $TEMP_DIR"
  rm -rf "$TEMP_DIR"

  log "SUCCESS" "Cleanup completed"
}

# Function to handle errors
handle_error() {
  log "ERROR" "An error occurred during testing. See log file for details: $LOG_FILE"
  cleanup
  exit 1
}

# Set up error handling
trap handle_error ERR

# Create temporary directory for test
mkdir -p "$TEMP_DIR"
log "INFO" "Created temporary directory: $TEMP_DIR"
log "INFO" "Log file: $LOG_FILE"

# Check if Azure CLI is logged in
log "INFO" "Checking Azure CLI login status..."
if ! az account show &>/dev/null; then
  log "ERROR" "Azure CLI is not logged in. Please login with 'az login'"
  exit 1
fi

# Get subscription ID for Terraform
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
log "INFO" "Using Azure subscription: $SUBSCRIPTION_ID"

# Step 1: Create temporary resource group
log "INFO" "Creating temporary resource group: $TEMP_RG_NAME"
az group create --name "$TEMP_RG_NAME" --location "$LOCATION" --tags "purpose=testing" "temporary=true" "created=$(date +%Y-%m-%d)" >>"$LOG_FILE" 2>&1

# Verify resource group was created
if ! az group show --name "$TEMP_RG_NAME" &>/dev/null; then
  log "ERROR" "Failed to create resource group: $TEMP_RG_NAME"
  exit 1
fi

log "SUCCESS" "Created temporary resource group: $TEMP_RG_NAME"

# Create temporary Terraform configuration
cat >"$TEMP_DIR/main.tf" <<EOF
# Test configuration for existing resource group functionality
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "${MODULE_DIR}"

  # Required variables
  resource_prefix     = "rgtest"
  environment         = "dev"
  instance            = "001"
  location            = "${LOCATION}"

  # Test existing resource group
  use_existing_resource_group = true
  resource_group_name = "${TEMP_RG_NAME}"
}

# Output all module outputs for validation
output "resource_group_name" {
  value = module.resource_group.resource_group_name
}

output "resource_group_id" {
  value = module.resource_group.resource_group_id
}

output "resource_group_location" {
  value = module.resource_group.resource_group_location
}
EOF

# Step 2: Initialize and apply Terraform
log "INFO" "Initializing Terraform in temporary directory..."
cd "$TEMP_DIR"
export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
terraform init >>"$LOG_FILE" 2>&1

log "INFO" "Running Terraform apply..."
terraform apply -auto-approve >>"$LOG_FILE" 2>&1

# Step 3: Verify outputs
log "INFO" "Verifying Terraform outputs..."

# Get output values
TF_RG_NAME=$(terraform output -raw resource_group_name)
TF_RG_LOCATION=$(terraform output -raw resource_group_location)

# Verify resource group name output matches the expected name
if [ "$TF_RG_NAME" != "$TEMP_RG_NAME" ]; then
  log "ERROR" "Resource group name output mismatch: Expected '$TEMP_RG_NAME', got '$TF_RG_NAME'"
  cleanup
  exit 1
fi

# Verify resource group location matches the expected location
if [ "$TF_RG_LOCATION" != "$LOCATION" ]; then
  log "ERROR" "Resource group location output mismatch: Expected '$LOCATION', got '$TF_RG_LOCATION'"
  cleanup
  exit 1
fi

log "SUCCESS" "Terraform outputs verified successfully!"

# Check if Terraform created a new resource group by mistake
RG_COUNT=$(az group list --query "[?starts_with(name, 'rg-rgtest-dev-001')].name" -o tsv | wc -l)
if [ "$RG_COUNT" -gt 0 ]; then
  log "ERROR" "Terraform created a new resource group even though use_existing_resource_group=true"
  # Find and delete the incorrectly created resource group
  NEW_RG=$(az group list --query "[?starts_with(name, 'rg-rgtest-dev-001')].name" -o tsv)
  log "WARNING" "Deleting incorrectly created resource group: $NEW_RG"
  az group delete --name "$NEW_RG" --yes --no-wait
  cleanup
  exit 1
fi

log "SUCCESS" "Terraform correctly used the existing resource group without creating a new one!"

# Step 4: Clean up resources
cleanup

# Final success message
log "SUCCESS" "All tests passed! The module correctly handles existing resource groups."
echo -e "\n${GREEN}${BOLD}✓ TEST PASSED${NC}"
