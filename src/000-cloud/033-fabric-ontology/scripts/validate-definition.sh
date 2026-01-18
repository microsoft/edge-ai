#!/usr/bin/env bash
# shellcheck disable=SC1091
#===============================================================================
# Ontology Definition Validation Script
#===============================================================================
# Validates ontology definition YAML files against schema and semantic rules.
#
# This script performs two levels of validation:
# 1. Structural validation - Required fields, types, allowed values
# 2. Semantic validation - Cross-references, consistency checks
#
# USAGE:
#   ./validate-definition.sh --definition <path-to-yaml>
#   ./validate-definition.sh -d <path-to-yaml>
#   ./validate-definition.sh --help
#
# ARGUMENTS:
#   -d, --definition  Path to ontology definition YAML file (required)
#   -v, --verbose     Enable verbose output
#   -h, --help        Show this help message
#
# EXIT CODES:
#   0 - Definition is valid
#   1 - Validation failed (see error messages)
#   2 - Invalid arguments or missing dependencies
#
# EXAMPLES:
#   # Validate the Lakeshore Retail example
#   ./validate-definition.sh --definition ../definitions/examples/lakeshore-retail.yaml
#
#   # Validate with verbose output
#   ./validate-definition.sh -d my-ontology.yaml --verbose
#
# DEPENDENCIES:
#   - yq (https://github.com/mikefarah/yq) - YAML parser
#   - jq - JSON processor
#
# SEE ALSO:
#   - definitions/schema.json - JSON Schema for structural validation
#   - lib/definition-parser.sh - YAML parsing utilities
#===============================================================================

set -e
set -o pipefail

# Script location for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib/definition-parser.sh"

#===============================================================================
# Configuration
#===============================================================================
readonly SUPPORTED_TYPES=("string" "int" "double" "datetime" "boolean" "object")
readonly SUPPORTED_BINDINGS=("static" "timeseries")
readonly SUPPORTED_SOURCES=("lakehouse" "eventhouse")

#===============================================================================
# Logging Functions
#===============================================================================
VERBOSE=${VERBOSE:-false}

log() {
  printf "[ INFO  ]: %s\n" "$1"
}

warn() {
  printf "[ WARN  ]: %s\n" "$1" >&2
}

err() {
  printf "[ ERROR ]: %s\n" "$1" >&2
}

debug() {
  if [[ "$VERBOSE" == "true" ]]; then
    printf "[ DEBUG ]: %s\n" "$1"
  fi
}

success() {
  printf "[ OK    ]: %s\n" "$1"
}

#===============================================================================
# Usage
#===============================================================================
usage() {
  cat << 'EOF'
Ontology Definition Validation Script

Validates ontology definition YAML files before deployment.

USAGE:
  validate-definition.sh --definition <path> [OPTIONS]

ARGUMENTS:
  -d, --definition <path>   Path to ontology definition YAML file (required)

OPTIONS:
  -v, --verbose             Enable verbose output
  -h, --help                Show this help message

EXAMPLES:
  # Validate the Lakeshore Retail example
  ./validate-definition.sh -d definitions/examples/lakeshore-retail.yaml

  # Validate with verbose output
  ./validate-definition.sh -d my-ontology.yaml --verbose

EXIT CODES:
  0 - Definition is valid
  1 - Validation failed
  2 - Invalid arguments or missing dependencies
EOF
}

#===============================================================================
# Argument Parsing
#===============================================================================
DEFINITION_FILE=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--definition)
        DEFINITION_FILE="$2"
        shift 2
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown argument: $1"
        usage
        exit 2
        ;;
    esac
  done

  if [[ -z "$DEFINITION_FILE" ]]; then
    err "Missing required argument: --definition"
    usage
    exit 2
  fi

  if [[ ! -f "$DEFINITION_FILE" ]]; then
    err "Definition file not found: $DEFINITION_FILE"
    exit 2
  fi
}

#===============================================================================
# Validation Functions
#===============================================================================
ERRORS=()
WARNINGS=()

add_error() {
  ERRORS+=("$1")
  err "$1"
}

add_warning() {
  WARNINGS+=("$1")
  warn "$1"
}

# Check if value is in array
in_array() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

