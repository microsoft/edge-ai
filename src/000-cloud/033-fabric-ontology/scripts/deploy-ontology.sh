#!/usr/bin/env bash
# deploy-ontology.sh - Deploy Fabric Ontology from ontology definition
#
# Publishes entity types, properties, data bindings, relationships, and
# contextualizations into existing Microsoft Fabric resources.
#
# Dependencies: curl, jq, yq, az (Azure CLI), sha256sum
#
# Usage:
#   ./deploy-ontology.sh --definition <path> --workspace-id <id> --lakehouse-id <id>

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
ID_MAPPING_OUTPUT="${ID_MAPPING_OUTPUT:-/tmp/ontology-id-mapping.json}"
DEFINITION_PARTS_OUTPUT=""
PUBLICATION_OUTPUT=""
EXISTING_ONTOLOGY_ID=""
EXISTING_DEFINITION_PARTS="[]"

# Associative arrays for ID tracking
declare -A ENTITY_TYPE_IDS
declare -A PROPERTY_IDS
declare -A RELATIONSHIP_IDS
declare -A DATA_BINDING_IDS
declare -A CONTEXTUALIZATION_IDS
declare -A ENTITY_NAMES_BY_ID
declare -A RELATIONSHIP_NAMES_BY_ID

####
# Usage and Argument Parsing
####

usage() {
  cat <<EOF
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
  --output <path>          Write the publication result as JSON
  --kql-database-id <id>  KQL Database ID (for reference)

Options:
  --id-mapping-output <path>
                           Write the logical-name-to-Fabric-ID mapping to this path
                           (default: /tmp/ontology-id-mapping.json)
  --definition-parts-output <path>
                           Write generated definition parts and exit before authentication
  --dry-run               Show what would be created without making changes
  -h, --help              Show this help message

Examples:
  # Supported static Lakehouse publisher profile
  $(basename "$0") --definition ./definitions/examples/cora-corax-dim.yaml \
    --workspace-id abc123 --lakehouse-id def456

  # Experimental time-series binding path
  $(basename "$0") --definition ./definitions/examples/cora-corax-dim-timeseries.yaml \
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
    --id-mapping-output)
      ID_MAPPING_OUTPUT="$2"
      shift 2
      ;;
    --definition-parts-output)
      DEFINITION_PARTS_OUTPUT="$2"
      shift 2
      ;;
    --output)
      PUBLICATION_OUTPUT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h | --help)
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

if [[ -z "$DEFINITION_PARTS_OUTPUT" && "$DRY_RUN" != "true" && -z "$PUBLICATION_OUTPUT" ]]; then
  err "Missing required argument: --output"
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

if ! "$SCRIPT_DIR/validate-definition.sh" --definition "$DEFINITION_FILE" >&2; then
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
# ID Reconciliation and Generation
####

deterministic_hash() {
  local logical_key="$1"
  printf '%s' "fabric-ontology:$logical_key" | sha256sum | cut -d ' ' -f 1
}

generate_bigint_id() {
  local logical_key="$1"
  local hash
  hash=$(deterministic_hash "$logical_key")
  printf '%d\n' "0x${hash:0:15}"
}

generate_uuid() {
  local logical_key="$1"
  local hash
  hash=$(deterministic_hash "$logical_key")
  printf '%s-%s-5%s-8%s-%s\n' \
    "${hash:0:8}" \
    "${hash:8:4}" \
    "${hash:13:3}" \
    "${hash:17:3}" \
    "${hash:20:12}"
}

binding_logical_name() {
  printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"
}

contextualization_logical_name() {
  printf '%s|%s|%s|%s|%s\n' "$1" "$2" "$3" "$4" "$5"
}

