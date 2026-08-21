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

invalid_definitions=(
  invalid-display-property
  invalid-duplicate-names
  invalid-incomplete-timeseries-binding
  invalid-missing-endpoint-column
  invalid-name
  invalid-unsupported-type
)
for definition in "${invalid_definitions[@]}"; do
  if "scripts/validate-definition.sh" \
    --definition "tests/definitions/${definition}.yaml" \
    >"$TEST_ROOT/${definition}.stdout" 2>"$TEST_ROOT/${definition}.stderr"; then
    echo "[ ERROR ]: Invalid definition unexpectedly passed: $definition" >&2
    exit 1
  fi
done
echo "[ OK    ]: All six invalid definitions return nonzero"

yq -o=json '.dataSources.lakehouse.tables // []' \
  "definitions/examples/cora-corax-dim.yaml" \
  | jq -r '.[].name' \
  | LC_ALL=C sort >"$TEST_ROOT/declared-seed-tables.txt"

for seed_file in fabric-ontology-dim/seed/*.csv; do
  seed_name="${seed_file##*/}"
  printf '%s\n' "${seed_name%.csv}"
done | LC_ALL=C sort >"$TEST_ROOT/actual-seed-tables.txt"

declared_seed_count=$(wc -l <"$TEST_ROOT/declared-seed-tables.txt")
actual_seed_count=$(wc -l <"$TEST_ROOT/actual-seed-tables.txt")
[[ "$declared_seed_count" -eq 19 ]]
[[ "$actual_seed_count" -eq 19 ]]
diff -u "$TEST_ROOT/declared-seed-tables.txt" "$TEST_ROOT/actual-seed-tables.txt"
echo "[ OK    ]: Exact-case Lakehouse seed inventory matches (19 declared, 19 files)"

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
  --rollback-output "$TEST_ROOT/publisher-rollback.json" \
  --diff-output "$TEST_ROOT/publisher-diff.json" \
  >"$TEST_ROOT/publisher.stdout" 2>"$TEST_ROOT/publisher.stderr"

[[ ! -s "$TEST_ROOT/publisher.stdout" ]]
diff -u <(
  cat <<EOF
--definition
$COMPONENT_DIR/tests/definitions/valid-static.yaml
--workspace-id
publisher-workspace-id
--lakehouse-id
publisher-lakehouse-id
--output
$TEST_ROOT/publisher-result.json
--rollback-output
$TEST_ROOT/publisher-rollback.json
--diff-output
$TEST_ROOT/publisher-diff.json
EOF
) "$TEST_ROOT/publisher-args.txt"
echo "[ OK    ]: Publisher delegates explicit resources and evidence output paths"

cp -R "scripts" "$TEST_ROOT/ontology-scripts"
cp -R "definitions" "$TEST_ROOT/definitions"
cat >"$TEST_ROOT/ontology-scripts/lib/fabric-api.sh" <<'EOF'
get_fabric_token() {
  printf 'test-token\n'
}

get_workspace() {
  printf '{"displayName":"Test Workspace"}\n'
}

select_workspace_item_by_display_name() {
  if [[ "${MOCK_EXISTING_ONTOLOGY:-false}" == "true" ]]; then
    printf '{"id":"published-ontology-id","displayName":"Valid Static Ontology"}\n'
  fi
}

create_item() {
  [[ -s "$MOCK_DIFF_OUTPUT" ]]
  printf '{"id":"published-ontology-id"}\n'
}

