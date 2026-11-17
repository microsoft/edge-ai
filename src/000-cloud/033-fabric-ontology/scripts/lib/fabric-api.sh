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
#   FABRIC_API_MAX_ATTEMPTS - Total transport attempts (default: 4, maximum: 10)
#   FABRIC_API_RETRY_BASE_DELAY - Initial retry delay in seconds (default: 1, maximum: 60)
#   FABRIC_API_RETRY_MAX_DELAY - Maximum retry delay in seconds (default: 30, maximum: 120)
#   FABRIC_API_CONNECT_TIMEOUT - Connection timeout in seconds (default: 10, maximum: 60)
#   FABRIC_API_REQUEST_TIMEOUT - Total request timeout in seconds (default: 60, maximum: 600)
#   FABRIC_API_MAX_PAGES - Maximum item-list pages (default: 100, maximum: 1000)
#   FABRIC_API_POLL_TIMEOUT - Long-running operation timeout in seconds (default: 300, maximum: 3600)
#   FABRIC_API_POLL_INTERVAL - Long-running operation poll interval in seconds (default: 5, maximum: 60)

set -e
set -o pipefail

fabric_bounded_config() {
  local name="$1"
  local value="$2"
  local minimum="$3"
  local maximum="$4"

  if [[ ! "$value" =~ ^[0-9]+$ ]] || ((value < minimum)); then
    echo "[ ERROR ]: $name must be an integer greater than or equal to $minimum" >&2
    return 1
  fi
  if ((value > maximum)); then
    echo "[ WARN ]: $name capped at $maximum" >&2
    value="$maximum"
  fi
  printf '%s\n' "$value"
}

# API Configuration
readonly FABRIC_API_BASE_URL="${FABRIC_API_BASE_URL:-https://api.fabric.microsoft.com/v1}"
FABRIC_API_MAX_ATTEMPTS=$(fabric_bounded_config FABRIC_API_MAX_ATTEMPTS "${FABRIC_API_MAX_ATTEMPTS:-4}" 1 10) || exit 1
FABRIC_API_RETRY_BASE_DELAY=$(fabric_bounded_config FABRIC_API_RETRY_BASE_DELAY "${FABRIC_API_RETRY_BASE_DELAY:-1}" 0 60) || exit 1
FABRIC_API_RETRY_MAX_DELAY=$(fabric_bounded_config FABRIC_API_RETRY_MAX_DELAY "${FABRIC_API_RETRY_MAX_DELAY:-30}" 0 120) || exit 1
FABRIC_API_CONNECT_TIMEOUT=$(fabric_bounded_config FABRIC_API_CONNECT_TIMEOUT "${FABRIC_API_CONNECT_TIMEOUT:-10}" 1 60) || exit 1
FABRIC_API_REQUEST_TIMEOUT=$(fabric_bounded_config FABRIC_API_REQUEST_TIMEOUT "${FABRIC_API_REQUEST_TIMEOUT:-60}" 1 600) || exit 1
FABRIC_API_MAX_PAGES=$(fabric_bounded_config FABRIC_API_MAX_PAGES "${FABRIC_API_MAX_PAGES:-100}" 1 1000) || exit 1
FABRIC_API_POLL_TIMEOUT=$(fabric_bounded_config FABRIC_API_POLL_TIMEOUT "${FABRIC_API_POLL_TIMEOUT:-300}" 1 3600) || exit 1
FABRIC_API_POLL_INTERVAL=$(fabric_bounded_config FABRIC_API_POLL_INTERVAL "${FABRIC_API_POLL_INTERVAL:-5}" 1 60) || exit 1
readonly FABRIC_API_MAX_ATTEMPTS FABRIC_API_RETRY_BASE_DELAY FABRIC_API_RETRY_MAX_DELAY
readonly FABRIC_API_CONNECT_TIMEOUT FABRIC_API_REQUEST_TIMEOUT FABRIC_API_MAX_PAGES
readonly FABRIC_API_POLL_TIMEOUT FABRIC_API_POLL_INTERVAL
readonly FABRIC_RESOURCE="https://api.fabric.microsoft.com"
readonly STORAGE_RESOURCE="https://storage.azure.com"
readonly ONELAKE_DFS_URL="https://onelake.dfs.fabric.microsoft.com"
readonly KUSTO_RESOURCE="https://kusto.kusto.windows.net"

