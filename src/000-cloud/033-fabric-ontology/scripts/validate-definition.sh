#!/usr/bin/env bash
# Validates ontology definition YAML files against the checked-in schema and semantic rules.

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/../definitions/schema.json"

VERBOSE=${VERBOSE:-false}
DEFINITION_FILE=""
DEFINITION_JSON=""
PYTHON_COMMAND=""
ERRORS=()
WARNINGS=()

log() { printf "[ INFO  ]: %s\n" "$1"; }
warn() { printf "[ WARN  ]: %s\n" "$1" >&2; }
err() { printf "[ ERROR ]: %s\n" "$1" >&2; }
debug() {
  if [[ "$VERBOSE" == "true" ]]; then
    printf "[ DEBUG ]: %s\n" "$1"
  fi
}
success() { printf "[ OK    ]: %s\n" "$1"; }

usage() {
  cat <<'EOF'
Ontology Definition Validation Script

USAGE:
  validate-definition.sh --definition <path> [OPTIONS]

ARGUMENTS:
  -d, --definition <path>   Path to ontology definition YAML file (required)

OPTIONS:
  -v, --verbose             Enable verbose output
  -h, --help                Show this help message

EXIT CODES:
  0 - Definition is valid
  1 - Validation failed
  2 - Invalid arguments or missing dependencies
EOF
}

add_error() {
  ERRORS+=("$1")
  err "$1"
}

add_warning() {
  WARNINGS+=("$1")
  warn "$1"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d | --definition)
        if [[ $# -lt 2 ]]; then
          err "Missing value for $1"
          exit 2
        fi
        DEFINITION_FILE="$2"
        shift 2
        ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      -h | --help)
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
    exit 2
  fi
  if [[ ! -f "$DEFINITION_FILE" ]]; then
    err "Definition file not found: $DEFINITION_FILE"
    exit 2
  fi
}

require_dependencies() {
  if ! command -v jq >/dev/null 2>&1; then
    err "Required tool not found: jq"
    exit 2
  fi

  local candidate
  local candidates=("${PYTHON:-}" python3 python /c/Python313/python.exe /mnt/c/Python313/python.exe)
  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" ]] && command -v "$candidate" >/dev/null 2>&1 \
      && "$candidate" -c 'import jsonschema, yaml' >/dev/null 2>&1; then
      PYTHON_COMMAND="$candidate"
      break
    fi
  done
  if [[ -z "$PYTHON_COMMAND" ]]; then
    err "No Python interpreter with jsonschema and PyYAML was found"
    exit 2
  fi
}

cleanup() {
  [[ -n "$DEFINITION_JSON" ]] && rm -f "$DEFINITION_JSON"
}

python_file_path() {
  local path="$1"
  if [[ "$PYTHON_COMMAND" == *.exe ]] && command -v wslpath >/dev/null 2>&1; then
    wslpath -w "$path"
  else
    printf '%s\n' "$path"
  fi
}

convert_definition() {
  local definition_path output_path
  DEFINITION_JSON=$(mktemp)
  trap cleanup EXIT
  definition_path=$(python_file_path "$DEFINITION_FILE")
  output_path=$(python_file_path "$DEFINITION_JSON")

  if ! "$PYTHON_COMMAND" - "$definition_path" "$output_path" <<'PY'; then
import json
import sys

import yaml

with open(sys.argv[1], encoding="utf-8") as definition_file:
    definition = yaml.safe_load(definition_file)
with open(sys.argv[2], "w", encoding="utf-8") as output_file:
    json.dump(definition, output_file)
PY
    add_error "Definition is not valid YAML"
    return 1
  fi
  if ! jq empty "$DEFINITION_JSON"; then
    add_error "Definition could not be converted to valid JSON"
    return 1
  fi
}

validate_schema() {
  debug "Validating Draft 7 JSON Schema"

  local definition_path schema_output schema_path
  schema_path=$(python_file_path "$SCHEMA_FILE")
  definition_path=$(python_file_path "$DEFINITION_JSON")
  if schema_output=$(
    "$PYTHON_COMMAND" - "$schema_path" "$definition_path" <<'PY'
import json
import sys

from jsonschema import Draft7Validator, FormatChecker

with open(sys.argv[1], encoding="utf-8") as schema_file:
    schema = json.load(schema_file)
with open(sys.argv[2], encoding="utf-8") as instance_file:
    instance = json.load(instance_file)

Draft7Validator.check_schema(schema)
validator = Draft7Validator(schema, format_checker=FormatChecker())
errors = sorted(validator.iter_errors(instance), key=lambda error: list(error.absolute_path))
for error in errors:
    path = ".".join(str(part) for part in error.absolute_path) or "<root>"
    print(f"{path}: {error.message}")
sys.exit(1 if errors else 0)
PY
  ); then
    return
  fi

  while IFS= read -r message; do
    [[ -n "$message" ]] && add_error "Schema: $message"
  done <<<"$schema_output"
}

