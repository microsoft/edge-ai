#!/usr/bin/env bash

tenant=""
help="Usage: az-sub-init.sh [--tenant your-tenant.onmicrosoft.com] [--help]

Attempts to set the ARM_SUBSCRIPTION_ID env var to 'id' from 'az account show' in the following ways:
- 'az login' if not logged in (optionally with specific tenant)
- 'az account show -o tsv --query id' for the current logged in account

Needed for Terraform

Current ARM_SUBSCRIPTION_ID: ${ARM_SUBSCRIPTION_ID}"

while [[ $# -gt 0 ]]; do
  case $1 in
  --tenant)
    tenant="$2"
    shift 2
    ;;
  --help)
    echo "${help}"
    exit 0
    ;;
  *)
    echo "${help}"
    echo
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

get_current_subscription_id() {
  az account show -o tsv --query "id" 2>/dev/null
}

is_correct_tenant() {
  if [[ -z "${tenant}" ]]; then
    return 0 # No specific tenant required
  fi

  local current_tenant
  current_tenant=$(az rest --method get --url https://graph.microsoft.com/v1.0/domains \
    --query 'value[?isDefault].id' -o tsv 2>/dev/null || echo "")

  [[ "${tenant}" == "${current_tenant}" ]]
}

login_to_azure() {
  echo "Logging into Azure..."
  if [[ -n "${tenant}" ]]; then
    if ! az login --tenant "${tenant}"; then
      echo "Error: Failed to login to Azure with tenant ${tenant}"
      exit 1
    fi
  else
    if ! az login; then
      echo "Error: Failed to login to Azure"
      exit 1
    fi
  fi
}

current_subscription_id=$(get_current_subscription_id)

if [[ -z "${current_subscription_id}" ]] || ! is_correct_tenant; then
  login_to_azure

  current_subscription_id=$(get_current_subscription_id)
  if [[ -z "${current_subscription_id}" ]]; then
    echo "Error: Login succeeded but could not retrieve subscription ID"
    exit 1
  fi
fi

export ARM_SUBSCRIPTION_ID="${current_subscription_id}"
echo "ARM_SUBSCRIPTION_ID set to: ${ARM_SUBSCRIPTION_ID}"
