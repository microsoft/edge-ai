#!/usr/bin/env bash
# shellcheck disable=SC1091
# Deploy Data Sources - Creates Lakehouse and Eventhouse from ontology definition
#
# Creates and populates Fabric data sources (Lakehouse and Eventhouse) based on
# the dataSources section in an ontology definition YAML file.
#
# Dependencies: yq, jq, curl, az (Azure CLI)
#
# Required Arguments:
#   --definition <path>      Path to ontology definition YAML file
#   --workspace-id <id>      Fabric workspace ID (GUID)
#
# Optional Arguments:
#   --skip-lakehouse         Skip Lakehouse creation and data loading
#   --skip-eventhouse        Skip Eventhouse creation and data loading
#   --dry-run                Validate and show plan without making changes
#   -d, --debug              Enable debug output
#
# Environment Variables (optional):
#   FABRIC_API_BASE_URL      Override default Fabric API URL
#   SKIP_VALIDATION          Skip definition validation (not recommended)
#
# Outputs (exported as environment variables):
#   LAKEHOUSE_ID             Created/existing Lakehouse ID
#   LAKEHOUSE_NAME           Lakehouse display name
#   EVENTHOUSE_ID            Created/existing Eventhouse ID
#   EVENTHOUSE_NAME          Eventhouse display name
#   KQL_DATABASE_ID          Created/existing KQL Database ID
#   KQL_DATABASE_NAME        KQL Database display name
#
## Examples
##  ./deploy-data-sources.sh --definition ../definitions/examples/lakeshore-retail.yaml --workspace-id 12345678-1234-1234-1234-123456789abc
##  ./deploy-data-sources.sh --definition ontology.yaml --workspace-id $WORKSPACE_ID --skip-eventhouse
##  ./deploy-data-sources.sh --definition ontology.yaml --workspace-id $WORKSPACE_ID --dry-run
###

set -e
set -o pipefail

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library functions
source "$SCRIPT_DIR/lib/definition-parser.sh"
source "$SCRIPT_DIR/lib/fabric-api.sh"

# Template directory
TEMPLATE_DIR="$SCRIPT_DIR/../templates/kql"

# Arguments
DEFINITION_FILE=""
WORKSPACE_ID=""
SKIP_LAKEHOUSE="${SKIP_LAKEHOUSE:-false}"
SKIP_EVENTHOUSE="${SKIP_EVENTHOUSE:-false}"
SKIP_VALIDATION="${SKIP_VALIDATION:-false}"
DRY_RUN="${DRY_RUN:-false}"
DEBUG="${DEBUG:-false}"

####
# Utility Functions
####

usage() {
  echo "Usage: ${0##*/}"
  grep -x -B99 -m 1 "^###" "$0" \
    | sed -E -e '/^[^#]+=/ {s/^([^ ])/  \1/ ; s/#/ / ; s/=[^ ]*$// ;}' \
    | sed -E -e ':x' -e '/^[^#]+=/ {s/^(  [^ ]+)[^ ] /\1  / ;}' -e 'tx' \
    | sed -e 's/^## //' -e '/^#/d' -e '/^$/d'
  exit 1
}

log() {
  printf "========== %s ==========\n" "$1"
}

info() {
  printf "[ INFO ]: %s\n" "$1"
}

warn() {
  printf "[ WARN ]: %s\n" "$1" >&2
}

err() {
  printf "[ ERROR ]: %s\n" "$1" >&2
  exit 1
}

enable_debug() {
  echo "[ DEBUG ]: Enabling debug output"
  set -x
}

####
# Argument Parsing
####

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
    --skip-lakehouse)
      SKIP_LAKEHOUSE="true"
      shift
      ;;
    --skip-eventhouse)
      SKIP_EVENTHOUSE="true"
      shift
      ;;
    --skip-validation)
      SKIP_VALIDATION="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -d | --debug)
      DEBUG="true"
      enable_debug
      shift
      ;;
    -h | --help)
      usage
      ;;
    *)
      err "Unknown argument: $1"
      ;;
  esac
