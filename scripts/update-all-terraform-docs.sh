#!/usr/bin/env bash

# This script updates the Terraform documentation for all the modules
# in the repository. It uses the terraform-docs tool to generate the documentation
# based on the configuration provided in the .terraform-docs.yml file.
# The script loops over all the top-level directories in the src folder and checks
# if there is a "terraform" subfolder. If it finds one, it runs terraform-docs on
# that folder to generate the documentation for the Terraform folder and modules.
#
# Usage: ./update-all-terraform-docs.sh
#
# Dependencies:
#   - terraform-docs: https://terraform-docs.io/user-guide/installation/
#
# Exit Codes:
#   0 - Success
#   1 - Failure (e.g., missing dependencies, errors during execution)
#
# Example:
#   ./update-all-terraform-docs.sh

set -e

# Check if terraform-docs is installed
if ! command -v terraform-docs &>/dev/null; then
  echo "terraform-docs could not be found."
  echo "Please install terraform-docs and ensure it is in your PATH."
  echo "Installation instructions can be found at: https://terraform-docs.io/user-guide/installation/"
  echo
  exit 1
fi

# Get the script's directory for config file path resolution
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set the path to the terraform-docs configuration file based
# on this script's directory. This file is used to configure
# the output format and other options for terraform-docs.
terraform_docs_config="${terraform_docs_config:-$script_dir/../.terraform-docs.yml}"
echo "Starting document processing using terraform-docs with config file: $terraform_docs_config"
echo
echo "Starting terraform doc updates ..."
echo

# Loop over all component dirs and select only folders that have *.tf files.
# Exclude tests, .terraform, and ci directories. Remove duplicates with `sort -u`.
find "$script_dir/../src" "$script_dir/../blueprints" \
  -type d \( -name "tests" -o -name ".terraform" -o -name "ci" \) -prune -false -o \
  -type f -name "*.tf" -exec dirname {} \; |
  sort -u |
  while read -r folder; do
    if [ -d "$folder" ]; then
      echo "Updating Terraform docs in folder: $folder"
      terraform-docs "$folder" --config "$terraform_docs_config"
      echo "Completed processing Terraform docs in folder: $folder"
      echo
    fi
  done
