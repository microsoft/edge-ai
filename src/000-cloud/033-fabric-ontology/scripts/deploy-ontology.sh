#!/usr/bin/env bash
# shellcheck disable=SC1091
# deploy-ontology.sh - Deploy Fabric Ontology from ontology definition
#
# Creates entity types, properties, data bindings, relationships, and contextualizations
# using the Microsoft Fabric Ontology REST API.
#
# Dependencies: curl, jq, yq, az (Azure CLI), uuidgen
#
# Usage:
#   ./deploy-ontology.sh --definition <path> --workspace-id <id> --lakehouse-id <id> \
#     --eventhouse-id <id> --cluster-uri <uri>

set -e
set -o pipefail

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/definition-parser.sh"
source "$SCRIPT_DIR/lib/fabric-api.sh"

####
# Configuration
####

DEFINITION_FILE=""
WORKSPACE_ID=""
LAKEHOUSE_ID=""
EVENTHOUSE_ID=""
KQL_DATABASE_ID=""
CLUSTER_URI=""
DRY_RUN="false"

# Associative arrays for ID tracking (entity name -> generated ID)
declare -A ENTITY_TYPE_IDS
declare -A PROPERTY_IDS
declare -A RELATIONSHIP_IDS

####
# Usage and Argument Parsing
####

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy Fabric Ontology from ontology definition.

Required Arguments:
  --definition <path>     Path to ontology definition YAML file
  --workspace-id <id>     Fabric workspace ID (GUID)
  --lakehouse-id <id>     Lakehouse ID for static data bindings (GUID)

Conditional Arguments (required if eventhouse tables exist):
  --eventhouse-id <id>    Eventhouse ID for time-series bindings (GUID)
  --cluster-uri <uri>     Kusto cluster URI (e.g., https://xxx.kusto.fabric.microsoft.com)

Optional Arguments:
  --kql-database-id <id>  KQL Database ID (for reference)

Options:
  --dry-run               Show what would be created without making changes
  -h, --help              Show this help message

Examples:
  # Static data only (lakehouse)
  $(basename "$0") --definition ./definitions/examples/lakeshore-retail.yaml \\
    --workspace-id abc123 --lakehouse-id def456

  # With time-series data (lakehouse + eventhouse)
  $(basename "$0") --definition ./definitions/examples/lakeshore-retail.yaml \\
    --workspace-id abc123 --lakehouse-id def456 \\
    --eventhouse-id ghi789 --cluster-uri https://xyz.kusto.fabric.microsoft.com
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --definition)
      DEFINITION_FILE="$2"
      shift 2
      ;;
    --workspace-id)
      WORKSPACE_ID="$2"
      shift 2
      ;;
    --lakehouse-id)
      LAKEHOUSE_ID="$2"
      shift 2
      ;;
    --eventhouse-id)
      EVENTHOUSE_ID="$2"
      shift 2
      ;;
    --kql-database-id)
      KQL_DATABASE_ID="$2"
      shift 2
      ;;
    --cluster-uri)
      CLUSTER_URI="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown argument: $1"
      ;;
  esac
done

# Validate required arguments
if [[ -z "$DEFINITION_FILE" ]]; then
  err "Missing required argument: --definition"
fi

if [[ ! -f "$DEFINITION_FILE" ]]; then
  err "Definition file not found: $DEFINITION_FILE"
fi

if [[ -z "$WORKSPACE_ID" ]]; then
  err "Missing required argument: --workspace-id"
fi

if [[ -z "$LAKEHOUSE_ID" ]]; then
  err "Missing required argument: --lakehouse-id"
fi

