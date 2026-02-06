#!/bin/bash
# Use the Eventstream Definition API to capture an event stream item definition.

# Define variables
BASE_URL="https://api.fabric.microsoft.com/v1"
API_ENDPOINT="$BASE_URL/workspaces/$WORKSPACE_ID/eventstreams/$ITEM_ID/getDefinition"
DEFINITION_DIR="${OUTPUT_DIR:-out}/$WORKSPACE_ID/eventstreams/$ITEM_ID/definitions_$(date +%Y%m%d%H%M%S)"

# Get the bearer token using Azure CLI
ACCESS_TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken --output tsv)
# Fetch the event stream definition
response=$(curl -s -w "\n%{http_code}" -X POST "$API_ENDPOINT" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}')

# Extract HTTP status code from the response
http_code=$(echo "$response" | tail -c 4)
response_body=$(echo "$response" | sed '$d')

# Check if the response code is not 200
if ! [[ "$http_code" =~ ^[0-9]+$ ]] || [ "$http_code" -ne 200 ]; then
  echo "Error: Received HTTP status code $http_code"
  echo "Response: $response_body"
  exit 1
fi

# Extract and decode each part of the definition
# Create output directory if it doesn't exist
mkdir -p "${DEFINITION_DIR:out}"
echo "$response_body" | jq -c '.definition.parts[]' | while read -r part; do
  path=$(echo "$part" | jq -r '.path')
  payload=$(echo "$part" | jq -r '.payload')
  echo "$payload" | base64 --decode >"$DEFINITION_DIR/$path"
done

echo "Event stream definitions saved to $DEFINITION_DIR"