decode_item_definition() {
  local response="$1"
  local decoded_parts="[]"
  local part

  if ! jq -e '.definition.parts | type == "array"' <<<"$response" >/dev/null; then
    return 1
  fi

  while IFS= read -r part; do
    local path payload payload_type content
    path=$(jq -er '.path' <<<"$part") || return 1
    payload=$(jq -er '.payload' <<<"$part") || return 1
    payload_type=$(jq -er '.payloadType' <<<"$part") || return 1
    [[ "$payload_type" == "InlineBase64" ]] || return 1
    content=$(printf '%s' "$payload" | base64 --decode 2>/dev/null) || return 1
    jq -e . <<<"$content" >/dev/null || return 1
    if ! decoded_parts=$(jq \
      --arg path "$path" \
      --argjson content "$content" \
      '. += [{path: $path, content: $content}]' <<<"$decoded_parts"); then
      return 1
    fi
  done < <(jq -c '.definition.parts[]' <<<"$response")

  printf '%s\n' "$decoded_parts"
}

load_existing_ids() {
  local entity_name entity_id property_name property_id
  while IFS=$'\t' read -r entity_name entity_id; do
    [[ -n "$entity_name" && -n "$entity_id" ]] || err "Existing entity definition is missing a name or ID"
    ENTITY_TYPE_IDS[$entity_name]="$entity_id"
    ENTITY_NAMES_BY_ID[$entity_id]="$entity_name"
  done < <(jq -r '
    .[]
    | select(.path | test("^EntityTypes/[0-9]+/definition\\.json$"))
    | [.content.name, .content.id]
    | @tsv
  ' <<<"$EXISTING_DEFINITION_PARTS")

  while IFS=$'\t' read -r entity_name property_name property_id; do
    [[ -n "$property_name" && -n "$property_id" ]] || err "Existing property definition is missing a name or ID"
    PROPERTY_IDS["${entity_name}:${property_name}"]="$property_id"
  done < <(jq -r '
    .[]
    | select(.path | test("^EntityTypes/[0-9]+/definition\\.json$"))
    | .content.name as $entityName
    | (.content.properties[]?, .content.timeseriesProperties[]?)
    | [$entityName, .name, .id]
    | @tsv
  ' <<<"$EXISTING_DEFINITION_PARTS")

  local relationship_name relationship_id
  while IFS=$'\t' read -r relationship_name relationship_id; do
    [[ -n "$relationship_name" && -n "$relationship_id" ]] || err "Existing relationship definition is missing a name or ID"
    RELATIONSHIP_IDS[$relationship_name]="$relationship_id"
    RELATIONSHIP_NAMES_BY_ID[$relationship_id]="$relationship_name"
  done < <(jq -r '
    .[]
    | select(.path | test("^RelationshipTypes/[0-9]+/definition\\.json$"))
    | [.content.name, .content.id]
    | @tsv
  ' <<<"$EXISTING_DEFINITION_PARTS")

  local parent_id binding_id binding_type source_type table_name logical_name
  while IFS=$'\t' read -r parent_id binding_id binding_type source_type table_name; do
    entity_name="${ENTITY_NAMES_BY_ID[$parent_id]:-}"
    [[ -n "$entity_name" && -n "$binding_id" ]] || err "Existing data binding cannot be matched to an entity"
    logical_name=$(binding_logical_name "$entity_name" "$binding_type" "$source_type" "$table_name")
    DATA_BINDING_IDS[$logical_name]="$binding_id"
  done < <(jq -r '
    .[]
    | select(.path | test("^EntityTypes/[0-9]+/DataBindings/[0-9a-fA-F-]+\\.json$"))
    | [
        (.path | capture("^EntityTypes/(?<id>[0-9]+)/").id),
        .content.id,
        .content.dataBindingConfiguration.dataBindingType,
        .content.dataBindingConfiguration.sourceTableProperties.sourceType,
        .content.dataBindingConfiguration.sourceTableProperties.sourceTableName
      ]
    | @tsv
  ' <<<"$EXISTING_DEFINITION_PARTS")

  local source_columns target_columns
  while IFS=$'\t' read -r parent_id binding_id source_type table_name source_columns target_columns; do
    relationship_name="${RELATIONSHIP_NAMES_BY_ID[$parent_id]:-}"
    [[ -n "$relationship_name" && -n "$binding_id" ]] || err "Existing contextualization cannot be matched to a relationship"
    logical_name=$(contextualization_logical_name \
      "$relationship_name" "$source_type" "$table_name" "$source_columns" "$target_columns")
    CONTEXTUALIZATION_IDS[$logical_name]="$binding_id"
  done < <(jq -r '
    .[]
    | select(.path | test("^RelationshipTypes/[0-9]+/Contextualizations/[0-9a-fA-F-]+\\.json$"))
    | [
        (.path | capture("^RelationshipTypes/(?<id>[0-9]+)/").id),
        .content.id,
        .content.dataBindingTable.sourceType,
        .content.dataBindingTable.sourceTableName,
        ([.content.sourceKeyRefBindings[].sourceColumnName] | join(",")),
        ([.content.targetKeyRefBindings[].sourceColumnName] | join(","))
      ]
    | @tsv
  ' <<<"$EXISTING_DEFINITION_PARTS")
}

# Get or generate entity type ID (uses pre-generated ID if available)
get_entity_type_id() {
  local entity_name="$1"
  if [[ -z "${ENTITY_TYPE_IDS[$entity_name]:-}" ]]; then
    # This should not happen if pre_generate_ids was called
    warn "Entity type ID not pre-generated for: $entity_name"
    ENTITY_TYPE_IDS[$entity_name]=$(generate_bigint_id "entity:$entity_name")
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
    PROPERTY_IDS[$key]=$(generate_bigint_id "property:$key")
  fi
  echo "${PROPERTY_IDS[$key]}"
}

# Get or generate relationship ID (uses pre-generated ID if available)
get_relationship_id() {
  local rel_name="$1"
  if [[ -z "${RELATIONSHIP_IDS[$rel_name]:-}" ]]; then
    # This should not happen if pre_generate_ids was called
    warn "Relationship ID not pre-generated for: $rel_name"
    RELATIONSHIP_IDS[$rel_name]=$(generate_bigint_id "relationship:$rel_name")
  fi
  echo "${RELATIONSHIP_IDS[$rel_name]}"
}

####
# Authoritative Ontology Part Generation
####

# Ontology definition parts are constructed programmatically with jq in this file.

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

  local table_name binding_id logical_name
  table_name=$(echo "$binding_json" | jq -r '.table')
  logical_name=$(binding_logical_name "$entity_name" "NonTimeSeries" "LakehouseTable" "$table_name")
  binding_id="${DATA_BINDING_IDS[$logical_name]}"

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

  local table_name timestamp_col binding_id logical_name
  table_name=$(echo "$binding_json" | jq -r '.table')
  timestamp_col=$(echo "$binding_json" | jq -r '.timestampColumn // "timestamp"')
  logical_name=$(binding_logical_name "$entity_name" "TimeSeries" "KustoTable" "$table_name")
  binding_id="${DATA_BINDING_IDS[$logical_name]}"

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

  local table_name from_col to_col
  table_name=$(echo "$binding" | jq -r '.table')
  from_col=$(echo "$binding" | jq -r '.fromColumn')
  to_col=$(echo "$binding" | jq -r '.toColumn')
  local logical_name
  logical_name=$(contextualization_logical_name \
    "$rel_name" "LakehouseTable" "$table_name" "$from_col" "$to_col")
  ctx_id="${CONTEXTUALIZATION_IDS[$logical_name]}"

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
    if [[ -z "${ENTITY_TYPE_IDS[$entity_name]:-}" ]]; then
      ENTITY_TYPE_IDS[$entity_name]=$(generate_bigint_id "entity:$entity_name")
    fi

    # Pre-generate property IDs for this entity
    local static_props ts_props prop_count
    static_props=$(get_entity_static_properties "$DEFINITION_FILE" "$entity_name")
    prop_count=$(echo "$static_props" | jq 'length')
    for j in $(seq 0 $((prop_count - 1))); do
      local prop_name
      prop_name=$(echo "$static_props" | jq -r ".[$j].name")
      if [[ -z "${PROPERTY_IDS["${entity_name}:${prop_name}"]:-}" ]]; then
        PROPERTY_IDS["${entity_name}:${prop_name}"]=$(generate_bigint_id "property:${entity_name}:${prop_name}")
      fi
    done

    ts_props=$(get_entity_timeseries_properties "$DEFINITION_FILE" "$entity_name")
    prop_count=$(echo "$ts_props" | jq 'length')
    for j in $(seq 0 $((prop_count - 1))); do
      local prop_name
      prop_name=$(echo "$ts_props" | jq -r ".[$j].name")
      if [[ -z "${PROPERTY_IDS["${entity_name}:${prop_name}"]:-}" ]]; then
        PROPERTY_IDS["${entity_name}:${prop_name}"]=$(generate_bigint_id "property:${entity_name}:${prop_name}")
      fi
    done

    local static_binding table_name logical_name
    static_binding=$(get_entity_static_binding "$DEFINITION_FILE" "$entity_name")
    if [[ -n "$static_binding" && "$static_binding" != "null" ]]; then
      table_name=$(jq -r '.table' <<<"$static_binding")
      logical_name=$(binding_logical_name "$entity_name" "NonTimeSeries" "LakehouseTable" "$table_name")
      if [[ -z "${DATA_BINDING_IDS[$logical_name]:-}" ]]; then
        DATA_BINDING_IDS[$logical_name]=$(generate_uuid "binding:$logical_name")
      fi
    fi

    local timeseries_binding
    timeseries_binding=$(get_entity_timeseries_binding "$DEFINITION_FILE" "$entity_name")
    if [[ -n "$timeseries_binding" && "$timeseries_binding" != "null" ]]; then
      table_name=$(jq -r '.table' <<<"$timeseries_binding")
      logical_name=$(binding_logical_name "$entity_name" "TimeSeries" "KustoTable" "$table_name")
      if [[ -z "${DATA_BINDING_IDS[$logical_name]:-}" ]]; then
        DATA_BINDING_IDS[$logical_name]=$(generate_uuid "binding:$logical_name")
      fi
    fi
  done

  # Pre-generate relationship IDs
  local relationships rel_count
  relationships=$(get_relationships "$DEFINITION_FILE")
  rel_count=$(echo "$relationships" | jq 'length')

  for i in $(seq 0 $((rel_count - 1))); do
    local rel_name
    rel_name=$(echo "$relationships" | jq -r ".[$i].name")
    if [[ -z "${RELATIONSHIP_IDS[$rel_name]:-}" ]]; then
      RELATIONSHIP_IDS[$rel_name]=$(generate_bigint_id "relationship:$rel_name")
    fi

    local rel_binding table_name from_col to_col logical_name
    rel_binding=$(echo "$relationships" | jq ".[$i].binding // null")
    if [[ "$rel_binding" != "null" ]]; then
      table_name=$(jq -r '.table' <<<"$rel_binding")
      from_col=$(jq -r '.fromColumn' <<<"$rel_binding")
      to_col=$(jq -r '.toColumn' <<<"$rel_binding")
      logical_name=$(contextualization_logical_name \
        "$rel_name" "LakehouseTable" "$table_name" "$from_col" "$to_col")
      if [[ -z "${CONTEXTUALIZATION_IDS[$logical_name]:-}" ]]; then
        CONTEXTUALIZATION_IDS[$logical_name]=$(generate_uuid "contextualization:$logical_name")
      fi
    fi
  done
}

build_id_mapping() {
  local mapping='{"version":1,"terms":[]}'
  local entity_types entity_count
  entity_types=$(get_entity_types "$DEFINITION_FILE")
  entity_count=$(jq 'length' <<<"$entity_types")

  for i in $(seq 0 $((entity_count - 1))); do
    local entity_name properties property_count property_name property_key
    entity_name=$(jq -r ".[$i].name" <<<"$entity_types")
    mapping=$(jq --arg logicalName "$entity_name" --arg id "${ENTITY_TYPE_IDS[$entity_name]}" \
      '.terms += [{kind: "entity", logicalName: $logicalName, id: $id}]' <<<"$mapping")

    properties=$(jq ".[$i] | [(.properties // [])[], (.timeseriesProperties // [])[]]" <<<"$entity_types")
    property_count=$(jq 'length' <<<"$properties")
    for j in $(seq 0 $((property_count - 1))); do
      property_name=$(jq -r ".[$j].name" <<<"$properties")
      property_key="${entity_name}:${property_name}"
      mapping=$(jq \
        --arg logicalName "${entity_name}.${property_name}" \
        --arg id "${PROPERTY_IDS[$property_key]}" \
        '.terms += [{kind: "property", logicalName: $logicalName, id: $id}]' <<<"$mapping")
    done

    local binding table_name logical_name
    binding=$(get_entity_static_binding "$DEFINITION_FILE" "$entity_name")
    if [[ -n "$binding" && "$binding" != "null" ]]; then
      table_name=$(jq -r '.table' <<<"$binding")
      logical_name=$(binding_logical_name "$entity_name" "NonTimeSeries" "LakehouseTable" "$table_name")
      mapping=$(jq --arg logicalName "$logical_name" --arg id "${DATA_BINDING_IDS[$logical_name]}" \
        '.terms += [{kind: "binding", logicalName: $logicalName, id: $id}]' <<<"$mapping")
    fi

    binding=$(get_entity_timeseries_binding "$DEFINITION_FILE" "$entity_name")
    if [[ -n "$binding" && "$binding" != "null" ]]; then
      table_name=$(jq -r '.table' <<<"$binding")
      logical_name=$(binding_logical_name "$entity_name" "TimeSeries" "KustoTable" "$table_name")
      mapping=$(jq --arg logicalName "$logical_name" --arg id "${DATA_BINDING_IDS[$logical_name]}" \
        '.terms += [{kind: "binding", logicalName: $logicalName, id: $id}]' <<<"$mapping")
    fi
  done

  local relationships relationship_count
  relationships=$(get_relationships "$DEFINITION_FILE")
  relationship_count=$(jq 'length' <<<"$relationships")
  for i in $(seq 0 $((relationship_count - 1))); do
    local relationship_name binding table_name from_col to_col logical_name
    relationship_name=$(jq -r ".[$i].name" <<<"$relationships")
    mapping=$(jq --arg logicalName "$relationship_name" --arg id "${RELATIONSHIP_IDS[$relationship_name]}" \
      '.terms += [{kind: "relationship", logicalName: $logicalName, id: $id}]' <<<"$mapping")

    binding=$(jq ".[$i].binding // null" <<<"$relationships")
    if [[ "$binding" != "null" ]]; then
      table_name=$(jq -r '.table' <<<"$binding")
      from_col=$(jq -r '.fromColumn' <<<"$binding")
      to_col=$(jq -r '.toColumn' <<<"$binding")
      logical_name=$(contextualization_logical_name \
        "$relationship_name" "LakehouseTable" "$table_name" "$from_col" "$to_col")
      mapping=$(jq --arg logicalName "$logical_name" --arg id "${CONTEXTUALIZATION_IDS[$logical_name]}" \
        '.terms += [{kind: "contextualization", logicalName: $logicalName, id: $id}]' <<<"$mapping")
    fi
  done

  jq -S '.terms |= sort_by(.kind, .logicalName)' <<<"$mapping"
}

write_json_atomically() {
  local output_path="$1"
  local content="$2"
  local output_dir temp_file
  output_dir=$(dirname "$output_path")
  mkdir -p "$output_dir"
  temp_file=$(mktemp "$output_path.tmp.XXXXXX")

  if ! jq -e -S . <<<"$content" >"$temp_file"; then
    rm -f "$temp_file"
    err "Failed to encode JSON output: $output_path"
  fi
  mv "$temp_file" "$output_path"
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

  log "Publishing Ontology"

  local ontology_id="$EXISTING_ONTOLOGY_ID"

  if [[ -n "$ontology_id" ]]; then
    info "Ontology '$ONTOLOGY_NAME' already exists: $ontology_id"
  elif [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would create generic Ontology item: $ONTOLOGY_NAME"
  else
    local item_response
    if ! item_response=$(create_item "$WORKSPACE_ID" "Ontology" "$ONTOLOGY_NAME" "$FABRIC_TOKEN"); then
      err "Failed to create generic Ontology item: $ONTOLOGY_NAME"
    fi
    if ! ontology_id=$(jq -er '.id' <<<"$item_response"); then
      err "Failed to retrieve created Ontology item ID: $ONTOLOGY_NAME"
    fi
    ok "Ontology item created: $ontology_id"
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would update generic item definition with metadata"
    return 0
  fi

  info "Updating ontology definition..."
  if ! update_item_definition "$WORKSPACE_ID" "$ontology_id" "$definition_parts" "$FABRIC_TOKEN" >/dev/null; then
    err "Failed to update ontology definition: $ontology_id"
  fi
  ok "Ontology definition updated"
  echo "$ontology_id"
}

verify_ontology_definition() {
  local ontology_id="$1"
  local expected_parts="$2"
  local response actual_parts

  info "Retrieving published ontology definition: $ontology_id"
  if ! response=$(get_item_definition "$WORKSPACE_ID" "$ontology_id" "$FABRIC_TOKEN"); then
    err "Failed to retrieve published ontology definition: $ontology_id"
  fi
  if ! actual_parts=$(decode_item_definition "$response"); then
    err "Failed to decode published ontology definition: $ontology_id"
  fi

  if ! jq -e --argjson expected "$expected_parts" '
    ($expected | map(.path)) as $expectedPaths
    | (map(.path)) as $actualPaths
    | all($expectedPaths[]; . as $path | $actualPaths | index($path) != null)
  ' <<<"$actual_parts" >/dev/null; then
    err "Published ontology definition is missing required generated part paths"
  fi

  if ! jq -e '
    def path_id($pattern): .path | capture($pattern).id;
    ([.[] | select(.path | test("^EntityTypes/[0-9]+/definition\\.json$"))]) as $entities
    | ([.[] | select(.path | test("^RelationshipTypes/[0-9]+/definition\\.json$"))]) as $relationships
    | ($entities | map(.content.id)) as $entityIds
    | ($relationships | map(.content.id)) as $relationshipIds
    | ($entities | map({key: .content.id, value: ([.content.properties[]?.id, .content.timeseriesProperties[]?.id])}) | from_entries) as $propertyIds
    | all($entities[]; . as $entity
      | ($entity.content.id == ($entity | path_id("^EntityTypes/(?<id>[0-9]+)/definition\\.json$")))
      and all($entity.content.entityIdParts[]; $propertyIds[$entity.content.id] | index(.) != null)
      and ($propertyIds[$entity.content.id] | index($entity.content.displayNamePropertyId) != null))
    and all(.[] | select(.path | test("^EntityTypes/[0-9]+/DataBindings/[0-9a-fA-F-]+\\.json$"));
        (path_id("^EntityTypes/(?<id>[0-9]+)/DataBindings/") as $entityId
        | ($entityIds | index($entityId) != null)
        and (.content.id == (.path | capture("/DataBindings/(?<id>[0-9a-fA-F-]+)\\.json$").id))
        and all(.content.dataBindingConfiguration.propertyBindings[]; . as $binding
          | $propertyIds[$entityId] | index($binding.targetPropertyId) != null)))
    and all($relationships[]; . as $relationship
      | ($relationship.content.id == ($relationship | path_id("^RelationshipTypes/(?<id>[0-9]+)/definition\\.json$")))
      and ($entityIds | index($relationship.content.source.entityTypeId) != null)
      and ($entityIds | index($relationship.content.target.entityTypeId) != null))
    and all(.[] | select(.path | test("^RelationshipTypes/[0-9]+/Contextualizations/[0-9a-fA-F-]+\\.json$"));
        (path_id("^RelationshipTypes/(?<id>[0-9]+)/Contextualizations/") as $relationshipId
        | ($relationships[] | select(.content.id == $relationshipId).content) as $relationship
        | ($relationshipIds | index($relationshipId) != null)
        and (.content.id == (.path | capture("/Contextualizations/(?<id>[0-9a-fA-F-]+)\\.json$").id))
        and all(.content.sourceKeyRefBindings[]; . as $binding
          | $propertyIds[$relationship.source.entityTypeId] | index($binding.targetPropertyId) != null)
        and all(.content.targetKeyRefBindings[]; . as $binding
          | $propertyIds[$relationship.target.entityTypeId] | index($binding.targetPropertyId) != null)))
  ' <<<"$actual_parts" >/dev/null; then
    err "Published ontology definition contains invalid internal references"
  fi

  ok "Published ontology definition paths and references verified"
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

if [[ -n "$DEFINITION_PARTS_OUTPUT" ]]; then
  pre_generate_ids
  DEFINITION_PARTS=$(build_ontology_definition)
  mkdir -p "$(dirname "$DEFINITION_PARTS_OUTPUT")"
  jq . <<<"$DEFINITION_PARTS" >"$DEFINITION_PARTS_OUTPUT"
  info "Ontology definition parts: $DEFINITION_PARTS_OUTPUT"
  exit 0
fi

log "Authenticating to Fabric API"
FABRIC_TOKEN=$(get_fabric_token)
info "Authentication successful"

log "Verifying Workspace Access"
workspace_response=$(get_workspace "$WORKSPACE_ID" "$FABRIC_TOKEN")
workspace_name=$(echo "$workspace_response" | jq -r '.displayName')
info "Workspace: $workspace_name ($WORKSPACE_ID)"

# Reconcile IDs from the selected deployed definition before allocating missing IDs
if ! existing_ontology=$(select_workspace_item_by_display_name \
  "$WORKSPACE_ID" "Ontology" "$ONTOLOGY_NAME" "$FABRIC_TOKEN"); then
  err "Failed to select existing Ontology item: $ONTOLOGY_NAME"
fi
if [[ -n "$existing_ontology" ]]; then
  if ! EXISTING_ONTOLOGY_ID=$(jq -er '.id' <<<"$existing_ontology"); then
    err "Failed to decode selected Ontology item: $ONTOLOGY_NAME"
  fi
fi

if [[ -n "$EXISTING_ONTOLOGY_ID" ]]; then
  info "Exporting deployed ontology definition: $EXISTING_ONTOLOGY_ID"
  if ! existing_definition_response=$(get_item_definition "$WORKSPACE_ID" "$EXISTING_ONTOLOGY_ID" "$FABRIC_TOKEN"); then
    err "Failed to retrieve deployed ontology definition: $EXISTING_ONTOLOGY_ID"
  fi
  if ! EXISTING_DEFINITION_PARTS=$(decode_item_definition "$existing_definition_response"); then
    err "Failed to decode deployed ontology definition: $EXISTING_ONTOLOGY_ID"
  fi
  load_existing_ids
fi

# Pre-generate all IDs to avoid subshell issues with associative arrays
pre_generate_ids
ID_MAPPING=$(build_id_mapping)
write_json_atomically "$ID_MAPPING_OUTPUT" "$ID_MAPPING"
info "Ontology ID mapping: $ID_MAPPING_OUTPUT"

# Build ontology definition parts
DEFINITION_PARTS=$(build_ontology_definition)

parts_count=$(echo "$DEFINITION_PARTS" | jq 'length')
info "Total definition parts: $parts_count"

# Create or update ontology
if ! ONTOLOGY_ID=$(create_ontology "$DEFINITION_PARTS"); then
  err "Ontology publication failed"
fi

if [[ "$DRY_RUN" != "true" ]]; then
  verify_ontology_definition "$ONTOLOGY_ID" "$DEFINITION_PARTS"
fi

log "Deployment Complete"
if [[ "$DRY_RUN" == "true" ]]; then
  warn "DRY RUN - No ontology was published and no publication output was written"
else
  PUBLICATION_RESULT=$(jq -n \
    --arg workspaceId "$WORKSPACE_ID" \
    --arg lakehouseId "$LAKEHOUSE_ID" \
    --arg ontologyItemId "$ONTOLOGY_ID" \
    --argjson mapping "$ID_MAPPING" \
    '{
      version: 1,
      workspaceId: $workspaceId,
      lakehouseId: $lakehouseId,
      ontologyItemId: $ontologyItemId,
      mapping: $mapping
    }')
  write_json_atomically "$PUBLICATION_OUTPUT" "$PUBLICATION_RESULT"
  ok "Ontology ID: $ONTOLOGY_ID"
  info "Publication output: $PUBLICATION_OUTPUT"
  warn "Ontology setup is async - entity types take 10-20 minutes to fully provision"
  info "The portal will show 'Setting up your ontology' until complete"
fi