if ((FABRIC_API_RETRY_BASE_DELAY > FABRIC_API_RETRY_MAX_DELAY)); then
  echo "[ ERROR ]: FABRIC_API_RETRY_BASE_DELAY cannot exceed FABRIC_API_RETRY_MAX_DELAY" >&2
  exit 1
fi

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

fabric_sleep() {
  sleep "$1"
}

fabric_retry_jitter() {
  local ceiling="$1"
  if ((ceiling == 0)); then
    printf '0\n'
  else
    printf '%s\n' "$((RANDOM % (ceiling + 1)))"
  fi
}

fabric_retry_wait() {
  local attempt="$1"
  local retry_after="${2:-}"
  local delay="$FABRIC_API_RETRY_BASE_DELAY"

  if [[ "$retry_after" =~ ^[0-9]+$ ]]; then
    delay="$retry_after"
    ((delay > FABRIC_API_RETRY_MAX_DELAY)) && delay="$FABRIC_API_RETRY_MAX_DELAY"
  else
    local exponent=$((attempt - 1))
    while ((exponent > 0 && delay < FABRIC_API_RETRY_MAX_DELAY)); do
      delay=$((delay * 2))
      ((delay > FABRIC_API_RETRY_MAX_DELAY)) && delay="$FABRIC_API_RETRY_MAX_DELAY"
      ((exponent--))
    done
    delay=$(fabric_retry_jitter "$delay")
  fi

  fabric_sleep "$delay"
}

