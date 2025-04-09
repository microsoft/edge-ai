#!/usr/bin/env bash
# Bicep Docs Check Script
#
# Purpose:
# This script checks if the Bicep documentation is up-to-date with the code.
# It creates a temporary directory, runs the update-all-bicep-docs.sh script,
# and compares the generated docs with the existing ones to detect outdated documentation.
#
# Functionality:
# - Creates a temporary directory for checking changes
# - Copies update-all-bicep-docs.sh script to avoid modifying originals
# - Runs documentation generation in the temporary directory
# - Compares generated docs with existing ones
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
# - Azure CLI with Bicep extension
# - update-all-bicep-docs.sh script
#
# Usage Examples:
# ```bash
# # Check if Bicep documentation needs updating:
# ./bicep-docs-check.sh
# ```

set -e

# Check if Azure CLI is installed
if ! command -v az &>/dev/null; then
  echo "Azure CLI (az) could not be found."
  echo "Please install Azure CLI and ensure it is in your PATH."
  echo "Installation instructions can be found at: https://docs.microsoft.com/cli/azure/install-azure-cli"
  echo
  exit 1
fi

# Check if Bicep extension is installed
if ! az bicep version &>/dev/null; then
  echo "Installing Azure Bicep extension..."
  az bicep install
fi

# Run the script to update all Bicep auto-gen README.md files
echo "Running the script ./update-all-bicep-docs.sh ..."
error_output=$("$(dirname "$0")/update-all-bicep-docs.sh" 2>&1) || {
  exit_code=$?
  echo "Error executing update-all-bicep-docs.sh:"
  echo "$error_output"
  echo "Exit code: $exit_code"
  exit $exit_code
}

echo "Checking for changes in README.md files ..."
changed_files=$(git diff --name-only)
docs_changed=false
for file in $changed_files; do
    if [[ $file == src/*/bicep/README.md || $file == blueprints/*/bicep/README.md ]]; then
        if head -n 1 "$file" | grep -q "^<!-- <!-- BEGIN_BICEP_DOCS --> -->$"; then
        echo "Updates required for: ./$file"
        docs_changed=true
        fi
    fi
done
echo "README.md files checked."
echo $docs_changed