update_item_definition() {
  [[ -s "$MOCK_DIFF_OUTPUT" ]]
  [[ -s "$MOCK_ROLLBACK_OUTPUT" ]]
  jq -e --arg itemId "$2" '.items[$itemId].ontologyItemId == $itemId' "$MOCK_ROLLBACK_OUTPUT" >/dev/null
  if [[ "${MOCK_EXISTING_ONTOLOGY:-false}" == "true" ]]; then
    jq -e --slurpfile state "$MOCK_DEFINITION_STATE" --arg itemId "$2" \
      '.items[$itemId].preMutationState == "Present"
       and .items[$itemId].rollbackAction == "updateDefinition"
       and .items[$itemId].request.definition == $state[0].definition' \
      "$MOCK_ROLLBACK_OUTPUT" >/dev/null
  else
    jq -e --arg itemId "$2" \
      '.items[$itemId].preMutationState == "Absent"
       and .items[$itemId].rollbackAction == "deleteItem"' \
      "$MOCK_ROLLBACK_OUTPUT" >/dev/null
  fi
  printf 'update\n' >>"$MOCK_MUTATION_CALLS"
  if [[ "${MOCK_UPDATE_FAILURE:-false}" == "true" ]]; then
    return 1
  fi
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
  MOCK_DIFF_OUTPUT="$TEST_ROOT/semantic-diff.json" \
  MOCK_ROLLBACK_OUTPUT="$TEST_ROOT/rollback.json" \
  MOCK_MUTATION_CALLS="$TEST_ROOT/mutation-calls.txt" \
  ID_MAPPING_OUTPUT="$TEST_ROOT/id-mapping.json" \
  "$TEST_ROOT/ontology-scripts/deploy-ontology.sh" \
  --definition "$COMPONENT_DIR/tests/definitions/valid-static.yaml" \
  --workspace-id "publisher-workspace-id" \
  --lakehouse-id "publisher-lakehouse-id" \
  --output "$TEST_ROOT/publication.json" \
  --rollback-output "$TEST_ROOT/rollback.json" \
  --diff-output "$TEST_ROOT/semantic-diff.json" \
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
jq -e \
  --arg rollbackOutput "$TEST_ROOT/rollback.json" \
  --arg diffOutput "$TEST_ROOT/semantic-diff.json" '
  .version == 2
  and .workspaceId == "publisher-workspace-id"
  and .lakehouseId == "publisher-lakehouse-id"
  and .ontologyItemId == "published-ontology-id"
  and .evidence.rollback == $rollbackOutput
  and .evidence.semanticDiff == $diffOutput
  and .itemOperation.status == "Succeeded"
  and .itemOperation.verification == "DefinitionPartsVerified"
  and .graphReadiness.status == "NotChecked"
  and .mapping.version == 1
  and (.mapping.terms | length > 0)
  and all(.mapping.terms[]; has("kind") and has("logicalName") and has("id"))
' "$TEST_ROOT/publication.json" >/dev/null
diff -u <(jq -S . "$TEST_ROOT/id-mapping.json") <(jq -S .mapping "$TEST_ROOT/publication.json")
jq -e '
  .items["published-ontology-id"].preMutationState == "Absent"
  and .items["published-ontology-id"].rollbackAction == "deleteItem"
' "$TEST_ROOT/rollback.json" >/dev/null
[[ $(cat "$TEST_ROOT/mutation-calls.txt") == "update" ]]
grep -F "Graph readiness was not checked" "$TEST_ROOT/ontology.stderr" >/dev/null
echo "[ OK    ]: New-item rollback precedes update and publication separates Graph readiness"

: >"$TEST_ROOT/mutation-calls.txt"
MOCK_EXISTING_ONTOLOGY=true \
  MOCK_DEFINITION_STATE="$TEST_ROOT/published-definition.json" \
  MOCK_DIFF_OUTPUT="$TEST_ROOT/unchanged-semantic-diff.json" \
  MOCK_ROLLBACK_OUTPUT="$TEST_ROOT/unchanged-rollback.json" \
  MOCK_MUTATION_CALLS="$TEST_ROOT/mutation-calls.txt" \
  ID_MAPPING_OUTPUT="$TEST_ROOT/unchanged-id-mapping.json" \
  "$TEST_ROOT/ontology-scripts/deploy-ontology.sh" \
  --definition "$COMPONENT_DIR/tests/definitions/valid-static.yaml" \
  --workspace-id "publisher-workspace-id" \
  --lakehouse-id "publisher-lakehouse-id" \
  --output "$TEST_ROOT/unchanged-publication.json" \
  --rollback-output "$TEST_ROOT/unchanged-rollback.json" \
  --diff-output "$TEST_ROOT/unchanged-semantic-diff.json" \
  >"$TEST_ROOT/unchanged.stdout" 2>"$TEST_ROOT/unchanged.stderr"

jq -e '.counts == {added: 0, removed: 0, changed: 0}' \
  "$TEST_ROOT/unchanged-semantic-diff.json" >/dev/null
jq -e '.terms | group_by([.kind, .logicalName]) | all(length == 1)' \
  "$TEST_ROOT/id-mapping.json" >/dev/null
jq -e '.terms | group_by([.kind, .logicalName]) | all(length == 1)' \
  "$TEST_ROOT/unchanged-id-mapping.json" >/dev/null
diff -u \
  <(jq -S '.terms | map({key: ([.kind, .logicalName] | join("/")), value: .id}) | from_entries' \
    "$TEST_ROOT/id-mapping.json") \
  <(jq -S '.terms | map({key: ([.kind, .logicalName] | join("/")), value: .id}) | from_entries' \
    "$TEST_ROOT/unchanged-id-mapping.json")
[[ $(cat "$TEST_ROOT/mutation-calls.txt") == "update" ]]
echo "[ OK    ]: Unchanged redeployment preserves every logical term ID"

jq '
  .definition.parts = (
    [.definition.parts[] | select(.path != ".platform")]
    | map(if .path == "definition.json"
        then .payload = ({legacy: true} | tostring | @base64)
        else .
        end)
    | . + [{path: "legacy.json", payload: ({} | tostring | @base64), payloadType: "InlineBase64"}]
  )
' "$TEST_ROOT/published-definition.json" >"$TEST_ROOT/existing-definition.json"
mv "$TEST_ROOT/existing-definition.json" "$TEST_ROOT/published-definition.json"
cp "$TEST_ROOT/published-definition.json" "$TEST_ROOT/expected-rollback-definition.json"
: >"$TEST_ROOT/mutation-calls.txt"

MOCK_EXISTING_ONTOLOGY=true \
  MOCK_DEFINITION_STATE="$TEST_ROOT/published-definition.json" \
  MOCK_DIFF_OUTPUT="$TEST_ROOT/existing-semantic-diff.json" \
  MOCK_ROLLBACK_OUTPUT="$TEST_ROOT/existing-rollback.json" \
  MOCK_MUTATION_CALLS="$TEST_ROOT/mutation-calls.txt" \
  ID_MAPPING_OUTPUT="$TEST_ROOT/existing-id-mapping.json" \
  "$TEST_ROOT/ontology-scripts/deploy-ontology.sh" \
  --definition "$COMPONENT_DIR/tests/definitions/valid-static.yaml" \
  --workspace-id "publisher-workspace-id" \
  --lakehouse-id "publisher-lakehouse-id" \
  --output "$TEST_ROOT/existing-publication.json" \
  --rollback-output "$TEST_ROOT/existing-rollback.json" \
  --diff-output "$TEST_ROOT/existing-semantic-diff.json" \
  >"$TEST_ROOT/existing.stdout" 2>"$TEST_ROOT/existing.stderr"

jq -e '
  .addedPaths == [".platform"]
  and .removedPaths == ["legacy.json"]
  and .changedPaths == ["definition.json"]
  and .counts == {added: 1, removed: 1, changed: 1}
' "$TEST_ROOT/existing-semantic-diff.json" >/dev/null
jq -e --slurpfile expected "$TEST_ROOT/expected-rollback-definition.json" '
  .items["published-ontology-id"].request.definition == $expected[0].definition
' "$TEST_ROOT/existing-rollback.json" >/dev/null
[[ $(cat "$TEST_ROOT/mutation-calls.txt") == "update" ]]
echo "[ OK    ]: Existing-item rollback preserves exact restore payload and semantic diff classifies paths"

if MOCK_EXISTING_ONTOLOGY=true \
  MOCK_UPDATE_FAILURE=true \
  MOCK_DEFINITION_STATE="$TEST_ROOT/expected-rollback-definition.json" \
  MOCK_DIFF_OUTPUT="$TEST_ROOT/failed-semantic-diff.json" \
  MOCK_ROLLBACK_OUTPUT="$TEST_ROOT/failed-rollback.json" \
  MOCK_MUTATION_CALLS="$TEST_ROOT/failed-mutation-calls.txt" \
  ID_MAPPING_OUTPUT="$TEST_ROOT/failed-id-mapping.json" \
  "$TEST_ROOT/ontology-scripts/deploy-ontology.sh" \
  --definition "$COMPONENT_DIR/tests/definitions/valid-static.yaml" \
  --workspace-id "publisher-workspace-id" \
  --lakehouse-id "publisher-lakehouse-id" \
  --output "$TEST_ROOT/failed-publication.json" \
  --rollback-output "$TEST_ROOT/failed-rollback.json" \
  --diff-output "$TEST_ROOT/failed-semantic-diff.json" \
  >"$TEST_ROOT/failed.stdout" 2>"$TEST_ROOT/failed.stderr"; then
  echo "[ ERROR ]: Failed ontology update unexpectedly succeeded" >&2
  exit 1
fi
[[ -s "$TEST_ROOT/failed-rollback.json" ]]
[[ -s "$TEST_ROOT/failed-semantic-diff.json" ]]
[[ ! -e "$TEST_ROOT/failed-publication.json" ]]
if compgen -G "$TEST_ROOT/failed-*.json.tmp.*" >/dev/null; then
  echo "[ ERROR ]: Failed publication left an atomic output temporary file" >&2
  exit 1
fi
echo "[ OK    ]: Failed update retains recovery evidence without publication success or temporary outputs"

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

MOCK_CURL_ATTEMPTS="$TEST_ROOT/curl-attempts.txt"
MOCK_CURL_INVOCATIONS="$TEST_ROOT/curl-invocations.txt"
MOCK_SLEEP_DELAYS="$TEST_ROOT/sleep-delays.txt"
MOCK_CURL_SCENARIO=""

# shellcheck disable=SC2317 # This mock is exercised before being undefined.
curl() {
  printf '%q ' "$@" >>"$MOCK_CURL_INVOCATIONS"
  printf '\n' >>"$MOCK_CURL_INVOCATIONS"

  local headers_file=""
  local response_file=""
  while (($# > 0)); do
    case "$1" in
      --dump-header)
        headers_file="$2"
        shift 2
        ;;
      --output)
        response_file="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  printf 'attempt\n' >>"$MOCK_CURL_ATTEMPTS"
  local attempt
  attempt=$(wc -l <"$MOCK_CURL_ATTEMPTS")
  : >"$headers_file"
  : >"$response_file"

  case "$MOCK_CURL_SCENARIO:$attempt" in
    retry-after:1)
      printf 'HTTP/1.1 429 Too Many Requests\r\nRetry-After: 7\r\n\r\n' >"$headers_file"
      printf '{"error":"rate limited"}' >"$response_file"
      printf '429'
      ;;
    headerless-202:1)
      printf 'HTTP/1.1 202 Accepted\r\n\r\n' >"$headers_file"
      printf '{"status":"Accepted"}' >"$response_file"
      printf '202'
      ;;
    async-success:1)
      printf 'HTTP/1.1 202 Accepted\r\nLocation: https://api.fabric.microsoft.com/v1/operations/operation-id\r\n\r\n' >"$headers_file"
      printf '{}' >"$response_file"
      printf '202'
      ;;
    async-success:2)
      printf 'HTTP/1.1 200 OK\r\n\r\n' >"$headers_file"
      printf '{"status":"Running"}' >"$response_file"
      printf '200'
      ;;
    async-success:3)
      printf 'HTTP/1.1 200 OK\r\n\r\n' >"$headers_file"
      printf '{"status":"Succeeded","createdItem":{"id":"created-id"}}' >"$response_file"
      printf '200'
      ;;
    async-success:4)
      printf 'HTTP/1.1 200 OK\r\n\r\n' >"$headers_file"
      printf '{"id":"created-id"}' >"$response_file"
      printf '200'
      ;;
    service:1 | exhaust:*)
      printf 'HTTP/1.1 503 Service Unavailable\r\n\r\n' >"$headers_file"
      printf '{"error":"unavailable"}' >"$response_file"
      printf '503'
      ;;
    transport:1)
      return 7
      ;;
    bad-request:*)
      printf 'HTTP/1.1 400 Bad Request\r\n\r\n' >"$headers_file"
      printf '{"error":"invalid"}' >"$response_file"
      printf '400'
      ;;
    *)
      printf 'HTTP/1.1 200 OK\r\n\r\n' >"$headers_file"
      printf '{"ok":true}' >"$response_file"
      printf '200'
      ;;
  esac
}

