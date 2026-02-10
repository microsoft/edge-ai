#!/usr/bin/env bash
# shellcheck disable=SC1091
# deploy.sh - Deploy complete ontology with local data
#
# Generic deployment script that deploys any ontology definition along with
# local CSV/Parquet data files. This is the recommended entry point for
# deploying custom ontologies.
#
# Deployment sequence:
#   1. Validate definition
#   2. Create Lakehouse and load data from --data-dir
#   3. Create Semantic Model (Direct Lake)
#   4. Create Ontology (entity types, relationships)
#
# Dependencies: curl, jq, yq, az (Azure CLI)
#
# Usage:
#   ./deploy.sh --definition <path> --workspace-id <id> [--data-dir <path>]
#
# Examples:
#   # Deploy with local data directory
#   ./deploy.sh --definition ./scratchpad/smart-building/smart-building.yaml \
#     --workspace-id abc123 --data-dir ./scratchpad/smart-building/data
#
#   # Deploy using sourceUrl/sourceFile from YAML (no --data-dir)
#   ./deploy.sh --definition ./definitions/examples/lakeshore-retail.yaml \
#     --workspace-id abc123

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/definition-parser.sh"
source "$SCRIPT_DIR/lib/fabric-api.sh"

####
# Configuration
####

DEFINITION_FILE=""
WORKSPACE_ID=""
DATA_DIR=""
SKIP_DATA_SOURCES="false"
SKIP_SEMANTIC_MODEL="false"
SKIP_ONTOLOGY="false"
DRY_RUN="false"

# Resource IDs populated during deployment
LAKEHOUSE_ID=""
LAKEHOUSE_NAME=""
EVENTHOUSE_ID=""
KQL_DATABASE_ID=""
CLUSTER_URI=""

####
# Usage
####

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Deploy a complete ontology with data to Microsoft Fabric.

This script orchestrates the full deployment:
  1. Data Sources: Creates Lakehouse, uploads data, loads Delta tables
  2. Semantic Model: Creates Direct Lake semantic model
  3. Ontology: Creates entity types, relationships, and data bindings

Required Arguments:
  --definition <path>       Path to ontology definition YAML file
  --workspace-id <id>       Fabric workspace ID (GUID)

Data Source Arguments (one of):
  --data-dir <path>         Directory containing CSV/Parquet files to upload
                            File names must match table names in definition
                            (e.g., buildings.csv for table "buildings")
  (or)                      Definition YAML contains sourceUrl/sourceFile entries

Optional Arguments:
  --skip-data-sources       Skip data source creation (use existing Lakehouse)
  --skip-semantic-model     Skip semantic model creation
  --skip-ontology           Skip ontology creation
  --lakehouse-id <id>       Use existing Lakehouse (required with --skip-data-sources)
  --dry-run                 Show deployment plan without making changes
  -h, --help                Show this help message

Examples:
  # Deploy custom ontology with local data
  $(basename "$0") --definition ./my-ontology.yaml \\
    --workspace-id abc123 --data-dir ./my-data/

  # Deploy example with remote data (sourceUrl in YAML)
  $(basename "$0") --definition ./definitions/examples/lakeshore-retail.yaml \\
    --workspace-id abc123

  # Skip data loading, deploy to existing Lakehouse
  $(basename "$0") --definition ./my-ontology.yaml \\
    --workspace-id abc123 --skip-data-sources --lakehouse-id def456

  # Dry run to preview deployment
  $(basename "$0") --definition ./my-ontology.yaml \\
    --workspace-id abc123 --data-dir ./my-data/ --dry-run
EOF
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
    --data-dir)
      DATA_DIR="$2"
      shift 2
      ;;
    --lakehouse-id)
      LAKEHOUSE_ID="$2"
      shift 2
      ;;
    --skip-data-sources)
      SKIP_DATA_SOURCES="true"
      shift
      ;;
    --skip-semantic-model)
      SKIP_SEMANTIC_MODEL="true"
      shift
      ;;
    --skip-ontology)
      SKIP_ONTOLOGY="true"
      shift
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
      err "Unknown option: $1"
      ;;
  esac
done

####
# Validation
####

log "Validating Prerequisites"