done

####
# Validate Arguments
####

if [[ -z "$DEFINITION_FILE" ]]; then
  err "--definition <path> is required"
fi

if [[ ! -f "$DEFINITION_FILE" ]]; then
  err "Definition file not found: $DEFINITION_FILE"
fi

if [[ -z "$WORKSPACE_ID" ]]; then
  err "--workspace-id <id> is required"
fi

####
# Validate Definition
####

if [[ "$SKIP_VALIDATION" != "true" ]]; then
  log "Validating Definition"
  if ! "$SCRIPT_DIR/validate-definition.sh" --definition "$DEFINITION_FILE"; then
    err "Definition validation failed"
  fi
  info "Definition validation passed"
fi

####
# Extract Metadata
####

log "Extracting Definition Metadata"
ONTOLOGY_NAME=$(get_metadata_name "$DEFINITION_FILE")
ONTOLOGY_VERSION=$(get_metadata_version "$DEFINITION_FILE")
info "Ontology: $ONTOLOGY_NAME (v$ONTOLOGY_VERSION)"

####
# Authenticate
####

log "Authenticating to Fabric API"
FABRIC_TOKEN=$(get_fabric_token)
STORAGE_TOKEN=$(get_storage_token)
info "Authentication successful"

####
# Verify Workspace Access
####

log "Verifying Workspace Access"
workspace_response=$(get_workspace "$WORKSPACE_ID" "$FABRIC_TOKEN")
workspace_name=$(echo "$workspace_response" | jq -r '.displayName // "Unknown"')
info "Workspace: $workspace_name ($WORKSPACE_ID)"

####
# Deploy Lakehouse
####

deploy_lakehouse() {
  local lakehouse_name lakehouse_id lakehouse_response

  lakehouse_name=$(get_lakehouse_name "$DEFINITION_FILE")
  if [[ -z "$lakehouse_name" ]]; then
    info "No lakehouse defined in dataSources, skipping"
    return 0
  fi

  log "Deploying Lakehouse"
  info "Lakehouse name: $lakehouse_name"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would create/get Lakehouse: $lakehouse_name"
    return 0
  fi

  # Create or get existing lakehouse
  lakehouse_response=$(get_or_create_lakehouse "$WORKSPACE_ID" "$lakehouse_name" "$FABRIC_TOKEN")
  lakehouse_id=$(echo "$lakehouse_response" | jq -r '.id')

  if [[ -z "$lakehouse_id" || "$lakehouse_id" == "null" ]]; then
    err "Failed to get Lakehouse ID"
  fi

  export LAKEHOUSE_ID="$lakehouse_id"
  export LAKEHOUSE_NAME="$lakehouse_name"
  info "Lakehouse ID: $lakehouse_id"

  # Process lakehouse tables
  process_lakehouse_tables "$lakehouse_id"
}

process_lakehouse_tables() {
  local lakehouse_id="$1"
  local tables table_count table_name source_url source_file format

  tables=$(get_lakehouse_tables "$DEFINITION_FILE")
  table_count=$(echo "$tables" | jq 'length')

  if [[ "$table_count" -eq 0 ]]; then
    info "No tables defined in lakehouse, skipping data loading"
    return 0
  fi

  info "Processing $table_count lakehouse tables"

  for i in $(seq 0 $((table_count - 1))); do
    table_name=$(echo "$tables" | jq -r ".[$i].name")
    source_url=$(echo "$tables" | jq -r ".[$i].sourceUrl // empty")
    source_file=$(echo "$tables" | jq -r ".[$i].sourceFile // empty")
    format=$(echo "$tables" | jq -r ".[$i].format // \"csv\"")

    info "Table: $table_name (format: $format)"

    if [[ "$DRY_RUN" == "true" ]]; then
      info "[DRY-RUN] Would process table: $table_name"
      continue
    fi

    # Download source data if URL provided
    local local_file=""
    if [[ -n "$source_url" ]]; then
      local_file=$(download_source_file "$source_url" "$table_name")
    elif [[ -n "$source_file" ]]; then
      local_file="$source_file"
      if [[ ! -f "$local_file" ]]; then
        warn "Source file not found: $local_file, skipping table $table_name"
        continue
      fi
    else
      warn "No sourceUrl or sourceFile for table $table_name, skipping"
      continue
    fi

    # Upload to OneLake Files
    upload_to_onelake "$WORKSPACE_ID" "$lakehouse_id" "raw/${table_name}.${format}" "$local_file" "$STORAGE_TOKEN"

    # Convert to Delta table
    load_lakehouse_table "$WORKSPACE_ID" "$lakehouse_id" "$table_name" "raw/${table_name}.${format}" "$format" "$FABRIC_TOKEN"

    info "Table $table_name loaded successfully"

    # Clean up downloaded file
    if [[ -n "$source_url" && -f "$local_file" ]]; then
      rm -f "$local_file"
    fi
  done
}