# Check for eventhouse requirements if time-series data exists
HAS_EVENTHOUSE=$(get_eventhouse_name "$DEFINITION_FILE")
if [[ -n "$HAS_EVENTHOUSE" && "$HAS_EVENTHOUSE" != "null" ]]; then
  if [[ -z "$EVENTHOUSE_ID" ]]; then
    err "Eventhouse ID required when definition contains eventhouse data sources (--eventhouse-id)"
  fi
  if [[ -z "$CLUSTER_URI" ]]; then
    err "Cluster URI required when definition contains eventhouse data sources (--cluster-uri)"
  fi
fi

####
# Validation
####

log "Validating Definition"
info "Validating definition: $DEFINITION_FILE"

if ! "$SCRIPT_DIR/validate-definition.sh" --definition "$DEFINITION_FILE"; then
  err "Definition validation failed"
fi

info "Definition validation passed"

####
# Extract Metadata
####

log "Extracting Definition Metadata"

ONTOLOGY_NAME=$(get_metadata_name "$DEFINITION_FILE")
ONTOLOGY_DESC=$(get_metadata_description "$DEFINITION_FILE")
DATABASE_NAME=$(get_eventhouse_database "$DEFINITION_FILE")

info "Ontology: $ONTOLOGY_NAME"
info "Description: ${ONTOLOGY_DESC:-N/A}"

####
# Authentication
####

log "Authenticating to Fabric API"
FABRIC_TOKEN=$(get_fabric_token)
info "Authentication successful"

####
# Verify Workspace Access
####

log "Verifying Workspace Access"
workspace_response=$(get_workspace "$WORKSPACE_ID" "$FABRIC_TOKEN")
workspace_name=$(echo "$workspace_response" | jq -r '.displayName')
info "Workspace: $workspace_name ($WORKSPACE_ID)"

####
# ID Generation Functions
####

# Generate unique 64-bit ID (BigInt as string)
generate_bigint_id() {
  local timestamp random_part
  timestamp=$(date +%s%N | cut -c1-13)
  random_part=$((RANDOM % 10000))
  printf "%s%04d" "$timestamp" "$random_part"
}

# Generate UUID v4
generate_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    # Fallback using /dev/urandom
    od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
  fi
}

# Get or generate entity type ID (uses pre-generated ID if available)
get_entity_type_id() {
  local entity_name="$1"
  if [[ -z "${ENTITY_TYPE_IDS[$entity_name]:-}" ]]; then
    # This should not happen if pre_generate_ids was called
    warn "Entity type ID not pre-generated for: $entity_name"
    ENTITY_TYPE_IDS[$entity_name]=$(generate_bigint_id)
  fi
  echo "${ENTITY_TYPE_IDS[$entity_name]}"
}

# Get or generate property ID (uses pre-generated ID if available)
get_property_id() {
  local entity_name="$1"
  local property_name="$2"
  local key="${entity_name}:${property_name}"
  if [[ -z "${PROPERTY_IDS[$key]:-}" ]]; then
    # This should not happen if pre_generate_ids was called
    warn "Property ID not pre-generated for: $key"
    PROPERTY_IDS[$key]=$(generate_bigint_id)
  fi
  echo "${PROPERTY_IDS[$key]}"
}

# Get or generate relationship ID (uses pre-generated ID if available)
get_relationship_id() {
  local rel_name="$1"
  if [[ -z "${RELATIONSHIP_IDS[$rel_name]:-}" ]]; then
    # This should not happen if pre_generate_ids was called
    warn "Relationship ID not pre-generated for: $rel_name"
    RELATIONSHIP_IDS[$rel_name]=$(generate_bigint_id)
  fi
  echo "${RELATIONSHIP_IDS[$rel_name]}"
}

####
# JSON Generation Functions
####

# Build property JSON object
build_property_json() {
  local prop_id="$1"
  local prop_name="$2"
  local prop_type="$3"

  local fabric_type
  fabric_type=$(map_property_type "$prop_type")

  jq -n \
    --arg id "$prop_id" \
    --arg name "$prop_name" \
    --arg valueType "$fabric_type" \
    '{
      "id": $id,
      "name": $name,
      "redefines": null,
      "baseTypeNamespaceType": null,
      "valueType": $valueType
    }'
}

