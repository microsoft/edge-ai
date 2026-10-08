#!/usr/bin/env bash
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#
# onvif-ptz-check.sh
# Checks an ONVIF camera directly over ONVIF SOAP, independent of Azure IoT
# Operations: lists service addresses and media profile tokens, and runs a
# short pan and tilt movement test.

set -euo pipefail

readonly SOAP_ENV="http://www.w3.org/2003/05/soap-envelope"
readonly NS_DEVICE="http://www.onvif.org/ver10/device/wsdl"
readonly NS_MEDIA="http://www.onvif.org/ver10/media/wsdl"
readonly NS_MEDIA2="http://www.onvif.org/ver20/media/wsdl"
readonly NS_PTZ="http://www.onvif.org/ver20/ptz/wsdl"
readonly NS_SCHEMA="http://www.onvif.org/ver10/schema"

RESPONSE_FILE=""
MOVING=0
SLEEP_PID=""

usage() {
  cat <<'EOF'
Usage: onvif-ptz-check.sh <command>

Commands:
  services   List the camera's ONVIF service addresses (GetServices)
  profiles   List media profile tokens and whether each has PTZ (GetProfiles)
  move       Pan right, pan left, tilt up, and tilt down, then stop

Environment variables:
  CAMERA_HOST        Camera IP address or hostname (required)
  CAMERA_PORT        ONVIF port (default: 80)
  CAMERA_SCHEME      http or https (default: http)
  ONVIF_DEVICE_PATH  Device service path (default: /onvif/device_service)
  ONVIF_MEDIA_URL    Media service URL (default: device service URL)
  ONVIF_PTZ_URL      PTZ service URL (default: device service URL)
  PROFILE_TOKEN      Media profile token (required for move)
  MOVE_SECONDS       Seconds for each movement step (default: 2)
  CURL_MAX_TIME      Timeout in seconds for each request (default: 10)
  CAMERA_USERNAME    Camera username (prompted when unset on a terminal)
  CAMERA_PASSWORD    Camera password (prompted when unset on a terminal)
  K8S_SECRET_NAME    Read the username and password keys from this secret
  K8S_NAMESPACE      Secret namespace (default: azure-iot-operations)
EOF
}

err() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_match() {
  local name="$1"
  local value="$2"
  local pattern="$3"
  if [[ ! "${value}" =~ ${pattern} ]]; then
    err "${name} has an invalid value"
  fi
}

init_config() {
  CAMERA_HOST="${CAMERA_HOST:-}"
  CAMERA_PORT="${CAMERA_PORT:-80}"
  CAMERA_SCHEME="${CAMERA_SCHEME:-http}"
  ONVIF_DEVICE_PATH="${ONVIF_DEVICE_PATH:-/onvif/device_service}"
  MOVE_SECONDS="${MOVE_SECONDS:-2}"
  CURL_MAX_TIME="${CURL_MAX_TIME:-10}"
  K8S_NAMESPACE="${K8S_NAMESPACE:-azure-iot-operations}"

  if [[ -z "${CAMERA_HOST}" ]]; then
    err "CAMERA_HOST is required"
  fi
  # Hostname, IPv4 address, or bracketed IPv6 address
  require_match CAMERA_HOST "${CAMERA_HOST}" \
    '^([A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?|\[[0-9A-Fa-f:.]+\])$'
  require_match CAMERA_PORT "${CAMERA_PORT}" '^[1-9][0-9]{0,4}$'
  if ((CAMERA_PORT > 65535)); then
    err "CAMERA_PORT has an invalid value"
  fi
  require_match CAMERA_SCHEME "${CAMERA_SCHEME}" '^https?$'
  require_match ONVIF_DEVICE_PATH "${ONVIF_DEVICE_PATH}" '^/[A-Za-z0-9._~/-]*$'
  require_match MOVE_SECONDS "${MOVE_SECONDS}" '^[1-9][0-9]?$'
  require_match CURL_MAX_TIME "${CURL_MAX_TIME}" '^[1-9][0-9]{0,2}$'

  DEVICE_URL="${CAMERA_SCHEME}://${CAMERA_HOST}:${CAMERA_PORT}${ONVIF_DEVICE_PATH}"
  MEDIA_URL="${ONVIF_MEDIA_URL:-${DEVICE_URL}}"
  PTZ_URL="${ONVIF_PTZ_URL:-${DEVICE_URL}}"
  require_match ONVIF_MEDIA_URL "${MEDIA_URL}" '^https?://[^[:space:]"<>]+$'
  require_match ONVIF_PTZ_URL "${PTZ_URL}" '^https?://[^[:space:]"<>]+$'
}

