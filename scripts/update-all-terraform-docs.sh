#!/usr/bin/env bash
# Update All Terraform Docs Script
#
# Purpose:
# This script updates the Terraform documentation for all modules in the repository
# using terraform-docs. It automatically generates documentation based on the
# configuration provided in the .terraform-docs.yml file.
#
# Functionality:
# - Searches for Terraform modules in src and blueprints directories
# - Runs terraform-docs on each found module
# - Updates README.md files with standardized documentation
# - Maintains consistent documentation across all Terraform modules
#
# Parameters:
# - None: Script uses predefined paths and configuration
#
# Output Variables:
# - None
#
# Exit Codes:
# - 0: Success
# - 1: Failure (e.g., missing dependencies, errors during execution)
#
# Dependencies:
# - terraform-docs: https://terraform-docs.io/user-guide/installation/
#
# Usage Examples:
# ```bash
# # Update all Terraform documentation:
# ./update-all-terraform-docs.sh
# ```

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
  -type f -name "*.tf" -exec dirname {} \; \
  | sort -u \
  | while read -r folder; do
    if [ -d "$folder" ]; then
      echo "Updating Terraform docs in folder: $folder"
      terraform-docs "$folder" --config "$terraform_docs_config"
      echo "Completed processing Terraform docs in folder: $folder"
      echo
    fi
  done

echo
echo "Formatting tables for MD060 compliance..."

# Find all generated README.md files in terraform directories and format tables
find "$script_dir/../src" "$script_dir/../blueprints" \
  -type d \( -name "tests" -o -name ".terraform" -o -name "ci" \) -prune -false -o \
  -path "*/terraform/README.md" -type f -print0 \
  | xargs -0 -r npx markdown-table-formatter

echo "Table formatting complete"
