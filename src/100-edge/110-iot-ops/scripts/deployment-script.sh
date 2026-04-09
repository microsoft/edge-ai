#!/user/bin/env bash

set -e

# Function to display script usage
usage() {
  echo "Usage: $0 [-h|--help]"
  echo ""
  echo "Gets deployment scripts from Azure Key Vault as secrets and executes them."
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help message and exit."
  echo ""
  echo "Environment Variables:"
  echo "  Required:"
  echo "    DEPLOY_KEY_VAULT_NAME       : Name of the Azure Key Vault containing deployment secrets."
  echo ""
  echo "  Optional (for Service Principal Login):"
  echo "    DEPLOY_SP_CLIENT_ID         : Client ID of the Service Principal."
  echo "    DEPLOY_SP_SECRET            : Client Secret of the Service Principal."
  echo "    DEPLOY_SP_TENANT_ID          : Tenant ID for the Service Principal."
  echo ""
  echo "  Optional (for Managed Identity Login):"
  echo "    (No specific variables needed, ensure Managed Identity has Key Vault access)"
  echo ""
  echo "  Optional (Control Login Behavior):"
  echo "    SHOULD_SKIP_LOGIN           : Set to any non-empty value to skip 'az login'. Assumes login is handled externally."
  echo ""
  echo "  Optional (Secrets With Scripts):"
  echo "    ADDITIONAL_FILES_SECRET_NAMES : Space-separated list of secret names in Key Vault. Each secret's value will be saved to a file named after the secret and executed (eval)."
  echo "    ENV_VAR_SECRET_NAMES        : Space-separated list of secret names in Key Vault. Each secret's value will be saved to a file named after the secret and sourced (source)."
  echo "    SCRIPT_SECRET_NAMES         : Space-separated list of secret names in Key Vault. Each secret's value will be saved to a file named after the secret and sourced (source)."
  echo ""
  echo "Example Usage:"
  echo "  # Using Managed Identity (ensure identity has permissions)"
  echo "  export DEPLOY_KEY_VAULT_NAME='my-keyvault-name'"
  echo "  export SCRIPT_SECRET_NAMES='script-secret1'"
  echo "  ./deployment-script.sh"
  echo ""
  echo "  # Using Service Principal"
  echo "  export DEPLOY_KEY_VAULT_NAME='my-keyvault-name'"
  echo "  export DEPLOY_SP_CLIENT_ID='your-sp-client-id'"
  echo "  export DEPLOY_SP_SECRET='your-sp-secret'"
  echo "  export DEPLOY_SP_TENANT_ID='your-tenant-id'"
  echo "  export SCRIPT_SECRET_NAMES='script-secret1'"
  echo "  ./deployment-script.sh"
  echo ""
  echo "  # With additional secrets"
  echo "  export DEPLOY_KEY_VAULT_NAME='my-keyvault-name'"
  echo "  export ADDITIONAL_FILES_SECRET_NAMES='secret-file1 secret-file2'"
  echo "  export ENV_VAR_SECRET_NAMES='env-vars-secret'"
  echo "  export SCRIPT_SECRET_NAMES='script-secret1 script-secret2'"
  echo "  ./deployment-script.sh"
  exit 0
}

# Parse command-line options
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi

echo "Starting deployment-script.sh"

# Validation

if [[ -z "$DEPLOY_KEY_VAULT_NAME" ]]; then
  echo "ERROR: DEPLOY_KEY_VAULT_NAME is required."
  exit 1
fi

# Setup parameters for dynamic install and MSAL for Managed Identities with AZ CLI.

az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true
az config set core.use_msal_managed_identity=true

# Log in with Managed Identity or Service Principal if provided.

if [[ ! $SHOULD_SKIP_LOGIN ]]; then
  if [[ $DEPLOY_SP_CLIENT_ID && $DEPLOY_SP_SECRET ]]; then
    az login --service-principal --username "${DEPLOY_SP_CLIENT_ID}" --password "${DEPLOY_SP_SECRET}" --tenant "${DEPLOY_SP_TENANT_ID}"
  else
    az login --identity
  fi
fi

echo "Retrieving deployment secrets from Key Vault: $DEPLOY_KEY_VAULT_NAME"

# Retrieve a secret from Key Vault and save to a file.
get_secret_to_file() {
  local secret_name="$1"

  echo "Retrieving secret: $secret_name"

  if ! az keyvault secret show --name "$secret_name" --vault-name "$DEPLOY_KEY_VAULT_NAME" --query "value" -o tsv >"./$secret_name"; then
    echo "ERROR: Failed getting $secret_name from $DEPLOY_KEY_VAULT_NAME, verify roles are properly set for logged in user or identity..."
    exit 1
  fi

  chmod +x "./$secret_name"

  echo "Retrieved and saved $secret_name to ./$secret_name"
  return 0
}

if [[ -z "$ADDITIONAL_FILES_SECRET_NAMES" ]]; then
  ADDITIONAL_FILES_SECRET_NAMES=("$ADDITIONAL_FILES_SECRET_NAMES")
  for secret_name in "${ADDITIONAL_FILES_SECRET_NAMES[@]}"; do
    get_secret_to_file "$secret_name"
    eval "./$secret_name"
  done
fi

if [[ -z "$ENV_VAR_SECRET_NAMES" ]]; then
  ENV_VAR_SECRET_NAMES=("$ENV_VAR_SECRET_NAMES")
  for secret_name in "${ENV_VAR_SECRET_NAMES[@]}"; do
    get_secret_to_file "$secret_name"
    # shellcheck source=/dev/null
    source "./$secret_name"
  done
fi

if [[ -z "$SCRIPT_SECRET_NAMES" ]]; then
  SCRIPT_SECRET_NAMES=("$SCRIPT_SECRET_NAMES")
  for secret_name in "${SCRIPT_SECRET_NAMES[@]}"; do
    get_secret_to_file "$secret_name"
    # shellcheck source=/dev/null
    source "./$secret_name"
  done
fi

echo "Finished deployment script..."
