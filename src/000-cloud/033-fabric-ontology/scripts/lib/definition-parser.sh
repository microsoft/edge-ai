#!/usr/bin/env bash
# Definition Parser Library - Utilities for parsing ontology definition YAML
#
# Dependencies: yq (https://github.com/mikefarah/yq)
#
# Usage:
#   source ./lib/definition-parser.sh
#   name=$(get_metadata_name "ontology.yaml")
#
# shellcheck disable=SC2034

set -e
set -o pipefail

# Verify yq is available
command -v yq >/dev/null 2>&1 || {
  echo "[ ERROR ]: yq is required but not installed. Install from https://github.com/mikefarah/yq" >&2
  exit 1
}

# Get metadata.name from definition
get_metadata_name() {
  local definition_file="$1"
  yq -r '.metadata.name' "$definition_file"
}

# Get metadata.description from definition
get_metadata_description() {
  local definition_file="$1"
  yq -r '.metadata.description // ""' "$definition_file"
}

# Get metadata.version from definition
get_metadata_version() {
  local definition_file="$1"
  yq -r '.metadata.version // "1.0.0"' "$definition_file"
}

# Get entityTypes as JSON array
get_entity_types() {
  local definition_file="$1"
  yq -o=json '.entityTypes // []' "$definition_file"
}

# Get list of entity type names (one per line)
get_entity_type_names() {
  local definition_file="$1"
  yq -r '.entityTypes[].name' "$definition_file"
}

# Get entity type count
get_entity_type_count() {
  local definition_file="$1"
  yq '.entityTypes | length' "$definition_file"
}

# Get specific entity type by name as JSON
get_entity_type() {
  local definition_file="$1"
  local entity_name="$2"
  yq -o=json ".entityTypes[] | select(.name == \"$entity_name\")" "$definition_file"
}

# Get entity type key property name
get_entity_key() {
  local definition_file="$1"
  local entity_name="$2"
  yq -r ".entityTypes[] | select(.name == \"$entity_name\") | .key" "$definition_file"
}

# Get entity type display name property
get_entity_display_name() {
  local definition_file="$1"
  local entity_name="$2"
  local display_name
  display_name=$(yq -r ".entityTypes[] | select(.name == \"$entity_name\") | .displayName // \"\"" "$definition_file")
  if [[ -z "$display_name" ]]; then
    get_entity_key "$definition_file" "$entity_name"
  else
    echo "$display_name"
  fi
}

# Get properties for specific entity as JSON array
get_entity_properties() {
  local definition_file="$1"
  local entity_name="$2"
  yq -o=json ".entityTypes[] | select(.name == \"$entity_name\") | .properties // []" "$definition_file"
}

# Get entity property names (one per line)
get_entity_property_names() {
  local definition_file="$1"
  local entity_name="$2"
  yq -r ".entityTypes[] | select(.name == \"$entity_name\") | .properties[].name" "$definition_file"
}

# Get static properties for an entity (binding == "static" or binding is null)
get_entity_static_properties() {
  local definition_file="$1"
  local entity_name="$2"
  yq -o=json ".entityTypes[] | select(.name == \"$entity_name\") | .properties | map(select(.binding == \"static\" or .binding == null))" "$definition_file"
}

# Get timeseries properties for an entity
get_entity_timeseries_properties() {
  local definition_file="$1"
  local entity_name="$2"
  yq -o=json ".entityTypes[] | select(.name == \"$entity_name\") | .properties | map(select(.binding == \"timeseries\"))" "$definition_file"
}

# Get entity data binding (single binding)
get_entity_data_binding() {
  local definition_file="$1"
  local entity_name="$2"
  yq -o=json ".entityTypes[] | select(.name == \"$entity_name\") | .dataBinding // null" "$definition_file"
}

# Get entity data bindings (multiple bindings)
get_entity_data_bindings() {
  local definition_file="$1"
  local entity_name="$2"
  yq -o=json ".entityTypes[] | select(.name == \"$entity_name\") | .dataBindings // []" "$definition_file"
}

# Get static data binding for entity (searches both dataBinding and dataBindings)
get_entity_static_binding() {
  local definition_file="$1"
  local entity_name="$2"
  local binding

  binding=$(yq -o=json ".entityTypes[] | select(.name == \"$entity_name\") | .dataBinding | select(.type == \"static\")" "$definition_file" 2>/dev/null)
  if [[ -n "$binding" && "$binding" != "null" ]]; then
    echo "$binding"
    return
  fi

  yq -o=json ".entityTypes[] | select(.name == \"$entity_name\") | .dataBindings[] | select(.type == \"static\")" "$definition_file" 2>/dev/null || echo "null"
}

# Get timeseries data binding for entity
get_entity_timeseries_binding() {
  local definition_file="$1"
  local entity_name="$2"
  yq -o=json ".entityTypes[] | select(.name == \"$entity_name\") | .dataBindings[] | select(.type == \"timeseries\")" "$definition_file" 2>/dev/null || echo "null"
}

# Get lakehouse data source configuration
get_lakehouse_config() {
  local definition_file="$1"
  yq -o=json '.dataSources.lakehouse // null' "$definition_file"
}