fabric_sleep() {
  printf '%s\n' "$1" >>"$MOCK_SLEEP_DELAYS"
}

fabric_retry_jitter() {
  printf '1\n'
}

reset_transport_mock() {
  local scenario="$1"
  MOCK_CURL_SCENARIO="$scenario"
  : >"$MOCK_CURL_ATTEMPTS"
  : >"$MOCK_CURL_INVOCATIONS"
  : >"$MOCK_SLEEP_DELAYS"
}

reset_transport_mock retry-after
# shellcheck disable=SC2218 # Mock functions are intentionally redefined later.
fabric_api_call "GET" "/retry-after" "" "test-token" >/dev/null
[[ $(wc -l <"$MOCK_CURL_ATTEMPTS") -eq 2 ]]
diff -u <(printf '7\n') "$MOCK_SLEEP_DELAYS"
grep -F -- "--connect-timeout $FABRIC_API_CONNECT_TIMEOUT" "$MOCK_CURL_INVOCATIONS" >/dev/null
grep -F -- "--max-time $FABRIC_API_REQUEST_TIMEOUT" "$MOCK_CURL_INVOCATIONS" >/dev/null
echo "[ OK    ]: HTTP 429 honors Retry-After and every request includes bounded timeouts"

reset_transport_mock service
# shellcheck disable=SC2218 # Mock functions are intentionally redefined later.
fabric_api_call "GET" "/service" "" "test-token" >/dev/null
[[ $(wc -l <"$MOCK_CURL_ATTEMPTS") -eq 2 ]]
diff -u <(printf '1\n') "$MOCK_SLEEP_DELAYS"
echo "[ OK    ]: HTTP 503 retries with deterministic bounded jitter"

