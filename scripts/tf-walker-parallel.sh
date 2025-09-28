#!/bin/bash

# tf-walker-parallel.sh - Walk through terraform directories and execute commands in parallel
# Usage: tf-walker-parallel.sh "command to execute" [out_folder] [need_auth] [max_jobs]

set -e

# Parse arguments
cmd="$1"
out_folder="${2:-tf-walker-$(date +%Y%m%d-%H%M%S)}"
need_auth="${3:-false}"
max_jobs="${4:-4}"  # Default to 4 parallel jobs (may need to determine based on user's cpu count)

if [ -z "$cmd" ]; then
    echo "Usage: tf-walker-parallel.sh \"command to execute\" [out_folder] [need_auth] [max_jobs]"
    echo "Example: tf-walker-parallel.sh \"terraform init; terraform test\" \"test-run-1\" true"
    exit 1
fi

temp_dir="$(pwd)/out/$out_folder"
mkdir -p "$temp_dir"

# Cleanup function for trap
cleanup() {
    echo
    echo "Interrupted. Cleaning up..."

    # Kill all background jobs
    if [ -n "$(jobs -p)" ]; then
        echo "Terminating background processes..."
        # shellcheck disable=SC2046
        kill $(jobs -p) 2>/dev/null || true
        wait 2>/dev/null || true
    fi

    # Kill any parallel or xargs processes
    pkill -P $$ 2>/dev/null || true

    # Remove temp directory
    if [ -d "$temp_dir" ]; then
        echo "Removing temporary directory: $temp_dir"
        rm -rf "$temp_dir"
    fi

    exit 130
}

trap cleanup INT TERM

# Authenticate if needed
if [ "$need_auth" = "true" ]; then
    echo "Authenticating with Azure..."
    # Save current arguments to avoid passing them to az-sub-init.sh
    saved_args=("$@")
    set --  # Clear arguments
    # shellcheck source=/dev/null
    source ./scripts/az-sub-init.sh
    set -- "${saved_args[@]}"  # Restore arguments
fi

# Find all terraform directories
echo "Searching for terraform directories..."
terraform_dirs=()
while IFS= read -r dir; do
    # Check if directory contains .tf files
    if ls "$dir"/*.tf >/dev/null 2>&1; then
        terraform_dirs+=("$dir")
    else
        echo "Skipping $dir (no .tf files found)"
    fi
done < <(find blueprints src -name "terraform" -type d 2>/dev/null)

if [ ${#terraform_dirs[@]} -eq 0 ]; then
    echo "No terraform directories found."
    exit 0
fi

echo "Found ${#terraform_dirs[@]} terraform directories to process"
echo "Running with max $max_jobs parallel jobs..."
echo "Output will be saved to: $temp_dir"
echo ""

# Function to execute command in a directory
execute_command() {
    local dir="$1"
    local cmd="$2"
    local output_file="$3"
    local temp_file="$output_file.tmp"
    local start_time
    start_time=$(date +%s)

    echo "📋 $dir" > "$temp_file"

    if ! cd "$dir"; then
        {
          echo ""
          echo "Could not change to directory $dir"
          echo ""
          echo "❌ Failed $dir"
        } >> "$temp_file"
        return 1
    fi

    local msg=""
    local result=0
    if eval "$cmd" >> "$temp_file" 2>&1; then
      msg="✅ Completed"
      result=0
    else
      msg="❌ Failed"
      result=1
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    {
      echo ""
      echo "$msg $dir (${duration}s)"
    } >> "$temp_file"

    mv "$temp_file" "$output_file"

    cd - >/dev/null
    return "$result"
}

# Function to process a single directory
process_directory() {
    local dir="$1"
    local cmd="$2"

    # Create unique output files for this directory
    local dir_safe
    dir_safe=$(echo "$dir" | tr '/' '_')
    local output_file="$temp_dir/output_$dir_safe"
    local error_file="$temp_dir/error_$dir_safe"

    echo "🚀 Processing $dir"

    # Execute command and capture result
    result=0
    if ! execute_command "$dir" "$cmd" "$output_file"; then
        cp "$output_file" "$error_file"
        result=1
    fi

    cat "$output_file"

    return "$result"
}

# Export functions and variables so they're available to parallel processes
export -f execute_command
export -f process_directory
export temp_dir

# Track overall success
overall_success=true

# Use GNU parallel if available, otherwise use xargs with optimized command line
if command -v parallel >/dev/null 2>&1; then
    echo "Using GNU parallel for processing..."
    if ! printf '%s\n' "${terraform_dirs[@]}" | parallel -j "$max_jobs" --line-buffer process_directory {} "$cmd"; then
        overall_success=false
    fi
else
    echo "Using xargs for parallel processing..."
    if ! printf '%s\n' "${terraform_dirs[@]}" | xargs -I {} -P "$max_jobs" bash -c "process_directory \"{}\" \"$cmd\""; then
        overall_success=false
    fi
fi

echo ""
echo "=== Finished processing terraform directories ==="
echo ""

# Check for any error files and print them out again
if ls "$temp_dir"/error_* >/dev/null 2>&1; then
    overall_success=false
    echo "❗ The following directories failed:"

    for error_file in "$temp_dir"/error_*; do
        cat "$error_file"
    done
else
    echo "🎉 All directories completed successfully!"
fi

echo "Cleaning up temporary files..."
rm -rf "$temp_dir"

echo ""
echo "Completed processing terraform directories"

if [ "$overall_success" = "false" ]; then
    exit 1
fi
