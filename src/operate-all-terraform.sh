#!/bin/bash

set -e

# Optional parameters for the layer to start from and end at (e.g. "--start-layer 040" "--end-layer 060")
start_layer=""
end_layer=""

operation="apply"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --start-layer)
    start_layer="$2"
    shift
    shift
    ;;
  --end-layer)
    end_layer="$2"
    shift
    shift
    ;;
  --operation)
    operation="$2"
    shift
    shift
    ;;
  *)
    echo "Usage: $0 [--start-layer LAYER_NUMBER] [--end-layer LAYER_NUMBER] [--operation apply|test]"
    exit 1
    ;;
  esac
done

if [[ "$operation" != "apply" && "$operation" != "test" ]]; then
  echo "Invalid operation: $operation. Allowed values are 'apply' or 'test'."
  exit 1
fi

print_visible() {
  echo "-------------- $1 -----------------"
}

apply_terraform() {
  local folder_name="$1"
  local folder_path="$folder_name/ci/terraform/"
  if [ ! -d "$folder_path" ]; then
    print_visible "Skipping $folder_name: no /terraform folder."
    return
  fi
  print_visible "Applying terraform in $folder_path"
  terraform -chdir="$folder_path" init
  if [ "$operation" = "test" ]; then
    terraform -chdir="$folder_path" test
    return
  fi
  terraform -chdir="$folder_path" apply -auto-approve -var-file=../../../terraform.tfvars
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
  print_visible "Starting terraform apply from layer $start_layer"
else
  print_visible "Starting terraform apply for the following folders: ${folders[*]}"
fi

for folder in "${folders[@]}"; do
  # If the folder begins with or fully matches $start_layer, stop skipping
  if [[ "$folder" == "$start_layer"* ]]; then
    start_skipping=false
  fi
  if [ "$start_skipping" = false ]; then
    apply_terraform "$folder"
  fi
  # If the folder begins with or fully matches $end_layer, stop execution
  if [[ "$folder" == "$end_layer"* ]]; then
    print_visible "Stopping terraform apply at layer $end_layer"
    break
  fi
done
