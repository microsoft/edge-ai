#!/usr/bin/env bash
#
# upload-script-secrets.sh
# Uploads the cluster server and node setup scripts to Key Vault as gzip-compressed,
# base64-encoded secrets to stay within the Key Vault secret size limit.
# Counterpart to deploy-script-secrets.sh, which downloads and decompresses them.

set -euo pipefail

## Required Environment Variables:
# KEY_VAULT_NAME            - Key Vault to store the script secrets in
# SERVER_SCRIPT_SECRET_NAME - Secret name for the cluster server setup script
# NODE_SCRIPT_SECRET_NAME   - Secret name for the cluster node setup script
# SERVER_SCRIPT             - Content of the cluster server setup script
# NODE_SCRIPT               - Content of the cluster node setup script

readonly MAX_ATTEMPTS=10
readonly RETRY_DELAY_SECONDS=30

err() {
  printf "ERROR: %s\n" "$1" >&2
  exit 1
}

upload_script_secret() {
  local secret_name="$1"
  local script_content="$2"
  local secret_file
  local attempt

  secret_file="$(mktemp)"
  chmod 600 "${secret_file}"
  printf '%s' "${script_content}" | gzip -9 -n | base64 -w0 >"${secret_file}"

  for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
    if az keyvault secret set \
      --vault-name "${KEY_VAULT_NAME}" \
      --name "${secret_name}" \
      --file "${secret_file}" \
      --content-type 'application/gzip;base64' \
      --output none; then
      rm -f "${secret_file}"
      return 0
    fi
    echo "Setting Key Vault secret '${secret_name}' attempt ${attempt}/${MAX_ATTEMPTS} failed, retrying in ${RETRY_DELAY_SECONDS}s..."
    sleep "${RETRY_DELAY_SECONDS}"
  done

  rm -f "${secret_file}"
  err "Failed to set Key Vault secret '${secret_name}'"
}

main() {
  local required_var
  for required_var in KEY_VAULT_NAME SERVER_SCRIPT_SECRET_NAME NODE_SCRIPT_SECRET_NAME SERVER_SCRIPT NODE_SCRIPT; do
    if [[ -z "${!required_var:-}" ]]; then
      err "${required_var} environment variable is required"
    fi
  done

  upload_script_secret "${SERVER_SCRIPT_SECRET_NAME}" "${SERVER_SCRIPT}"
  upload_script_secret "${NODE_SCRIPT_SECRET_NAME}" "${NODE_SCRIPT}"
}

main "$@"