load_credentials() {
  CAMERA_USERNAME="${CAMERA_USERNAME:-}"
  CAMERA_PASSWORD="${CAMERA_PASSWORD:-}"

  if [[ -n "${K8S_SECRET_NAME:-}" ]]; then
    require_match K8S_SECRET_NAME "${K8S_SECRET_NAME}" \
      '^[a-z0-9]([-a-z0-9.]*[a-z0-9])?$'
    require_match K8S_NAMESPACE "${K8S_NAMESPACE}" \
      '^[a-z0-9]([-a-z0-9]*[a-z0-9])?$'
    CAMERA_USERNAME=$(kubectl get secret "${K8S_SECRET_NAME}" \
      --namespace "${K8S_NAMESPACE}" \
      --output jsonpath='{.data.username}' | base64 -d)
    CAMERA_PASSWORD=$(kubectl get secret "${K8S_SECRET_NAME}" \
      --namespace "${K8S_NAMESPACE}" \
      --output jsonpath='{.data.password}' | base64 -d)
  fi

  if [[ -z "${CAMERA_USERNAME}" ]]; then
    if [[ ! -t 0 ]]; then
      err "Set CAMERA_USERNAME or K8S_SECRET_NAME"
    fi
    read -r -p "Camera username: " CAMERA_USERNAME
  fi
  if [[ -z "${CAMERA_PASSWORD}" ]]; then
    if [[ ! -t 0 ]]; then
      err "Set CAMERA_PASSWORD or K8S_SECRET_NAME"
    fi
    read -r -s -p "Camera password: " CAMERA_PASSWORD
    printf '\n' >&2
  fi

  if [[ -z "${CAMERA_USERNAME}" || -z "${CAMERA_PASSWORD}" ]]; then
    err "Camera username and password are required"
  fi
  if [[ "${CAMERA_USERNAME}${CAMERA_PASSWORD}" == *[$'\r\n']* ]]; then
    err "Camera credentials must not contain line breaks"
  fi
}

# Quotes a value for a curl config file so credentials never appear in argv.
curl_config_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "${value}"
}

# Posts a SOAP body with digest authentication. Writes the response body to
# RESPONSE_FILE and prints the HTTP status code.
soap_post() {
  local url="$1"
  local body="$2"
  local credentials
  credentials=$(curl_config_quote "${CAMERA_USERNAME}:${CAMERA_PASSWORD}")

  printf 'user = %s\n' "${credentials}" \
    | curl --config - --digest --silent --show-error \
      --max-time "${CURL_MAX_TIME}" \
      --header "Content-Type: application/soap+xml; charset=utf-8" \
      --data-binary "<?xml version=\"1.0\" encoding=\"UTF-8\"?><s:Envelope xmlns:s=\"${SOAP_ENV}\"><s:Body>${body}</s:Body></s:Envelope>" \
      --output "${RESPONSE_FILE}" \
      --write-out '%{http_code}' \
      "${url}"
}

fault_reason() {
  tr -d '\r\n' <"${RESPONSE_FILE}" \
    | grep -oE '<([A-Za-z0-9_.-]+:)?Text[^>]*>[^<]*' \
    | sed -E 's/<[^>]*>//' \
    | head -n 1 || true
}

request() {
  local url="$1"
  local body="$2"
  local expected="$3"
  local status

  status=$(soap_post "${url}" "${body}")
  if [[ "${status}" != "200" ]] || ! grep -q "${expected}" "${RESPONSE_FILE}"; then
    printf 'ERROR: %s returned HTTP %s' "${expected%Response}" "${status}" >&2
    local reason
    reason=$(fault_reason)
    if [[ -n "${reason}" ]]; then
      printf ': %s' "${reason}" >&2
    fi
    printf '\n' >&2
    return 1
  fi
}

cmd_services() {
  request "${DEVICE_URL}" \
    "<GetServices xmlns=\"${NS_DEVICE}\"><IncludeCapability>false</IncludeCapability></GetServices>" \
    "GetServicesResponse"

  local services
  # Each Service element lists Namespace before XAddr
  services=$(tr -d '\r\n' <"${RESPONSE_FILE}" \
    | grep -oE '<([A-Za-z0-9_.-]+:)?Namespace>[^<]+</([A-Za-z0-9_.-]+:)?Namespace>[[:space:]]*<([A-Za-z0-9_.-]+:)?XAddr>[^<]+' \
    | sed -E 's#<[^>]*>([^<]+)</[^>]*>[[:space:]]*<[^>]*>#\1 #' || true)

  if [[ -z "${services}" ]]; then
    err "No services found in the GetServices response"
  fi

  local namespace
  local address
  while read -r namespace address; do
    case "${namespace}" in
      "${NS_DEVICE}") printf '%-8s %s\n' "Device" "${address}" ;;
      "${NS_MEDIA}") printf '%-8s %s\n' "Media" "${address}" ;;
      "${NS_MEDIA2}") printf '%-8s %s\n' "Media2" "${address}" ;;
      "${NS_PTZ}") printf '%-8s %s\n' "PTZ" "${address}" ;;
      *) printf '%-8s %s (%s)\n' "Other" "${address}" "${namespace}" ;;
    esac
  done <<<"${services}"
}