download_source_file() {
  local url="$1"
  local table_name="$2"
  local tmp_file

  tmp_file=$(mktemp "/tmp/${table_name}.XXXXXX.csv")

  info "Downloading: $url" >&2
  if ! curl -sSL "$url" -o "$tmp_file"; then
    err "Failed to download: $url"
  fi

  echo "$tmp_file"
}

####
# Deploy Eventhouse
####

deploy_eventhouse() {
  local eventhouse_name database_name eventhouse_id eventhouse_response database_id database_response

  eventhouse_name=$(get_eventhouse_name "$DEFINITION_FILE")
  if [[ -z "$eventhouse_name" ]]; then
    info "No eventhouse defined in dataSources, skipping"
    return 0
  fi

  database_name=$(get_eventhouse_database "$DEFINITION_FILE")
  if [[ -z "$database_name" ]]; then
    database_name="${eventhouse_name}DB"
    warn "No database name specified, using default: $database_name"
  fi

  log "Deploying Eventhouse"
  info "Eventhouse name: $eventhouse_name"
  info "Database name: $database_name"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would create/get Eventhouse: $eventhouse_name"
    info "[DRY-RUN] Would create/get KQL Database: $database_name"
    return 0
  fi

  # Create or get existing eventhouse
  eventhouse_response=$(get_or_create_eventhouse "$WORKSPACE_ID" "$eventhouse_name" "$FABRIC_TOKEN")
  eventhouse_id=$(echo "$eventhouse_response" | jq -r '.id')

  if [[ -z "$eventhouse_id" || "$eventhouse_id" == "null" ]]; then
    err "Failed to get Eventhouse ID"
  fi

  export EVENTHOUSE_ID="$eventhouse_id"
  export EVENTHOUSE_NAME="$eventhouse_name"
  info "Eventhouse ID: $eventhouse_id"

  # Get Eventhouse query URI for KQL operations
  local query_uri
  query_uri=$(get_eventhouse_query_uri "$WORKSPACE_ID" "$eventhouse_id" "$FABRIC_TOKEN")
  if [[ -z "$query_uri" ]]; then
    err "Failed to get Eventhouse query URI"
  fi
  export EVENTHOUSE_QUERY_URI="$query_uri"
  info "Eventhouse Query URI: $query_uri"

  # Create or get existing KQL database
  database_response=$(get_or_create_kql_database "$WORKSPACE_ID" "$database_name" "$eventhouse_id" "$FABRIC_TOKEN")
  database_id=$(echo "$database_response" | jq -r '.id')

  if [[ -z "$database_id" || "$database_id" == "null" ]]; then
    err "Failed to get KQL Database ID"
  fi

  export KQL_DATABASE_ID="$database_id"
  export KQL_DATABASE_NAME="$database_name"
  info "KQL Database ID: $database_id"

  # Process eventhouse tables
  process_eventhouse_tables "$database_name"
}

