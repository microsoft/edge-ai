#!/bin/bash
# Terraform Docs Installation Script
#
# Purpose:
# This script installs terraform-docs and checks for new versions. It can be used to manage
# terraform-docs installation and versioning for local development or CI/CD pipelines.
#
# Functionality:
# - Installs terraform-docs at a specified version
# - Checks for latest version via GitHub API
# - Shows warnings when a newer version is available
# - Detects system architecture automatically
#
# Parameters:
# - -v version: Specify terraform-docs version (default: v0.20.0)
# - -h: Display help message
#
# Output Variables:
# - None
#
# Exit Codes:
# - 0: Success
# - 1: Failure (e.g., unsupported architecture, download failures)
#
# Dependencies:
# - curl: Used for downloading files and API requests
#
# Usage Examples:
# ```bash
# # Install default version:
# ./install-terraform-docs.sh
#
# # Install specific version:
# ./install-terraform-docs.sh -v v0.20.0
#
# # Show help:
# ./install-terraform-docs.sh -h
# ```

# Default values
DEFAULT_VERSION="v0.20.0"
VERSION="$DEFAULT_VERSION"

# Function to display usage information
usage() {
  echo "Usage: $0 [-v version] [-h]"
  echo "  -v version  Specify terraform-docs version (default: $DEFAULT_VERSION)"
  echo "  -h          Display this help message"
  exit 1
}

# Function to compare semantic versions
# Returns:
#   0 if version1 = version2
#   1 if version1 > version2
#   2 if version1 < version2
compare_versions() {
  # Strip the 'v' prefix if present
  local v1="${1#v}"
  local v2="${2#v}"

  # Extract major, minor, patch components
  local IFS=.
  read -ra ver1 <<<"$v1"
  read -ra ver2 <<<"$v2"

  # Fill empty fields with zeros
  for ((i=${#ver1[@]}; i<3; i++)); do
    ver1[i]=0
  done
  for ((i=${#ver2[@]}; i<3; i++)); do
    ver2[i]=0
  done

  # Compare major, minor, and patch versions
  for ((i=0; i<3; i++)); do
    if [[ -z ${ver1[i]} ]]; then
      ver1[i]=0
    fi
    if [[ -z ${ver2[i]} ]]; then
      ver2[i]=0
    fi
    # Clean input and ensure they're valid integers
    v1_num=${ver1[i]//[^0-9]/}
    v2_num=${ver2[i]//[^0-9]/}

    v1_num=${v1_num:-0}
    v2_num=${v2_num:-0}

    if [[ $v1_num -gt $v2_num ]]; then
      return 1
    fi
    if [[ $v1_num -lt $v2_num ]]; then
      return 2
    fi
  done

  # Versions are equal
  return 0
}

# Function to check if a version is newer than another
# Returns:
#   0 if version1 is newer than version2
#   1 if version1 is not newer than version2
is_newer_version() {
  compare_versions "$1" "$2"
  local result=$?

  if [[ $result -eq 1 ]]; then
    return 0  # version1 is newer
  else
    return 1  # version1 is not newer
  fi
}

# Parse command line options
while getopts "v:h" opt; do
  case $opt in
    v) VERSION="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

echo "Using terraform-docs version: $VERSION"

# Check for latest terraform-docs version and compare with specified version
echo "Checking for latest terraform-docs version..."
# Use GitHub API to get the latest release version
LATEST_VERSION=$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$')

echo "Latest version: $LATEST_VERSION"
echo "Specified version: $VERSION"

# Compare versions using semantic versioning
if is_newer_version "$LATEST_VERSION" "$VERSION"; then
  echo "##vso[task.logissue type=warning]A newer version of terraform-docs is available: $LATEST_VERSION (currently using $VERSION). Consider updating the terraformDocsVersion parameter."
else
  echo "Using the latest version of terraform-docs: $VERSION"
fi

# Check if terraform-docs is already installed
if command -v terraform-docs &> /dev/null; then
  echo "terraform-docs is already installed"
  INSTALLED_VERSION=$(terraform-docs --version | head -n 1 | cut -d ' ' -f 3)
  echo "Installed version: $INSTALLED_VERSION"

  # Check if specified version is newer than installed version
  if [[ "$INSTALLED_VERSION" != "$VERSION" ]]; then
    if is_newer_version "$VERSION" "$INSTALLED_VERSION"; then
      echo "Specified version ($VERSION) is newer than installed version ($INSTALLED_VERSION). Updating..."
    else
      echo "Specified version ($VERSION) is different from installed version ($INSTALLED_VERSION). Changing version..."
    fi

    # Detect architecture for update
    ARCH=$(uname -m)
    case $ARCH in
      x86_64|amd64)
        TERRAFORM_DOCS_ARCH="amd64"
        ;;
      aarch64|arm64)
        TERRAFORM_DOCS_ARCH="arm64"
        ;;
      *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
    esac

    # Download and install the specified version
    echo "Installing terraform-docs for $TERRAFORM_DOCS_ARCH architecture..."
    curl -Lo ./terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/$VERSION/terraform-docs-$VERSION-$(uname)-$TERRAFORM_DOCS_ARCH.tar.gz"
    tar -xzf terraform-docs.tar.gz
    chmod +x terraform-docs
    sudo mv terraform-docs /usr/local/bin/
    echo "terraform-docs has been updated to version $VERSION"
  else
    echo "Already using the requested version of terraform-docs: $INSTALLED_VERSION"
  fi
else
  echo "terraform-docs not found. Installing..."
  # Detect architecture
  ARCH=$(uname -m)
  case $ARCH in
    x86_64|amd64)
      TERRAFORM_DOCS_ARCH="amd64"
      ;;
    aarch64|arm64)
      TERRAFORM_DOCS_ARCH="arm64"
      ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac

  # Install terraform-docs (using the specified version)
  echo "Installing terraform-docs for $TERRAFORM_DOCS_ARCH architecture..."
  curl -Lo ./terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/$VERSION/terraform-docs-$VERSION-$(uname)-$TERRAFORM_DOCS_ARCH.tar.gz"
  tar -xzf terraform-docs.tar.gz
  chmod +x terraform-docs
  sudo mv terraform-docs /usr/local/bin/
fi
