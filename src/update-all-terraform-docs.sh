#!/bin/bash

set -e

# Optional parameter for the layer to start from (e.g. "--start-layer 040")
start_layer=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --start-layer)
    start_layer="$2"
    shift
    shift
    ;;
  *)
    echo "Usage: $0 [--start-layer LAYER_NUMBER]"
    exit 1
    ;;
  esac
done

print_visible() {
  echo "-------------- $1 -----------------"
}

update_terraform_docs() {
  local folder_name="$1"
  local folder_path="$folder_name/terraform/"
  if [ ! -d "$folder_path" ]; then
    print_visible "Skipping $folder_name: no /terraform folder."
    return
  fi
  print_visible "Updating README.md for terraform in $folder_path"
  terraform-docs "$folder_path" --config .terraform-docs.yml
}

folders=(
  "005-onboard-reqs"
  "010-vm-host"
  "020-cncf-cluster"
  "030-iot-ops-cloud-reqs"
  "040-iot-ops"
  "050-messaging"
  "060-storage"
  "070-observability"
  "080-iot-ops-utility"
)

start_skipping=false
if [ -n "$start_layer" ]; then
  start_skipping=true
  print_visible "Starting terraform doc update from layer $start_layer"
else
  print_visible "Starting terraform doc update for the following folders: ${folders[*]}"
fi

for folder in "${folders[@]}"; do
  # If the folder begins with or fully matches $start_layer, stop skipping
  if [[ "$folder" == "$start_layer"* ]]; then
    start_skipping=false
  fi
  if [ "$start_skipping" = false ]; then
    update_terraform_docs "$folder"
  fi
done
