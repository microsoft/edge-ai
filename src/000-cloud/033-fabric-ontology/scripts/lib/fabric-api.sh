#!/usr/bin/env bash
# Fabric API Library - Common functions for Microsoft Fabric REST API operations
#
# Dependencies: curl, jq, az (Azure CLI)
#
# Usage:
#   source ./lib/fabric-api.sh
#   token=$(get_fabric_token)
#   fabric_api_call "GET" "/workspaces" "" "$token"
#
# Environment Variables (optional):
#   FABRIC_API_BASE_URL - Override default API base URL

set -e
set -o pipefail

# API Configuration
readonly FABRIC_API_BASE_URL="${FABRIC_API_BASE_URL:-https://api.fabric.microsoft.com/v1}"
readonly FABRIC_RESOURCE="https://api.fabric.microsoft.com"
readonly STORAGE_RESOURCE="https://storage.azure.com"
readonly ONELAKE_DFS_URL="https://onelake.dfs.fabric.microsoft.com"
readonly KUSTO_RESOURCE="https://kusto.kusto.windows.net"

# Verify required tools
for cmd in curl jq az; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[ ERROR ]: $cmd is required but not installed." >&2
    exit 1
  }
done

# Get Azure AD token for Fabric REST API
get_fabric_token() {
  az account get-access-token \
    --resource "$FABRIC_RESOURCE" \
    --query accessToken \
    --output tsv
}

# Get Azure AD token for OneLake/Storage operations
get_storage_token() {
  az account get-access-token \
    --resource "$STORAGE_RESOURCE" \
    --query accessToken \
    --output tsv
}

# Get Azure AD token for Kusto/KQL operations
get_kusto_token() {
  az account get-access-token \
    --resource "$KUSTO_RESOURCE" \
    --query accessToken \
    --output tsv
}

# Generic Fabric API call with error handling (file-based for large payloads)
# Arguments:
#   $1 - HTTP method (GET, POST, PUT, PATCH, DELETE)
#   $2 - API endpoint (relative to base URL, e.g., "/workspaces")
#   $3 - Path to file containing request body JSON, or empty
#   $4 - Bearer token (optional, will fetch if not provided)
# Returns: Response body on success, exits on error
fabric_api_call_file() {
  local method="$1"
  local endpoint="$2"
  local body_file="${3:-}"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  local url="${FABRIC_API_BASE_URL}${endpoint}"
  local headers_file response http_code response_body

  headers_file=$(mktemp)

  if [[ -n "$body_file" && -f "$body_file" ]]; then
    response=$(curl -s -w "\n%{http_code}" -D "$headers_file" -X "$method" "$url" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d @"$body_file")
  else
    response=$(curl -s -w "\n%{http_code}" -D "$headers_file" -X "$method" "$url" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json")
  fi

  http_code=$(echo "$response" | tail -c 4)
  response_body=$(echo "$response" | sed '$d')

  # Handle different response codes
  case "$http_code" in
    200 | 201)
      rm -f "$headers_file"
      echo "$response_body"
      return 0
      ;;
    204)
      rm -f "$headers_file"
      echo "{}"
      return 0
      ;;
    202)
      # Long-running operation - check for Location header and poll
      local location operation_id
      location=$(grep -i "^Location:" "$headers_file" | sed 's/^[Ll]ocation: *//' | tr -d '\r')
      operation_id=$(grep -i "^x-ms-operation-id:" "$headers_file" | sed 's/^x-ms-operation-id: *//' | tr -d '\r')
      rm -f "$headers_file"

      if [[ -n "$location" ]]; then
        echo "[ INFO ]: Long-running operation, polling for completion..." >&2
        poll_operation "$location" "$token" 300
        return $?
      elif [[ -n "$operation_id" ]]; then
        echo "[ INFO ]: Long-running operation ID: $operation_id, polling..." >&2
        poll_operation "${FABRIC_API_BASE_URL}/operations/${operation_id}" "$token" 300
        return $?
      else
        # No location header, return body if any
        echo "$response_body"
        return 0
      fi
      ;;
    *)
      rm -f "$headers_file"
      echo "[ ERROR ]: API call failed with HTTP $http_code" >&2
      echo "[ ERROR ]: Endpoint: $method $url" >&2
      echo "[ ERROR ]: Response: $response_body" >&2
      return 1
      ;;
  esac
}