#-------------------------------------------------------------------------------
# Validate API version and kind
#-------------------------------------------------------------------------------
validate_api_version() {
  debug "Checking apiVersion and kind..."

  local api_version
  api_version=$(yq -r '.apiVersion // ""' "$DEFINITION_FILE")

  if [[ -z "$api_version" ]]; then
    add_error "Missing required field: apiVersion"
  elif [[ "$api_version" != "fabric.ontology/v1" ]]; then
    add_error "Invalid apiVersion: '$api_version' (expected 'fabric.ontology/v1')"
  fi

  local kind
  kind=$(yq -r '.kind // ""' "$DEFINITION_FILE")

  if [[ -z "$kind" ]]; then
    add_error "Missing required field: kind"
  elif [[ "$kind" != "OntologyDefinition" ]]; then
    add_error "Invalid kind: '$kind' (expected 'OntologyDefinition')"
  fi
}

#-------------------------------------------------------------------------------
# Validate metadata section
#-------------------------------------------------------------------------------
validate_metadata() {
  debug "Checking metadata..."

  local name
  name=$(get_metadata_name "$DEFINITION_FILE")

  if [[ -z "$name" || "$name" == "null" ]]; then
    add_error "Missing required field: metadata.name"
  else
    debug "  metadata.name: $name"
  fi
}

#-------------------------------------------------------------------------------
# Validate entity types
#-------------------------------------------------------------------------------
validate_entity_types() {
  debug "Checking entityTypes..."

  local count
  count=$(get_entity_type_count "$DEFINITION_FILE")

  if [[ "$count" -eq 0 ]]; then
    add_error "At least one entityType is required"
    return
  fi

  debug "  Found $count entity type(s)"

  # Collect all entity names for relationship validation
  local entity_names=()
  while IFS= read -r name; do
    entity_names+=("$name")
  done < <(get_entity_type_names "$DEFINITION_FILE")

  # Validate each entity type
  for entity_name in "${entity_names[@]}"; do
    validate_entity_type "$entity_name"
  done
}