cmd_profiles() {
  request "${MEDIA_URL}" "<GetProfiles xmlns=\"${NS_MEDIA}\"/>" \
    "GetProfilesResponse"

  local profiles
  # Splits the response so each line starts with one Profiles element
  profiles=$(tr -d '\r\n' <"${RESPONSE_FILE}" \
    | awk '{ gsub(/<([A-Za-z0-9_.-]+:)?Profiles[ \t]/, "\n&"); print }' \
    | tail -n +2)

  if [[ -z "${profiles}" ]]; then
    err "No profiles found in the GetProfiles response"
  fi

  printf '%-24s %-5s %s\n' "TOKEN" "PTZ" "NAME"
  local profile
  local token
  local name
  local ptz
  while IFS= read -r profile; do
    token=$(sed -nE 's/^<[^>]*[[:space:]]token="([^"]+)".*/\1/p' <<<"${profile}")
    name=$(grep -oE '<([A-Za-z0-9_.-]+:)?Name>[^<]*' <<<"${profile}" \
      | head -n 1 | sed -E 's/<[^>]*>//' || true)
    ptz="no"
    if [[ "${profile}" == *PTZConfiguration* ]]; then
      ptz="yes"
    fi
    printf '%-24s %-5s %s\n' "${token}" "${ptz}" "${name}"
  done <<<"${profiles}"
}

ptz_stop() {
  request "${PTZ_URL}" \
    "<Stop xmlns=\"${NS_PTZ}\"><ProfileToken>${PROFILE_TOKEN}</ProfileToken><PanTilt>true</PanTilt><Zoom>true</Zoom></Stop>" \
    "StopResponse"
}

move_step() {
  local label="$1"
  local x="$2"
  local y="$3"

  printf '%s for %s seconds\n' "${label}" "${MOVE_SECONDS}"
  request "${PTZ_URL}" \
    "<ContinuousMove xmlns=\"${NS_PTZ}\"><ProfileToken>${PROFILE_TOKEN}</ProfileToken><Velocity><PanTilt xmlns=\"${NS_SCHEMA}\" x=\"${x}\" y=\"${y}\"/></Velocity></ContinuousMove>" \
    "ContinuousMoveResponse"
  # Background sleep keeps the INT and TERM traps responsive
  sleep "${MOVE_SECONDS}" &
  SLEEP_PID=$!
  wait "${SLEEP_PID}"
  SLEEP_PID=""
  ptz_stop
}

cmd_move() {
  PROFILE_TOKEN="${PROFILE_TOKEN:-}"
  if [[ -z "${PROFILE_TOKEN}" ]]; then
    err "PROFILE_TOKEN is required; run the profiles command to list tokens"
  fi
  # ONVIF ReferenceToken values are limited to 64 characters
  require_match PROFILE_TOKEN "${PROFILE_TOKEN}" '^[A-Za-z0-9_.:-]{1,64}$'

  MOVING=1
  move_step "Pan right" 0.5 0.0
  move_step "Pan left" -0.5 0.0
  move_step "Tilt up" 0.0 0.5
  move_step "Tilt down" 0.0 -0.5
  MOVING=0

  printf 'Movement test complete. Confirm the camera panned right and left,'
  printf ' then tilted up and down.\n'
}

cleanup() {
  if [[ -n "${SLEEP_PID}" ]]; then
    kill "${SLEEP_PID}" 2>/dev/null || true
  fi
  if ((MOVING)); then
    MOVING=0
    ptz_stop || printf 'WARNING: Stop failed; stop the camera manually\n' >&2
  fi
  if [[ -n "${RESPONSE_FILE}" ]]; then
    rm -f "${RESPONSE_FILE}"
  fi
}

main() {
  local command="${1:-}"
  case "${command}" in
    services | profiles | move) ;;
    -h | --help | help)
      usage
      return 0
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac

  init_config
  load_credentials

  RESPONSE_FILE=$(mktemp)
  trap cleanup EXIT
  trap 'exit 130' INT TERM

  "cmd_${command}"
}

main "$@"
