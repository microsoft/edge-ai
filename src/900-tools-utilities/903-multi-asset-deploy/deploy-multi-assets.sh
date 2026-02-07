#!/bin/bash
set -euo pipefail

readonly CSV_FILE="${1:-}"
readonly RESOURCE_GROUP="${2:-}"
readonly CUSTOM_LOCATION_ID="${3:-}"
readonly ADR_NAMESPACE="${4:-default-namespace}"

usage() {
  echo "Usage: ${0} <csv_file> <resource_group> <custom_location_id> [adr_namespace]"
  exit 1
}

[[ -z "${CSV_FILE}" || -z "${RESOURCE_GROUP}" || -z "${CUSTOM_LOCATION_ID}" ]] && usage
[[ ! -f "${CSV_FILE}" ]] && {
  echo "Error: CSV file not found"
  exit 1
}

get_assets() {
  tail -n +2 "${1}" | grep -v '^#' | cut -d',' -f1 | sort -u
}

deploy_asset() {
  local asset="${1}"

  # Get asset data
  local rows
  rows=$(tail -n +2 "${CSV_FILE}" | grep -v '^#' | grep "^${asset},")
  local first_row
  first_row=$(echo "${rows}" | head -n1)

  # Parse metadata from first row
  IFS=',' read -ra meta <<<"${first_row}"

  # Build data points from all rows
  local data_points=""
  local first=true
  while IFS=',' read -ra fields; do
    [[ -z "${fields[0]}" ]] && continue
    if [[ "${first}" == "true" ]]; then
      first=false
    else
      data_points+=","
    fi
    data_points+="{\"name\":\"${fields[15]}\",\"dataSource\":\"${fields[16]}\",\"observabilityMode\":\"${fields[25]}\""
    if [[ -n "${fields[17]}" ]]; then
      data_points+=",\"dataPointConfiguration\":\"${fields[17]}\""
    fi
    data_points+="}"
  done <<<"${rows}"

  # Build inline parameters
  echo "🚀 Deploying ${asset}..."
  az deployment group create \
    --resource-group "${RESOURCE_GROUP}" \
    --template-file "../../100-edge/111-assets/bicep/main.bicep" \
    --name "deploy-${asset}-$(date +%s)" \
    --parameters \
    common="{\"resourcePrefix\":\"${asset//-/}\",\"location\":\"West US 2\",\"environment\":\"dev\",\"instance\":\"001\"}" \
    customLocationId="${CUSTOM_LOCATION_ID}" \
    adrNamespaceName="${ADR_NAMESPACE}" \
    namespacedDevices="[{\"name\":\"${meta[2]}\",\"isEnabled\":true,\"endpoints\":{\"outbound\":{\"assigned\":{}},\"inbound\":{\"${meta[3]}\":{\"endpointType\":\"Microsoft.OpcUa\",\"address\":\"opc.tcp://opcplc-000000:50000\",\"authentication\":{\"method\":\"Anonymous\"}}}}}]" \
    namespacedAssets="[{\"name\":\"${meta[0]}\",\"displayName\":\"${meta[1]}\",\"externalAssetId\":\"${meta[24]}\",\"deviceRef\":{\"deviceName\":\"${meta[2]}\",\"endpointName\":\"${meta[3]}\"},\"description\":\"${meta[4]}\",\"documentationUri\":\"${meta[5]}\",\"isEnabled\":${meta[6]},\"hardwareRevision\":\"${meta[7]}\",\"manufacturer\":\"${meta[8]}\",\"manufacturerUri\":\"${meta[9]}\",\"model\":\"${meta[10]}\",\"productCode\":\"${meta[11]}\",\"serialNumber\":\"${meta[12]}\",\"softwareRevision\":\"${meta[13]}\",\"attributes\":${meta[27]},\"datasets\":[{\"name\":\"${meta[14]}\",\"dataPoints\":[${data_points}],\"destinations\":[]}],\"defaultDatasetsConfiguration\":\"${meta[22]}\",\"defaultEventsConfiguration\":\"${meta[23]}\"}]" \
    assetEndpointProfiles="[]" \
    legacyAssets="[]" \
    shouldCreateDefaultAsset=false \
    shouldCreateDefaultNamespacedAsset=false \
    --only-show-errors
}

# Check Azure login
az account show >/dev/null || {
  echo "Error: Run 'az login' first"
  exit 1
}

# Deploy each asset
for asset in $(get_assets "${CSV_FILE}"); do
  [[ -n "${asset}" ]] && deploy_asset "${asset}" && echo "✅ ${asset} deployed"
done

echo "🎉 All assets deployed!"
