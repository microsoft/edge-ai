#!/bin/bash
# -----------------------------------------------------------------------------
# Bicep Documentation Generator Script
# -----------------------------------------------------------------------------
#
# This script automates the process of generating documentation for Bicep modules:
# 1. Finds all main.bicep files in the specified directories (./src and ./blueprints by default)
# 2. Builds each main.bicep file to a temporary ARM JSON file in folder .arm, which is created and then deleted
# 3. Generates documentation using the generate-bicep-docs.py script
# 4. Places the generated README.md files in the same directories as the original Bicep files
#
# Dependencies:
#   - Azure CLI (az) with bicep extension
#   - Python 3.x with generate-bicep-docs.py script
#
# Usage:
#   ./update-all-bicep-docs.sh [directory1 directory2 ...]
#
# Example:
#   ./update-all-bicep-docs.sh
#   ./update-all-bicep-docs.sh ./src
#
# Exit Codes:
#   0 - Success
#   1 - Failure (e.g., missing dependencies, errors during execution)
# -----------------------------------------------------------------------------

set -e

# Default directories to search if none provided
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
DEFAULT_DIRS=("$repo_root/src" "$repo_root/blueprints")

# Use provided directories or defaults
if [ $# -eq 0 ]; then
    DIRS=("${DEFAULT_DIRS[@]}")
else
    DIRS=("$@")
fi

# Path to the generate-bicep-docs.py script
python_script_path="${python_script_path:-$script_dir/generate-bicep-docs.py}"

# Check if the Python script exists
if [ ! -f "$python_script_path" ]; then
    echo "Error: Documentation generator script not found at $python_script_path"
    exit 1
fi

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI (az) is not installed. Please install it first."
    exit 1
fi

# Check if bicep extension is installed
if ! az bicep version &> /dev/null; then
    echo "Installing Azure Bicep extension..."
    az bicep install
fi

# Function to create parent directories if they don't exist
create_directories() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Function to get the absolute path of a file
get_absolute_path() {
    local path="$1"
    echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
}

# Create a centralized .arm directory at the root of the repository
ROOT_ARM_DIR="$repo_root/.arm"
create_directories "$ROOT_ARM_DIR"

# Counters for summary
total_files=0
successful_files=0
failed_files=0

# Process each directory
for dir in "${DIRS[@]}"; do
    echo "Searching for main.bicep files in: $dir"

    # Find all main.bicep files, but exclude any in /ci/bicep folders
    while IFS= read -r bicep_file; do
        # Skip if this is in a /ci/bicep path
        if [[ "$bicep_file" == *"/ci/bicep/"* ]]; then
            echo "Skipping CI Bicep file: $bicep_file"
            continue
        fi

        # Convert to absolute path
        absolute_bicep_file=$(get_absolute_path "$bicep_file")
        echo "Processing: $absolute_bicep_file"
        total_files=$((total_files + 1))

        # Get directory path and filename
        bicep_dir=$(dirname "$absolute_bicep_file")
        bicep_name=$(basename "$absolute_bicep_file" .bicep)

        # Create a path in .arm directory that mirrors the structure relative to repo_root
        relative_to_repo=${bicep_dir#"$repo_root"/}
        arm_dir="$ROOT_ARM_DIR/$relative_to_repo"
        create_directories "$arm_dir"

        # Destination ARM JSON file
        json_file="$arm_dir/$bicep_name.json"

        # Output README file will be in the same directory as the original bicep file
        readme_file="$bicep_dir/README.md"

        # Build the Bicep file to ARM JSON
        if az bicep build --file "$absolute_bicep_file" --outfile "$json_file" --no-restore; then
           echo "✅ Successfully built ARM template: $json_file"

            # Generate documentation using the Python script
            if python3 "$python_script_path" "$json_file" "$readme_file" --modules-nesting-level 1; then
                successful_files=$((successful_files + 1))
            else
                echo "❌ Failed to generate documentation for: $absolute_bicep_file"
                failed_files=$((failed_files + 1))
            fi
        else
            echo "❌ Failed to build ARM template for: $absolute_bicep_file"
            failed_files=$((failed_files + 1))
        fi

        echo "-----------------------------------"
    done < <(find "$dir" -name "main.bicep" -type f)
done

# Print summary
echo "======================================"
echo "Documentation Generation Summary"
echo "======================================"
echo "Total Bicep files processed: $total_files"
echo "✅ Successfully documented: $successful_files"
if [ $failed_files -gt 0 ]; then
    echo "❌ Failed to document: $failed_files"
else
    echo "✅ All files successfully documented"
fi
echo "======================================"
echo "⚠️  Before you commit!"
echo "    Please run 'npm run mdlint-fix' to fix any markdown linting issues by the generated markdown content."
echo "======================================"

# Cleanup: Remove the temporary .arm directory
echo "Cleaning up temporary files..."
if [ -d "$ROOT_ARM_DIR" ]; then
    rm -rf "$ROOT_ARM_DIR"
    echo "✅ Removed temporary directory: $ROOT_ARM_DIR"
else
    echo "⚠️ Temporary directory not found: $ROOT_ARM_DIR"
fi

# Return appropriate exit code
if [ $failed_files -gt 0 ]; then
    echo "Some files failed to process. Please check the logs above."
    exit 1
else
    echo "All files processed successfully."
    exit 0
fi