# Build property binding JSON object
build_property_binding() {
  local source_column="$1"
  local target_prop_id="$2"

  jq -n \
    --arg col "$source_column" \
    --arg propId "$target_prop_id" \
    '{
      "sourceColumnName": $col,
      "targetPropertyId": $propId
    }'
}

# Build entity type definition
build_entity_type_definition() {
  local entity_name="$1"
  local entity_json="$2"

  local entity_id key_name display_name_prop
  entity_id=$(get_entity_type_id "$entity_name")
  key_name=$(echo "$entity_json" | jq -r '.key')
  display_name_prop=$(echo "$entity_json" | jq -r '.displayName // .key')

  # Get key property ID
  local key_prop_id
  key_prop_id=$(get_property_id "$entity_name" "$key_name")

  # Get display name property ID
  local display_prop_id
  display_prop_id=$(get_property_id "$entity_name" "$display_name_prop")

  # Build properties array (static properties only)
  local properties_array="[]"
  local static_props
  static_props=$(get_entity_static_properties "$DEFINITION_FILE" "$entity_name")
  local prop_count
  prop_count=$(echo "$static_props" | jq 'length')

  for i in $(seq 0 $((prop_count - 1))); do
    local prop_name prop_type prop_id prop_json
    prop_name=$(echo "$static_props" | jq -r ".[$i].name")
    prop_type=$(echo "$static_props" | jq -r ".[$i].type")
    prop_id=$(get_property_id "$entity_name" "$prop_name")
    prop_json=$(build_property_json "$prop_id" "$prop_name" "$prop_type")
    properties_array=$(echo "$properties_array" | jq --argjson prop "$prop_json" '. += [$prop]')
  done

  # Build timeseries properties array
  local timeseries_array="[]"
  local ts_props
  ts_props=$(get_entity_timeseries_properties "$DEFINITION_FILE" "$entity_name")
  local ts_count
  ts_count=$(echo "$ts_props" | jq 'length')

  for i in $(seq 0 $((ts_count - 1))); do
    local prop_name prop_type prop_id prop_json
    prop_name=$(echo "$ts_props" | jq -r ".[$i].name")
    prop_type=$(echo "$ts_props" | jq -r ".[$i].type")
    prop_id=$(get_property_id "$entity_name" "$prop_name")
    prop_json=$(build_property_json "$prop_id" "$prop_name" "$prop_type")
    timeseries_array=$(echo "$timeseries_array" | jq --argjson prop "$prop_json" '. += [$prop]')
  done

  # Build entity ID parts (key property IDs)
  local entity_id_parts
  entity_id_parts=$(jq -n --arg id "$key_prop_id" '[$id]')

  # Build entity type JSON
  jq -n \
    --arg entityId "$entity_id" \
    --arg entityName "$entity_name" \
    --argjson entityIdParts "$entity_id_parts" \
    --arg displayNamePropId "$display_prop_id" \
    --argjson properties "$properties_array" \
    --argjson timeseriesProps "$timeseries_array" \
    '{
      "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/ontology/entityType/1.0.0/schema.json",
      "id": $entityId,
      "namespace": "usertypes",
      "baseEntityTypeId": null,
      "name": $entityName,
      "entityIdParts": $entityIdParts,
      "displayNamePropertyId": $displayNamePropId,
      "namespaceType": "Custom",
      "visibility": "Visible",
      "properties": $properties,
      "timeseriesProperties": $timeseriesProps
    }'
}

