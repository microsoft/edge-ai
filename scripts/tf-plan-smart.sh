#!/bin/bash

# tf-plan-smart.sh - Smart terraform plan that only passes declared variables
# Usage: tf-plan-smart.sh [additional terraform plan flags]
#
# This script checks which variables are declared in variables.tf and only
# passes those variables to terraform plan, avoiding "undeclared variable" errors.

set -e

# Default variable values
declare -A DEFAULT_VARS=(
    ["environment"]="prod"
    ["resource_prefix"]="build"
    ["location"]="westus"
)

# Check if variables.tf exists
if [ ! -f "variables.tf" ]; then
    echo "No variables.tf found in current directory, running terraform plan without variables"
    # shellcheck disable=SC2068
    terraform plan $@
    exit $?
fi

# Extract declared variable names from variables.tf
DECLARED_VARS=()
while IFS= read -r var_name; do
    DECLARED_VARS+=("$var_name")
done < <(grep -oE 'variable\s+"[^"]+"' variables.tf | grep -oE '"[^"]+"' | tr -d '"')

if [ ${#DECLARED_VARS[@]} -eq 0 ]; then
    echo "No variables declared in variables.tf, running terraform plan without variables"
    # shellcheck disable=SC2068
    terraform plan $@
    exit $?
fi

# Build array of terraform plan arguments
PLAN_ARGS=()

for var_name in "${DECLARED_VARS[@]}"; do
    # Check if this variable has a default value defined
    if [ -v "DEFAULT_VARS[$var_name]" ]; then
        PLAN_ARGS+=("-var")
        PLAN_ARGS+=("${var_name}=${DEFAULT_VARS[$var_name]}")
    fi
done

# Add additional flags from command line arguments
for arg in "$@"; do
    PLAN_ARGS+=("$arg")
done

echo "Running ${PLAN_ARGS[*]}"

# Execute the plan command
terraform plan "${PLAN_ARGS[@]}"
