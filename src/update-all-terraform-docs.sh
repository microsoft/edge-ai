#!/usr/bin/env bash

set -e

# Find all top-level directories in the src folder that contain a nested terraform folder
echo "$PWD"
TERRAFORM_DOCS_CONFIG=".terraform-docs.yml"
echo "Starting document processing using terraform-docs with config file: $TERRAFORM_DOCS_CONFIG"

echo "Searching top-level directories containing terraform ..."
echo "Starting terraform doc updates ..."

# Loop over top_level_dirs and select only the folders 
# where there is a "terraform" subfolder and call tf-docs on them
find src -mindepth 1 -maxdepth 1 -type d | while read -r folder; do
  if [ -d "$folder/terraform" ]; then
    echo "Updating Terraform docs in folder: $folder/terraform"
    terraform-docs "$folder/terraform" --config "$TERRAFORM_DOCS_CONFIG"
    echo "Completed processing Terraform docs in folder: $folder"
  fi
done