# Build Lakehouse data binding
build_lakehouse_binding() {
  local entity_name="$1"
  local binding_json="$2"

  local table_name binding_id
  table_name=$(echo "$binding_json" | jq -r '.table')
  binding_id=$(generate_uuid)

  # Build property bindings from entity properties
  local property_bindings="[]"
  local static_props
  static_props=$(get_entity_static_properties "$DEFINITION_FILE" "$entity_name")
  local prop_count
  prop_count=$(echo "$static_props" | jq 'length')

  for i in $(seq 0 $((prop_count - 1))); do
    local prop_name source_col prop_id binding
    prop_name=$(echo "$static_props" | jq -r ".[$i].name")
    source_col=$(echo "$static_props" | jq -r ".[$i].sourceColumn // .[$i].name")
    prop_id=$(get_property_id "$entity_name" "$prop_name")
    binding=$(build_property_binding "$source_col" "$prop_id")
    property_bindings=$(echo "$property_bindings" | jq --argjson b "$binding" '. += [$b]')
  done

  jq -n \
    --arg bindingId "$binding_id" \
    --argjson propBindings "$property_bindings" \
    --arg wsId "$WORKSPACE_ID" \
    --arg lhId "$LAKEHOUSE_ID" \
    --arg tableName "$table_name" \
    '{
      "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/ontology/dataBinding/1.0.0/schema.json",
      "id": $bindingId,
      "dataBindingConfiguration": {
        "dataBindingType": "NonTimeSeries",
        "propertyBindings": $propBindings,
        "sourceTableProperties": {
          "sourceType": "LakehouseTable",
          "workspaceId": $wsId,
          "itemId": $lhId,
          "sourceTableName": $tableName,
          "sourceSchema": null
        }
      }
    }'
}

# Build Eventhouse data binding
build_eventhouse_binding() {
  local entity_name="$1"
  local binding_json="$2"

  local table_name timestamp_col binding_id
  table_name=$(echo "$binding_json" | jq -r '.table')
  timestamp_col=$(echo "$binding_json" | jq -r '.timestampColumn // "timestamp"')
  binding_id=$(generate_uuid)

  # Build property bindings from timeseries properties
  local property_bindings="[]"
  local ts_props
  ts_props=$(get_entity_timeseries_properties "$DEFINITION_FILE" "$entity_name")
  local prop_count
  prop_count=$(echo "$ts_props" | jq 'length')

  # Add correlation column binding (typically the entity key)
  local key_name correlation_col key_prop_id key_binding
  key_name=$(get_entity_key "$DEFINITION_FILE" "$entity_name")
  correlation_col=$(echo "$binding_json" | jq -r '.correlationColumn // empty')
  if [[ -n "$correlation_col" ]]; then
    key_prop_id=$(get_property_id "$entity_name" "$key_name")
    key_binding=$(build_property_binding "$correlation_col" "$key_prop_id")
    property_bindings=$(echo "$property_bindings" | jq --argjson b "$key_binding" '. += [$b]')
  fi

  for i in $(seq 0 $((prop_count - 1))); do
    local prop_name source_col prop_id binding
    prop_name=$(echo "$ts_props" | jq -r ".[$i].name")
    source_col=$(echo "$ts_props" | jq -r ".[$i].sourceColumn // .[$i].name")
    prop_id=$(get_property_id "$entity_name" "$prop_name")
    binding=$(build_property_binding "$source_col" "$prop_id")
    property_bindings=$(echo "$property_bindings" | jq --argjson b "$binding" '. += [$b]')
  done

  # For KustoTable bindings, itemId should be the KQL Database ID
  local kql_db_id="${KQL_DATABASE_ID:-$EVENTHOUSE_ID}"

  jq -n \
    --arg bindingId "$binding_id" \
    --arg tsCol "$timestamp_col" \
    --argjson propBindings "$property_bindings" \
    --arg wsId "$WORKSPACE_ID" \
    --arg kqlDbId "$kql_db_id" \
    --arg clusterUri "$CLUSTER_URI" \
    --arg dbName "$DATABASE_NAME" \
    --arg tableName "$table_name" \
    '{
      "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/ontology/dataBinding/1.0.0/schema.json",
      "id": $bindingId,
      "dataBindingConfiguration": {
        "dataBindingType": "TimeSeries",
        "timestampColumnName": $tsCol,
        "propertyBindings": $propBindings,
        "sourceTableProperties": {
          "sourceType": "KustoTable",
          "workspaceId": $wsId,
          "itemId": $kqlDbId,
          "clusterUri": $clusterUri,
          "databaseName": $dbName,
          "sourceTableName": $tableName
        }
      }
    }'
}

