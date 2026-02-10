#!/usr/bin/env bash
# shellcheck disable=SC1091
# deploy-semantic-model.sh - Deploy Direct Lake Semantic Model from ontology definition
#
# Dependencies: curl, jq, yq, az (Azure CLI), uuidgen
#
# Usage:
#   ./deploy-semantic-model.sh --definition <path> --workspace-id <id> --lakehouse-id <id>
#   ./deploy-semantic-model.sh --definition ./definitions/examples/lakeshore-retail.yaml \
#     --workspace-id abc123 --lakehouse-id def456

set -e
set -o pipefail

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates/semantic-model"

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
DRY_RUN="false"

####
# Usage and Argument Parsing
####

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Deploy Direct Lake Semantic Model from ontology definition.

Required Arguments:
  --definition <path>     Path to ontology definition YAML file
  --workspace-id <id>     Fabric workspace ID (GUID)
  --lakehouse-id <id>     Lakehouse ID for Direct Lake binding (GUID)

Options:
  --dry-run               Show what would be created without making changes
  -h, --help              Show this help message

Examples:
  $(basename "$0") --definition ./definitions/examples/lakeshore-retail.yaml \\
    --workspace-id abc123 --lakehouse-id def456

  $(basename "$0") --definition ./my-ontology.yaml \\
    --workspace-id abc123 --lakehouse-id def456 --dry-run
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
MODEL_NAME=$(get_semantic_model_name "$DEFINITION_FILE")

if [[ -z "$MODEL_NAME" ]]; then
  MODEL_NAME="${ONTOLOGY_NAME}Model"
  warn "No semantic model name specified, using default: $MODEL_NAME"
fi

info "Ontology: $ONTOLOGY_NAME"
info "Semantic Model: $MODEL_NAME"

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
# Type Mapping Functions
####

map_tmdl_type() {
  local def_type="$1"
  case "$def_type" in
    string) echo "string" ;;
    int | integer) echo "int64" ;;
    double | float | decimal) echo "double" ;;
    datetime) echo "dateTime" ;;
    boolean | bool) echo "boolean" ;;
    *) echo "string" ;;
  esac
}

####
# TMDL Generation Functions
####

generate_uuid() {
  # Generate UUID using available method (portable across platforms)
  if command -v uuidgen &>/dev/null; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  elif [[ -r /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
  else
    # Fallback: generate pseudo-UUID from random bytes
    printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x' \
      $((RANDOM)) $((RANDOM)) $((RANDOM)) \
      $(((RANDOM & 0x0fff) | 0x4000)) \
      $(((RANDOM & 0x3fff) | 0x8000)) \
      $((RANDOM)) $((RANDOM)) $((RANDOM))
  fi
}

generate_database_tmdl() {
  local model_name="$1"
  MODEL_NAME="$model_name" envsubst <"$TEMPLATE_DIR/database.tmdl.tmpl"
}

generate_expressions_tmdl() {
  local workspace_id="$1"
  local lakehouse_id="$2"
  WORKSPACE_ID="$workspace_id" LAKEHOUSE_ID="$lakehouse_id" envsubst <"$TEMPLATE_DIR/expressions.tmdl.tmpl"
}

generate_table_refs() {
  local entity_types entity_count entity_name
  entity_types=$(get_entity_types "$DEFINITION_FILE")
  entity_count=$(echo "$entity_types" | jq 'length')

  for i in $(seq 0 $((entity_count - 1))); do
    entity_name=$(echo "$entity_types" | jq -r ".[$i].name")
    echo "ref table '$entity_name'"
  done
}

generate_model_tmdl() {
  local table_refs
  table_refs=$(generate_table_refs)
  TABLE_REFS="$table_refs" envsubst <"$TEMPLATE_DIR/model.tmdl.tmpl"
}

generate_table_tmdl() {
  local entity_name="$1"
  local entity_json="$2"
  local output_file="$3"
  local key_prop lineage_tag source_table

  key_prop=$(echo "$entity_json" | jq -r '.key')
  lineage_tag=$(generate_uuid)

  # Get data binding source table
  local data_binding
  data_binding=$(echo "$entity_json" | jq -r '.dataBinding.table // .dataBindings[0].table // empty')
  if [[ -z "$data_binding" ]]; then
    source_table=$(echo "$entity_name" | tr '[:upper:]' '[:lower:]')
  else
    source_table="$data_binding"
  fi

  # Write table header directly to file
  {
    echo "table '$entity_name'"
    echo "	lineageTag: $lineage_tag"
    echo ""
    echo "	partition '$entity_name-Partition' = entity"
    echo "		mode: directLake"
    echo "		entityName: $source_table"
    echo "		schemaName: dbo"
    echo "		expressionSource: DatabaseQuery"
    echo ""
  } >"$output_file"

  # Write columns directly to file
  local properties prop_count prop_name prop_type source_col is_key binding tmdl_type summarize_by
  properties=$(echo "$entity_json" | jq '.properties // []')
  prop_count=$(echo "$properties" | jq 'length')

  for j in $(seq 0 $((prop_count - 1))); do
    prop_name=$(echo "$properties" | jq -r ".[$j].name")
    prop_type=$(echo "$properties" | jq -r ".[$j].type")
    source_col=$(echo "$properties" | jq -r ".[$j].sourceColumn // .[$j].name")

    # Check if this property is the key
    if [[ "$prop_name" == "$key_prop" ]]; then
      is_key="true"
    else
      is_key="false"
    fi

    # Only include static/lakehouse-bound properties in semantic model
    binding=$(echo "$properties" | jq -r ".[$j].binding // \"static\"")
    if [[ "$binding" == "timeseries" ]]; then
      continue
    fi

    tmdl_type=$(map_tmdl_type "$prop_type")

    # Determine summarizeBy based on type and key status
    case "$tmdl_type" in
      int64 | double)
        if [[ "$is_key" == "true" ]]; then
          summarize_by="none"
        else
          summarize_by="sum"
        fi
        ;;
      *)
        summarize_by="none"
        ;;
    esac

    # Write column directly to file
    {
      echo "	column '$prop_name'"
      echo "		dataType: $tmdl_type"
      if [[ "$is_key" == "true" ]]; then
        echo "		isKey"
      fi
      echo "		sourceColumn: $source_col"
      echo "		summarizeBy: $summarize_by"
      echo ""
    } >>"$output_file"
  done
}

