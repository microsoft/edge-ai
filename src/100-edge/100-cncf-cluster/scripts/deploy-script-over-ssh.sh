#!/usr/bin/env bash
# shellcheck disable=SC2269

## Required Environment Variables:

ARC_RESOURCE_GROUP_NAME="${ARC_RESOURCE_GROUP_NAME}" # The Resource Group name containing the Azure Arc-connected machine
ARC_RESOURCE_NAME="${ARC_RESOURCE_NAME}"             # The name of the Azure Arc-connected machine to run the script on
SSH_LOCAL_USER="${SSH_LOCAL_USER}"                   # Local account used for the SSH session; must have passwordless sudo
SSH_PRIVATE_KEY_PATH="${SSH_PRIVATE_KEY_PATH}"       # Path to the private key authorized for 'SSH_LOCAL_USER'
SCRIPT_B64="${SCRIPT_B64}"                           # Base64 of the script to stage and run as root on the machine

## Examples
##  ARC_RESOURCE_GROUP_NAME=rg-sample ARC_RESOURCE_NAME=arc-sample SSH_LOCAL_USER=azureuser SSH_PRIVATE_KEY_PATH=~/.ssh/id_rsa SCRIPT_B64="$(base64 -w0 setup.sh)" ./deploy-script-over-ssh.sh
###

usage() {
  echo "usage: ${0##*./}"
  grep -x -B99 -m 1 "^###" "$0" \
    | sed -E -e '/^[^#]+=/ {s/^([^ ])/  \1/ ; s/#/ / ; s/=[^ ]*$// ;}' \
    | sed -E -e ':x' -e '/^[^#]+=/ {s/^(  [^ ]+)[^ ] /\1  / ;}' -e 'tx' \
    | sed -e 's/^## //' -e '/^#/d' -e '/^$/d'
  exit 1
}

log() {
  printf "========== %s ==========\n" "$1"
}

err() {
  printf "[ ERROR ]: %s\n" "$1" >&2
  exit 1
}

if [ $# -gt 0 ]; then
  usage
fi

set -euo pipefail

[ -n "$ARC_RESOURCE_GROUP_NAME" ] || err "ARC_RESOURCE_GROUP_NAME environment variable is required"
[ -n "$ARC_RESOURCE_NAME" ] || err "ARC_RESOURCE_NAME environment variable is required"
[ -n "$SSH_LOCAL_USER" ] || err "SSH_LOCAL_USER environment variable is required"
[ -n "$SSH_PRIVATE_KEY_PATH" ] || err "SSH_PRIVATE_KEY_PATH environment variable is required"
[ -n "$SCRIPT_B64" ] || err "SCRIPT_B64 environment variable is required"

command -v az &>/dev/null || err "Azure CLI is required"
az extension show --name ssh &>/dev/null || err "Azure CLI 'ssh' extension is required: az extension add --name ssh"
[ -r "$SSH_PRIVATE_KEY_PATH" ] || err "Private key is not readable: $SSH_PRIVATE_KEY_PATH"

# Staging through a file rather than 'bash -s' keeps the script off stdin, which the script itself may read.
# shellcheck disable=SC2016 # Expansions are intentionally deferred to the remote shell.
remote_bootstrap='set -euo pipefail; script_file=$(mktemp /tmp/deploy-script-over-ssh.XXXXXX); trap "rm -f $script_file" EXIT; base64 -d > "$script_file"; chmod 0700 "$script_file"; bash "$script_file"'

# The payload is base64, so it never contains a quote that could break out of the remote command.
remote_command="printf '%s' '$SCRIPT_B64' | sudo bash -c '$remote_bootstrap'"

log "Running script on '$ARC_RESOURCE_NAME' in '$ARC_RESOURCE_GROUP_NAME' as '$SSH_LOCAL_USER'"

az ssh arc \
  --resource-group "$ARC_RESOURCE_GROUP_NAME" \
  --name "$ARC_RESOURCE_NAME" \
  --local-user "$SSH_LOCAL_USER" \
  --private-key-file "$SSH_PRIVATE_KEY_PATH" \
  -- -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o BatchMode=yes \
  -o LogLevel=ERROR \
  "$remote_command"

log "Script completed on '$ARC_RESOURCE_NAME'"
