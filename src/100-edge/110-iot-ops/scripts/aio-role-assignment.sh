#!/usr/bin/env bash

set -e
set -o pipefail

## Required Environment Variables:

ARC_RESOURCE_GROUP_NAME="${ARC_RESOURCE_GROUP_NAME:-}" # The Resource Group name where the Azure Arc cluster is connected
ARC_RESOURCE_NAME="${ARC_RESOURCE_NAME:-}"             # The name of the Azure Arc cluster
TARGET_RESOURCE_NAME="${TARGET_RESOURCE_NAME:-}"       # The name of the target resource

## Optional Environment Variables:

SHOULD_ASSIGN_PUBLISHING_ROLE="${SHOULD_ASSIGN_PUBLISHING_ROLE:-true}"               # Assign publishing/sending role (defaults to true)
SHOULD_ASSIGN_SUBSCRIBING_ROLE="${SHOULD_ASSIGN_SUBSCRIBING_ROLE:-true}"             # Assign subscribing/receiving role (defaults to true)
TARGET_RESOURCE_GROUP_NAME="${TARGET_RESOURCE_GROUP_NAME:-$ARC_RESOURCE_GROUP_NAME}" # The Resource Group name where the target resource is located (defaults to ARC_RESOURCE_GROUP_NAME)

## Examples
##   ARC_RESOURCE_GROUP_NAME=rg-sample-eastu2-001 ARC_RESOURCE_NAME=arck-sample-001 TARGET_RESOURCE_NAME=ehn-sample ./aio-role-assignment.sh
##   ARC_RESOURCE_GROUP_NAME=rg-sample-eastu2-001 ARC_RESOURCE_NAME=arck-sample-001 SHOULD_ASSIGN_PUBLISHING_ROLE=false TARGET_RESOURCE_NAME=egn-sample ./aio-role-assignment.sh
###

####
# Functions
####

log() {
  printf "========== %s ==========\n" "$1"
}

err() {
  printf "[ ERROR ]: %s\n" "$1" >&2
  exit 1
}

usage() {
  echo "usage: ${0##*./}"
  grep -x -B99 -m 1 "^###" "$0" \
    | sed -E -e '/^[^#]+=/ {s/^([^ ])/  \1/ ; s/#/ / ; s/=[^ ]*$// ;}' \
    | sed -E -e ':x' -e '/^[^#]+=/ {s/^(  [^ ]+)[^ ] /\1  / ;}' -e 'tx' \
    | sed -e 's/^## //' -e '/^#/d' -e '/^$/d'
  exit 1
}

enable_debug() {
  echo "[ DEBUG ]: Enabling writing out all commands being executed"
  set -x
}

get_iot_operations_identity() {
  log "Getting IoT Operations identity information"

  principal_id=""
  identity_description=""

  log "Checking for IoT Operations User Assigned Managed Identity"
  if user_assigned_identity=$(az resource list \
    --resource-group "$ARC_RESOURCE_GROUP_NAME" \
    --resource-type "Microsoft.IoTOperations/instances" \
    --query "[0].identity.userAssignedIdentities.*.principalId | [0]" \
    --output tsv 2>/dev/null) && [[ -n "$user_assigned_identity" ]]; then

    principal_id="$user_assigned_identity"
    identity_description="IoT Operations User Assigned Managed Identity"
    log "Found IoT Operations User Assigned Managed Identity: $principal_id"
    return 0
  fi

  log "No managed identity found, checking for AIO Extension Principal ID"
  if aio_extension_id=$(
    az k8s-extension list \
      --cluster-type connectedClusters \
      --cluster-name "$ARC_RESOURCE_NAME" \
      --resource-group "$ARC_RESOURCE_GROUP_NAME" \
      --query "[?extensionType == 'microsoft.iotoperations'].identity.principalId | [0]" \
      --output tsv 2>/dev/null
  ) && [[ -n "$aio_extension_id" ]]; then

    principal_id="$aio_extension_id"
    identity_description="AIO Extension Principal"
    log "Found AIO Extension Principal ID: $principal_id"
    return 0
  fi

  err "Could not determine identity to assign roles to. No IoT Operations instance with managed identity or AIO extension found"
}