reset_transport_mock transport
# shellcheck disable=SC2218 # Mock functions are intentionally redefined later.
fabric_api_call "GET" "/transport" "" "test-token" >/dev/null
[[ $(wc -l <"$MOCK_CURL_ATTEMPTS") -eq 2 ]]
echo "[ OK    ]: Curl transport failure retries"

reset_transport_mock bad-request
if fabric_api_call "GET" "/bad-request" "" "test-token" >/dev/null 2>&1; then
  echo "[ ERROR ]: HTTP 400 unexpectedly succeeded" >&2
  exit 1
fi
[[ $(wc -l <"$MOCK_CURL_ATTEMPTS") -eq 1 ]]
[[ ! -s "$MOCK_SLEEP_DELAYS" ]]
echo "[ OK    ]: Nonretriable HTTP 400 performs one attempt"

reset_transport_mock exhaust
if fabric_api_call "GET" "/exhaust" "" "test-token" >/dev/null 2>&1; then
  echo "[ ERROR ]: Exhausted HTTP 503 attempts unexpectedly succeeded" >&2
  exit 1
fi
[[ $(wc -l <"$MOCK_CURL_ATTEMPTS") -eq "$FABRIC_API_MAX_ATTEMPTS" ]]
[[ $(wc -l <"$MOCK_SLEEP_DELAYS") -eq $((FABRIC_API_MAX_ATTEMPTS - 1)) ]]
echo "[ OK    ]: Retriable failures stop at the configured attempt bound"

