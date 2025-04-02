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
# - -v version: Specify terraform-docs version (default: v0.16.0)
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
# ./install-terraform-docs.sh -v v0.16.0
#
# # Show help:
# ./install-terraform-docs.sh -h
# ```

# Default values
DEFAULT_VERSION="v0.16.0"
VERSION="$DEFAULT_VERSION"

# Function to display usage information
usage() {
  echo "Usage: $0 [-v version] [-h]"
  echo "  -v version  Specify terraform-docs version (default: $DEFAULT_VERSION)"
  echo "  -h          Display this help message"
  exit 1
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

# Compare versions - using simple string comparison, since terraform-docs uses vX.Y.Z format
if [ "$LATEST_VERSION" != "$VERSION" ]; then
  echo "##vso[task.logissue type=warning]A newer version of terraform-docs is available: $LATEST_VERSION (currently using $VERSION). Consider updating the terraformDocsVersion parameter."
else
  echo "Using the latest version of terraform-docs: $VERSION"
fi

# Check if terraform-docs is already installed
if ! command -v terraform-docs &> /dev/null; then
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
else
  echo "terraform-docs is already installed"
  terraform-docs --version
fi
