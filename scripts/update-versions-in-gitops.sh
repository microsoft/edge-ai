#!/bin/bash

# Usage: ./update-versions.sh <environment> <ACR_NAME> <ACR_RESOURCE_GROUP> [repo_root] [environments_dir]
# Updates kustomization.yaml image tags in the specified environment to the latest semver tag from Azure Container Registry (ACR)

if [ $# -lt 3 ]; then
  echo "Usage: $0 <environment> <ACR_NAME> <ACR_RESOURCE_GROUP> [repo_root] [environments_dir]"
  exit 1
fi

ENV="$1"
ACR_NAME="$2"
ACR_RESOURCE_GROUP="$3"
REPO_ROOT="${4:-.}"
ENVIRONMENTS_DIR="${5:-environments}"
KUSTOMIZATION="$REPO_ROOT/$ENVIRONMENTS_DIR/$ENV/kustomization.yaml"

if [ ! -f "$KUSTOMIZATION" ]; then
  echo "File not found: $KUSTOMIZATION"
  exit 1
fi

# Extract registry from the first image entry and remove domain/host to get the ACR_NAME part
REGISTRY=$(grep 'newName:' "$KUSTOMIZATION" | head -n1 | awk '{print $2}' | cut -d'/' -f1 | sed 's/\.azurecr\.io$//')

if [ -z "$REGISTRY" ]; then
  echo "Could not determine Docker registry from $KUSTOMIZATION"
  exit 1
fi

if ! az account show >/dev/null; then
  echo "Azure CLI is not logged in. Please log in using 'az login' or ensure the pipeline has access."
  exit 1
fi

# Assume Azure CLI is already logged in via the Azure DevOps service connection (AzureCLI@2)
echo "Using existing Azure CLI login context (service connection). Verifying access to ACR '$ACR_NAME'..."
if ! az acr show -n "${ACR_NAME}" -g "${ACR_RESOURCE_GROUP}" >/dev/null; then
  echo "Failed to access ACR '$ACR_NAME' in resource group '$ACR_RESOURCE_GROUP'. Ensure the service connection has permissions."
  exit 1
fi

update_tag() {
  local image_name="$1"
  local acr_repo="$2"
  local tags
  local latest_tag

  echo "Processing image: $image_name from repo: $acr_repo"

  # Only update if acr_repo matches ACR_NAME
  if [[ "$REGISTRY" != "$ACR_NAME" ]]; then
    echo "Registry $REGISTRY does not match ACR_NAME $ACR_NAME, skipping $acr_repo."
    return
  fi

  # Fetch tags using az acr CLI
  tags=$(az acr repository show-tags -n "${ACR_NAME}" --repository "${acr_repo}" --orderby time_desc --output tsv)

  if [ -z "$tags" ]; then
    echo "Failed to fetch tags for $acr_repo"
    return
  fi

  echo "Fetched tags for $acr_repo: $tags"

  # Filter semver tags, sort, and get the latest
  latest_tag=$(echo "$tags" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
  if [ -n "$latest_tag" ]; then
    # Update the tag in the kustomization.yaml
    # Use portable sed -i behavior on GNU sed (ubuntu-latest). The pattern assumes structure:
    # - name: <image_name>\n    newName: ...\n    newTag: ...
    sed -i "/- name: $image_name/{n;n;s/^\s*newTag:.*/    newTag: \"$latest_tag\"/}" "$KUSTOMIZATION"
    echo "Updated $image_name to tag $latest_tag"
  else
    echo "No semver tag found for $acr_repo, skipping."
  fi
}

# For each image entry, update the tag
awk '/- name:/ {name=$3} /newName:/ {repo=$2; sub(/^[^\/]+\//, "", repo); print name, repo}' "$KUSTOMIZATION" | while read -r image repo; do
  echo "Updating image: $image from repo: $repo"
  update_tag "$image" "$repo"
done