reset_transport_mock success
printf '{"request":true}\n' >"$TEST_ROOT/request-body.json"
fabric_api_call_file "POST" "/file-request" "$TEST_ROOT/request-body.json" "test-token" >/dev/null
grep -F -- "--connect-timeout $FABRIC_API_CONNECT_TIMEOUT" "$MOCK_CURL_INVOCATIONS" >/dev/null
grep -F -- "--max-time $FABRIC_API_REQUEST_TIMEOUT" "$MOCK_CURL_INVOCATIONS" >/dev/null
echo "[ OK    ]: File-based requests use the centralized timeout-aware transport"

reset_transport_mock headerless-202
if fabric_api_call "POST" "/headerless-202" '{}' "test-token" >/dev/null 2>&1; then
  echo "[ ERROR ]: Headerless HTTP 202 unexpectedly succeeded" >&2
  exit 1
fi
echo "[ OK    ]: HTTP 202 without an operation reference fails closed"

reset_transport_mock async-success
async_result=$(fabric_api_call "POST" "/async-success" '{}' "test-token")
[[ $(jq -r '.id' <<<"$async_result") == "created-id" ]]
[[ $(wc -l <"$MOCK_CURL_ATTEMPTS") -eq 4 ]]
echo "[ OK    ]: HTTP 202 succeeds only after Running reaches terminal Succeeded"

