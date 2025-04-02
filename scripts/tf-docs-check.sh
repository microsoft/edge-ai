#!/usr/bin/env bash
# Terraform Docs Check Script
#
# Purpose:
# This script checks if terraform-docs is installed and then runs the update-all-terraform-docs.sh script.
# It returns a boolean value to indicate if README.md files have changed after running the auto-docs-gen.
# The intent is that the build/CI system calls this script while contributors would call the
# update-all-terraform-docs.sh script directly.
#
# Functionality:
# - Verifies terraform-docs installation
# - Executes update-all-terraform-docs.sh script
# - Checks for changes in README.md files
# - Reports which files require updates
#
# Parameters:
# - None: The script uses predefined paths and settings
#
# Output Variables:
# - Returns boolean (true/false) indicating if README.md files have changed
#
# Exit Codes:
# - 0: Success
# - 1: Failure (e.g., missing dependencies, errors during execution)
#
# Dependencies:
# - terraform-docs: https://terraform-docs.io/user-guide/installation/
# - jq: https://stedolan.github.io/jq/download/
#
# Usage Examples:
# ```bash
# # Check if terraform documentation needs updating:
# ./tf-docs-check.sh
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

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq could not be found."
  echo "Please install jq and ensure it is in your PATH."
  echo "Installation instructions for jq can be found at: https://stedolan.github.io/jq/download/."
  echo
  exit 1
fi

# Run the script to update all TF auto-gen README.md files
echo "Running the script ./update-all-terraform-docs.sh ..."
error_output=$("$(dirname "$0")/update-all-terraform-docs.sh" 2>&1) || {
  exit_code=$?
  echo "Error executing update-all-terraform-docs.sh:"
  echo "$error_output"
  echo "Exit code: $exit_code"
  exit $exit_code
}

# Check for changes in README.md files
echo "Checking for changes in README.md files ..."
changed_files=$(git diff --name-only)
readme_changed=false
for file in $changed_files; do
    if [[ $file == src/*/README.md ]]; then
        if head -n 1 "$file" | grep -q "^<!-- BEGIN_TF_DOCS -->$"; then
        echo "Updates required for: ./$file"
        readme_changed=true
        fi
    fi
done
echo "README.md files checked."
echo $readme_changed