process_eventhouse_tables() {
  local database_name="$1"
  local tables table_count table_name source_url format schema

  tables=$(get_eventhouse_tables "$DEFINITION_FILE")
  table_count=$(echo "$tables" | jq 'length')

  if [[ "$table_count" -eq 0 ]]; then
    info "No tables defined in eventhouse, skipping"
    return 0
  fi

  info "Processing $table_count eventhouse tables"

  for i in $(seq 0 $((table_count - 1))); do
    table_name=$(echo "$tables" | jq -r ".[$i].name")
    source_url=$(echo "$tables" | jq -r ".[$i].sourceUrl // empty")
    format=$(echo "$tables" | jq -r ".[$i].format // \"csv\"")
    schema=$(echo "$tables" | jq ".[$i].schema // []")

    info "Table: $table_name"

    if [[ "$DRY_RUN" == "true" ]]; then
      info "[DRY-RUN] Would create KQL table: $table_name"
      continue
    fi

    # Generate KQL schema from definition
    create_kql_table "$database_name" "$table_name" "$schema"

    # Create CSV mapping
    create_kql_csv_mapping "$database_name" "$table_name" "$schema"

    # Set retention/caching policies
    local policies
    policies=$(echo "$tables" | jq ".[$i].policies // {}")
    local retention caching
    retention=$(echo "$policies" | jq -r '.retention // "30d"' | sed 's/d$//')
    caching=$(echo "$policies" | jq -r '.caching // "7d"' | sed 's/d$//')

    set_kql_retention_policy "$database_name" "$table_name" "$retention" "$caching"

    # Ingest data if source URL provided
    if [[ -n "$source_url" ]]; then
      ingest_kql_data "$database_name" "$table_name" "$source_url" "$format"
    fi

    info "Table $table_name created successfully"
  done
}

# Strip KQL comments and empty lines from template output
strip_kql_comments() {
  grep -v '^[[:space:]]*//\|^[[:space:]]*$' | tr '\n' ' ' | sed 's/[[:space:]]*$//'
}

create_kql_table() {
  local database_name="$1"
  local table_name="$2"
  local schema="$3"
  local column_schema="" col_name col_type kql_type

  # Build column schema from definition
  local schema_count
  schema_count=$(echo "$schema" | jq 'length')

  for j in $(seq 0 $((schema_count - 1))); do
    col_name=$(echo "$schema" | jq -r ".[$j].name")
    col_type=$(echo "$schema" | jq -r ".[$j].type")
    kql_type=$(map_kql_type "$col_type")

    if [[ -n "$column_schema" ]]; then
      column_schema="$column_schema, "
    fi
    column_schema="${column_schema}${col_name}: ${kql_type}"
  done

  # Generate KQL command from template (strip comments)
  local kql_command
  kql_command=$(TABLE_NAME="$table_name" COLUMN_SCHEMA="$column_schema" envsubst <"$TEMPLATE_DIR/create-table.kql.tmpl" | strip_kql_comments)

  info "Creating KQL table: $table_name"
  execute_kql "$EVENTHOUSE_QUERY_URI" "$database_name" "$kql_command"
}

create_kql_csv_mapping() {
  local database_name="$1"
  local table_name="$2"
  local schema="$3"
  local mapping_name="${table_name}CsvMapping"
  local mapping_json="["

  # Build JSON mapping array
  local schema_count
  schema_count=$(echo "$schema" | jq 'length')

  for j in $(seq 0 $((schema_count - 1))); do
    local col_name col_type kql_type
    col_name=$(echo "$schema" | jq -r ".[$j].name")
    col_type=$(echo "$schema" | jq -r ".[$j].type")
    kql_type=$(map_kql_type "$col_type")

    if [[ "$j" -gt 0 ]]; then
      mapping_json="$mapping_json,"
    fi
    mapping_json="${mapping_json}{\"Name\":\"${col_name}\",\"DataType\":\"${kql_type}\",\"Ordinal\":${j}}"
  done

  mapping_json="$mapping_json]"

  # Generate KQL command from template (strip comments)
  local kql_command
  kql_command=$(TABLE_NAME="$table_name" MAPPING_NAME="$mapping_name" MAPPING_JSON="$mapping_json" envsubst <"$TEMPLATE_DIR/create-mapping.kql.tmpl" | strip_kql_comments)

  info "Creating CSV mapping: $mapping_name"
  execute_kql "$EVENTHOUSE_QUERY_URI" "$database_name" "$kql_command"
}