unset -f curl

MOCK_PAGE_CALLS="$TEST_ROOT/page-calls.txt"
MOCK_POST_CALLS="$TEST_ROOT/post-calls.txt"
MOCK_PAGE_SCENARIO="second-page"

# shellcheck disable=SC2317 # This mock is exercised before being redefined.
fabric_api_call() {
  local method="$1"
  local endpoint="$2"
  printf '%s %s\n' "$method" "$endpoint" >>"$MOCK_PAGE_CALLS"

  if [[ "$method" == "POST" ]]; then
    printf 'POST\n' >>"$MOCK_POST_CALLS"
    printf '{"id":"created-id","displayName":"Target Ontology"}\n'
    return 0
  fi

  case "$MOCK_PAGE_SCENARIO:$endpoint" in
    second-page:*continuationToken*)
      printf '{"value":[{"id":"second-page-id","displayName":"Target Ontology","type":"Ontology"}]}\n'
      ;;
    second-page:*)
      printf '{"value":[{"id":"other-id","displayName":"Other","type":"Ontology"}],"continuationToken":"page-2"}\n'
      ;;
    duplicate:*continuationToken*)
      printf '{"value":[{"id":"duplicate-2","displayName":"Target Ontology","type":"Ontology"}]}\n'
      ;;
    duplicate:*)
      printf '{"value":[{"id":"duplicate-1","displayName":"Target Ontology","type":"Ontology"}],"continuationToken":"page-2"}\n'
      ;;
    cycle:*)
      printf '{"value":[],"continuationUri":"/workspaces/workspace-id/items?type=Ontology"}\n'
      ;;
    malformed:*)
      printf '{"continuationToken":"page-2"}\n'
      ;;
  esac
}

: >"$MOCK_PAGE_CALLS"
selected_item=$(select_workspace_item_by_display_name \
  "workspace-id" "Ontology" "Target Ontology" "test-token")
[[ $(jq -r '.id' <<<"$selected_item") == "second-page-id" ]]
[[ $(wc -l <"$MOCK_PAGE_CALLS") -eq 2 ]]
echo "[ OK    ]: Exact display-name selection finds a second-page match"

MOCK_PAGE_SCENARIO="duplicate"
: >"$MOCK_PAGE_CALLS"
: >"$MOCK_POST_CALLS"
if get_or_create_item "workspace-id" "Ontology" "Target Ontology" "test-token" >/dev/null 2>&1; then
  echo "[ ERROR ]: Duplicate display names unexpectedly selected or created an item" >&2
  exit 1
fi
[[ ! -s "$MOCK_POST_CALLS" ]]
echo "[ OK    ]: Duplicate display names across pages fail before POST"

MOCK_PAGE_SCENARIO="cycle"
: >"$MOCK_PAGE_CALLS"
if list_workspace_items_paginated "workspace-id" "Ontology" "test-token" >/dev/null 2>&1; then
  echo "[ ERROR ]: Pagination cycle unexpectedly succeeded" >&2
  exit 1
fi
echo "[ OK    ]: Pagination cycles fail closed"

