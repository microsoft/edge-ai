#!/usr/bin/env bash

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATED_PARTS=$(mktemp)
CANONICAL_PARTS=$(mktemp)
TEST_ROOT=$(mktemp -d)

cleanup() {
  rm -f "$GENERATED_PARTS" "$CANONICAL_PARTS"
  rm -rf "$TEST_ROOT"
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

for definition in valid-static identity-base identity-additive; do
  definition_path="tests/definitions/${definition}.yaml"
  if [[ ! -f "$definition_path" ]]; then
    definition_path="tests/expected/${definition}.yaml"
  fi
  "scripts/validate-definition.sh" --definition "$definition_path" >/dev/null
done
echo "[ OK    ]: Static and identity definition regressions pass"

if "scripts/deploy.sh" \
  --definition "tests/definitions/valid-static.yaml" \
  --workspace-id "publisher-workspace-id" \
  --output "$TEST_ROOT/missing-lakehouse.json" \
  >"$TEST_ROOT/missing-lakehouse.stdout" 2>"$TEST_ROOT/missing-lakehouse.stderr"; then
  echo "[ ERROR ]: Publisher accepted a missing Lakehouse ID" >&2
  exit 1
fi
grep -F -- "--lakehouse-id is required" "$TEST_ROOT/missing-lakehouse.stderr" >/dev/null
[[ ! -s "$TEST_ROOT/missing-lakehouse.stdout" ]]
echo "[ OK    ]: Missing Lakehouse input fails before publisher delegation"

mkdir -p "$TEST_ROOT/publisher/scripts/lib"
cp "scripts/deploy.sh" "$TEST_ROOT/publisher/scripts/deploy.sh"
cp "scripts/lib/logging.sh" "$TEST_ROOT/publisher/scripts/lib/logging.sh"
cat >"$TEST_ROOT/publisher/scripts/deploy-ontology.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$PUBLISHER_ARGS_OUTPUT"
EOF
chmod +x "$TEST_ROOT/publisher/scripts/deploy-ontology.sh"

PUBLISHER_ARGS_OUTPUT="$TEST_ROOT/publisher-args.txt" \
  "$TEST_ROOT/publisher/scripts/deploy.sh" \
  --definition "$COMPONENT_DIR/tests/definitions/valid-static.yaml" \
  --workspace-id "publisher-workspace-id" \
  --lakehouse-id "publisher-lakehouse-id" \
  --output "$TEST_ROOT/publisher-result.json" \
  >"$TEST_ROOT/publisher.stdout" 2>"$TEST_ROOT/publisher.stderr"

[[ ! -s "$TEST_ROOT/publisher.stdout" ]]
diff -u <(cat <<EOF
--definition
$COMPONENT_DIR/tests/definitions/valid-static.yaml
--workspace-id
publisher-workspace-id
--lakehouse-id
publisher-lakehouse-id
--output
$TEST_ROOT/publisher-result.json
EOF
) "$TEST_ROOT/publisher-args.txt"
echo "[ OK    ]: Publisher delegates only explicit existing IDs and output path"

cp -R "scripts" "$TEST_ROOT/ontology-scripts"
cp -R "definitions" "$TEST_ROOT/definitions"
cat >"$TEST_ROOT/ontology-scripts/lib/fabric-api.sh" <<'EOF'
get_fabric_token() {
  printf 'test-token\n'
}

get_workspace() {
  printf '{"displayName":"Test Workspace"}\n'
}

fabric_api_call() {
  printf '{"value":[]}\n'
}

get_or_create_ontology() {
  printf '{"id":"published-ontology-id"}\n'
}

update_item_definition() {
  jq -n --argjson parts "$3" '{definition: {parts: $parts}}' >"$MOCK_DEFINITION_STATE"
}

get_item_definition() {
  cat "$MOCK_DEFINITION_STATE"
}

build_definition_part() {
  local path="$1"
  local content="$2"
  jq -n --arg path "$path" --arg payload "$(printf '%s' "$content" | base64 -w 0)" \
    '{path: $path, payload: $payload, payloadType: "InlineBase64"}'
}
EOF

if ! MOCK_DEFINITION_STATE="$TEST_ROOT/published-definition.json" \
  ID_MAPPING_OUTPUT="$TEST_ROOT/id-mapping.json" \
  "$TEST_ROOT/ontology-scripts/deploy-ontology.sh" \
    --definition "$COMPONENT_DIR/tests/definitions/valid-static.yaml" \
    --workspace-id "publisher-workspace-id" \
    --lakehouse-id "publisher-lakehouse-id" \
    --output "$TEST_ROOT/publication.json" \
    >"$TEST_ROOT/ontology.stdout" 2>"$TEST_ROOT/ontology.stderr"; then
  cat "$TEST_ROOT/ontology.stdout" >&2
  cat "$TEST_ROOT/ontology.stderr" >&2
  echo "[ ERROR ]: Mocked ontology publication failed" >&2
  exit 1
fi

if [[ -s "$TEST_ROOT/ontology.stdout" ]]; then
  cat "$TEST_ROOT/ontology.stdout" >&2
  echo "[ ERROR ]: Ontology publication wrote to stdout" >&2
  exit 1
fi
grep -F "Ontology ID: published-ontology-id" "$TEST_ROOT/ontology.stderr" >/dev/null
jq -e '
  .version == 1
  and .workspaceId == "publisher-workspace-id"
  and .lakehouseId == "publisher-lakehouse-id"
  and .ontologyItemId == "published-ontology-id"
  and .mapping.version == 1
  and (.mapping.terms | length > 0)
  and all(.mapping.terms[]; has("kind") and has("logicalName") and has("id"))
' "$TEST_ROOT/publication.json" >/dev/null
diff -u <(jq -S . "$TEST_ROOT/id-mapping.json") <(jq -S .mapping "$TEST_ROOT/publication.json")
echo "[ OK    ]: Publication writes valid machine JSON while human logs remain on stderr"

MOCK_DEFINITION_STATE="$TEST_ROOT/dry-run-definition.json" \
  ID_MAPPING_OUTPUT="$TEST_ROOT/dry-run-id-mapping.json" \
  "$TEST_ROOT/ontology-scripts/deploy-ontology.sh" \
  --definition "$COMPONENT_DIR/tests/definitions/valid-static.yaml" \
  --workspace-id "publisher-workspace-id" \
  --lakehouse-id "publisher-lakehouse-id" \
  --output "$TEST_ROOT/dry-run-publication.json" \
  --dry-run \
  >"$TEST_ROOT/dry-run.stdout" 2>"$TEST_ROOT/dry-run.stderr"

[[ ! -s "$TEST_ROOT/dry-run.stdout" ]]
[[ ! -e "$TEST_ROOT/dry-run-publication.json" ]]
if grep -F "Ontology ID:" "$TEST_ROOT/dry-run.stderr" >/dev/null; then
  echo "[ ERROR ]: Dry run claimed a published ontology ID" >&2
  exit 1
fi
grep -F "No ontology was published" "$TEST_ROOT/dry-run.stderr" >/dev/null
echo "[ OK    ]: Dry run writes no publication result and claims no ontology ID"

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