add_duplicate_errors() {
  local collection="$1"
  local label="$2"
  local duplicate

  while IFS= read -r duplicate; do
    [[ -n "$duplicate" ]] && add_error "Duplicate $label name: '$duplicate'"
  done < <(jq -r "$collection | map(.name) | sort | group_by(.)[] | select(length > 1) | .[0]" "$DEFINITION_JSON")
}

table_exists() {
  local source="$1"
  local table="$2"
  jq -e --arg source "$source" --arg table "$table" \
    '.dataSources[$source].tables // [] | any(.name == $table)' "$DEFINITION_JSON" >/dev/null
}

eventhouse_column_exists() {
  local table="$1"
  local column="$2"
  jq -e --arg table "$table" --arg column "$column" \
    '.dataSources.eventhouse.tables // [] | map(select(.name == $table)) | .[0].schema // [] | any(.name == $column)' \
    "$DEFINITION_JSON" >/dev/null
}

validate_binding() {
  local entity_name="$1"
  local binding="$2"
  local path="$3"
  local binding_type source table timestamp_column correlation_column

  binding_type=$(jq -r '.type // ""' <<<"$binding")
  source=$(jq -r '.source // ""' <<<"$binding")
  table=$(jq -r '.table // ""' <<<"$binding")

  if [[ "$binding_type" == "static" && "$source" != "lakehouse" ]]; then
    add_error "Entity '$entity_name', $path: Static bindings must use lakehouse"
  elif [[ "$binding_type" == "timeseries" && "$source" != "eventhouse" ]]; then
    add_error "Entity '$entity_name', $path: Timeseries bindings must use eventhouse"
  fi

  if [[ -n "$source" && -n "$table" ]] && ! table_exists "$source" "$table"; then
    add_error "Entity '$entity_name', $path: Table '$table' is not declared for source '$source'"
  fi

  if [[ "$binding_type" != "timeseries" ]]; then
    return
  fi

  timestamp_column=$(jq -r '.timestampColumn // ""' <<<"$binding")
  correlation_column=$(jq -r '.correlationColumn // ""' <<<"$binding")

  if [[ -z "$timestamp_column" ]]; then
    add_error "Entity '$entity_name', $path: Timeseries binding requires timestampColumn"
  elif ! eventhouse_column_exists "$table" "$timestamp_column"; then
    add_error "Entity '$entity_name', $path: Timestamp column '$timestamp_column' is not declared in '$table'"
  fi

  if [[ -z "$correlation_column" ]]; then
    add_error "Entity '$entity_name', $path: Timeseries binding requires correlationColumn"
  elif ! eventhouse_column_exists "$table" "$correlation_column"; then
    add_error "Entity '$entity_name', $path: Correlation column '$correlation_column' is not declared in '$table'"
  fi
}