# Generic Fabric API call with error handling
# Arguments:
#   $1 - HTTP method (GET, POST, PUT, PATCH, DELETE)
#   $2 - API endpoint (relative to base URL, e.g., "/workspaces")
#   $3 - Request body (JSON string or empty)
#   $4 - Bearer token (optional, will fetch if not provided)
# Returns: Response body on success, exits on error
fabric_api_call() {
  local method="$1"
  local endpoint="$2"
  local body="${3:-}"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  local url="${FABRIC_API_BASE_URL}${endpoint}"
  local headers_file response http_code response_body

  headers_file=$(mktemp)

  if [[ -n "$body" ]]; then
    # Use file-based approach to avoid shell argument length limits
    local body_file
    body_file=$(mktemp)
    echo "$body" >"$body_file"
    response=$(curl -s -w "\n%{http_code}" -D "$headers_file" -X "$method" "$url" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d @"$body_file")
    rm -f "$body_file"
  else
    response=$(curl -s -w "\n%{http_code}" -D "$headers_file" -X "$method" "$url" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json")
  fi

  http_code=$(echo "$response" | tail -c 4)
  response_body=$(echo "$response" | sed '$d')

  # Handle different response codes
  case "$http_code" in
    200 | 201)
      rm -f "$headers_file"
      echo "$response_body"
      return 0
      ;;
    204)
      rm -f "$headers_file"
      echo "{}"
      return 0
      ;;
    202)
      # Long-running operation - check for Location header and poll
      local location operation_id
      location=$(grep -i "^Location:" "$headers_file" | sed 's/^[Ll]ocation: *//' | tr -d '\r')
      operation_id=$(grep -i "^x-ms-operation-id:" "$headers_file" | sed 's/^x-ms-operation-id: *//' | tr -d '\r')
      rm -f "$headers_file"

      if [[ -n "$location" ]]; then
        echo "[ INFO ]: Long-running operation, polling for completion..." >&2
        poll_operation "$location" "$token" 300
        return $?
      elif [[ -n "$operation_id" ]]; then
        echo "[ INFO ]: Long-running operation ID: $operation_id, polling..." >&2
        poll_operation "${FABRIC_API_BASE_URL}/operations/${operation_id}" "$token" 300
        return $?
      else
        # No location header, return body if any
        echo "$response_body"
        return 0
      fi
      ;;
    *)
      rm -f "$headers_file"
      echo "[ ERROR ]: API call failed with HTTP $http_code" >&2
      echo "[ ERROR ]: Endpoint: $method $url" >&2
      echo "[ ERROR ]: Response: $response_body" >&2
      return 1
      ;;
  esac
}