validate_entity_type() {
  local entity_name="$1"
  debug "  Validating entity: $entity_name"

  # Get entity key
  local key
  key=$(get_entity_key "$DEFINITION_FILE" "$entity_name")

  if [[ -z "$key" || "$key" == "null" ]]; then
    add_error "Entity '$entity_name': Missing required field 'key'"
    return
  fi

  # Get property names
  local prop_names=()
  while IFS= read -r prop_name; do
    prop_names+=("$prop_name")
  done < <(get_entity_property_names "$DEFINITION_FILE" "$entity_name")

  if [[ ${#prop_names[@]} -eq 0 ]]; then
    add_error "Entity '$entity_name': At least one property is required"
    return
  fi

  # Validate key references a valid property
  if ! in_array "$key" "${prop_names[@]}"; then
    add_error "Entity '$entity_name': Key '$key' does not reference a valid property. Available: ${prop_names[*]}"
  fi

  # Validate each property
  local properties
  properties=$(get_entity_properties "$DEFINITION_FILE" "$entity_name")

  echo "$properties" | jq -c '.[]' | while read -r prop; do
    local prop_name prop_type prop_binding
    prop_name=$(echo "$prop" | jq -r '.name')
    prop_type=$(echo "$prop" | jq -r '.type')
    prop_binding=$(echo "$prop" | jq -r '.binding // "static"')

    # Validate property type
    if ! in_array "$prop_type" "${SUPPORTED_TYPES[@]}"; then
      add_error "Entity '$entity_name', property '$prop_name': Invalid type '$prop_type'. Supported: ${SUPPORTED_TYPES[*]}"
    fi

    # Validate binding type if specified
    if [[ "$prop_binding" != "null" ]] && ! in_array "$prop_binding" "${SUPPORTED_BINDINGS[@]}"; then
      add_error "Entity '$entity_name', property '$prop_name': Invalid binding '$prop_binding'. Supported: ${SUPPORTED_BINDINGS[*]}"
    fi
  done

  # Validate data bindings
  validate_entity_bindings "$entity_name"
}

validate_entity_bindings() {
  local entity_name="$1"

  # Check for single dataBinding
  local single_binding
  single_binding=$(get_entity_data_binding "$DEFINITION_FILE" "$entity_name")

  # Check for multiple dataBindings
  local multi_bindings
  multi_bindings=$(get_entity_data_bindings "$DEFINITION_FILE" "$entity_name")

  local has_single has_multi
  has_single=$([[ "$single_binding" != "null" && -n "$single_binding" ]] && echo "true" || echo "false")
  has_multi=$([[ $(echo "$multi_bindings" | jq 'length') -gt 0 ]] && echo "true" || echo "false")

  if [[ "$has_single" == "false" && "$has_multi" == "false" ]]; then
    add_warning "Entity '$entity_name': No dataBinding or dataBindings defined"
    return
  fi

  # Validate single binding
  if [[ "$has_single" == "true" ]]; then
    validate_binding "$entity_name" "$single_binding" "dataBinding"
  fi

  # Validate multiple bindings
  if [[ "$has_multi" == "true" ]]; then
    echo "$multi_bindings" | jq -c '.[]' | while read -r binding; do
      local binding_type
      binding_type=$(echo "$binding" | jq -r '.type')
      validate_binding "$entity_name" "$binding" "dataBindings[$binding_type]"
    done
  fi
}

validate_binding() {
  local entity_name="$1"
  local binding="$2"
  local binding_path="$3"

  local binding_type source table
  binding_type=$(echo "$binding" | jq -r '.type')
  source=$(echo "$binding" | jq -r '.source')
  table=$(echo "$binding" | jq -r '.table')

  # Validate binding type
  if ! in_array "$binding_type" "${SUPPORTED_BINDINGS[@]}"; then
    add_error "Entity '$entity_name', $binding_path: Invalid type '$binding_type'. Supported: ${SUPPORTED_BINDINGS[*]}"
  fi

  # Validate source
  if ! in_array "$source" "${SUPPORTED_SOURCES[@]}"; then
    add_error "Entity '$entity_name', $binding_path: Invalid source '$source'. Supported: ${SUPPORTED_SOURCES[*]}"
  fi

  # Validate table is specified
  if [[ -z "$table" || "$table" == "null" ]]; then
    add_error "Entity '$entity_name', $binding_path: Missing required field 'table'"
  fi

  # Validate source is defined in dataSources
  if [[ "$source" == "lakehouse" ]]; then
    local lakehouse_name
    lakehouse_name=$(get_lakehouse_name "$DEFINITION_FILE")
    if [[ -z "$lakehouse_name" || "$lakehouse_name" == "null" ]]; then
      add_error "Entity '$entity_name', $binding_path: References lakehouse but dataSources.lakehouse is not defined"
    else
      # Validate table exists in lakehouse
      local table_exists
      table_exists=$(yq ".dataSources.lakehouse.tables[] | select(.name == \"$table\") | .name" "$DEFINITION_FILE")
      if [[ -z "$table_exists" ]]; then
        add_error "Entity '$entity_name', $binding_path: Table '$table' not found in dataSources.lakehouse.tables"
      fi
    fi
  elif [[ "$source" == "eventhouse" ]]; then
    local eventhouse_name
    eventhouse_name=$(get_eventhouse_name "$DEFINITION_FILE")
    if [[ -z "$eventhouse_name" || "$eventhouse_name" == "null" ]]; then
      add_error "Entity '$entity_name', $binding_path: References eventhouse but dataSources.eventhouse is not defined"
    else
      # Validate table exists in eventhouse
      local table_exists
      table_exists=$(yq ".dataSources.eventhouse.tables[] | select(.name == \"$table\") | .name" "$DEFINITION_FILE")
      if [[ -z "$table_exists" ]]; then
        add_error "Entity '$entity_name', $binding_path: Table '$table' not found in dataSources.eventhouse.tables"
      fi
    fi
  fi

  # Validate timeseries-specific fields
  if [[ "$binding_type" == "timeseries" ]]; then
    local timestamp_col
    timestamp_col=$(echo "$binding" | jq -r '.timestampColumn // ""')
    if [[ -z "$timestamp_col" ]]; then
      add_error "Entity '$entity_name', $binding_path: Timeseries binding requires 'timestampColumn'"
    fi
  fi
}

#-------------------------------------------------------------------------------
# Validate relationships
#-------------------------------------------------------------------------------
validate_relationships() {
  debug "Checking relationships..."

  local count
  count=$(get_relationship_count "$DEFINITION_FILE")

  if [[ "$count" -eq 0 ]]; then
    debug "  No relationships defined (optional)"
    return
  fi

  debug "  Found $count relationship(s)"

  # Collect all entity names
  local entity_names=()
  while IFS= read -r name; do
    entity_names+=("$name")
  done < <(get_entity_type_names "$DEFINITION_FILE")

  # Validate each relationship
  while IFS= read -r rel_name; do
    validate_relationship "$rel_name" "${entity_names[@]}"
  done < <(get_relationship_names "$DEFINITION_FILE")
}

validate_relationship() {
  local rel_name="$1"
  shift
  local entity_names=("$@")

  debug "  Validating relationship: $rel_name"

  local rel
  rel=$(get_relationship "$DEFINITION_FILE" "$rel_name")

  local from_entity to_entity
  from_entity=$(echo "$rel" | jq -r '.from')
  to_entity=$(echo "$rel" | jq -r '.to')

  # Validate from entity exists
  if ! in_array "$from_entity" "${entity_names[@]}"; then
    add_error "Relationship '$rel_name': 'from' entity '$from_entity' not found. Available: ${entity_names[*]}"
  fi

  # Validate to entity exists
  if ! in_array "$to_entity" "${entity_names[@]}"; then
    add_error "Relationship '$rel_name': 'to' entity '$to_entity' not found. Available: ${entity_names[*]}"
  fi
}

#-------------------------------------------------------------------------------
# Validate data sources
#-------------------------------------------------------------------------------
validate_data_sources() {
  debug "Checking dataSources..."

  local has_lakehouse has_eventhouse
  has_lakehouse=$(has_lakehouse "$DEFINITION_FILE" && echo "true" || echo "false")
  has_eventhouse=$(has_eventhouse "$DEFINITION_FILE" && echo "true" || echo "false")

  if [[ "$has_lakehouse" == "false" && "$has_eventhouse" == "false" ]]; then
    add_warning "No data sources defined (dataSources.lakehouse or dataSources.eventhouse)"
  fi

  if [[ "$has_lakehouse" == "true" ]]; then
    validate_lakehouse_config
  fi

  if [[ "$has_eventhouse" == "true" ]]; then
    validate_eventhouse_config
  fi
}

validate_lakehouse_config() {
  debug "  Validating lakehouse configuration..."

  local name
  name=$(get_lakehouse_name "$DEFINITION_FILE")
  debug "    name: $name"

  local tables
  tables=$(get_lakehouse_tables "$DEFINITION_FILE")
  local table_count
  table_count=$(echo "$tables" | jq 'length')

  if [[ "$table_count" -eq 0 ]]; then
    add_error "dataSources.lakehouse: At least one table is required"
  fi

  # Validate each table has name
  echo "$tables" | jq -c '.[]' | while read -r table; do
    local table_name
    table_name=$(echo "$table" | jq -r '.name // ""')
    if [[ -z "$table_name" ]]; then
      add_error "dataSources.lakehouse.tables: Table missing required field 'name'"
    fi
  done
}

validate_eventhouse_config() {
  debug "  Validating eventhouse configuration..."

  local name database
  name=$(get_eventhouse_name "$DEFINITION_FILE")
  database=$(get_eventhouse_database "$DEFINITION_FILE")

  debug "    name: $name"
  debug "    database: $database"

  if [[ -z "$database" || "$database" == "null" ]]; then
    add_error "dataSources.eventhouse: Missing required field 'database'"
  fi

  local tables
  tables=$(get_eventhouse_tables "$DEFINITION_FILE")
  local table_count
  table_count=$(echo "$tables" | jq 'length')

  if [[ "$table_count" -eq 0 ]]; then
    add_error "dataSources.eventhouse: At least one table is required"
  fi

  # Validate each table has name and schema
  echo "$tables" | jq -c '.[]' | while read -r table; do
    local table_name schema_count
    table_name=$(echo "$table" | jq -r '.name // ""')
    schema_count=$(echo "$table" | jq '.schema | length // 0')

    if [[ -z "$table_name" ]]; then
      add_error "dataSources.eventhouse.tables: Table missing required field 'name'"
    elif [[ "$schema_count" -eq 0 ]]; then
      add_error "dataSources.eventhouse.tables[$table_name]: Missing required field 'schema'"
    fi
  done
}

#===============================================================================
# Main
#===============================================================================
main() {
  parse_args "$@"

  log "Validating definition: $DEFINITION_FILE"
  echo

  # Run all validations
  validate_api_version
  validate_metadata
  validate_data_sources
  validate_entity_types
  validate_relationships

  echo

  # Summary
  local error_count=${#ERRORS[@]}
  local warning_count=${#WARNINGS[@]}

  if [[ $error_count -eq 0 ]]; then
    success "Definition is valid"
    if [[ $warning_count -gt 0 ]]; then
      log "$warning_count warning(s)"
    fi
    exit 0
  else
    err "Validation failed with $error_count error(s)"
    if [[ $warning_count -gt 0 ]]; then
      log "$warning_count warning(s)"
    fi
    exit 1
  fi
}

main "$@"