set_kql_retention_policy() {
  local database_name="$1"
  local table_name="$2"
  local retention_days="$3"
  local caching_days="$4"

  # Generate KQL commands from template
  local kql_commands
  kql_commands=$(TABLE_NAME="$table_name" RETENTION_DAYS="$retention_days" CACHING_DAYS="$caching_days" envsubst <"$TEMPLATE_DIR/retention-policy.kql.tmpl")

  info "Setting retention policy: ${retention_days}d retention, ${caching_days}d caching"

  # Execute each command separately (retention and caching are separate commands)
  while IFS= read -r command; do
    # Skip comments and empty lines - trim leading whitespace
    command="${command#"${command%%[![:space:]]*}"}"
    if [[ -n "$command" && ! "$command" =~ ^// ]]; then
      execute_kql "$EVENTHOUSE_QUERY_URI" "$database_name" "$command"
    fi
  done <<<"$kql_commands"
}

ingest_kql_data() {
  local database_name="$1"
  local table_name="$2"
  local source_url="$3"
  local format="$4"
  local mapping_name="${table_name}CsvMapping"

  info "Ingesting data from: $source_url"

  local kql_command
  kql_command=".ingest into table ${table_name} (h\"${source_url}\") with (format=\"${format}\", ingestionMappingReference=\"${mapping_name}\")"

  execute_kql "$EVENTHOUSE_QUERY_URI" "$database_name" "$kql_command"
}

####
# Main Execution
####

log "Starting Data Sources Deployment"
info "Definition: $DEFINITION_FILE"
info "Workspace: $WORKSPACE_ID"
info "Dry run: $DRY_RUN"

# Deploy Lakehouse
if [[ "$SKIP_LAKEHOUSE" != "true" ]]; then
  deploy_lakehouse
else
  info "Skipping Lakehouse deployment (--skip-lakehouse)"
fi

# Deploy Eventhouse
if [[ "$SKIP_EVENTHOUSE" != "true" ]]; then
  deploy_eventhouse
else
  info "Skipping Eventhouse deployment (--skip-eventhouse)"
fi

####
# Output Summary
####

log "Deployment Complete"

echo ""
echo "=== Data Sources Summary ==="
echo ""

if [[ -n "$LAKEHOUSE_ID" ]]; then
  echo "Lakehouse:"
  echo "  Name: ${LAKEHOUSE_NAME:-N/A}"
  echo "  ID:   ${LAKEHOUSE_ID:-N/A}"
  echo ""
fi

if [[ -n "$EVENTHOUSE_ID" ]]; then
  echo "Eventhouse:"
  echo "  Name: ${EVENTHOUSE_NAME:-N/A}"
  echo "  ID:   ${EVENTHOUSE_ID:-N/A}"
  echo ""
  echo "KQL Database:"
  echo "  Name: ${KQL_DATABASE_NAME:-N/A}"
  echo "  ID:   ${KQL_DATABASE_ID:-N/A}"
  echo ""
fi

# Output JSON for programmatic consumption
if [[ "$DRY_RUN" != "true" ]]; then
  echo ""
  echo "=== JSON Output ==="
  jq -n \
    --arg lh_id "${LAKEHOUSE_ID:-}" \
    --arg lh_name "${LAKEHOUSE_NAME:-}" \
    --arg eh_id "${EVENTHOUSE_ID:-}" \
    --arg eh_name "${EVENTHOUSE_NAME:-}" \
    --arg db_id "${KQL_DATABASE_ID:-}" \
    --arg db_name "${KQL_DATABASE_NAME:-}" \
    '{
      lakehouse: {id: $lh_id, name: $lh_name},
      eventhouse: {id: $eh_id, name: $eh_name},
      kqlDatabase: {id: $db_id, name: $db_name}
    }'
fi

info "Data sources deployment complete"