# Build relationship type definition
build_relationship_definition() {
  local rel_json="$1"

  local rel_name from_entity to_entity rel_id source_entity_id target_entity_id
  rel_name=$(echo "$rel_json" | jq -r '.name')
  from_entity=$(echo "$rel_json" | jq -r '.from')
  to_entity=$(echo "$rel_json" | jq -r '.to')

  rel_id=$(get_relationship_id "$rel_name")
  source_entity_id=$(get_entity_type_id "$from_entity")
  target_entity_id=$(get_entity_type_id "$to_entity")

  jq -n \
    --arg relId "$rel_id" \
    --arg relName "$rel_name" \
    --arg srcId "$source_entity_id" \
    --arg tgtId "$target_entity_id" \
    '{
      "id": $relId,
      "namespace": "usertypes",
      "name": $relName,
      "namespaceType": "Custom",
      "source": {"entityTypeId": $srcId},
      "target": {"entityTypeId": $tgtId}
    }'
}

# Build contextualization (relationship data binding)
build_contextualization() {
  local rel_json="$1"

  local rel_name from_entity to_entity binding ctx_id
  rel_name=$(echo "$rel_json" | jq -r '.name')
  from_entity=$(echo "$rel_json" | jq -r '.from')
  to_entity=$(echo "$rel_json" | jq -r '.to')
  binding=$(echo "$rel_json" | jq '.binding // null')

  if [[ "$binding" == "null" ]]; then
    return 0
  fi

  ctx_id=$(generate_uuid)
  local table_name from_col to_col
  table_name=$(echo "$binding" | jq -r '.table')
  from_col=$(echo "$binding" | jq -r '.fromColumn')
  to_col=$(echo "$binding" | jq -r '.toColumn')

  # Get source entity key property ID
  local from_key from_key_prop_id
  from_key=$(get_entity_key "$DEFINITION_FILE" "$from_entity")
  from_key_prop_id=$(get_property_id "$from_entity" "$from_key")

  # Get target entity key property ID
  local to_key to_key_prop_id
  to_key=$(get_entity_key "$DEFINITION_FILE" "$to_entity")
  to_key_prop_id=$(get_property_id "$to_entity" "$to_key")

  # Build key ref bindings
  local source_bindings target_bindings
  source_bindings=$(jq -n \
    --arg col "$from_col" \
    --arg propId "$from_key_prop_id" \
    '[{"sourceColumnName": $col, "targetPropertyId": $propId}]')

  target_bindings=$(jq -n \
    --arg col "$to_col" \
    --arg propId "$to_key_prop_id" \
    '[{"sourceColumnName": $col, "targetPropertyId": $propId}]')

  jq -n \
    --arg ctxId "$ctx_id" \
    --arg wsId "$WORKSPACE_ID" \
    --arg lhId "$LAKEHOUSE_ID" \
    --arg tableName "$table_name" \
    --argjson srcBindings "$source_bindings" \
    --argjson tgtBindings "$target_bindings" \
    '{
      "id": $ctxId,
      "dataBindingTable": {
        "workspaceId": $wsId,
        "itemId": $lhId,
        "sourceTableName": $tableName,
        "sourceSchema": null,
        "sourceType": "LakehouseTable"
      },
      "sourceKeyRefBindings": $srcBindings,
      "targetKeyRefBindings": $tgtBindings
    }'
}

####
# Pre-generate IDs
####

