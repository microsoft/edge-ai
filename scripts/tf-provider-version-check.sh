#!/usr/bin/env bash

usage() { echo "$0 usage:" && grep " .)\ #" "$0"; exit 0; }

# Function to check if terraform-cli is installed
check_terraform_install() {
    if ! command -v terraform &> /dev/null; then
      echo "terraform-cli not found; please download and install the"
      echo "terraform cli from https://developer.hashicorp.com/terraform/install"
      exit 1
    else
      echo "terraform-cli is installed. Continuing ..."
    fi
}

check_provider_versions_in_folder() {
    local folder=$1
    echo "Checking provider versions in folder: $folder"

    # Change to the folder being passed in
    pushd "$folder" > /dev/null || exit 1

    # Run terraform init (calculate elapsed time)
    echo "executing terraform init"
    terraform init -input=false -no-color > /dev/null

    # Call TF version command and parse the output
    version_data=$(terraform version -json)
    echo "$version_data" | jq .

    # Parse the provider selections and build an array to check for updates
    # This section will parse the provider subobject and extract the provider name
    # and version.
    # example object:
    # {
    #  "terraform_version": "1.10.5",
    #  "platform": "linux_amd64",
    #  "provider_selections": {
    #    "registry.terraform.io/hashicorp/azuread": "3.1.0",
    #    "registry.terraform.io/hashicorp/azurerm": "4.16.0",
    #    "registry.terraform.io/hashicorp/random": "3.6.3"
    #  },
    #  "terraform_outdated": false
    # }
    provider_details=$(echo "$version_data" | jq -r '
        .provider_selections |
          to_entries[] |
          "\(.key | split("/") | .[0]) \(.key | split("/") | .[1]) \(.key | split("/") | .[2]) \(.value)"
        ')

    # Loop through the provider details and check for updates
    # by calling the tf registry API and comparing the versions
    while IFS= read -r line; do

        # Check if the pipeline is canceled, and exit if so
        if [ "$AGENT_JOBSTATUS" = "Canceled" ]; then
            echo "Pipeline is canceled. Exiting..."
            exit 0
        fi

        registry=$(echo "$line" | awk '{print $1}')
        source=$(echo "$line" | awk '{print $2}')
        provider=$(echo "$line" | awk '{print $3}')
        version=$(echo "$line" | awk '{print $4}')

        # Check if the provider is in checked_providers based on
        # provider name. If it is in the checked_providers array and the
        # version data is equal, skip the provider If it is not, then check
        # to see if the provider version is less than the latest version
        # available in the checked_providers array. If it is less than the
        # latest version available, then add the provider to the version_error_tracking_array
        # Check if the provider is in checked_providers based on provider name
        provider_in_checked=false

        echo "Checking status of provider: $provider"
        #echo "Checked providers: ${checked_providers[*]}"

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
                    continue 2  # Continue the while loop

                # If the provider version is less than the checked_provider's latest_version, add to version_error_tracking_array
                elif [ "$(printf '%s\n' "$version" "$checked_provider_latest_version" | sort -V | head -n 1)" == "$version" ]; then
                    echo "Version mismatch. Provider: $provider is outdated, target version: $checked_provider_latest_version, current version: $version"
                    version_error_tracking_array+=("$folder,$provider,$version,$latest_version")
                fi
            fi
        done


        url="https://$registry/v1/providers/$source/$provider/versions"
        echo "Checking provider: $provider as it has not yet been checked"
        response=$(curl -s "$url")
        # Check versions
        latest_version=$(echo "$response" | jq -r '.versions[].version' | sort -V | tail -n 1)

        if [ "$(printf '%s\n' "$version" "$latest_version" | sort -V | tail -n 1)" != "$version" ]; then
          # Log a build warning if the provider version is outdated
          version_error_tracking_array+=("$folder,$provider,$version,$latest_version")
        fi

        # Add to checked_providers if unique
        if ! $provider_in_checked; then
            echo "Adding provider: $provider to checked_providers with version: $latest_version"
            checked_providers+=("$provider,$latest_version")
        fi
    done <<< "$provider_details"
    # echo "Tracking array: ${version_error_tracking_array[*]}"
    popd || exit 1
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
check_terraform_install

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

# Pass the tracking array to jq to format the output
echo "${version_error_tracking_array[@]}" | jq -r .
