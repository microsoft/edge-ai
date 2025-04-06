#!/usr/bin/env bash

# Folder Change Detection Script
#
# Purpose:
# This script detects changes in the repository's folders and files, providing a structured
# JSON output that identifies which components have been modified to help determine what
# needs to be tested or rebuilt.
#
# Functionality:
# - Detects changes in shell scripts (.sh) in the subscription setup folder
# - Detects changes in PowerShell scripts (.ps1) in the subscription setup folder
# - Identifies Terraform folders that contain modified files
# - Identifies Bicep folders that contain modified files
# - Optionally returns all folders containing Terraform and Bicep files, not just those with changes
# - Generates a structured JSON response with the results
#
# Parameters:
# - --include-all-folders: When provided, includes all folders that contain Terraform and Bicep files
# - --base-branch <branch>: The branch to compare against (default: origin/main)
#
# Dependencies:
# - git: For detecting changes between branches
# - jq: For JSON manipulation and formatting
#
# Exit Codes:
# - 0: Success
# - 1: Failure (e.g., missing dependencies, errors during execution)
#
# Output:
# A JSON object with the following structure:
# {
#   "subscription": {
#     "shell_changes": true|false,
#     "powershell_changes": true|false
#   },
#   "terraform": {
#     "has_changes": true|false,
#     "folders": { ... }
#   },
#   "bicep": {
#     "has_changes": true|false,
#     "folders": { ... }
#   }
# }
#
# Usage Examples:
# ```bash
# # Check only changed Terraform and Bicep folders:
# ./detect-folder-changes.sh
#
# # Include all Terraform and Bicep folders regardless of changes:
# ./detect-folder-changes.sh --include-all-folders
#
# # Compare against a different branch:
# ./detect-folder-changes.sh --base-branch origin/develop
# ```
#
# This script is primarily used by CI/CD workflows to determine which components
# need testing or deployment based on what files have changed in a pull request or commit.

set -e

# Parse command line arguments
INCLUDE_ALL_FOLDERS=
BASE_BRANCH="origin/main" # Default base branch

while [[ $# -gt 0 ]]; do
  case $1 in
  --include-all-folders)
    INCLUDE_ALL_FOLDERS="true"
    shift
    ;;
  --base-branch)
    BASE_BRANCH="$2"
    shift 2
    ;;
  *)
    echo "Unknown option: $1"
    echo "Usage: $0 [--include-all-folders] [--base-branch <branch>]"
    exit 1
    ;;
  esac
done

# Check for dependencies
if ! command -v git &>/dev/null; then
  echo "Error: git is not installed or not in PATH" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed or not in PATH" >&2
  exit 1
fi

# Initialize variables to track changes
SUBSCRIPTION_SHELL_CHANGES=false
SUBSCRIPTION_PWSH_CHANGES=false
TERRAFORM_HAS_CHANGES=false
TERRAFORM_FOLDERS="{}" # Initialize with an empty JSON object instead of "none"
BICEP_HAS_CHANGES=false
BICEP_FOLDERS="{}" # Initialize with an empty JSON object instead of "none"

# Check if shell files in subscription setup folder have changed
if echo "$changed_files" | grep -q 'src/000-subscription/.*\.sh$'; then
  SUBSCRIPTION_SHELL_CHANGES=true
fi

# Check if PowerShell files in subscription setup folder have changed
if echo "$changed_files" | grep -q 'src/000-subscription/.*\.ps1$'; then
  SUBSCRIPTION_PWSH_CHANGES=true
fi

extract_paths() {
  awk -F'/' '{
      if ($1 == "src")
        print $1"/"$2"/"$3;
      else if ($1 == "blueprints")
        print $1"/"$2;
    }' | sort -u
}

paths_to_json() {
  jq -R -s -c 'split("\n") |
      map(select(length > 0)) |
      map({key: ., value: {folderName: .}}) |
      from_entries'
}

# Function to process folders with specified file extensions
process_folders() {
  local file_extensions=("$@") # Multiple file extensions as arguments

  # Find only folders with changed specified file types
  local pattern
  IFS="|" pattern="${file_extensions[*]}"

  # Use more intelligent path extraction based on directory type
  grep -E "^(src|blueprints)/[^/]+/.*\.($pattern)$" |
    extract_paths |
    paths_to_json
}

find_all_files() {
  local file_extensions=("$@") # Multiple file extensions as arguments

  # Find all folders containing specified file types
  find_command="find src blueprints -type f \("

  # Build the find command with proper -name options for each extension
  for i in "${!file_extensions[@]}"; do
    if [ "$i" -gt 0 ]; then
      find_command+=" -o"
    fi
    find_command+=" -name \"*.${file_extensions[$i]}\""
  done

  # Close the find command and use awk to extract the correct path components
  find_command+=" \)"

  # Execute the command and process with jq
  eval "$find_command"
}

find_changed_files() {
  git diff --name-only --diff-filter=ACMRT "$BASE_BRANCH"...HEAD
}

get_changed_files() {
  if [[ $INCLUDE_ALL_FOLDERS ]]; then
    find_all_files "tf" "tfvars" "tfstate" "hcl" "bicep"
  else
    find_changed_files
  fi
}

changed_files=$(get_changed_files)

# Process Terraform and Bicep folders
changed_tf_folders=$(echo "$changed_files" | process_folders "tf" "tfvars" "tfstate" "hcl")
changed_bicep_folders=$(echo "$changed_files" | process_folders "bicep")

# Check if we found any Terraform folder changes
if [ "$(jq 'length' <<<"$changed_tf_folders")" -ne 0 ]; then
  TERRAFORM_HAS_CHANGES=true
  TERRAFORM_FOLDERS="$changed_tf_folders"
fi

# Check if we found any Bicep folder changes
if [ "$(jq 'length' <<<"$changed_bicep_folders")" -ne 0 ]; then
  BICEP_HAS_CHANGES=true
  BICEP_FOLDERS="$changed_bicep_folders"
fi

# Create the final JSON output
json_output=$(jq -n \
  --arg shell_changes "$SUBSCRIPTION_SHELL_CHANGES" \
  --arg pwsh_changes "$SUBSCRIPTION_PWSH_CHANGES" \
  --arg tf_has_changes "$TERRAFORM_HAS_CHANGES" \
  --argjson tf_folders "$TERRAFORM_FOLDERS" \
  --arg bicep_has_changes "$BICEP_HAS_CHANGES" \
  --argjson bicep_folders "$BICEP_FOLDERS" \
  '{
    "subscription": {
      "shell_changes": ($shell_changes == "true"),
      "powershell_changes": ($pwsh_changes == "true")
    },
    "terraform": {
      "has_changes": ($tf_has_changes == "true"),
      "folders": $tf_folders
    },
    "bicep": {
      "has_changes": ($bicep_has_changes == "true"),
      "folders": $bicep_folders
    }
  }')

# Output the JSON
echo "$json_output"

# Exit with success
exit 0