# Poll long-running operation until completion
# Arguments:
#   $1 - Operation URL (from Location header or x-ms-operation-id)
#   $2 - Bearer token (optional)
#   $3 - Max wait time in seconds (default: 300)
# Returns: Final operation result JSON (includes createdItem for create operations)
poll_operation() {
  local operation_url="$1"
  local token="${2:-}"
  local max_wait="${3:-300}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  local elapsed=0
  local sleep_interval=5

  while [[ $elapsed -lt $max_wait ]]; do
    local response
    response=$(curl -s -X GET "$operation_url" \
      -H "Authorization: Bearer $token")

    local status
    status=$(echo "$response" | jq -r '.status // .Status // "Unknown"')

    case "$status" in
      "Succeeded" | "succeeded")
        # Fetch the result endpoint to get the created item
        local result_url="${operation_url}/result"
        local result_response
        result_response=$(curl -s -X GET "$result_url" \
          -H "Authorization: Bearer $token")

        # Return result if valid, otherwise check for createdItem in status response
        if [[ -n "$result_response" && "$result_response" != "null" ]]; then
          local result_id
          result_id=$(echo "$result_response" | jq -r '.id // empty')
          if [[ -n "$result_id" ]]; then
            echo "$result_response"
            return 0
          fi
        fi

        # Fallback: check createdItem in status response
        local created_item
        created_item=$(echo "$response" | jq -r '.createdItem // empty')
        if [[ -n "$created_item" && "$created_item" != "null" ]]; then
          echo "$created_item"
        else
          echo "$response"
        fi
        return 0
        ;;
      "Failed" | "failed")
        echo "[ ERROR ]: Operation failed" >&2
        echo "$response" >&2
        return 1
        ;;
      "Running" | "running" | "InProgress" | "inProgress" | "NotStarted" | "notStarted")
        echo "[ INFO ]: Operation status: $status (${elapsed}s/${max_wait}s)" >&2
        sleep "$sleep_interval"
        ((elapsed += sleep_interval))
        ;;
      *)
        echo "[ WARN ]: Unknown operation status: $status" >&2
        sleep "$sleep_interval"
        ((elapsed += sleep_interval))
        ;;
    esac
  done

  echo "[ ERROR ]: Operation timed out after ${max_wait}s" >&2
  return 1
}

# Get workspace by ID
get_workspace() {
  local workspace_id="$1"
  local token="${2:-}"
  fabric_api_call "GET" "/workspaces/$workspace_id" "" "$token"
}

# List items in workspace by type
list_workspace_items() {
  local workspace_id="$1"
  local item_type="$2"
  local token="${3:-}"
  fabric_api_call "GET" "/workspaces/$workspace_id/${item_type}s" "" "$token"
}

# Get or create Lakehouse (idempotent)
# Arguments:
#   $1 - Workspace ID
#   $2 - Lakehouse display name
#   $3 - Bearer token (optional)
# Returns: Lakehouse JSON (id, displayName)
get_or_create_lakehouse() {
  local workspace_id="$1"
  local lakehouse_name="$2"
  local token="${3:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  # Check if lakehouse exists
  local existing
  existing=$(fabric_api_call "GET" "/workspaces/$workspace_id/lakehouses" "" "$token")

  local lakehouse_id
  lakehouse_id=$(echo "$existing" | jq -r ".value[] | select(.displayName == \"$lakehouse_name\") | .id")

  if [[ -n "$lakehouse_id" ]]; then
    echo "[ INFO ]: Lakehouse '$lakehouse_name' already exists: $lakehouse_id" >&2
    echo "$existing" | jq ".value[] | select(.id == \"$lakehouse_id\")"
    return 0
  fi

  # Create new lakehouse
  echo "[ INFO ]: Creating Lakehouse '$lakehouse_name'..." >&2
  local body
  body=$(jq -n --arg name "$lakehouse_name" '{"displayName": $name}')

  local response
  response=$(fabric_api_call "POST" "/workspaces/$workspace_id/lakehouses" "$body" "$token")
  echo "$response"
}

# Get or create Eventhouse (idempotent)
get_or_create_eventhouse() {
  local workspace_id="$1"
  local eventhouse_name="$2"
  local token="${3:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  # Check if eventhouse exists
  local existing
  existing=$(fabric_api_call "GET" "/workspaces/$workspace_id/eventhouses" "" "$token")

  local eventhouse_id
  eventhouse_id=$(echo "$existing" | jq -r ".value[] | select(.displayName == \"$eventhouse_name\") | .id")

  if [[ -n "$eventhouse_id" ]]; then
    echo "[ INFO ]: Eventhouse '$eventhouse_name' already exists: $eventhouse_id" >&2
    echo "$existing" | jq ".value[] | select(.id == \"$eventhouse_id\")"
    return 0
  fi

  # Create new eventhouse
  echo "[ INFO ]: Creating Eventhouse '$eventhouse_name'..." >&2
  local body
  body=$(jq -n --arg name "$eventhouse_name" '{"displayName": $name}')

  local response
  response=$(fabric_api_call "POST" "/workspaces/$workspace_id/eventhouses" "$body" "$token")
  echo "$response"
}

