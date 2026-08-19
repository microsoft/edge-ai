#!/usr/bin/env bash

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATED_PARTS=$(mktemp)
CANONICAL_PARTS=$(mktemp)

cleanup() {
  rm -f "$GENERATED_PARTS" "$CANONICAL_PARTS"
}

trap cleanup EXIT

cd "$COMPONENT_DIR"

"scripts/deploy-ontology.sh" \
  --definition "tests/definitions/valid-static.yaml" \
  --workspace-id "golden-workspace-id" \
  --lakehouse-id "golden-lakehouse-id" \
  --definition-parts-output "$GENERATED_PARTS"

jq -S '
  [
    .[]
    | {
        path,
        content: (
          .payload
          | @base64d
          | fromjson
          | walk(if type == "object" then del(.workspaceId, .itemId) else . end)
        )
      }
  ]
  | sort_by(.path)
' "$GENERATED_PARTS" >"$CANONICAL_PARTS"

diff -u <(jq -S . "$SCRIPT_DIR/expected/valid-static-parts.json") "$CANONICAL_PARTS"
echo "[ OK    ]: Canonical generated ontology parts match the golden fixture"

source "$COMPONENT_DIR/scripts/lib/fabric-api.sh"

EXPECTED_PARTS='[{"path":"definition.json","payload":"e30=","payloadType":"InlineBase64"}]'

fabric_api_call() {
  local method="$1"
  local endpoint="$2"
  local body="$3"
  local token="$4"

  [[ "$method" == "POST" ]]
  [[ "$endpoint" == "/workspaces/workspace-id/items/item-id/updateDefinition?updateMetadata=true" ]]
  [[ "$token" == "test-token" ]]
  jq -e --argjson expected "$EXPECTED_PARTS" '.definition.parts == $expected' <<<"$body" >/dev/null
  printf '{"status":"Succeeded"}\n'
}

update_item_definition "workspace-id" "item-id" "$EXPECTED_PARTS" "test-token" >/dev/null
echo "[ OK    ]: Generic item update uses the metadata-aware endpoint"

fabric_api_call() {
  return 1
}

if update_item_definition "workspace-id" "item-id" "$EXPECTED_PARTS" "test-token" >/dev/null; then
  echo "[ ERROR ]: Failed generic item update returned success" >&2
  exit 1
fi
echo "[ OK    ]: Failed generic item update returns nonzero"