if [[ -z "$DEFINITION_FILE" ]]; then
  err "--definition is required"
fi

if [[ ! -f "$DEFINITION_FILE" ]]; then
  err "Definition file not found: $DEFINITION_FILE"
fi

if [[ -z "$WORKSPACE_ID" ]]; then
  err "--workspace-id is required"
fi

if [[ "$SKIP_DATA_SOURCES" == "true" && -z "$LAKEHOUSE_ID" ]]; then
  err "--lakehouse-id is required when using --skip-data-sources"
fi

if [[ -n "$DATA_DIR" && ! -d "$DATA_DIR" ]]; then
  err "Data directory not found: $DATA_DIR"
fi

# Check required tools
for tool in az curl jq yq; do
  if ! command -v "$tool" &>/dev/null; then
    err "Required tool not found: $tool"
  fi
done

# Check Azure CLI authentication
if ! az account show &>/dev/null; then
  err "Azure CLI not authenticated. Run 'az login' first."
fi

ok "Prerequisites validated"

####
# Validate Definition
####

log "Validating Definition"
info "Definition: $DEFINITION_FILE"

if ! "$SCRIPT_DIR/validate-definition.sh" --definition "$DEFINITION_FILE"; then
  err "Definition validation failed"
fi

ok "Definition validation passed"

####
# Extract Metadata
####

log "Extracting Metadata"

ONTOLOGY_NAME=$(get_metadata_name "$DEFINITION_FILE")
ONTOLOGY_DESC=$(get_metadata_description "$DEFINITION_FILE")
LAKEHOUSE_NAME=$(get_lakehouse_name "$DEFINITION_FILE")

info "Ontology: $ONTOLOGY_NAME"
info "Description: $ONTOLOGY_DESC"
info "Lakehouse: $LAKEHOUSE_NAME"

####
# Display Configuration
####

log "Deployment Configuration"

info "Workspace ID: $WORKSPACE_ID"
info "Definition: $DEFINITION_FILE"
if [[ -n "$DATA_DIR" ]]; then
  info "Data Directory: $DATA_DIR"
fi
info "Deploy Data Sources: $(if [[ "$SKIP_DATA_SOURCES" == "true" ]]; then echo "No (skipped)"; else echo "Yes"; fi)"
info "Deploy Semantic Model: $(if [[ "$SKIP_SEMANTIC_MODEL" == "true" ]]; then echo "No (skipped)"; else echo "Yes"; fi)"
info "Deploy Ontology: $(if [[ "$SKIP_ONTOLOGY" == "true" ]]; then echo "No (skipped)"; else echo "Yes"; fi)"

if [[ -n "$LAKEHOUSE_ID" ]]; then
  info "Lakehouse ID: $LAKEHOUSE_ID (provided)"
fi

if [[ "$DRY_RUN" == "true" ]]; then
  warn "DRY RUN MODE - No changes will be made"
fi

####
# Authenticate
####

log "Authenticating to Fabric API"
FABRIC_TOKEN=$(get_fabric_token)
STORAGE_TOKEN=$(get_storage_token)
ok "Authentication successful"

####
# Verify Workspace
####

log "Verifying Workspace Access"
workspace_response=$(get_workspace "$WORKSPACE_ID" "$FABRIC_TOKEN")
workspace_name=$(echo "$workspace_response" | jq -r '.displayName // "Unknown"')
info "Workspace: $workspace_name ($WORKSPACE_ID)"

####
# Step 1: Deploy Data Sources
####