# Get or create KQL database (idempotent)
get_or_create_kql_database() {
  local workspace_id="$1"
  local database_name="$2"
  local eventhouse_id="$3"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  # Check if database exists
  local existing
  existing=$(fabric_api_call "GET" "/workspaces/$workspace_id/kqlDatabases" "" "$token")

  local database_id
  database_id=$(echo "$existing" | jq -r ".value[] | select(.displayName == \"$database_name\") | .id")

  if [[ -n "$database_id" ]]; then
    echo "[ INFO ]: KQL Database '$database_name' already exists: $database_id" >&2
    echo "$existing" | jq ".value[] | select(.id == \"$database_id\")"
    return 0
  fi

  # Create new KQL database
  echo "[ INFO ]: Creating KQL Database '$database_name'..." >&2
  local body
  body=$(jq -n \
    --arg name "$database_name" \
    --arg ehId "$eventhouse_id" \
    '{"displayName": $name, "creationPayload": {"databaseType": "ReadWrite", "parentEventhouseItemId": $ehId}}')

  local response
  response=$(fabric_api_call "POST" "/workspaces/$workspace_id/kqlDatabases" "$body" "$token")

  # KQL database creation is a long-running operation - wait for it
  echo "[ INFO ]: Waiting for KQL Database creation..." >&2
  sleep 10

  # Re-fetch the database list to get the ID
  existing=$(fabric_api_call "GET" "/workspaces/$workspace_id/kqlDatabases" "" "$token")
  database_id=$(echo "$existing" | jq -r ".value[] | select(.displayName == \"$database_name\") | .id")

  if [[ -n "$database_id" ]]; then
    echo "$existing" | jq ".value[] | select(.id == \"$database_id\")"
    return 0
  fi

  echo "$response"
}

# Get or create Semantic Model (idempotent)
get_or_create_semantic_model() {
  local workspace_id="$1"
  local model_name="$2"
  local definition_parts="$3"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  # Check if semantic model exists
  local existing
  existing=$(fabric_api_call "GET" "/workspaces/$workspace_id/semanticModels" "" "$token")

  local model_id
  model_id=$(echo "$existing" | jq -r ".value[] | select(.displayName == \"$model_name\") | .id")

  if [[ -n "$model_id" ]]; then
    echo "[ INFO ]: Semantic Model '$model_name' already exists: $model_id" >&2
    echo "$existing" | jq ".value[] | select(.id == \"$model_id\")"
    return 0
  fi

  # Create new semantic model with definition
  echo "[ INFO ]: Creating Semantic Model '$model_name'..." >&2
  local body
  body=$(jq -n \
    --arg name "$model_name" \
    --argjson parts "$definition_parts" \
    '{"displayName": $name, "definition": {"parts": $parts}}')

  local response
  response=$(fabric_api_call "POST" "/workspaces/$workspace_id/semanticModels" "$body" "$token")
  echo "$response"
}

# Get or create generic Fabric item (idempotent)
get_or_create_item() {
  local workspace_id="$1"
  local item_type="$2"
  local item_name="$3"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  # Check if item exists
  local existing
  existing=$(fabric_api_call "GET" "/workspaces/$workspace_id/items?type=$item_type" "" "$token")

  local item_id
  item_id=$(echo "$existing" | jq -r ".value[] | select(.displayName == \"$item_name\") | .id")

  if [[ -n "$item_id" ]]; then
    echo "[ INFO ]: $item_type '$item_name' already exists: $item_id" >&2
    echo "$existing" | jq ".value[] | select(.id == \"$item_id\")"
    return 0
  fi

  # Create new item
  echo "[ INFO ]: Creating $item_type '$item_name'..." >&2
  local body
  body=$(jq -n \
    --arg name "$item_name" \
    --arg type "$item_type" \
    '{"displayName": $name, "type": $type}')

  local response
  response=$(fabric_api_call "POST" "/workspaces/$workspace_id/items" "$body" "$token")
  echo "$response"
}

