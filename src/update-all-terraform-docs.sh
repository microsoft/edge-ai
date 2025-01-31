#!/usr/bin/env bash

# This script is used to update the Terraform documentation for all the modules
# in the repository. It uses the terraform-docs tool to generate the documentation
# based on the configuration provided in the hard-coded .terraform-docs.yml file.
# The script loops over all the top-level directories in the src folder and checks
# if there is a "terraform" subfolder. If it finds one, it runs terraform-docs on
# that folder to generate the documentation for the Terraform folder and modules.

# The script is intended to be run from the root of the repository or from the
# src directory and assumes that the terraform-docs tool is installed and available
# in the user's PATH.

# The terraform-docs tool installation instructions can be found at:
# https://terraform-docs.io/user-guide/installation/

set -e

# Check if terraform-docs is installed
if ! command -v terraform-docs &> /dev/null; then
  echo "terraform-docs could not be found." 
  echo "Please install terraform-docs and ensure it is in your PATH."
  echo "Installation instructions can be found at: https://terraform-docs.io/user-guide/installation/"
  echo
  exit 1
fi

# Get the script directory for config file path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Set the path to the terraform-docs configuration file
TERRAFORM_DOCS_CONFIG="${TERRAFORM_DOCS_CONFIG:-$SCRIPT_DIR/../.terraform-docs.yml}"
echo "Starting document processing using terraform-docs with config file: $TERRAFORM_DOCS_CONFIG"
echo
echo "Starting terraform doc updates ..."
echo

# Loop over top_level_dirs and select only the folders
# where there is a "terraform" subfolder and call tf-docs on them.
find "$SCRIPT_DIR/../src" -mindepth 1 -maxdepth 1 -type d | while read -r folder; do
  # Check if the folder contains a "terraform" subfolder
  if [ -d "$folder/terraform" ]; then
    echo "Updating Terraform docs in folder: $folder/terraform"
    # Run terraform-docs on the folder. The configuration file declares a recursive
    # processing of the folder and its subfolders (ie. modules).
    terraform-docs "$folder/terraform" --config "$TERRAFORM_DOCS_CONFIG"
    echo "Completed processing Terraform docs in folder: $folder"
    echo
  fi
done
