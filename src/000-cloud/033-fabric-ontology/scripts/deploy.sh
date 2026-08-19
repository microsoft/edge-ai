#!/usr/bin/env bash
# deploy.sh - Publish a static Fabric Ontology into existing resources

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/logging.sh"

DEFINITION_FILE=""
WORKSPACE_ID=""
LAKEHOUSE_ID=""
OUTPUT_FILE=""
DRY_RUN="false"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Publish a static Lakehouse ontology into existing Microsoft Fabric resources.

Required Arguments:
  --definition <path>     Path to ontology definition YAML file
  --workspace-id <id>     Existing Fabric workspace ID (GUID)
  --lakehouse-id <id>     Existing Lakehouse ID (GUID)
  --output <path>         Write the publication result as JSON

Options:
  --dry-run               Show publication intent without publishing or writing output
  -h, --help              Show this help message

This supported publisher does not create or load Fabric resources. Resource creation
and data loading are separate demonstration concerns outside this entry point.
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
    --output)
      OUTPUT_FILE="$2"
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
      err "Unknown option: $1"
      ;;
  esac
done

if [[ -z "$DEFINITION_FILE" ]]; then
  err "--definition is required"
fi
if [[ ! -f "$DEFINITION_FILE" ]]; then
  err "Definition file not found: $DEFINITION_FILE"
fi
if [[ -z "$WORKSPACE_ID" ]]; then
  err "--workspace-id is required"
fi
if [[ -z "$LAKEHOUSE_ID" ]]; then
  err "--lakehouse-id is required"
fi
if [[ -z "$OUTPUT_FILE" ]]; then
  err "--output is required"
fi

deploy_args=(
  "--definition" "$DEFINITION_FILE"
  "--workspace-id" "$WORKSPACE_ID"
  "--lakehouse-id" "$LAKEHOUSE_ID"
  "--output" "$OUTPUT_FILE"
)

if [[ "$DRY_RUN" == "true" ]]; then
  deploy_args+=("--dry-run")
fi

log "Publishing Static Fabric Ontology"
info "Workspace ID: $WORKSPACE_ID"
info "Lakehouse ID: $LAKEHOUSE_ID"
info "Publication output: $OUTPUT_FILE"

"$SCRIPT_DIR/deploy-ontology.sh" "${deploy_args[@]}"

if [[ "$DRY_RUN" == "true" ]]; then
  warn "DRY RUN - No ontology was published and no publication output was written"
else
  ok "Ontology publication result: $OUTPUT_FILE"
fi
