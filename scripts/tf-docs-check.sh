#!/usr/bin/env bash

# This script checks if terraform-docs is installed and then
# runs the ./src/update-all-terraform-docs.sh script. It
# returns a boolean value to indicate if README.md files
# have changed after running the auto-docs-gen. The intent
# is that the build/ci system calls this script and contributors
# would call the ./src/update-all-terraform-docs.sh script
# directly.

# Check if terraform-docs and jq are installed
if ! command -v terraform-docs &> /dev/null; then
  echo "terraform-docs not found. Please download and install terraform-docs from https://terraform-docs.io/user-guide/installation/."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "jq not found. Please download and install jq from https://stedolan.github.io/jq/download/."
  exit 1
fi

# Run the script to update all TF auto-gen README.md files
echo "Running the script ./src/update-all-terraform-docs.sh ..."
./src/update-all-terraform-docs.sh

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