# Pre-generate all entity type IDs to avoid subshell issues with associative arrays
# Must be called before build_ontology_definition
pre_generate_ids() {
  local entity_types entity_count

  entity_types=$(get_entity_types "$DEFINITION_FILE")
  entity_count=$(echo "$entity_types" | jq 'length')

  for i in $(seq 0 $((entity_count - 1))); do
    local entity_name
    entity_name=$(echo "$entity_types" | jq -r ".[$i].name")
    # Generate and cache the entity type ID
    ENTITY_TYPE_IDS[$entity_name]=$(generate_bigint_id)

    # Pre-generate property IDs for this entity
    local static_props ts_props prop_count
    static_props=$(get_entity_static_properties "$DEFINITION_FILE" "$entity_name")
    prop_count=$(echo "$static_props" | jq 'length')
    for j in $(seq 0 $((prop_count - 1))); do
      local prop_name
      prop_name=$(echo "$static_props" | jq -r ".[$j].name")
      PROPERTY_IDS["${entity_name}:${prop_name}"]=$(generate_bigint_id)
    done

    ts_props=$(get_entity_timeseries_properties "$DEFINITION_FILE" "$entity_name")
    prop_count=$(echo "$ts_props" | jq 'length')
    for j in $(seq 0 $((prop_count - 1))); do
      local prop_name
      prop_name=$(echo "$ts_props" | jq -r ".[$j].name")
      PROPERTY_IDS["${entity_name}:${prop_name}"]=$(generate_bigint_id)
    done
  done

  # Pre-generate relationship IDs
  local relationships rel_count
  relationships=$(get_relationships "$DEFINITION_FILE")
  rel_count=$(echo "$relationships" | jq 'length')

  for i in $(seq 0 $((rel_count - 1))); do
    local rel_name
    rel_name=$(echo "$relationships" | jq -r ".[$i].name")
    RELATIONSHIP_IDS[$rel_name]=$(generate_bigint_id)
  done
}

####
# Build Ontology Definition Parts
####