# Get lakehouse name
get_lakehouse_name() {
  local definition_file="$1"
  yq -r '.dataSources.lakehouse.name // ""' "$definition_file"
}

# Get lakehouse tables as JSON array
get_lakehouse_tables() {
  local definition_file="$1"
  yq -o=json '.dataSources.lakehouse.tables // []' "$definition_file"
}

# Get lakehouse table names (one per line)
get_lakehouse_table_names() {
  local definition_file="$1"
  yq -r '.dataSources.lakehouse.tables[].name // empty' "$definition_file"
}

# Get specific lakehouse table by name
get_lakehouse_table() {
  local definition_file="$1"
  local table_name="$2"
  yq -o=json ".dataSources.lakehouse.tables[] | select(.name == \"$table_name\")" "$definition_file"
}

# Get eventhouse data source configuration
get_eventhouse_config() {
  local definition_file="$1"
  yq -o=json '.dataSources.eventhouse // null' "$definition_file"
}

# Get eventhouse name
get_eventhouse_name() {
  local definition_file="$1"
  yq -r '.dataSources.eventhouse.name // ""' "$definition_file"
}

# Get eventhouse database name
get_eventhouse_database() {
  local definition_file="$1"
  yq -r '.dataSources.eventhouse.database // ""' "$definition_file"
}

# Get eventhouse tables as JSON array
get_eventhouse_tables() {
  local definition_file="$1"
  yq -o=json '.dataSources.eventhouse.tables // []' "$definition_file"
}

# Get eventhouse table names (one per line)
get_eventhouse_table_names() {
  local definition_file="$1"
  yq -r '.dataSources.eventhouse.tables[].name // empty' "$definition_file"
}

# Get specific eventhouse table by name
get_eventhouse_table() {
  local definition_file="$1"
  local table_name="$2"
  yq -o=json ".dataSources.eventhouse.tables[] | select(.name == \"$table_name\")" "$definition_file"
}

# Get relationships as JSON array
get_relationships() {
  local definition_file="$1"
  yq -o=json '.relationships // []' "$definition_file"
}

# Get relationship names (one per line)
get_relationship_names() {
  local definition_file="$1"
  yq -r '.relationships[].name // empty' "$definition_file"
}

# Get relationship count
get_relationship_count() {
  local definition_file="$1"
  yq '.relationships | length // 0' "$definition_file"
}

# Get specific relationship by name
get_relationship() {
  local definition_file="$1"
  local rel_name="$2"
  yq -o=json ".relationships[] | select(.name == \"$rel_name\")" "$definition_file"
}

# Get semantic model configuration
get_semantic_model_config() {
  local definition_file="$1"
  yq -o=json '.semanticModel // null' "$definition_file"
}

# Get semantic model name
get_semantic_model_name() {
  local definition_file="$1"
  yq -r '.semanticModel.name // ""' "$definition_file"
}

# Get semantic model mode (directLake or import)
get_semantic_model_mode() {
  local definition_file="$1"
  yq -r '.semanticModel.mode // "directLake"' "$definition_file"
}

# Map definition property type to Fabric ontology type
map_property_type() {
  local def_type="$1"
  case "$def_type" in
    "string") echo "String" ;;
    "int") echo "BigInt" ;;
    "double") echo "Double" ;;
    "datetime") echo "DateTime" ;;
    "boolean") echo "Boolean" ;;
    "object") echo "Object" ;;
    *) echo "String" ;;
  esac
}

# Map definition property type to KQL type
map_kql_type() {
  local def_type="$1"
  case "$def_type" in
    "string") echo "string" ;;
    "int") echo "int" ;;
    "double") echo "real" ;;
    "datetime") echo "datetime" ;;
    "boolean") echo "bool" ;;
    "object") echo "dynamic" ;;
    *) echo "string" ;;
  esac
}

# Map definition property type to TMDL type
map_tmdl_type() {
  local def_type="$1"
  case "$def_type" in
    "string") echo "string" ;;
    "int") echo "int64" ;;
    "double") echo "double" ;;
    "datetime") echo "dateTime" ;;
    "boolean") echo "boolean" ;;
    "object") echo "string" ;;
    *) echo "string" ;;
  esac
}

# Check if definition has lakehouse data source
has_lakehouse() {
  local definition_file="$1"
  local name
  name=$(get_lakehouse_name "$definition_file")
  [[ -n "$name" ]]
}

# Check if definition has eventhouse data source
has_eventhouse() {
  local definition_file="$1"
  local name
  name=$(get_eventhouse_name "$definition_file")
  [[ -n "$name" ]]
}

# Check if definition has semantic model configuration
has_semantic_model() {
  local definition_file="$1"
  local name
  name=$(get_semantic_model_name "$definition_file")
  [[ -n "$name" ]]
}

# Check if entity has timeseries binding
entity_has_timeseries() {
  local definition_file="$1"
  local entity_name="$2"
  local binding
  binding=$(get_entity_timeseries_binding "$definition_file" "$entity_name")
  [[ -n "$binding" && "$binding" != "null" ]]
}
