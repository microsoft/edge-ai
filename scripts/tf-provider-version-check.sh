#!/usr/bin/env bash
# Terraform Provider Version Check Script
#
# Purpose:
# This script checks the provider versions in the Terraform configuration files in the
# specified folder or all folders and compares them with the latest versions available in the
# Terraform registry. It outputs any mismatches found and is useful for build systems to
# ensure that the most recent released versions of providers are being used.
#
# Functionality:
# - Searches for provider configurations in Terraform files
# - Compares configured provider versions with latest available versions
# - Reports outdated provider versions
# - Can check a specific folder or all Terraform folders
#
# Parameters:
# - -a: Run check on all terraform folders under src/
# - -f <folder_path>: Run check on a specific folder path
#
# Output Variables:
# - JSON output of version mismatches for build reporting
#
# Exit Codes:
# - 0: Success
# - 1: Failure (e.g., missing dependencies, errors during execution)
#
# Dependencies:
# - terraform: https://developer.hashicorp.com/terraform/install
# - jq: https://stedolan.github.io/jq/download/
#
# Usage Examples:
# ```bash
# # Check all terraform folders:
# ./tf-provider-version-check.sh -a
#
# # Check a specific folder:
# ./tf-provider-version-check.sh -f ./src/030-iot-ops-cloud-reqs/terraform
# ```

set -e

usage() { echo "$0 usage:" && grep " .)\ #" "$0"; exit 0; }

# Function to check if terraform-cli is installed
check_dependency_install_status() {
    if ! command -v terraform &> /dev/null; then
        echo "terraform-cli not found."
        echo "Please install terraform-cli and ensure it is in your PATH."
        echo "Installation instructions for terraform-cli can be found at: https://developer.hashicorp.com/terraform/install"
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
}

