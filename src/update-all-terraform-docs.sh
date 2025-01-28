#!/usr/bin/env bash

set -e

# Find all top-level directories in the src folder that contain a nested terraform folder

TERRAFORM_DOCS_CONFIG=".terraform-docs.yml"
echo "Starting document processing using terraform-docs with config file: $TERRAFORM_DOCS_CONFIG"

update_terraform_docs() {
  local folder_name="$1"
  local folder_path="$folder_name/terraform/"
  echo "Updating README.md for terraform in $folder_path"
  terraform-docs "$folder_path" --config $TERRAFORM_DOCS_CONFIG
}

echo "Searching top-level directories containing terraform ..."
# Find all top-level directories in the src folder that contain a nested terraform folder
folders=()
# -r read literal; -d delimiter is null (spaces and special chars)
while IFS= read -r -d '' folder; do
  folders+=("$folder")
# print parent directories separated by null char, exec on each find
done < <(find src -mindepth 2 -maxdepth 2 -type d -name 'terraform' -exec dirname {} \; -print0 | sort -zu)

echo "Starting terraform doc update for the following folders: ${folders[*]}"

for folder in "${folders[@]}"; do
  echo "Updating Terrform docs in folder: $folder"
  update_terraform_docs "$folder"
  echo "Updated Terrform docs in folder: $folder"
done
