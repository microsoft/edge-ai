#!/bin/bash

# This script compares the version and train of components in the local Terraform
# variables file with AIO components defined and  with the version and train of
# components in a remote JSON file. It outputs any mismatches found and is useful
# for build systems to ensure that the most recent released versions of AIO
# components and trains are being used.

# URL of the JSON file from GitHub for Azure IoT Operations
# that contains the version and train information for required components
AIO_MANIFEST_VERSIONS_URL="https://raw.githubusercontent.com/Azure/azure-iot-operations/main/release/azure-iot-operations-enablement.json"

# Path to the local Terraform variables file with component version and train information
CURRENT_AIO_VERSION_TF_DATA="./src/040-iot-ops/terraform/variables.init.tf"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq not found. Please download and install jq from https://stedolan.github.io/jq/download/."
  exit 1
fi

# Read the local Terraform variables file content
local_tf_content=$(cat $CURRENT_AIO_VERSION_TF_DATA)

# Convert the local Terraform variables file content into an array
local_variables=()
inside_variable_block=false
variable_block=""
brace_counter=0

# Loop through each line of the local Terraform variables file content
# and extract variable blocks using brace counting
while IFS= read -r line; do
  if [[ $line =~ ^variable ]]; then
    inside_variable_block=true
    variable_block="$line"
    brace_counter=1
  elif $inside_variable_block; then
    variable_block="$variable_block"$'\n'"$line"
    if [[ $line == *"{"* ]]; then
      ((brace_counter++))
    fi
    if [[ $line == *"}"* ]]; then
      ((brace_counter--))
    fi
    if [[ $brace_counter -eq 0 ]]; then
      inside_variable_block=false
      local_variables+=("$variable_block")
      variable_block=""
    fi
  fi
done <<< "$local_tf_content"

# Clean up each variable block by removing the "type" object and control characters
cleaned_variables=()
for variable in "${local_variables[@]}"; do
  cleaned_variable=$(echo "$variable" | sed '/type = object/,/}/d' | tr -d '\r')
  cleaned_variables+=("$cleaned_variable")
done

# Convert local_variables array elements to a JSON array of objects
json_array="[]"

# Loop through cleaned variables and extract name, version, and train
for variable in "${cleaned_variables[@]}"; do
  name=$(echo "$variable" | awk -F'"' '/variable/ {print $2}')
  version=$(echo "$variable" | awk -F'=' '/version/ {gsub(/[ ",]/, "", $2); print $2}')
  train=$(echo "$variable" | awk -F'=' '/train/ {gsub(/[ ",]/, "", $2); print $2}')
  json_array=$(echo "$json_array" | jq --arg name "$name" --arg version "$version" --arg train "$train" '. += [{"name": $name, "version": $version, "train": $train}]')
done

# Download the JSON file and serialize its content to a variable
json_content=$(curl -s $AIO_MANIFEST_VERSIONS_URL)
# echo "$json_content"

# Extract version and train information for specified components from the downloaded JSON
declare -A remote_versions

# List of components to extract with internal to remote mapping
components=(
  "platform:platform"
  "secret_sync_controller:secretStore"
  "edge_storage_accelerator:containerStorage"
  "open_service_mesh:openServiceMesh"
)

# Loop through the components and extract their versions and trains
for component in "${components[@]}"; do
  local_name="${component%%:*}"
  remote_name="${component##*:}"
  remote_versions["${local_name}_version"]=$(echo "$json_content" | jq -r ".variables.VERSIONS.${remote_name}")
  remote_versions["${local_name}_train"]=$(echo "$json_content" | jq -r ".variables.TRAINS.${remote_name}")
done

# Compare the remote and local JSON content
version_error_tracking_array=()
for variable in $(echo "$json_array" | jq -c '.[]'); do
  name=$(echo "$variable" | jq -r '.name')
  local_version=$(echo "$variable" | jq -r '.version')
  local_train=$(echo "$variable" | jq -r '.train')
  remote_version="${remote_versions[${name}_version]}"
  remote_train="${remote_versions[${name}_train]}"
  if [ "$local_version" != "$remote_version" ] || [ "$local_train" != "$remote_train" ]; then
    version_error_tracking_array+=("$name,$local_version,$remote_version,$local_train,$remote_train")
  fi
done

# Join the array elements with newlines and pass to jq
# to format the output as JSON for the build
printf "%s\n" "${version_error_tracking_array[@]}" | jq -R -s '
  split("\n") |
  map(select(length > 0)) |
  map(split(",")) |
  map({name: .[0], local_version: .[1], remote_version: .[2], local_train: .[3], remote_train: .[4]})
'