generate_relationships_tmdl() {
  local relationships rel_count from_entity to_entity rel_guid
  relationships=$(get_relationships "$DEFINITION_FILE")
  rel_count=$(echo "$relationships" | jq 'length')

  if [[ "$rel_count" -eq 0 ]]; then
    echo "// No relationships defined"
    return
  fi

  local entity_types from_key to_key
  entity_types=$(get_entity_types "$DEFINITION_FILE")

  for i in $(seq 0 $((rel_count - 1))); do
    from_entity=$(echo "$relationships" | jq -r ".[$i].from")
    to_entity=$(echo "$relationships" | jq -r ".[$i].to")
    rel_guid=$(generate_uuid)

    # Get primary key columns from entity definitions for semantic model relationships
    # Note: binding.fromColumn/toColumn are for bridge tables, not semantic model relationships
    from_key=$(echo "$entity_types" | jq -r ".[] | select(.name == \"$from_entity\") | .key")
    to_key=$(echo "$entity_types" | jq -r ".[] | select(.name == \"$to_entity\") | .key")

    # TMDL relationships connect entity tables via their primary keys
    # fromColumn references the "many" side (from entity's key)
    # toColumn references the "one" side (to entity's key)
    echo "relationship $rel_guid"
    echo "	fromColumn: '$from_entity'.'$from_key'"
    echo "	toColumn: '$to_entity'.'$to_key'"
    echo ""
  done
}

####
# Build Semantic Model Definition
####