check_provider_versions_in_folder() {
    local folder=$1
    # echo "Checking provider versions in folder: $folder"

    # Change to the folder being passed in
    pushd "$folder" > /dev/null || exit 1

    # Run terraform init (calculate elapsed time)
    # echo "executing terraform init"
    terraform init -input=false -no-color > /dev/null
    # echo "terraform init completed"

    # Call TF version command and parse the output
    # echo "Provider Data: $provider_data"
    provider_data=$(terraform providers)

    # Parse the provider data and build an array to check for updates
    # This section will parse the provider subobject and extract the provider name
    # and version.
    # Returned result of providers call:
    #
    # Providers required by configuration:
    # .
    # ├── provider[registry.terraform.io/azure/azapi] >= 2.2.0
    # ├── provider[registry.terraform.io/hashicorp/azurerm] >= 4.8.0
    # ├── provider[registry.terraform.io/hashicorp/azuread] >= 3.0.2
    # ├── test.tests.iot-ops-cloud-reqs
    # │   └── run.setup_tests
    # │       └── provider[registry.terraform.io/hashicorp/random] >= 3.5.1
    # ├── module.schema_registry
    # │   ├── provider[registry.terraform.io/hashicorp/random]
    # │   ├── provider[registry.terraform.io/hashicorp/azurerm]
    # │   └── provider[registry.terraform.io/azure/azapi]
    # ├── module.sse_key_vault
    # │   └── provider[registry.terraform.io/hashicorp/azurerm]
    # └── module.uami
    #     └── provider[registry.terraform.io/hashicorp/azurerm]
    # This will create the final space delimited tuple array, shaped like:
    #     [
    #       (registry.terraform.io/hashicorp/azurerm 4.8.0),
    #       (registry.terraform.io/hashicorp/azuread 3.0.2),
    #       (registry.terraform.io/azure/azapi 2.2.0),
    #       (registry.terraform.io/hashicorp/random 3.5.1)
    #     ]
    provider_details=$(echo "$provider_data" | \
    # Extract lines where there are any characters up to 'provider'
    # and get the rest of the string
    sed -nE 's/.*provider\[([^]]+)][^[:digit:]]+([[:digit:].]+)/\1 \2/p')
    # echo "Provider Details: $provider_details"

    # Loop through the provider details and check for updates
    # by calling the tf registry API and comparing the versions
    while IFS= read -r line; do

        # Check if the pipeline is canceled, and exit if so
        if [ "$AGENT_JOBSTATUS" = "Canceled" ]; then
            echo "Pipeline is canceled. Exiting..."
            exit 0
        fi

        # Slice the provider details into registry, source, provider, and version
        # [registry.terraform.io] / [hashicorp] / [azurerm] [4.8.0]
        registry=$(echo "$line" | awk -F'/' '{print $1}')
        source=$(echo "$line" | awk -F'/' '{print $2}')
        provider=$(echo "$line" | awk -F'/' '{print $3}' | awk '{print $1}')
        version=$(echo "$line" | awk '{print $2}')

        # Check if the provider is in checked_providers based on
        # provider name. If it is in the checked_providers array and the
        # version data is equal, skip the provider If it is not, then check
        # to see if the provider version is less than the latest version
        # available in the checked_providers array. If it is less than the
        # latest version available, then add the provider to the version_error_tracking_array
        # Check if the provider is in checked_providers based on provider name
        provider_in_checked=false

        echo "Checking status of provider: $provider"
        # echo "Checked providers: ${checked_providers[*]}"

        # Loop through checked_providers array to check if the provider has already been checked
        for checked_providers_entry in "${checked_providers[@]}"; do

            # Set the checked_provider and checked_latest_version
            checked_provider=$(echo "$checked_providers_entry" | cut -d',' -f1)
            checked_provider_latest_version=$(echo "$checked_providers_entry" | cut -d',' -f2)

            if [[ "$checked_provider" == "$provider" ]]; then
                provider_in_checked=true

                # If the provider version is equal to the checked_provider's latest_version, skip the provider
                if [ "$version" == "$checked_provider_latest_version" ]; then
                    echo "Provider: $provider is up to date"
                    continue
                # If the provider version is less than the checked_provider's latest_version, add to version_error_tracking_array
                elif [ "$(printf '%s\n' "$version" "$checked_provider_latest_version" | sort -V | head -n 1)" == "$version" ]; then
                    echo "Version mismatch. Provider: $provider is outdated, target version: $checked_provider_latest_version, current version: $version"
                    version_error_tracking_array+=("$folder,$provider,$version,$checked_provider_latest_version")
                fi
            fi
        done

        if ! $provider_in_checked; then
            echo "Connecting to remote to collect details for provider: $provider"
            url="https://$registry/v1/providers/$source/$provider/versions"
            response=$(curl -s "$url")
            # Check versions
            latest_version=$(echo "$response" | jq -r '.versions[].version' | sort -V | tail -n 1)

            if [ "$(printf '%s\n' "$version" "$latest_version" | sort -V | tail -n 1)" != "$version" ]; then
                # Log a build warning if the provider version is outdated
                echo "$provider is out of date. Declared version is $version, Latest version is $latest_version."
                version_error_tracking_array+=("$folder,$provider,$version,$latest_version")
            fi

            # Add to checked_providers if unique
            echo "Adding provider: $provider to checked_providers with version: $latest_version"
            checked_providers+=("$provider,$latest_version")
        fi
    done <<< "$provider_details"
    # echo "Tracking array: ${version_error_tracking_array[*]}"
    popd > /dev/null || exit 1
}

# Establish a tracking array to store the provider version data
version_error_tracking_array=()
checked_providers=()

# Parse command line arguments
run_all=false
specific_folder=""

while getopts "af:" opt; do
  case $opt in
    a) # Run Terraform provider version check in all folders
      run_all=true
      ;;
    f) # Run Terraform provider version check on a specific folder, e.g. `./src/030-iot-ops-cloud-reqs/terraform`
      specific_folder=$OPTARG
      ;;
    *)
      echo "Usage: $0 [-a] [-f folder]"
      exit 1
      ;;
  esac
done

# Check if terraform CLI is installed
check_dependency_install_status

# Run in specified folder or all folders
if [ "$run_all" = true ]; then
    top_level_tf_folders=$(find src -mindepth 1 -maxdepth 1 -type d -exec test -d "{}/terraform" \; -print)
    for folder in $top_level_tf_folders; do
        if [ -d "./$folder/terraform" ]; then
            check_provider_versions_in_folder "./$folder/terraform"
        fi
    done
elif [ -n "$specific_folder" ]; then
    if [ -d "./$specific_folder" ]; then
        check_provider_versions_in_folder "./$specific_folder"
    else
        echo "Specified folder does not exist: $specific_folder"
        exit 1
    fi
else
    echo "Usage: $0 [-a] [-f folder]"
    exit 1
fi

# Join the array elements with newlines and pass to jq
# to format the output as JSON for the build
printf "%s\n" "${version_error_tracking_array[@]}" | jq -R -s '
  split("\n") |
  map(select(length > 0)) |
  map(split(",")) |
  map({folder: .[0], provider: .[1], current_version: .[2], latest_version: .[3]})
'