build_ontology_definition() {
  local parts_array="[]"

  log "Building Ontology Definition Parts"

  # 1. Platform metadata
  local platform_json
  platform_json=$(jq -n \
    --arg name "$ONTOLOGY_NAME" \
    '{
      "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
      "metadata": {"type": "Ontology", "displayName": $name},
      "config": {"version": "2.0", "logicalId": "00000000-0000-0000-0000-000000000000"}
    }')
  local platform_part
  platform_part=$(build_definition_part ".platform" "$platform_json")
  parts_array=$(echo "$parts_array" | jq --argjson p "$platform_part" '. += [$p]')
  info "Added: .platform"

  # 2. Root definition.json (empty object)
  local root_def_part
  root_def_part=$(build_definition_part "definition.json" "{}")
  parts_array=$(echo "$parts_array" | jq --argjson p "$root_def_part" '. += [$p]')
  info "Added: definition.json"

  # 3. Entity types and their data bindings
  local entity_types entity_count
  entity_types=$(get_entity_types "$DEFINITION_FILE")
  entity_count=$(echo "$entity_types" | jq 'length')
  info "Processing $entity_count entity types"

  for i in $(seq 0 $((entity_count - 1))); do
    local entity_name entity_json entity_id entity_def entity_def_part
    entity_name=$(echo "$entity_types" | jq -r ".[$i].name")
    entity_json=$(echo "$entity_types" | jq ".[$i]")
    # Use pre-generated ID from associative array directly
    entity_id="${ENTITY_TYPE_IDS[$entity_name]}"

    # Build entity type definition
    entity_def=$(build_entity_type_definition "$entity_name" "$entity_json")
    entity_def_part=$(build_definition_part "EntityTypes/${entity_id}/definition.json" "$entity_def")
    parts_array=$(echo "$parts_array" | jq --argjson p "$entity_def_part" '. += [$p]')
    info "Added: EntityTypes/${entity_id}/definition.json ($entity_name)"

    # Add static (lakehouse) data binding
    local static_binding
    static_binding=$(get_entity_static_binding "$DEFINITION_FILE" "$entity_name")
    if [[ -n "$static_binding" && "$static_binding" != "null" ]]; then
      local lh_binding binding_id lh_binding_part
      lh_binding=$(build_lakehouse_binding "$entity_name" "$static_binding")
      binding_id=$(echo "$lh_binding" | jq -r '.id')
      lh_binding_part=$(build_definition_part "EntityTypes/${entity_id}/DataBindings/${binding_id}.json" "$lh_binding")
      parts_array=$(echo "$parts_array" | jq --argjson p "$lh_binding_part" '. += [$p]')
      info "Added: EntityTypes/${entity_id}/DataBindings/${binding_id}.json (Lakehouse)"
    fi

    # Add timeseries (eventhouse) data binding
    local ts_binding
    ts_binding=$(get_entity_timeseries_binding "$DEFINITION_FILE" "$entity_name")
    if [[ -n "$ts_binding" && "$ts_binding" != "null" ]]; then
      local eh_binding binding_id eh_binding_part
      eh_binding=$(build_eventhouse_binding "$entity_name" "$ts_binding")
      binding_id=$(echo "$eh_binding" | jq -r '.id')
      eh_binding_part=$(build_definition_part "EntityTypes/${entity_id}/DataBindings/${binding_id}.json" "$eh_binding")
      parts_array=$(echo "$parts_array" | jq --argjson p "$eh_binding_part" '. += [$p]')
      info "Added: EntityTypes/${entity_id}/DataBindings/${binding_id}.json (Eventhouse)"
    fi
  done

  # 4. Relationship types and contextualizations
  local relationships rel_count
  relationships=$(get_relationships "$DEFINITION_FILE")
  rel_count=$(echo "$relationships" | jq 'length')
  info "Processing $rel_count relationships"

  for i in $(seq 0 $((rel_count - 1))); do
    local rel_json rel_name rel_id rel_def rel_def_part
    rel_json=$(echo "$relationships" | jq ".[$i]")
    rel_name=$(echo "$rel_json" | jq -r '.name')
    rel_id=$(get_relationship_id "$rel_name")

    # Build relationship type definition
    rel_def=$(build_relationship_definition "$rel_json")
    rel_def_part=$(build_definition_part "RelationshipTypes/${rel_id}/definition.json" "$rel_def")
    parts_array=$(echo "$parts_array" | jq --argjson p "$rel_def_part" '. += [$p]')
    info "Added: RelationshipTypes/${rel_id}/definition.json ($rel_name)"

    # Add contextualization if binding exists
    local ctx_def
    ctx_def=$(build_contextualization "$rel_json")
    if [[ -n "$ctx_def" ]]; then
      local ctx_id ctx_part
      ctx_id=$(echo "$ctx_def" | jq -r '.id')
      ctx_part=$(build_definition_part "RelationshipTypes/${rel_id}/Contextualizations/${ctx_id}.json" "$ctx_def")
      parts_array=$(echo "$parts_array" | jq --argjson p "$ctx_part" '. += [$p]')
      info "Added: RelationshipTypes/${rel_id}/Contextualizations/${ctx_id}.json"
    fi
  done

  echo "$parts_array"
}

####
# Create or Update Ontology
####