build_semantic_model_definition() {
  local temp_dir database_tmdl model_tmdl expressions_tmdl relationships_tmdl pbism_content

  temp_dir=$(mktemp -d)
  mkdir -p "$temp_dir/definition/tables"

  info "Generating TMDL files in: $temp_dir" >&2

  # Generate database.tmdl
  database_tmdl=$(generate_database_tmdl "$MODEL_NAME")
  echo "$database_tmdl" >"$temp_dir/definition/database.tmdl"
  info "Generated: database.tmdl" >&2

  # Generate model.tmdl
  model_tmdl=$(generate_model_tmdl)
  echo "$model_tmdl" >"$temp_dir/definition/model.tmdl"
  info "Generated: model.tmdl" >&2

  # Generate expressions.tmdl
  expressions_tmdl=$(generate_expressions_tmdl "$WORKSPACE_ID" "$LAKEHOUSE_ID")
  echo "$expressions_tmdl" >"$temp_dir/definition/expressions.tmdl"
  info "Generated: expressions.tmdl" >&2

  # Generate table TMDL files
  local entity_types entity_count entity_name entity_json
  entity_types=$(get_entity_types "$DEFINITION_FILE")
  entity_count=$(echo "$entity_types" | jq 'length')

  for i in $(seq 0 $((entity_count - 1))); do
    entity_name=$(echo "$entity_types" | jq -r ".[$i].name")
    entity_json=$(echo "$entity_types" | jq ".[$i]")

    # Skip entities that only have timeseries binding (no lakehouse table)
    local has_static_binding
    has_static_binding=$(echo "$entity_json" | jq -r '
      if .dataBinding then
        .dataBinding.type == "static"
      elif .dataBindings then
        [.dataBindings[] | select(.type == "static")] | length > 0
      else
        false
      end
    ')

    if [[ "$has_static_binding" != "true" ]]; then
      info "Skipping entity $entity_name (no static data binding)" >&2
      continue
    fi

    generate_table_tmdl "$entity_name" "$entity_json" "$temp_dir/definition/tables/$entity_name.tmdl"
    info "Generated: tables/$entity_name.tmdl" >&2
  done

  # Generate relationships.tmdl
  relationships_tmdl=$(generate_relationships_tmdl)
  echo "$relationships_tmdl" >"$temp_dir/definition/relationships.tmdl"
  info "Generated: relationships.tmdl" >&2

  # Generate definition.pbism (required for TMDL format, version 4.0+)
  local pbism_content
  pbism_content=$(cat "$TEMPLATE_DIR/definition.pbism.tmpl")
  echo "$pbism_content" >"$temp_dir/definition.pbism"
  info "Generated: definition.pbism" >&2

  echo "$temp_dir"
}

####
# Create Semantic Model via API
####

create_semantic_model() {
  local temp_dir="$1"
  local parts_file
  parts_file=$(mktemp)
  echo "[]" >"$parts_file"

  # Build definition parts from generated files using find for recursive traversal
  # Store file list first to avoid subshell issues with while loop
  local file_list
  file_list=$(find "$temp_dir" -type f)

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local rel_path content_b64
    # Get path relative to temp_dir
    rel_path="${file#"$temp_dir"/}"

    # Base64 encode
    content_b64=$(base64 <"$file" | tr -d '\n\r')

    # Build part object and append to array
    local current_parts new_parts
    current_parts=$(cat "$parts_file")
    new_parts=$(echo "$current_parts" | jq \
      --arg path "$rel_path" \
      --arg payload "$content_b64" \
      '. += [{"path": $path, "payload": $payload, "payloadType": "InlineBase64"}]')
    echo "$new_parts" >"$parts_file"
  done <<<"$file_list"

  local parts_array
  parts_array=$(cat "$parts_file")
  rm -f "$parts_file"

  # Verify we have parts
  local parts_count
  parts_count=$(echo "$parts_array" | jq 'length')
  if [[ "$parts_count" -eq 0 ]]; then
    err "No definition parts generated"
  fi
  info "Built $parts_count definition parts" >&2

  # Build request body using file to avoid shell quoting issues
  local request_body_file
  request_body_file=$(mktemp)
  echo "$parts_array" >"${request_body_file}.parts"

  if ! jq -n \
    --arg name "$MODEL_NAME" \
    --slurpfile parts "${request_body_file}.parts" \
    '{
      "displayName": $name,
      "definition": {
        "format": "TMDL",
        "parts": $parts[0]
      }
    }' >"$request_body_file" 2>&1; then
    # Alternative: read file content directly
    jq -n \
      --arg name "$MODEL_NAME" \
      --argjson parts "$(cat "${request_body_file}.parts")" \
      '{
        "displayName": $name,
        "definition": {
          "format": "TMDL",
          "parts": $parts
        }
      }' >"$request_body_file"
  fi

  rm -f "${request_body_file}.parts"
  local request_body
  request_body=$(cat "$request_body_file")

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would create semantic model: $MODEL_NAME" >&2
    info "[DRY-RUN] Definition parts count: $parts_count" >&2
    rm -f "$request_body_file"
    echo '{"id": "dry-run-id", "displayName": "'"$MODEL_NAME"'"}'
    return 0
  fi

  # Check if semantic model already exists
  local list_response existing_model
  list_response=$(fabric_api_call "GET" "/workspaces/$WORKSPACE_ID/semanticModels" "" "$FABRIC_TOKEN")
  existing_model=$(echo "$list_response" | jq -r ".value[] | select(.displayName == \"$MODEL_NAME\")")

  if [[ -n "$existing_model" ]]; then
    local existing_id
    existing_id=$(echo "$existing_model" | jq -r '.id')
    info "Semantic model '$MODEL_NAME' already exists: $existing_id" >&2

    # Update definition using file-based approach
    local update_body_file
    update_body_file=$(mktemp)
    echo "$parts_array" >"${update_body_file}.parts"

    jq -n \
      --slurpfile parts "${update_body_file}.parts" \
      '{
        "definition": {
          "format": "TMDL",
          "parts": $parts[0]
        }
      }' >"$update_body_file"

    rm -f "${update_body_file}.parts"
    local update_body
    update_body=$(cat "$update_body_file")
    rm -f "$update_body_file"

    info "Updating semantic model definition..." >&2
    fabric_api_call "POST" "/workspaces/$WORKSPACE_ID/semanticModels/$existing_id/updateDefinition" "$update_body" "$FABRIC_TOKEN" || true

    rm -f "$request_body_file"
    echo "$existing_model"
    return 0
  fi

  # Create new semantic model
  info "Creating semantic model: $MODEL_NAME" >&2
  local response
  if ! response=$(fabric_api_call "POST" "/workspaces/$WORKSPACE_ID/semanticModels" "$request_body" "$FABRIC_TOKEN"); then
    err "Failed to create semantic model"
  fi
  rm -f "$request_body_file"

  echo "$response"
}