if [[ "$SKIP_DATA_SOURCES" != "true" ]]; then
  log "Step 1: Deploying Data Sources"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would create Lakehouse: $LAKEHOUSE_NAME"

    # Show what tables would be created
    tables=$(get_lakehouse_tables "$DEFINITION_FILE")
    table_count=$(echo "$tables" | jq 'length')

    for i in $(seq 0 $((table_count - 1))); do
      table_name=$(echo "$tables" | jq -r ".[$i].name")

      # Check for local data file
      if [[ -n "$DATA_DIR" ]]; then
        for ext in csv parquet; do
          if [[ -f "$DATA_DIR/${table_name}.${ext}" ]]; then
            info "[DRY-RUN] Would upload: ${table_name}.${ext} -> table '$table_name'"
            break
          fi
        done
      else
        source_url=$(echo "$tables" | jq -r ".[$i].sourceUrl // empty")
        source_file=$(echo "$tables" | jq -r ".[$i].sourceFile // empty")
        if [[ -n "$source_url" ]]; then
          info "[DRY-RUN] Would download: $source_url -> table '$table_name'"
        elif [[ -n "$source_file" ]]; then
          info "[DRY-RUN] Would upload: $source_file -> table '$table_name'"
        fi
      fi
    done

    # Set placeholder ID for dry-run mode
    LAKEHOUSE_ID="dry-run-lakehouse-id"
  else
    # Create or get Lakehouse
    info "Creating Lakehouse: $LAKEHOUSE_NAME"
    lakehouse_response=$(get_or_create_lakehouse "$WORKSPACE_ID" "$LAKEHOUSE_NAME" "$FABRIC_TOKEN")
    LAKEHOUSE_ID=$(echo "$lakehouse_response" | jq -r '.id')

    if [[ -z "$LAKEHOUSE_ID" || "$LAKEHOUSE_ID" == "null" ]]; then
      err "Failed to get Lakehouse ID"
    fi

    ok "Lakehouse ID: $LAKEHOUSE_ID"

    # Process tables
    tables=$(get_lakehouse_tables "$DEFINITION_FILE")
    table_count=$(echo "$tables" | jq 'length')

    info "Processing $table_count tables"

    for i in $(seq 0 $((table_count - 1))); do
      table_name=$(echo "$tables" | jq -r ".[$i].name")
      format=$(echo "$tables" | jq -r ".[$i].format // \"csv\"")
      source_url=$(echo "$tables" | jq -r ".[$i].sourceUrl // empty")
      source_file=$(echo "$tables" | jq -r ".[$i].sourceFile // empty")

      info "Table: $table_name"

      local_file=""

      # Priority 1: Local data directory
      if [[ -n "$DATA_DIR" ]]; then
        for ext in csv parquet; do
          if [[ -f "$DATA_DIR/${table_name}.${ext}" ]]; then
            local_file="$DATA_DIR/${table_name}.${ext}"
            format="$ext"
            info "Found local file: ${table_name}.${ext}"
            break
          fi
        done
      fi

      # Priority 2: sourceUrl from YAML
      if [[ -z "$local_file" && -n "$source_url" ]]; then
        info "Downloading from: $source_url"
        local_file=$(mktemp "/tmp/${table_name}.XXXXXX.${format}")
        if ! curl -sSL "$source_url" -o "$local_file"; then
          err "Failed to download: $source_url"
        fi
      fi

      # Priority 3: sourceFile from YAML
      if [[ -z "$local_file" && -n "$source_file" ]]; then
        # Resolve relative paths from definition file location
        if [[ ! "$source_file" = /* ]]; then
          source_file="$(dirname "$DEFINITION_FILE")/$source_file"
        fi
        if [[ -f "$source_file" ]]; then
          local_file="$source_file"
          info "Using source file: $source_file"
        fi
      fi

      if [[ -z "$local_file" || ! -f "$local_file" ]]; then
        warn "No data source found for table '$table_name', skipping"
        continue
      fi

      # Upload to OneLake Files
      info "Uploading to OneLake: raw/${table_name}.${format}"
      upload_to_onelake "$WORKSPACE_ID" "$LAKEHOUSE_ID" "raw/${table_name}.${format}" "$local_file" "$STORAGE_TOKEN"

      # Load as Delta table
      info "Loading Delta table: $table_name"
      load_lakehouse_table "$WORKSPACE_ID" "$LAKEHOUSE_ID" "$table_name" "raw/${table_name}.${format}" "$format" "$FABRIC_TOKEN"

      ok "Table '$table_name' loaded"

      # Cleanup temp files from URL downloads
      if [[ -n "$source_url" && "$local_file" == /tmp/* ]]; then
        rm -f "$local_file"
      fi
    done

    # Handle Eventhouse if defined
    eventhouse_name=$(get_eventhouse_name "$DEFINITION_FILE")
    if [[ -n "$eventhouse_name" && "$eventhouse_name" != "null" ]]; then
      info "Eventhouse deployment delegated to deploy-data-sources.sh"
      "$SCRIPT_DIR/deploy-data-sources.sh" \
        --definition "$DEFINITION_FILE" \
        --workspace-id "$WORKSPACE_ID" \
        --skip-lakehouse

      # Capture Eventhouse IDs from environment
      EVENTHOUSE_ID="${EVENTHOUSE_ID:-}"
      KQL_DATABASE_ID="${KQL_DATABASE_ID:-}"
      CLUSTER_URI="${EVENTHOUSE_QUERY_URI:-}"
    fi

    ok "Data sources deployed"
  fi
else
  log "Step 1: Skipping Data Sources"
  info "Using existing Lakehouse: $LAKEHOUSE_ID"
fi

####
# Step 2: Deploy Semantic Model
####

if [[ "$SKIP_SEMANTIC_MODEL" != "true" ]]; then
  log "Step 2: Deploying Semantic Model"

  if [[ -z "$LAKEHOUSE_ID" ]]; then
    err "Lakehouse ID is required for semantic model deployment"
  fi

  deploy_args=(
    "--definition" "$DEFINITION_FILE"
    "--workspace-id" "$WORKSPACE_ID"
    "--lakehouse-id" "$LAKEHOUSE_ID"
  )

  if [[ "$DRY_RUN" == "true" ]]; then
    deploy_args+=("--dry-run")
  fi

  "$SCRIPT_DIR/deploy-semantic-model.sh" "${deploy_args[@]}"
  ok "Semantic model deployed"
else
  log "Step 2: Skipping Semantic Model"
fi

####
# Step 3: Deploy Ontology
####

if [[ "$SKIP_ONTOLOGY" != "true" ]]; then
  log "Step 3: Deploying Ontology"

  if [[ -z "$LAKEHOUSE_ID" ]]; then
    err "Lakehouse ID is required for ontology deployment"
  fi

  deploy_args=(
    "--definition" "$DEFINITION_FILE"
    "--workspace-id" "$WORKSPACE_ID"
    "--lakehouse-id" "$LAKEHOUSE_ID"
  )

  if [[ -n "$EVENTHOUSE_ID" ]]; then
    deploy_args+=("--eventhouse-id" "$EVENTHOUSE_ID")
  fi
  if [[ -n "$CLUSTER_URI" ]]; then
    deploy_args+=("--cluster-uri" "$CLUSTER_URI")
  fi
  if [[ -n "$KQL_DATABASE_ID" ]]; then
    deploy_args+=("--kql-database-id" "$KQL_DATABASE_ID")
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    deploy_args+=("--dry-run")
  fi

  "$SCRIPT_DIR/deploy-ontology.sh" "${deploy_args[@]}"
  ok "Ontology deployed"
  warn "Ontology setup is async - entity types take 10-20 minutes to fully provision"
  info "The portal will show 'Setting up your ontology' until complete"
else
  log "Step 3: Skipping Ontology"
fi

####
# Summary
####

log "Deployment Complete"

if [[ "$DRY_RUN" == "true" ]]; then
  warn "DRY RUN - No changes were made"
  info "Remove --dry-run to perform actual deployment"
  exit 0
fi

cat <<EOF

=== Deployment Summary ===

Ontology: $ONTOLOGY_NAME
Workspace: $workspace_name ($WORKSPACE_ID)

Resources Created:
  Lakehouse: $LAKEHOUSE_NAME ($LAKEHOUSE_ID)
EOF

if [[ -n "$EVENTHOUSE_ID" ]]; then
  echo "  Eventhouse: $EVENTHOUSE_ID"
fi

cat <<EOF

=== Next Steps ===

1. Open your workspace:
   https://app.fabric.microsoft.com/groups/$WORKSPACE_ID

2. Verify the Lakehouse tables were created correctly

3. Open the Semantic Model and verify Direct Lake connection

4. Create a Data Agent (manual step - no API available):
   - Click '+ New item' → Search for 'Data agent'
   - Add the ontology as a data source
   - Add instruction: "Support group by in GQL"

EOF

info "Deployment complete"
