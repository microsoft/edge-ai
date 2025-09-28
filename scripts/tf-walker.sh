#!/bin/bash

# tf-walker.sh - Walk through terraform directories and execute commands
# Usage: tf-walker.sh "command to execute" [need_auth]

set -e

# Parse arguments
cmd="$1"
need_auth="${2:-false}"

if [ -z "$cmd" ]; then
    echo "Usage: tf-walker.sh \"command to execute\" [need_auth]"
    echo "Example: tf-walker.sh \"terraform init; terraform validate\" true"
    exit 1
fi

# Setup interrupt handling
trap 'echo; echo "Interrupted."; exit 130' INT TERM

# Authenticate if needed
if [ "$need_auth" = "true" ]; then
    echo "Authenticating with Azure..."
    # Save current arguments to avoid passing them to az-sub-init.sh
    saved_args=("$@")
    set --  # Clear arguments
    source ./scripts/az-sub-init.sh
    set -- "${saved_args[@]}"  # Restore arguments
fi

# Find all terraform directories and execute commands
echo "Searching for terraform directories..."
find blueprints src -name "terraform" -type d 2>/dev/null | while IFS= read -r dir; do
    # Check if directory contains .tf files
    if ls "$dir"/*.tf >/dev/null 2>&1; then
        echo ""
        echo "=== Processing $dir ==="

        # Change to directory and execute command
        if cd "$dir"; then
            eval "$cmd"
            cd - >/dev/null
        else
            echo "Error: Could not change to directory $dir"
            exit 1
        fi
    else
        echo "Skipping $dir (no .tf files found)"
    fi
done

echo ""
echo "Terraform walker completed successfully."