####
# Main Execution
####

log "Starting Semantic Model Deployment"
info "Definition: $DEFINITION_FILE"
info "Workspace: $WORKSPACE_ID"
info "Lakehouse: $LAKEHOUSE_ID"
info "Dry run: $DRY_RUN"

# Build TMDL definition
log "Generating TMDL Definition"
TEMP_DIR=$(build_semantic_model_definition)

# Create semantic model
log "Deploying Semantic Model"
if ! response=$(create_semantic_model "$TEMP_DIR"); then
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Handle long-running operation success response (status: Succeeded but no id)
# Need to look up the created semantic model by name
if echo "$response" | jq -e '.status == "Succeeded"' >/dev/null 2>&1; then
  info "Operation succeeded, looking up semantic model by name..."
  list_response=$(fabric_api_call "GET" "/workspaces/$WORKSPACE_ID/semanticModels" "" "$FABRIC_TOKEN")
  response=$(echo "$list_response" | jq -r ".value[] | select(.displayName == \"$MODEL_NAME\")")
fi

# Handle null or empty response
if [[ -z "$response" || "$response" == "null" ]]; then
  rm -rf "$TEMP_DIR"
  err "Received empty or null response from API"
fi

# Validate response is JSON before parsing
if ! echo "$response" | jq -e . >/dev/null 2>&1; then
  rm -rf "$TEMP_DIR"
  err "Invalid JSON response: $response"
fi

SEMANTIC_MODEL_ID=$(echo "$response" | jq -r '.id // empty')
SEMANTIC_MODEL_NAME=$(echo "$response" | jq -r '.displayName // empty')

if [[ -z "$SEMANTIC_MODEL_ID" || "$SEMANTIC_MODEL_ID" == "null" ]]; then
  err "Failed to get Semantic Model ID"
fi

export SEMANTIC_MODEL_ID
export SEMANTIC_MODEL_NAME
info "Semantic Model ID: $SEMANTIC_MODEL_ID"

# Cleanup
rm -rf "$TEMP_DIR"

####
# Output Summary
####

log "Deployment Complete"

cat <<EOF

=== Semantic Model Summary ===

Semantic Model:
  Name: $SEMANTIC_MODEL_NAME
  ID:   $SEMANTIC_MODEL_ID

Data Source:
  Workspace: $WORKSPACE_ID
  Lakehouse: $LAKEHOUSE_ID

=== JSON Output ===
{
  "semanticModel": {
    "id": "$SEMANTIC_MODEL_ID",
    "name": "$SEMANTIC_MODEL_NAME"
  }
}
EOF

info "Semantic model deployment complete"