fabric_api_url() {
  local endpoint="$1"
  local base_origin

  if [[ ! "$FABRIC_API_BASE_URL" =~ ^(https://[^/]+)(/.*)?$ ]]; then
    echo "[ ERROR ]: FABRIC_API_BASE_URL must be an absolute HTTPS URL" >&2
    return 1
  fi
  base_origin="${BASH_REMATCH[1]}"

  if [[ "$endpoint" =~ ^(https://[^/]+)(/.*)?$ ]]; then
    local endpoint_origin="${BASH_REMATCH[1]}"
    if [[ "${endpoint_origin,,}" != "${base_origin,,}" ]]; then
      echo "[ ERROR ]: Refusing to send Fabric authorization to a different origin: $endpoint_origin" >&2
      return 1
    fi
    printf '%s\n' "$endpoint"
  elif [[ "$endpoint" == /* ]]; then
    printf '%s%s\n' "$base_origin" "$endpoint"
  elif [[ "$endpoint" =~ ^[A-Za-z][A-Za-z0-9+.-]*: || "$endpoint" == //* ]]; then
    echo "[ ERROR ]: Invalid Fabric API endpoint: $endpoint" >&2
    return 1
  else
    printf '%s/%s\n' "${FABRIC_API_BASE_URL%/}" "$endpoint"
  fi
}

fabric_method_is_idempotent() {
  case "${1^^}" in
    GET | HEAD | PUT | DELETE | OPTIONS)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Retries idempotent requests after curl failures and HTTP 408, 429, or 5xx responses.
fabric_api_request() (
  local method="$1"
  local endpoint="$2"
  local body_file="${3:-}"
  local token="$4"
  local url
  if ! url=$(fabric_api_url "$endpoint"); then
    return 1
  fi

  local max_attempts=1
  if fabric_method_is_idempotent "$method"; then
    max_attempts="$FABRIC_API_MAX_ATTEMPTS"
  fi

  local attempt=1
  while ((attempt <= max_attempts)); do
    local headers_file response_file http_code curl_status response_body retry_after
    headers_file=$(mktemp)
    response_file=$(mktemp)
    trap 'rm -f "$headers_file" "$response_file"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    local curl_args=(
      --silent
      --show-error
      --connect-timeout "$FABRIC_API_CONNECT_TIMEOUT"
      --max-time "$FABRIC_API_REQUEST_TIMEOUT"
      --dump-header "$headers_file"
      --output "$response_file"
      --write-out "%{http_code}"
      --request "$method"
      "$url"
      --header "Authorization: Bearer $token"
      --header "Content-Type: application/json"
    )
    if [[ -n "$body_file" ]]; then
      curl_args+=(--data-binary "@$body_file")
    fi

    if http_code=$(curl "${curl_args[@]}"); then
      curl_status=0
    else
      curl_status=$?
    fi
    response_body=$(cat "$response_file")

    if ((curl_status != 0)); then
      rm -f "$headers_file" "$response_file"
      if ((attempt < max_attempts)); then
        echo "[ WARN ]: Fabric API transport failed (curl $curl_status); retrying attempt $((attempt + 1))/$max_attempts" >&2
        fabric_retry_wait "$attempt"
        ((attempt++))
        continue
      fi
      echo "[ ERROR ]: Fabric API transport failed after $attempt attempts (curl $curl_status)" >&2
      echo "[ ERROR ]: Endpoint: $method $url" >&2
      return 1
    fi

    case "$http_code" in
      200 | 201)
        rm -f "$headers_file" "$response_file"
        printf '%s\n' "$response_body"
        return 0
        ;;
      204)
        rm -f "$headers_file" "$response_file"
        printf '{}\n'
        return 0
        ;;
      202)
        local location operation_id
        location=$(awk 'tolower($1) == "location:" {sub(/\r$/, "", $2); print $2; exit}' "$headers_file")
        operation_id=$(awk 'tolower($1) == "x-ms-operation-id:" {sub(/\r$/, "", $2); print $2; exit}' "$headers_file")
        rm -f "$headers_file" "$response_file"

        if [[ -n "$location" ]]; then
          echo "[ INFO ]: Long-running operation, polling for completion..." >&2
          poll_operation "$location" "$token" "$FABRIC_API_POLL_TIMEOUT"
          return $?
        elif [[ -n "$operation_id" ]]; then
          echo "[ INFO ]: Long-running operation ID: $operation_id, polling..." >&2
          poll_operation "${FABRIC_API_BASE_URL}/operations/${operation_id}" "$token" "$FABRIC_API_POLL_TIMEOUT"
          return $?
        fi
        echo "[ ERROR ]: Fabric API returned HTTP 202 without an operation reference" >&2
        echo "[ ERROR ]: Endpoint: $method $url" >&2
        return 1
        ;;
      408 | 429 | 5??)
        retry_after=$(awk 'tolower($1) == "retry-after:" {sub(/\r$/, "", $2); print $2; exit}' "$headers_file")
        rm -f "$headers_file" "$response_file"
        if ((attempt < max_attempts)); then
          echo "[ WARN ]: Fabric API returned HTTP $http_code; retrying attempt $((attempt + 1))/$max_attempts" >&2
          fabric_retry_wait "$attempt" "$retry_after"
          ((attempt++))
          continue
        fi
        ;;
    esac

    rm -f "$headers_file" "$response_file"
    echo "[ ERROR ]: API call failed with HTTP $http_code after $attempt attempt(s)" >&2
    echo "[ ERROR ]: Endpoint: $method $url" >&2
    echo "[ ERROR ]: Response: $response_body" >&2
    return 1
  done
)

# Generic Fabric API call with error handling (file-based for large payloads)
fabric_api_call_file() {
  local method="$1"
  local endpoint="$2"
  local body_file="${3:-}"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi
  if [[ -n "$body_file" && ! -f "$body_file" ]]; then
    echo "[ ERROR ]: Request body file not found: $body_file" >&2
    return 1
  fi

  fabric_api_request "$method" "$endpoint" "$body_file" "$token"
}

# Generic Fabric API call with error handling
fabric_api_call() (
  local method="$1"
  local endpoint="$2"
  local body="${3:-}"
  local token="${4:-}"
  local body_file=""

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi
  if [[ -n "$body" ]]; then
    body_file=$(mktemp)
    trap 'rm -f "$body_file"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    printf '%s\n' "$body" >"$body_file"
  fi

  local status=0
  fabric_api_request "$method" "$endpoint" "$body_file" "$token" || status=$?
  [[ -n "$body_file" ]] && rm -f "$body_file"
  return "$status"
)

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
  local sleep_interval="$FABRIC_API_POLL_INTERVAL"

  while [[ $elapsed -lt $max_wait ]]; do
    local response
    if ! response=$(fabric_api_request "GET" "$operation_url" "" "$token"); then
      return 1
    fi

    if ! jq -e '
      type == "object"
      and ((.status // .Status) | type == "string" and length > 0)
    ' <<<"$response" >/dev/null; then
      echo "[ ERROR ]: Operation returned malformed status JSON" >&2
      return 1
    fi

    local status
    status=$(jq -r '.status // .Status' <<<"$response")

    case "$status" in
      "Succeeded" | "succeeded")
        # Fetch the result endpoint to get the created item
        local result_url="${operation_url}/result"
        local result_response
        result_response=$(fabric_api_request "GET" "$result_url" "" "$token") || result_response=""

        # Return result if valid, otherwise check for createdItem in status response
        if jq -e 'type == "object"' <<<"$result_response" >/dev/null 2>&1; then
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
      "Failed" | "failed" | "Cancelled" | "cancelled" | "Canceled" | "canceled")
        echo "[ ERROR ]: Operation reached terminal failure state: $status" >&2
        echo "$response" >&2
        return 1
        ;;
      "Running" | "running" | "InProgress" | "inProgress" | "NotStarted" | "notStarted")
        echo "[ INFO ]: Operation status: $status (${elapsed}s/${max_wait}s)" >&2
        fabric_sleep "$sleep_interval"
        ((elapsed += sleep_interval))
        ;;
      *)
        echo "[ ERROR ]: Operation returned unsupported status: $status" >&2
        return 1
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

# List every item page for an exact Fabric item type.
list_workspace_items_paginated() {
  local workspace_id="$1"
  local item_type="$2"
  local token="${3:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  local encoded_type endpoint
  encoded_type=$(jq -rn --arg value "$item_type" '$value | @uri')
  endpoint="/workspaces/$workspace_id/items?type=$encoded_type"

  local page_count=0
  local result='{"value":[]}'
  declare -A visited_endpoints=()

  while [[ -n "$endpoint" ]]; do
    ((page_count += 1))
    if ((page_count > FABRIC_API_MAX_PAGES)); then
      echo "[ ERROR ]: Fabric item pagination exceeded $FABRIC_API_MAX_PAGES pages" >&2
      return 1
    fi
    if [[ -n "${visited_endpoints[$endpoint]:-}" ]]; then
      echo "[ ERROR ]: Fabric item pagination cycle detected" >&2
      return 1
    fi
    visited_endpoints[$endpoint]=1

    local page
    if ! page=$(fabric_api_call "GET" "$endpoint" "" "$token"); then
      return 1
    fi
    if ! jq -e '
      type == "object"
      and (.value | type == "array")
      and (.continuationUri == null or (.continuationUri | type == "string" and length > 0))
      and (.continuationToken == null or (.continuationToken | type == "string" and length > 0))
    ' <<<"$page" >/dev/null; then
      echo "[ ERROR ]: Fabric item list returned a malformed page" >&2
      return 1
    fi
    if ! result=$(jq --argjson items "$(jq '.value' <<<"$page")" '.value += $items' <<<"$result"); then
      return 1
    fi

    local continuation_uri continuation_token
    continuation_uri=$(jq -r '.continuationUri // empty' <<<"$page")
    continuation_token=$(jq -r '.continuationToken // empty' <<<"$page")
    if [[ -n "$continuation_uri" ]]; then
      if [[ "$continuation_uri" == "$FABRIC_API_BASE_URL"/* || "$continuation_uri" == /* ]]; then
        endpoint="$continuation_uri"
      else
        echo "[ ERROR ]: Fabric item pagination returned an unexpected continuation URI" >&2
        return 1
      fi
    elif [[ -n "$continuation_token" ]]; then
      if [[ "$continuation_token" == *['&?#']* ]]; then
        echo "[ ERROR ]: Fabric item pagination returned an invalid continuation token" >&2
        return 1
      fi
      endpoint="/workspaces/$workspace_id/items?type=$encoded_type&continuationToken=$continuation_token"
    else
      endpoint=""
    fi
  done

  printf '%s\n' "$result"
}

# Return no item or one exact display-name match; duplicate names fail closed.
select_workspace_item_by_display_name() {
  local workspace_id="$1"
  local item_type="$2"
  local item_name="$3"
  local token="${4:-}"
  local existing matches match_count

  if ! existing=$(list_workspace_items_paginated "$workspace_id" "$item_type" "$token"); then
    return 1
  fi
  if ! matches=$(jq -ec --arg name "$item_name" '[.value[] | select(.displayName == $name)]' <<<"$existing"); then
    return 1
  fi
  match_count=$(jq 'length' <<<"$matches")
  if ((match_count > 1)); then
    echo "[ ERROR ]: Multiple $item_type items have display name '$item_name'; refusing to mutate" >&2
    return 1
  fi
  if ((match_count == 1)); then
    if ! jq -e '.[0] | type == "object" and (.id | type == "string" and length > 0)' <<<"$matches" >/dev/null; then
      echo "[ ERROR ]: Selected $item_type item is missing a valid ID" >&2
      return 1
    fi
    jq -c '.[0]' <<<"$matches"
  fi
}

create_item() {
  local workspace_id="$1"
  local item_type="$2"
  local item_name="$3"
  local token="${4:-}"

  if [[ -z "$token" ]]; then
    token=$(get_fabric_token)
  fi

  echo "[ INFO ]: Creating $item_type '$item_name'..." >&2
  local body
  if ! body=$(jq -n \
    --arg name "$item_name" \
    --arg type "$item_type" \
    '{"displayName": $name, "type": $type}'); then
    return 1
  fi

  fabric_api_call "POST" "/workspaces/$workspace_id/items" "$body" "$token"
}

# Get or create generic Fabric item (idempotent)
get_or_create_item() {
  local workspace_id="$1"
  local item_type="$2"
  local item_name="$3"
  local token="${4:-}"
  local existing_item

  if ! existing_item=$(select_workspace_item_by_display_name "$workspace_id" "$item_type" "$item_name" "$token"); then
    return 1
  fi

  if [[ -n "$existing_item" ]]; then
    local item_id
    item_id=$(jq -r '.id' <<<"$existing_item")
    echo "[ INFO ]: $item_type '$item_name' already exists: $item_id" >&2
    printf '%s\n' "$existing_item"
    return 0
  fi

  create_item "$workspace_id" "$item_type" "$item_name" "$token"
}

# Get or create Ontology item (idempotent)
get_or_create_ontology() {
  local workspace_id="$1"
  local ontology_name="$2"
  local token="${3:-}"
  get_or_create_item "$workspace_id" "Ontology" "$ontology_name" "$token"
}

# Get an existing item's definition
get_item_definition() {
  local workspace_id="$1"
  local item_id="$2"
  local token="${3:-}"

  fabric_api_call "POST" "/workspaces/$workspace_id/items/$item_id/getDefinition" '{}' "$token"
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
  if ! body=$(jq -n --argjson parts "$definition_parts" '{"definition": {"parts": $parts}}'); then
    return 1
  fi

  fabric_api_call "POST" "/workspaces/$workspace_id/items/$item_id/updateDefinition?updateMetadata=true" "$body" "$token"
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
