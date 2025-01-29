#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DOCS_CONFIG="${TERRAFORM_DOCS_CONFIG:-$SCRIPT_DIR/../.terraform-docs.yml}"
echo "Starting document processing using terraform-docs with config file: $TERRAFORM_DOCS_CONFIG"
echo
echo "Starting terraform doc updates ..."
echo

# Loop over top_level_dirs and select only the folders 
# where there is a "terraform" subfolder and call tf-docs on them
find "SCRIPT_DIR/../src" -mindepth 1 -maxdepth 1 -type d | while read -r folder; do
  if [ -d "$folder/terraform" ]; then
    echo "Updating Terraform docs in folder: $folder/terraform"
    terraform-docs "$folder/terraform" --config "$TERRAFORM_DOCS_CONFIG"
    echo "Completed processing Terraform docs in folder: $folder"
    echo
  fi
done