assign_role() {
  local role="$1"
  local principal_id="$2"
  local scope="$3"
  local description="$4"

  log "Assigning $role role to $description: $principal_id"
  if ! az role assignment create \
    --role "$role" \
    --assignee-object-id "$principal_id" \
    --assignee-principal-type "ServicePrincipal" \
    --scope "$scope"; then
    err "Failed to assign $role role to $description"
  fi
}

process_service_role_assignments() {
  local service_name="$1"
  local resource_type="$2"
  local publishing_role="$3"
  local subscribing_role="$4"

  log "Processing $service_name role assignments"

  log "Getting $service_name Resource ID"
  if ! service_resource_id=$(az resource show \
    --resource-group "$TARGET_RESOURCE_GROUP_NAME" \
    --name "$TARGET_RESOURCE_NAME" \
    --resource-type "$resource_type" \
    --query id \
    --output tsv); then
    err "Failed to get $service_name Resource ID for '$TARGET_RESOURCE_NAME' in resource group '$TARGET_RESOURCE_GROUP_NAME'"
  fi

  if [[ ${SHOULD_ASSIGN_PUBLISHING_ROLE,,} == "true" ]]; then
    assign_role "$publishing_role" "$principal_id" "$service_resource_id" "$identity_description"
  fi

  if [[ ${SHOULD_ASSIGN_SUBSCRIBING_ROLE,,} == "true" ]]; then
    assign_role "$subscribing_role" "$principal_id" "$service_resource_id" "$identity_description"
  fi
}

detect_target_resource_type() {
  log "Detecting target resource type for '$TARGET_RESOURCE_NAME'"

  if ! target_resource_type=$(az resource list \
    --resource-group "$TARGET_RESOURCE_GROUP_NAME" \
    --query "[?name == '$TARGET_RESOURCE_NAME'].type | [0]" \
    --output tsv 2>/dev/null) || [[ -z "$target_resource_type" ]]; then
    err "Failed to find resource '$TARGET_RESOURCE_NAME' in resource group '$TARGET_RESOURCE_GROUP_NAME'"
  fi

  log "Detected resource type: $target_resource_type"

  case "$target_resource_type" in
    "Microsoft.EventHub/namespaces")
      service_name="Event Hub Namespace"
      resource_type="Microsoft.EventHub/namespaces"
      publishing_role="Azure Event Hubs Data Sender"
      subscribing_role="Azure Event Hubs Data Receiver"
      ;;
    "Microsoft.EventGrid/namespaces")
      service_name="Event Grid Namespace"
      resource_type="Microsoft.EventGrid/namespaces"
      publishing_role="EventGrid TopicSpaces Publisher"
      subscribing_role="EventGrid TopicSpaces Subscriber"
      ;;
    *)
      err "Unsupported resource type '$target_resource_type'. Supported types: Microsoft.EventHub/namespaces, Microsoft.EventGrid/namespaces"
      ;;
  esac

  log "Configured for $service_name with publishing role '$publishing_role' and subscribing role '$subscribing_role'"
}

####
# Parameter Processing
####

if [[ $# -gt 0 ]]; then
  case "$1" in
    -d | --debug)
      enable_debug
      ;;
    -h | --help)
      usage
      ;;
    *)
      usage
      ;;
  esac
fi

####
# Validation
####

if [[ ! $ARC_RESOURCE_GROUP_NAME ]]; then
  err "'ARC_RESOURCE_GROUP_NAME' env var is required"
elif [[ ! $ARC_RESOURCE_NAME ]]; then
  err "'ARC_RESOURCE_NAME' env var is required"
elif [[ ! $TARGET_RESOURCE_NAME ]]; then
  err "'TARGET_RESOURCE_NAME' env var is required"
fi

if ! command -v "az" &>/dev/null; then
  err "'az' is missing and required"
fi

####
# Determine Identity Type and Get Principal ID
####

get_iot_operations_identity

# Global variables are now set: identity_type, principal_id, identity_description
log "Using $identity_description: $principal_id"

####
# Detect Target Resource Type and Process Role Assignments
####

detect_target_resource_type

# Process role assignments using the detected resource configuration
process_service_role_assignments "$service_name" "$resource_type" "$publishing_role" "$subscribing_role"

log "Successfully completed role assignments"