# Get or create Ontology item (idempotent)
get_or_create_ontology() {
  local workspace_id="$1"
  local ontology_name="$2"
  local token="${3:-}"
  get_or_create_item "$workspace_id" "Ontology" "$ontology_name" "$token"
}

# Update item definition
update_item_definition() {
  local workspace_id="$1"
  local item_id="$2"
  local definition_parts="$3"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  local body
  body=$(jq -n --argjson parts "$definition_parts" '{"definition": {"parts": $parts}}')

  fabric_api_call "POST" "/workspaces/$workspace_id/items/$item_id/updateDefinition" "$body" "$token"
}

# Upload file to OneLake via DFS API
# Arguments:
#   $1 - Workspace ID
#   $2 - Lakehouse ID
#   $3 - Remote file path (relative to Files/)
#   $4 - Local file path
#   $5 - Bearer token (optional)
upload_to_onelake() {
  local workspace_id="$1"
  local lakehouse_id="$2"
  local remote_path="$3"
  local local_file="$4"
  local token="${5:-}"

  if [[ -z "$token" ]]; then
    token=$(get_storage_token)
  fi

  # When using GUIDs, no .lakehouse suffix needed
  local base_url="${ONELAKE_DFS_URL}/${workspace_id}/${lakehouse_id}/Files"

  echo "[ INFO ]: Uploading to OneLake: $remote_path" >&2

  # Create parent directory if path contains subdirectories
  local dir_path
  dir_path=$(dirname "$remote_path")
  if [[ "$dir_path" != "." ]]; then
    local dir_url="${base_url}/${dir_path}?resource=directory"
    curl -s -X PUT "$dir_url" \
      -H "Authorization: Bearer $token" \
      -H "Content-Length: 0" >/dev/null 2>&1 || true
  fi

  # Create file (requires Content-Length: 0)
  local url="${base_url}/${remote_path}?resource=file"
  local response http_code
  response=$(curl -s -w "\n%{http_code}" -X PUT "$url" \
    -H "Authorization: Bearer $token" \
    -H "Content-Length: 0")
  http_code=$(echo "$response" | tail -c 4)

  if [[ "$http_code" != "201" && "$http_code" != "200" ]]; then
    echo "[ ERROR ]: Failed to create file: HTTP $http_code" >&2
    echo "[ ERROR ]: Response: $(echo "$response" | sed '$d')" >&2
    return 1
  fi

  # Upload content
  local file_size
  file_size=$(wc -c <"$local_file")
  local append_url="${base_url}/${remote_path}?action=append&position=0"

  response=$(curl -s -w "\n%{http_code}" -X PATCH "$append_url" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$local_file")
  http_code=$(echo "$response" | tail -c 4)

  if [[ "$http_code" != "202" && "$http_code" != "200" ]]; then
    echo "[ ERROR ]: Failed to upload content: HTTP $http_code" >&2
    return 1
  fi

  # Flush file
  local flush_url="${base_url}/${remote_path}?action=flush&position=$file_size"

  response=$(curl -s -w "\n%{http_code}" -X PATCH "$flush_url" \
    -H "Authorization: Bearer $token" \
    -H "Content-Length: 0")
  http_code=$(echo "$response" | tail -c 4)

  if [[ "$http_code" != "200" ]]; then
    echo "[ ERROR ]: Failed to flush file: HTTP $http_code" >&2
    return 1
  fi

  echo "[ INFO ]: Upload complete: $remote_path ($file_size bytes)" >&2
  return 0
}

# Load table from file in Lakehouse (CSV → Delta conversion)
load_lakehouse_table() {
  local workspace_id="$1"
  local lakehouse_id="$2"
  local table_name="$3"
  local file_path="$4"
  local file_format="${5:-Csv}"
  local token="${6:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  echo "[ INFO ]: Loading table '$table_name' from $file_path..." >&2

  # Capitalize format for API (Csv, Parquet)
  local api_format
  api_format=$(echo "$file_format" | sed 's/csv/Csv/i; s/parquet/Parquet/i')

  local body
  body=$(jq -n \
    --arg path "Files/$file_path" \
    --arg format "$api_format" \
    '{
      "relativePath": $path,
      "pathType": "File",
      "mode": "Overwrite",
      "formatOptions": {
        "format": $format,
        "header": true,
        "delimiter": ","
      }
    }')

  local response
  response=$(fabric_api_call "POST" "/workspaces/$workspace_id/lakehouses/$lakehouse_id/tables/$table_name/load" "$body" "$token")

  # Check if long-running operation
  local operation_id
  operation_id=$(echo "$response" | jq -r '.operationId // empty')

  if [[ -n "$operation_id" ]]; then
    echo "[ INFO ]: Waiting for table load operation..." >&2
    local operation_url="${FABRIC_API_BASE_URL}/operations/$operation_id"
    poll_operation "$operation_url" "$token" 300
  else
    echo "$response"
  fi
}

# Execute KQL management command against database
# Arguments:
#   $1 - Eventhouse query URI (e.g., https://<eh-id>.kusto.fabric.microsoft.com)
#   $2 - Database name
#   $3 - KQL command
#   $4 - Bearer token (optional, will use Kusto token if not provided)
execute_kql() {
  local query_uri="$1"
  local database_name="$2"
  local kql_command="$3"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_kusto_token)
  fi

  local mgmt_url="${query_uri}/v1/rest/mgmt"

  local body
  body=$(jq -n \
    --arg db "$database_name" \
    --arg csl "$kql_command" \
    '{"db": $db, "csl": $csl}')

  local response http_code
  response=$(curl -s -w "\n%{http_code}" -X POST "$mgmt_url" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$body")

  http_code=$(echo "$response" | tail -c 4)
  local response_body
  response_body=$(echo "$response" | sed '$d')

  if [[ "$http_code" != "200" ]]; then
    echo "[ ERROR ]: KQL command failed with HTTP $http_code" >&2
    echo "[ ERROR ]: Command: $kql_command" >&2
    echo "[ ERROR ]: Response: $response_body" >&2
    return 1
  fi

  echo "$response_body"
}

# Get Eventhouse query URI
get_eventhouse_query_uri() {
  local workspace_id="$1"
  local eventhouse_id="$2"
  local token="${3:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  local response
  response=$(fabric_api_call "GET" "/workspaces/$workspace_id/eventhouses/$eventhouse_id" "" "$token")
  echo "$response" | jq -r '.properties.queryServiceUri // empty'
}

# Generate a unique 64-bit ID (using timestamp and random)
generate_unique_id() {
  local timestamp random_part
  timestamp=$(date +%s%N | cut -c1-13)
  random_part=$((RANDOM % 10000))
  echo "${timestamp}${random_part}"
}

# Encode string to Base64
encode_base64() {
  local input="$1"
  echo -n "$input" | base64 -w 0
}

# Build definition part JSON for API
# Arguments:
#   $1 - Path (e.g., "definition.json", "EntityTypes/123/definition.json")
#   $2 - Content (JSON string)
build_definition_part() {
  local path="$1"
  local content="$2"
  local payload
  payload=$(encode_base64 "$content")
  jq -n --arg path "$path" --arg payload "$payload" '{"path": $path, "payload": $payload, "payloadType": "InlineBase64"}'
}