MOCK_PAGE_SCENARIO="malformed"
: >"$MOCK_PAGE_CALLS"
if list_workspace_items_paginated "workspace-id" "Ontology" "test-token" >/dev/null 2>&1; then
  echo "[ ERROR ]: Malformed pagination response unexpectedly succeeded" >&2
  exit 1
fi
echo "[ OK    ]: Malformed pagination responses fail closed"

EXPECTED_PARTS='[{"path":"definition.json","payload":"e30=","payloadType":"InlineBase64"}]'

# shellcheck disable=SC2317 # This mock is exercised before being redefined.
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

MOCK_OPERATION_RESPONSES="$TEST_ROOT/operation-responses.jsonl"
fabric_api_request() {
  local response
  response=$(head -n 1 "$MOCK_OPERATION_RESPONSES")
  tail -n +2 "$MOCK_OPERATION_RESPONSES" >"$MOCK_OPERATION_RESPONSES.next"
  mv "$MOCK_OPERATION_RESPONSES.next" "$MOCK_OPERATION_RESPONSES"
  printf '%s\n' "$response"
}

for terminal_state in Failed Cancelled Canceled; do
  printf '{"status":"%s"}\n' "$terminal_state" >"$MOCK_OPERATION_RESPONSES"
  if poll_operation "/operations/terminal" "test-token" 10 >/dev/null 2>&1; then
    echo "[ ERROR ]: Terminal state $terminal_state unexpectedly succeeded" >&2
    exit 1
  fi
done
echo "[ OK    ]: Failed and cancelled operation states fail closed"

for malformed_response in '{}' '[]' '{"status":1}' '{not-json'; do
  printf '%s\n' "$malformed_response" >"$MOCK_OPERATION_RESPONSES"
  if poll_operation "/operations/malformed" "test-token" 10 >/dev/null 2>&1; then
    echo "[ ERROR ]: Malformed operation response unexpectedly succeeded" >&2
    exit 1
  fi
done
echo "[ OK    ]: Malformed operation JSON and status fail closed"

printf '%s\n' '{"status":"Running"}' '{"status":"Running"}' >"$MOCK_OPERATION_RESPONSES"
if poll_operation "/operations/timeout" "test-token" 10 >/dev/null 2>&1; then
  echo "[ ERROR ]: Pending operation timeout unexpectedly succeeded" >&2
  exit 1
fi
echo "[ OK    ]: Pending operation states stop at the polling timeout"

mkdir -p "$TEST_ROOT/signal-bin"
cat >"$TEST_ROOT/signal-bin/az" <<'EOF'
#!/usr/bin/env bash
printf 'test-token\n'
EOF
cat >"$TEST_ROOT/signal-bin/curl" <<'EOF'
#!/usr/bin/env bash
while (($# > 0)); do
  case "$1" in
    --dump-header | --output)
      printf '%s\n' "$2" >>"$SIGNAL_TEMP_PATHS"
      shift 2
      ;;
    --data-binary)
      printf '%s\n' "${2#@}" >>"$SIGNAL_TEMP_PATHS"
      shift 2
      ;;
    *) shift ;;
  esac
done
kill -TERM "$PPID"
sleep 1
EOF
chmod +x "$TEST_ROOT/signal-bin/az" "$TEST_ROOT/signal-bin/curl"
if PATH="$TEST_ROOT/signal-bin:$PATH" \
  SIGNAL_TEMP_PATHS="$TEST_ROOT/signal-temp-paths.txt" \
  bash -c 'source "$1"; fabric_api_call POST /signal-test "{\"secret\":true}" test-token' \
  _ "$COMPONENT_DIR/scripts/lib/fabric-api.sh" >/dev/null 2>&1; then
  echo "[ ERROR ]: Signal-interrupted API request unexpectedly succeeded" >&2
  exit 1
fi
while IFS= read -r temp_path; do
  [[ ! -e "$temp_path" ]]
done <"$TEST_ROOT/signal-temp-paths.txt"
echo "[ OK    ]: Signal interruption removes request body, header, and response temporary files"