create_ontology() {
  local definition_parts="$1"

  log "Creating Ontology"

  # Check if ontology already exists
  local existing_response ontology_id
  existing_response=$(fabric_api_call "GET" "/workspaces/$WORKSPACE_ID/ontologies" "" "$FABRIC_TOKEN" 2>/dev/null || echo '{"value":[]}')
  ontology_id=$(echo "$existing_response" | jq -r ".value[] | select(.displayName == \"$ONTOLOGY_NAME\") | .id")

  if [[ -n "$ontology_id" ]]; then
    info "Ontology '$ONTOLOGY_NAME' already exists: $ontology_id"
    info "Updating definition..."

    if [[ "$DRY_RUN" == "true" ]]; then
      info "[DRY-RUN] Would update ontology definition"
      echo "$ontology_id"
      return 0
    fi

    # Update existing ontology definition
    local update_body
    update_body=$(jq -n --argjson parts "$definition_parts" '{"definition": {"parts": $parts}}')

    fabric_api_call "POST" "/workspaces/$WORKSPACE_ID/ontologies/$ontology_id/updateDefinition" "$update_body" "$FABRIC_TOKEN"
    ok "Ontology definition updated"
    echo "$ontology_id"
    return 0
  fi

  # Create new ontology with definition
  info "Creating ontology: $ONTOLOGY_NAME"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would create ontology: $ONTOLOGY_NAME"
    local parts_count
    parts_count=$(echo "$definition_parts" | jq 'length')
    info "[DRY-RUN] Definition parts count: $parts_count"
    echo "dry-run-ontology-id"
    return 0
  fi

  # Write parts to temp file to avoid shell argument length limits
  local parts_file request_body_file response
  parts_file=$(mktemp)
  request_body_file=$(mktemp)
  echo "$definition_parts" > "$parts_file"

  # Build request body using file-based approach
  jq -n \
    --arg name "$ONTOLOGY_NAME" \
    --arg desc "${ONTOLOGY_DESC:-}" \
    --slurpfile parts "$parts_file" \
    '{
      "displayName": $name,
      "description": $desc,
      "definition": {"parts": $parts[0]}
    }' > "$request_body_file"

  rm -f "$parts_file"

  # Save request body for debugging
  cp "$request_body_file" /tmp/ontology-request.json
  info "Request body saved to /tmp/ontology-request.json"

  response=$(fabric_api_call_file "POST" "/workspaces/$WORKSPACE_ID/ontologies" "$request_body_file" "$FABRIC_TOKEN")
  rm -f "$request_body_file"

  ontology_id=$(echo "$response" | jq -r '.id // empty')
  if [[ -z "$ontology_id" ]]; then
    # May be in createdItem for LRO
    ontology_id=$(echo "$response" | jq -r '.createdItem.id // empty')
  fi

  if [[ -n "$ontology_id" ]]; then
    ok "Ontology created: $ontology_id"
    echo "$ontology_id"
  else
    err "Failed to create ontology - no ID returned"
  fi
}

####
# Main
####

log "Deploying Fabric Ontology"
info "Ontology: $ONTOLOGY_NAME"
info "Workspace: $WORKSPACE_ID"
info "Lakehouse: $LAKEHOUSE_ID"
if [[ -n "$EVENTHOUSE_ID" ]]; then
  info "Eventhouse: $EVENTHOUSE_ID"
  info "Cluster URI: $CLUSTER_URI"
fi
if [[ "$DRY_RUN" == "true" ]]; then
  warn "DRY-RUN mode enabled"
fi

# Pre-generate all IDs to avoid subshell issues with associative arrays
pre_generate_ids

# Build ontology definition parts
DEFINITION_PARTS=$(build_ontology_definition)

parts_count=$(echo "$DEFINITION_PARTS" | jq 'length')
info "Total definition parts: $parts_count"

# Create or update ontology
ONTOLOGY_ID=$(create_ontology "$DEFINITION_PARTS")

log "Deployment Complete"
ok "Ontology ID: $ONTOLOGY_ID"
warn "Ontology setup is async - entity types take 10-20 minutes to fully provision"
info "The portal will show 'Setting up your ontology' until complete"

# Output for scripting
if [[ "$DRY_RUN" != "true" ]]; then
  echo ""
  echo "# Environment variables for downstream scripts:"
  echo "export ONTOLOGY_ID=\"$ONTOLOGY_ID\""
fi