validate_entity() {
  local entity="$1"
  local entity_name key display_name property_count property_name
  local binding binding_index binding_type candidate count
  local binding_types=()

  entity_name=$(jq -r '.name // ""' <<<"$entity")
  key=$(jq -r '.key // ""' <<<"$entity")
  display_name=$(jq -r '.displayName // ""' <<<"$entity")
  property_count=$(jq '.properties // [] | length' <<<"$entity")
  [[ "$property_count" -eq 0 ]] && return

  if ! jq -e --arg key "$key" '.properties | any(.name == $key)' <<<"$entity" >/dev/null; then
    add_error "Entity '$entity_name': Key '$key' does not reference a property"
  fi
  if [[ -n "$display_name" ]] && ! jq -e --arg display "$display_name" '.properties | any(.name == $display)' <<<"$entity" >/dev/null; then
    add_error "Entity '$entity_name': Display property '$display_name' does not reference a property"
  fi

  while IFS= read -r property_name; do
    add_error "Entity '$entity_name': Duplicate property name '$property_name'"
  done < <(jq -r '.properties | map(.name) | sort | group_by(.)[] | select(length > 1) | .[0]' <<<"$entity")

  if jq -e 'has("dataBinding") and has("dataBindings")' <<<"$entity" >/dev/null; then
    add_error "Entity '$entity_name': Use either dataBinding or dataBindings, not both"
  fi

  if jq -e 'has("dataBinding")' <<<"$entity" >/dev/null; then
    binding=$(jq -c '.dataBinding' <<<"$entity")
    binding_types+=("$(jq -r '.type // ""' <<<"$binding")")
    validate_binding "$entity_name" "$binding" "dataBinding"
  fi

  binding_index=0
  while IFS= read -r binding; do
    binding_type=$(jq -r '.type // ""' <<<"$binding")
    binding_types+=("$binding_type")
    validate_binding "$entity_name" "$binding" "dataBindings[$binding_index]"
    binding_index=$((binding_index + 1))
  done < <(jq -c '.dataBindings // [] | .[]' <<<"$entity")

  if [[ ${#binding_types[@]} -eq 0 ]]; then
    add_warning "Entity '$entity_name': No data binding is defined"
    return
  fi

  while IFS= read -r binding_type; do
    count=0
    for candidate in "${binding_types[@]}"; do
      [[ "$candidate" == "$binding_type" ]] && count=$((count + 1))
    done
    if [[ "$count" -eq 0 ]]; then
      add_error "Entity '$entity_name': Property binding '$binding_type' has no matching data binding"
    fi
  done < <(jq -r '.properties[] | .binding // empty' <<<"$entity" | sort -u)

  while IFS= read -r binding_type; do
    count=0
    for candidate in "${binding_types[@]}"; do
      [[ "$candidate" == "$binding_type" ]] && count=$((count + 1))
    done
    if [[ "$count" -gt 1 ]]; then
      add_error "Entity '$entity_name': Duplicate '$binding_type' data binding"
    fi
  done < <(printf '%s\n' "${binding_types[@]}" | sort -u)

  return 0
}

validate_relationship() {
  local relationship="$1"
  local relationship_name from_entity to_entity table from_column to_column

  relationship_name=$(jq -r '.name // ""' <<<"$relationship")
  from_entity=$(jq -r '.from // ""' <<<"$relationship")
  to_entity=$(jq -r '.to // ""' <<<"$relationship")

  if ! jq -e --arg name "$from_entity" '.entityTypes | any(.name == $name)' "$DEFINITION_JSON" >/dev/null; then
    add_error "Relationship '$relationship_name': From entity '$from_entity' is not declared"
  fi
  if ! jq -e --arg name "$to_entity" '.entityTypes | any(.name == $name)' "$DEFINITION_JSON" >/dev/null; then
    add_error "Relationship '$relationship_name': To entity '$to_entity' is not declared"
  fi
  if ! jq -e 'has("binding")' <<<"$relationship" >/dev/null; then
    return
  fi

  table=$(jq -r '.binding.table // ""' <<<"$relationship")
  from_column=$(jq -r '.binding.fromColumn // ""' <<<"$relationship")
  to_column=$(jq -r '.binding.toColumn // ""' <<<"$relationship")

  if [[ -n "$table" ]] && ! table_exists "lakehouse" "$table"; then
    add_error "Relationship '$relationship_name': Binding table '$table' is not declared in the lakehouse"
  fi
  [[ -z "$from_column" ]] && add_error "Relationship '$relationship_name': Binding requires fromColumn"
  [[ -z "$to_column" ]] && add_error "Relationship '$relationship_name': Binding requires toColumn"

  return 0
}

validate_semantics() {
  debug "Validating semantic constraints"
  add_duplicate_errors '.dataSources.lakehouse.tables // []' "lakehouse table"
  add_duplicate_errors '.dataSources.eventhouse.tables // []' "eventhouse table"
  add_duplicate_errors '.entityTypes' "entity"
  add_duplicate_errors '.relationships // []' "relationship"

  local entity relationship
  while IFS= read -r entity; do
    validate_entity "$entity"
  done < <(jq -c '.entityTypes[]' "$DEFINITION_JSON")

  while IFS= read -r relationship; do
    validate_relationship "$relationship"
  done < <(jq -c '.relationships // [] | .[]' "$DEFINITION_JSON")

  return 0
}

main() {
  parse_args "$@"
  require_dependencies
  log "Validating definition: $DEFINITION_FILE"

  if convert_definition; then
    validate_schema
    validate_semantics
  fi

  local error_count=${#ERRORS[@]}
  local warning_count=${#WARNINGS[@]}
  if [[ "$error_count" -gt 0 ]]; then
    err "Validation failed with $error_count error(s)"
    [[ "$warning_count" -gt 0 ]] && log "$warning_count warning(s)"
    return 1
  fi

  success "Definition is valid"
  [[ "$warning_count" -gt 0 ]] && log "$warning_count warning(s)"
  return 0
}

main "$@"
