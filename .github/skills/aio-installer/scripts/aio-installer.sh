#!/usr/bin/env bash
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#
# aio-installer.sh
# Drives stateful Azure IoT Operations blueprint deployments.

set -eEuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd -P)"
readonly REPO_ROOT
readonly DEFAULT_STATE=".copilot-tracking/aio-installer/current.json"
readonly MAX_PROGRESS_FILE_BYTES=1048576

ACTION="startup"
STATE_ARGUMENT="${DEFAULT_STATE}"
STATE_FILE=""
PROGRESS_FILE=""
PENDING_PLAN_FILE=""

usage() {
  cat <<'EOF'
Usage: aio-installer.sh <command> [options] [--state <path>]

Commands:
  catalog
      List blueprints, frameworks, and Terraform parameter templates as JSON.

  select --blueprint <name> --framework <terraform|bicep>
      Initialize installer state for a blueprint deployment.

  select-cli --runtime <stable|preview> [--accept-preview-terms]
      Initialize installer state for a generic local Azure CLI deployment.
      Preview requires explicit acceptance of Azure Preview supplemental terms.

  auth [--login] [--tenant <tenant>] [--subscription <id-or-name>]
      Verify Azure CLI authentication and select a subscription. Supplying a
      tenant requires --login.

  prepare [--use-existing | --force] [--base-template <file>]
          [--overlay <file>]...
      Generate or select terraform.tfvars or main.bicepparam. Terraform
      overlays must be files in the selected blueprint's Terraform folder.

  validate
      Initialize and validate Terraform, or build Bicep.

  plan [--deployment-name <name>] [--location <azure-region>]
      Save a Terraform plan or run a Bicep subscription what-if.

  apply --confirm APPLY
      Apply the saved Terraform plan or create the reviewed Bicep deployment.

  verify
      Verify Terraform outputs or Bicep deployment success.

  run --stage <prerequisites|dependencies|initialized|created|verified>
      --label <display-label> <--continue-stage|--complete-stage>
      [--confirm <token>] --
      <az|kubectl> [arguments...]
      Run one confirmed generic CLI command, stream raw output to the terminal,
      and publish bounded redacted progress to the canvas. Use --continue-stage
      before the final command and --complete-stage on the final command.
      Mutation tokens are DEPENDENCIES, INITIALIZE, and CREATE.

  status
      Print the current installer JSON state.

Global option:
  --state <path>  Workspace-relative or absolute state file path.
EOF
}

err() {
  printf 'ERROR: %s\n' "$1" >&2
  if [[ -n "${PROGRESS_FILE}" ]] && command -v jq &>/dev/null; then
    append_progress_event \
      "${ACTION}" "failed" "${ACTION}" "$1" 1 >/dev/null 2>&1 || true
  fi
  record_failure "$1"
  exit 1
}

require_command() {
  local command_name="$1"
  command -v "${command_name}" &>/dev/null \
    || err "'${command_name}' is required but is not installed"
}

resolve_state_file() {
  if [[ "${STATE_ARGUMENT}" = /* ]]; then
    STATE_FILE="${STATE_ARGUMENT}"
  else
    STATE_FILE="${REPO_ROOT}/${STATE_ARGUMENT}"
  fi
  PROGRESS_FILE="${STATE_FILE}.progress.ndjson"
}

require_state() {
  [[ -f "${STATE_FILE}" ]] \
    || err "Installer state does not exist; run select first"
}

write_json_atomically() {
  local content="$1"
  local state_dir
  local temp_file

  state_dir="$(dirname "${STATE_FILE}")"
  mkdir -p "${state_dir}"
  temp_file="$(mktemp "${STATE_FILE}.XXXXXX")"
  printf '%s\n' "${content}" >"${temp_file}"
  chmod 0600 "${temp_file}"
  mv "${temp_file}" "${STATE_FILE}"
}

state_value() {
  local filter="$1"
  jq -er "${filter}" "${STATE_FILE}"
}

update_state() {
  local filter="$1"
  shift
  local updated

  updated="$(jq "$@" \
    --arg updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "${filter} | .updated_at = \$updated_at" "${STATE_FILE}")"
  write_json_atomically "${updated}"
}

initialize_progress() {
  mkdir -p "$(dirname "${PROGRESS_FILE}")"
  : >"${PROGRESS_FILE}"
  chmod 0600 "${PROGRESS_FILE}"
}

sanitize_progress_line() {
  local line="$1"

  printf '%s' "${line}" | jq -Rr '
    gsub("\u001b\\[[0-9;?]*[ -/]*[@-~]"; "")
    | gsub(
        "(?i)(authorization|password|passwd|secret|token|api[_ -]?key|connection[_ -]?string)(\\\"?[=:][[:space:]]*|[[:space:]]+)(\\\"[^\\\"]*\\\"|\\u0027[^\\u0027]*\\u0027|[^,;[:space:]]+)";
        "[REDACTED_SECRET]"
      )
    | gsub("(?i)bearer[[:space:]]+[^[:space:]]+"; "Bearer [REDACTED]")
    | gsub(
        "[A-Za-z0-9_-]{20,}\\.[A-Za-z0-9_-]{20,}\\.[A-Za-z0-9_-]{20,}";
        "[REDACTED_JWT]"
      )
    | gsub("[A-Za-z0-9+/]{40,}={0,2}"; "[REDACTED]")
    | gsub(
        "[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[A-Za-z]{2,}";
        "[REDACTED_EMAIL]"
      )
    | .[0:1000]
  '
}

append_progress_event() {
  local stage="$1"
  local status="$2"
  local label="$3"
  local message="${4:-}"
  local exit_code="${5:-}"
  local event
  local progress_size

  [[ -n "${PROGRESS_FILE}" ]] || return 0
  label="$(sanitize_progress_line "${label}")"
  if [[ -n "${message}" ]]; then
    message="$(sanitize_progress_line "${message}")"
  fi
  mkdir -p "$(dirname "${PROGRESS_FILE}")"
  touch "${PROGRESS_FILE}"
  chmod 0600 "${PROGRESS_FILE}"
  event="$(jq -cn \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg stage "${stage}" \
    --arg status "${status}" \
    --arg label "${label}" \
    --arg message "${message}" \
    --arg exit_code "${exit_code}" \
    '{
      version: 1,
      timestamp: $timestamp,
      stage: $stage,
      status: $status,
      label: $label,
      message: (if $message == "" then null else $message end),
      exitCode: (if $exit_code == "" then null else ($exit_code | tonumber) end)
    }')"
  printf '%s\n' "${event}" >>"${PROGRESS_FILE}"
  progress_size="$(wc -c <"${PROGRESS_FILE}")"
  if ((progress_size > MAX_PROGRESS_FILE_BYTES)); then
    trim_progress
  fi
}

trim_progress() {
  local temporary

  [[ -f "${PROGRESS_FILE}" ]] || return 0
  temporary="$(mktemp "${PROGRESS_FILE}.XXXXXX")"
  tail -n 500 "${PROGRESS_FILE}" >"${temporary}"
  chmod 0600 "${temporary}"
  mv "${temporary}" "${PROGRESS_FILE}"
}

run_with_progress() {
  local stage="$1"
  local label="$2"
  shift 2
  local command_status
  local output_status
  local sanitized
  local -a pipeline_statuses

  append_progress_event "${stage}" "running" "${label}"
  trap - ERR
  set +e
  "$@" 2>&1 | {
    local line
    local line_count=0
    local truncated=false
    while IFS= read -r line || [[ -n "${line}" ]]; do
      printf '%s\n' "${line}"
      if ((line_count < 200)); then
        sanitized="$(sanitize_progress_line "${line}")"
        if [[ -n "${sanitized}" ]]; then
          append_progress_event \
            "${stage}" "output" "${label}" "${sanitized}"
        fi
      elif [[ "${truncated}" == false ]]; then
        append_progress_event \
          "${stage}" "output" "${label}" \
          "Additional command output is available only in the terminal."
        truncated=true
      fi
      ((line_count += 1))
    done
  }
  pipeline_statuses=("${PIPESTATUS[@]}")
  command_status="${pipeline_statuses[0]}"
  output_status="${pipeline_statuses[1]}"
  set -e
  trap on_error ERR

  if ((output_status != 0)); then
    append_progress_event \
      "${stage}" "failed" "${label}" \
      "Progress output processing failed." "${output_status}"
    trim_progress
    return "${output_status}"
  fi
  if ((command_status != 0)); then
    append_progress_event \
      "${stage}" "failed" "${label}" \
      "Command failed. Review the terminal output." "${command_status}"
    trim_progress
    return "${command_status}"
  fi

  append_progress_event "${stage}" "succeeded" "${label}" "" 0
  trim_progress
}

record_failure() {
  local message="$1"

  if [[ -n "${STATE_FILE}" && -f "${STATE_FILE}" ]] \
    && command -v jq &>/dev/null; then
    update_state \
      ".status = \"failed\" | .error = \$message" \
      --arg message "${message}" >/dev/null 2>&1 || true
  fi
}

set_stage() {
  local stage="$1"
  update_state \
    ".status = \$stage | .last_successful_stage = \$stage | .error = null" \
    --arg stage "${stage}"
}

on_error() {
  local exit_code=$?
  trap - ERR

  if [[ "${ACTION}" == "plan" || "${ACTION}" == "apply" ]]; then
    cleanup_saved_plan
  fi
  if [[ -n "${PROGRESS_FILE}" ]] && command -v jq &>/dev/null; then
    append_progress_event \
      "${ACTION}" "failed" "${ACTION}" \
      "Action failed. Review the terminal output." "${exit_code}" \
      >/dev/null 2>&1 || true
  fi
  record_failure "Action failed: ${ACTION}"

  exit "${exit_code}"
}

trap on_error ERR

deployment_directory() {
  local blueprint
  local framework

  blueprint="$(state_value '.blueprint')"
  framework="$(state_value '.framework')"
  printf '%s/blueprints/%s/%s\n' "${REPO_ROOT}" "${blueprint}" "${framework}"
}

repo_relative_path() {
  local absolute_path="$1"
  case "${absolute_path}" in
    "${REPO_ROOT}"/*)
      printf '%s\n' "${absolute_path#"${REPO_ROOT}/"}"
      ;;
    *)
      err "Path must be inside the repository: ${absolute_path}"
      ;;
  esac
}

blueprint_file() {
  local file_name="$1"
  local deployment_dir
  local file_path

  [[ "${file_name}" != */* ]] \
    || err "Use a file name from the selected blueprint directory"
  deployment_dir="$(deployment_directory)"
  file_path="${deployment_dir}/${file_name}"
  [[ -f "${file_path}" ]] || err "File not found: ${file_path}"
  printf '%s\n' "${file_path}"
}

file_hash() {
  local file_path="$1"

  if command -v sha256sum &>/dev/null; then
    sha256sum "${file_path}" | awk '{print $1}'
  else
    shasum -a 256 "${file_path}" | awk '{print $1}'
  fi
}

hash_stream() {
  if command -v sha256sum &>/dev/null; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

parameter_fingerprint() {
  local parameter_file
  local file_path
  local combined=""

  parameter_file="$(state_value '.parameter_file')"
  file_path="${REPO_ROOT}/${parameter_file}"
  combined+="$(file_hash "${file_path}") ${parameter_file}"$'\n'

  while IFS= read -r file_path; do
    [[ -n "${file_path}" ]] || continue
    combined+="$(file_hash "${REPO_ROOT}/${file_path}") ${file_path}"$'\n'
  done < <(jq -r '.overlays[]?' "${STATE_FILE}")

  printf '%s' "${combined}" | hash_stream
}

cleanup_saved_plan() {
  local plan_file=""

  if [[ -n "${PENDING_PLAN_FILE}" ]]; then
    rm -f "${PENDING_PLAN_FILE}"
    PENDING_PLAN_FILE=""
  fi

  if [[ -n "${STATE_FILE}" && -f "${STATE_FILE}" ]] \
    && command -v jq &>/dev/null; then
    plan_file="$(jq -r '.plan_file // empty' "${STATE_FILE}")"
    if [[ -n "${plan_file}" ]]; then
      rm -f "${plan_file}"
      update_state '.plan_file = null' >/dev/null 2>&1 || true
    fi
  fi
}

require_authenticated() {
  state_value '.azure.subscription_id' >/dev/null \
    || err "Azure authentication is not recorded; run auth first"
}

array_contains() {
  local expected="$1"
  shift
  local item

  for item in "$@"; do
    [[ "${item}" == "${expected}" ]] && return 0
  done
  return 1
}

export_terraform_subscription() {
  require_authenticated
  export ARM_SUBSCRIPTION_ID
  ARM_SUBSCRIPTION_ID="$(state_value '.azure.subscription_id')"
}

command_catalog() {
  local blueprint_dir
  local blueprint_name
  local framework
  local catalog='[]'
  local frameworks_json
  local templates_json
  local -a frameworks=()
  local -a templates=()

  require_command jq
  shopt -s nullglob

  for blueprint_dir in "${REPO_ROOT}"/blueprints/*; do
    [[ -d "${blueprint_dir}" ]] || continue
    blueprint_name="${blueprint_dir##*/}"
    frameworks=()
    templates=()

    for framework in terraform bicep; do
      [[ -d "${blueprint_dir}/${framework}" ]] && frameworks+=("${framework}")
    done

    for framework in "${blueprint_dir}"/terraform/*.tfvars.example; do
      templates+=("${framework##*/}")
    done

    ((${#frameworks[@]} > 0)) || continue
    frameworks_json="$(jq -cn '$ARGS.positional' --args "${frameworks[@]}")"
    templates_json="$(jq -cn '$ARGS.positional' --args "${templates[@]}")"
    catalog="$(jq -c \
      --arg name "${blueprint_name}" \
      --argjson frameworks "${frameworks_json}" \
      --argjson templates "${templates_json}" \
      '. + [{name: $name, frameworks: $frameworks, terraformTemplates: $templates}]' \
      <<<"${catalog}")"
  done

  jq -n \
    --arg default_blueprint "full-multi-node-cluster" \
    --argjson blueprints "${catalog}" \
    '{defaultBlueprint: $default_blueprint, blueprints: $blueprints}'
}

command_select() {
  local blueprint=""
  local framework=""
  local selected_dir
  local state

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --blueprint)
        blueprint="${2:-}"
        shift 2
        ;;
      --framework)
        framework="${2:-}"
        shift 2
        ;;
      *)
        err "Unknown select option: $1"
        ;;
    esac
  done

  [[ -n "${blueprint}" ]] || err "--blueprint is required"
  [[ "${framework}" == "terraform" || "${framework}" == "bicep" ]] \
    || err "--framework must be terraform or bicep"
  [[ "${blueprint}" =~ ^[a-z0-9][a-z0-9-]*$ ]] \
    || err "Blueprint name contains unsupported characters"

  selected_dir="${REPO_ROOT}/blueprints/${blueprint}/${framework}"
  [[ -d "${selected_dir}" ]] \
    || err "Selected blueprint framework does not exist: ${selected_dir}"

  state="$(jq -n \
    --arg blueprint "${blueprint}" \
    --arg framework "${framework}" \
    --arg selected_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      schema_version: 1,
      deployment_path: "edge-ai-blueprint",
      runtime: null,
      status: "selected",
      last_successful_stage: "selected",
      blueprint: $blueprint,
      framework: $framework,
      azure: {
        tenant_id: null,
        subscription_id: null,
        subscription_name: null
      },
      parameter_file: null,
      overlays: [],
      parameter_fingerprint: null,
      template_fingerprint: null,
      plan_file: null,
      deployment_name: null,
      location: null,
      error: null,
      updated_at: $selected_at
    }')"
  write_json_atomically "${state}"
  initialize_progress
  append_progress_event \
    "selected" "succeeded" "Select edge-ai blueprint" \
    "Selected ${blueprint} with ${framework}." 0
  printf 'Selected %s with %s.\n' "${blueprint}" "${framework}"
}

command_select_cli() {
  local runtime=""
  local accept_preview_terms=false
  local state

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --runtime)
        runtime="${2:-}"
        shift 2
        ;;
      --accept-preview-terms)
        accept_preview_terms=true
        shift
        ;;
      *)
        err "Unknown select-cli option: $1"
        ;;
    esac
  done

  [[ "${runtime}" == "stable" || "${runtime}" == "preview" ]] \
    || err "--runtime must be stable or preview"
  if [[ "${runtime}" == "preview" &&
    "${accept_preview_terms}" != true ]]; then
    err "Preview runtime requires --accept-preview-terms"
  fi
  if [[ "${runtime}" == "stable" &&
    "${accept_preview_terms}" == true ]]; then
    err "--accept-preview-terms is valid only with --runtime preview"
  fi

  state="$(jq -n \
    --arg runtime "${runtime}" \
    --arg selected_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      schema_version: 1,
      deployment_path: "generic-cli",
      runtime: $runtime,
      status: "selected",
      last_successful_stage: "selected",
      blueprint: null,
      framework: null,
      azure: {
        tenant_id: null,
        subscription_id: null,
        subscription_name: null
      },
      parameter_file: null,
      overlays: [],
      parameter_fingerprint: null,
      template_fingerprint: null,
      plan_file: null,
      deployment_name: null,
      location: null,
      error: null,
      updated_at: $selected_at
    }')"
  write_json_atomically "${state}"
  initialize_progress
  append_progress_event \
    "selected" "succeeded" "Select generic Azure CLI deployment" \
    "Generic local Azure CLI deployment selected with ${runtime} runtime." 0
  printf 'Selected generic local Azure CLI deployment with %s runtime.\n' \
    "${runtime}"
}

command_auth() {
  local should_login=false
  local tenant=""
  local subscription=""
  local account

  require_state
  require_command az
  if [[ "$(state_value '.deployment_path')" == "generic-cli" ]]; then
    case "$(state_value '.last_successful_stage')" in
      selected | authenticated) ;;
      *)
        err "Generic CLI authentication must complete before prerequisites"
        ;;
    esac
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --login)
        should_login=true
        shift
        ;;
      --tenant)
        tenant="${2:-}"
        shift 2
        ;;
      --subscription)
        subscription="${2:-}"
        shift 2
        ;;
      *)
        err "Unknown auth option: $1"
        ;;
    esac
  done

  if [[ -n "${tenant}" && "${should_login}" != true ]]; then
    err "--tenant requires --login so the tenant choice is explicit"
  fi

  if [[ "${should_login}" == true ]]; then
    if [[ -n "${tenant}" ]]; then
      run_with_progress \
        "authenticated" "Sign in to Azure" az login --tenant "${tenant}"
    else
      run_with_progress "authenticated" "Sign in to Azure" az login
    fi
  elif ! az account show &>/dev/null; then
    err "Azure CLI is not logged in; rerun auth with --login after user confirmation"
  fi

  if [[ -n "${subscription}" ]]; then
    run_with_progress \
      "authenticated" "Select Azure subscription" \
      az account set --subscription "${subscription}"
  fi

  account="$(az account show \
    --query '{tenantId:tenantId,subscriptionId:id,subscriptionName:name}' \
    --output json)"
  update_state \
    ".azure.tenant_id = \$tenant_id |
     .azure.subscription_id = \$subscription_id |
     .azure.subscription_name = \$subscription_name" \
    --arg tenant_id "$(jq -r '.tenantId' <<<"${account}")" \
    --arg subscription_id "$(jq -r '.subscriptionId' <<<"${account}")" \
    --arg subscription_name "$(jq -r '.subscriptionName' <<<"${account}")"
  set_stage "authenticated"
  append_progress_event \
    "authenticated" "succeeded" "Record Azure context" \
    "Azure subscription context recorded." 0
  printf 'Azure subscription selected: %s (%s)\n' \
    "$(jq -r '.subscriptionName' <<<"${account}")" \
    "$(jq -r '.subscriptionId' <<<"${account}")"
}

command_prepare() {
  local use_existing=false
  local force=false
  local base_template=""
  local framework
  local deployment_dir
  local parameter_path
  local parameter_relative
  local template_path
  local overlays_json
  local -a overlays=()
  local -a overlay_paths=()

  require_state

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --use-existing)
        use_existing=true
        shift
        ;;
      --force)
        force=true
        shift
        ;;
      --base-template)
        base_template="${2:-}"
        shift 2
        ;;
      --overlay)
        overlays+=("${2:-}")
        shift 2
        ;;
      *)
        err "Unknown prepare option: $1"
        ;;
    esac
  done

  [[ "${use_existing}" != true || "${force}" != true ]] \
    || err "--use-existing and --force are mutually exclusive"

  framework="$(state_value '.framework')"
  deployment_dir="$(deployment_directory)"

  if [[ "${framework}" == "terraform" ]]; then
    parameter_path="${deployment_dir}/terraform.tfvars"

    if [[ -f "${parameter_path}" && "${use_existing}" != true &&
      "${force}" != true ]]; then
      err "terraform.tfvars exists; choose --use-existing or --force"
    fi

    if [[ "${use_existing}" == true ]]; then
      [[ -f "${parameter_path}" ]] \
        || err "terraform.tfvars does not exist"
    elif [[ -n "${base_template}" ]]; then
      template_path="$(blueprint_file "${base_template}")"
      [[ "${base_template}" == *.tfvars.example ]] \
        || err "--base-template must be a *.tfvars.example file"
      cp "${template_path}" "${parameter_path}"
    else
      require_command terraform-docs
      (
        cd "${deployment_dir}"
        terraform-docs tfvars hcl . >"${parameter_path}"
      )
    fi

    for template_path in "${overlays[@]}"; do
      [[ "${template_path}" == *.tfvars.example ]] \
        || err "Terraform overlay must be a *.tfvars.example file"
      template_path="$(blueprint_file "${template_path}")"
      overlay_paths+=("$(repo_relative_path "${template_path}")")
    done
  else
    ((${#overlays[@]} == 0)) \
      || err "Terraform tfvars overlays cannot be applied to Bicep"
    [[ -z "${base_template}" ]] \
      || err "--base-template is only supported for Terraform"
    parameter_path="${deployment_dir}/main.bicepparam"

    if [[ -f "${parameter_path}" && "${use_existing}" != true &&
      "${force}" != true ]]; then
      err "main.bicepparam exists; choose --use-existing or --force"
    fi

    if [[ "${use_existing}" == true ]]; then
      [[ -f "${parameter_path}" ]] \
        || err "main.bicepparam does not exist"
    else
      require_command az
      (
        cd "${deployment_dir}"
        az bicep generate-params \
          --file main.bicep \
          --output-format bicepparam \
          --include-params all >"${parameter_path}"
      )
    fi
  fi

  chmod 0600 "${parameter_path}"

  parameter_relative="$(repo_relative_path "${parameter_path}")"
  overlays_json="$(jq -cn '$ARGS.positional' --args "${overlay_paths[@]}")"
  update_state \
    ".parameter_file = \$parameter_file |
     .overlays = \$overlays |
     .parameter_fingerprint = null |
      .template_fingerprint = null |
     .plan_file = null" \
    --arg parameter_file "${parameter_relative}" \
    --argjson overlays "${overlays_json}"
  set_stage "parameters-prepared"
  append_progress_event \
    "parameters-prepared" "succeeded" "Prepare deployment parameters" \
    "Parameter inputs are ready for review." 0
  printf 'Prepared parameters: %s\n' "${parameter_relative}"
}

command_validate() {
  local framework
  local deployment_dir

  require_state
  require_authenticated
  framework="$(state_value '.framework')"
  deployment_dir="$(deployment_directory)"

  if [[ "${framework}" == "terraform" ]]; then
    require_command terraform
    export_terraform_subscription
    (
      cd "${deployment_dir}"
      run_with_progress \
        "validated" "Initialize Terraform" terraform init
      run_with_progress \
        "validated" "Validate Terraform configuration" terraform validate
    )
  else
    require_command az
    az bicep build \
      --file "${deployment_dir}/main.bicep" \
      --stdout >/dev/null
  fi

  set_stage "validated"
  append_progress_event \
    "validated" "succeeded" "Validate deployment configuration" \
    "Validation completed successfully." 0
  printf 'Validation passed for %s.\n' "${framework}"
}

command_plan() {
  local deployment_name=""
  local location=""
  local framework
  local deployment_dir
  local parameter_file
  local fingerprint
  local template_fingerprint
  local plan_path
  local plan_relative
  local plan_dir
  local state_id
  local overlay
  local -a terraform_args=()

  require_state
  require_authenticated
  [[ "$(state_value '.last_successful_stage')" == "validated" ]] \
    || err "Plan requires successful validation"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --deployment-name)
        deployment_name="${2:-}"
        shift 2
        ;;
      --location)
        location="${2:-}"
        shift 2
        ;;
      *)
        err "Unknown plan option: $1"
        ;;
    esac
  done

  framework="$(state_value '.framework')"
  deployment_dir="$(deployment_directory)"
  parameter_file="${REPO_ROOT}/$(state_value '.parameter_file')"
  fingerprint="$(parameter_fingerprint)"

  if [[ "${framework}" == "terraform" ]]; then
    require_command terraform
    export_terraform_subscription
    cleanup_saved_plan
    plan_dir="${TMPDIR:-/tmp}/aio-installer"
    mkdir -p "${plan_dir}"
    chmod 0700 "${plan_dir}"
    state_id="$(printf '%s' "${STATE_FILE}" | hash_stream | cut -c1-16)"
    plan_path="${plan_dir}/${state_id}.tfplan"
    PENDING_PLAN_FILE="${plan_path}"
    terraform_args+=("-var-file=${parameter_file}")
    while IFS= read -r overlay; do
      [[ -n "${overlay}" ]] || continue
      terraform_args+=("-var-file=${REPO_ROOT}/${overlay}")
    done < <(jq -r '.overlays[]?' "${STATE_FILE}")

    (
      cd "${deployment_dir}"
      run_with_progress \
        "planned" "Create Terraform plan" terraform plan \
        -out="${plan_path}" \
        "${terraform_args[@]}"
    )
    chmod 0600 "${plan_path}"
    plan_relative="${plan_path}"
    update_state \
      ".parameter_fingerprint = \$fingerprint |
        .template_fingerprint = null |
       .plan_file = \$plan_file |
       .deployment_name = null |
       .location = null" \
      --arg fingerprint "${fingerprint}" \
      --arg plan_file "${plan_relative}"
    PENDING_PLAN_FILE=""
  else
    [[ -n "${deployment_name}" ]] \
      || err "Bicep plan requires --deployment-name"
    [[ -n "${location}" ]] || err "Bicep plan requires --location"
    [[ "${deployment_name}" =~ ^[A-Za-z0-9._()-]{1,64}$ ]] \
      || err "Bicep deployment name contains unsupported characters"
    require_command az
    template_fingerprint="$(az bicep build \
      --file "${deployment_dir}/main.bicep" \
      --stdout | hash_stream)"
    run_with_progress \
      "planned" "Preview Bicep deployment" az deployment sub what-if \
      --subscription "$(state_value '.azure.subscription_id')" \
      --name "${deployment_name}" \
      --location "${location}" \
      --parameters "${parameter_file}"
    update_state \
      ".parameter_fingerprint = \$fingerprint |
       .template_fingerprint = \$template_fingerprint |
       .plan_file = null |
       .deployment_name = \$deployment_name |
       .location = \$location" \
      --arg fingerprint "${fingerprint}" \
      --arg template_fingerprint "${template_fingerprint}" \
      --arg deployment_name "${deployment_name}" \
      --arg location "${location}"
  fi

  set_stage "planned"
  append_progress_event \
    "planned" "succeeded" "Review deployment preview" \
    "Deployment preview completed successfully." 0
}

command_apply() {
  local confirmation=""
  local framework
  local deployment_dir
  local expected_fingerprint
  local current_fingerprint
  local expected_template_fingerprint
  local current_template_fingerprint
  local parameter_file
  local plan_file
  local deployment_name
  local location

  require_state
  require_authenticated

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --confirm)
        confirmation="${2:-}"
        shift 2
        ;;
      *)
        err "Unknown apply option: $1"
        ;;
    esac
  done

  [[ "${confirmation}" == "APPLY" ]] \
    || err "Apply requires the literal confirmation token: --confirm APPLY"
  [[ "$(state_value '.last_successful_stage')" == "planned" ]] \
    || err "Apply requires a successful plan"

  expected_fingerprint="$(state_value '.parameter_fingerprint')"
  current_fingerprint="$(parameter_fingerprint)"
  [[ "${current_fingerprint}" == "${expected_fingerprint}" ]] \
    || err "Parameters changed after plan; run validate and plan again"

  framework="$(state_value '.framework')"
  deployment_dir="$(deployment_directory)"

  if [[ "${framework}" == "terraform" ]]; then
    require_command terraform
    export_terraform_subscription
    plan_file="$(state_value '.plan_file')"
    [[ -f "${plan_file}" ]] || err "Saved Terraform plan is missing"
    (
      cd "${deployment_dir}"
      run_with_progress \
        "applied" "Apply Terraform plan" terraform apply "${plan_file}"
    )
    cleanup_saved_plan
  else
    require_command az
    expected_template_fingerprint="$(state_value '.template_fingerprint')"
    current_template_fingerprint="$(az bicep build \
      --file "${deployment_dir}/main.bicep" \
      --stdout | hash_stream)"
    [[ "${current_template_fingerprint}" == "${expected_template_fingerprint}" ]] \
      || err "Bicep template changed after what-if; run validate and plan again"
    parameter_file="${REPO_ROOT}/$(state_value '.parameter_file')"
    deployment_name="$(state_value '.deployment_name')"
    location="$(state_value '.location')"
    run_with_progress \
      "applied" "Create Bicep deployment" az deployment sub create \
      --subscription "$(state_value '.azure.subscription_id')" \
      --name "${deployment_name}" \
      --location "${location}" \
      --parameters "${parameter_file}"
  fi

  set_stage "applied"
  append_progress_event \
    "applied" "succeeded" "Apply deployment" \
    "Deployment apply completed successfully." 0
}

command_verify() {
  local framework
  local deployment_dir
  local deployment_name
  local provisioning_state

  require_state
  require_authenticated
  [[ "$(state_value '.last_successful_stage')" == "applied" ]] \
    || err "Verification requires a successful apply"
  framework="$(state_value '.framework')"
  deployment_dir="$(deployment_directory)"

  if [[ "${framework}" == "terraform" ]]; then
    require_command terraform
    export_terraform_subscription
    (
      cd "${deployment_dir}"
      terraform output -json | jq -e 'has("azure_iot_operations")' >/dev/null
    )
  else
    require_command az
    deployment_name="$(state_value '.deployment_name')"
    provisioning_state="$(az deployment sub show \
      --subscription "$(state_value '.azure.subscription_id')" \
      --name "${deployment_name}" \
      --query properties.provisioningState \
      --output tsv)"
    [[ "${provisioning_state}" == "Succeeded" ]] \
      || err "Bicep deployment status is ${provisioning_state}"
  fi

  set_stage "verified"
  append_progress_event \
    "verified" "succeeded" "Verify deployment" \
    "Deployment verification passed." 0
  printf 'Deployment verification passed.\n'
}

command_run() {
  local stage=""
  local label=""
  local confirmation=""
  local continue_stage=false
  local complete_stage=false
  local expected_predecessor
  local expected_confirmation=""
  local executable
  local runtime
  local preview_help
  local -a command=()

  require_state
  [[ "$(state_value '.deployment_path')" == "generic-cli" ]] \
    || err "run is available only for a generic CLI installation"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stage)
        stage="${2:-}"
        shift 2
        ;;
      --label)
        label="${2:-}"
        shift 2
        ;;
      --continue-stage)
        continue_stage=true
        shift
        ;;
      --complete-stage)
        complete_stage=true
        shift
        ;;
      --confirm)
        confirmation="${2:-}"
        shift 2
        ;;
      --)
        shift
        command=("$@")
        break
        ;;
      *)
        err "Unknown run option: $1"
        ;;
    esac
  done

  case "${stage}" in
    prerequisites | dependencies | initialized | created | verified) ;;
    *)
      err "--stage must be prerequisites, dependencies, initialized, created, or verified"
      ;;
  esac
  [[ -n "${label}" && ${#label} -le 120 ]] \
    || err "--label is required and must be 120 characters or fewer"
  [[ "${label}" != *$'\n'* && "${label}" != *$'\r'* ]] \
    || err "--label cannot contain line breaks"
  [[ "${continue_stage}" != "${complete_stage}" ]] \
    || err "Choose exactly one of --continue-stage or --complete-stage"
  ((${#command[@]} > 0)) || err "run requires a command after --"
  executable="${command[0]}"
  [[ "${executable}" == "az" || "${executable}" == "kubectl" ]] \
    || err "run supports only az and kubectl commands"
  require_command "${executable}"

  case "${stage}" in
    prerequisites)
      expected_predecessor="authenticated"
      ;;
    dependencies)
      expected_predecessor="prerequisites"
      expected_confirmation="DEPENDENCIES"
      ;;
    initialized)
      expected_predecessor="dependencies"
      expected_confirmation="INITIALIZE"
      ;;
    created)
      expected_predecessor="initialized"
      expected_confirmation="CREATE"
      ;;
    verified)
      expected_predecessor="created"
      ;;
  esac
  require_authenticated
  [[ "$(state_value '.last_successful_stage')" == "${expected_predecessor}" ]] \
    || err "${stage} requires completed ${expected_predecessor} stage"
  if [[ -n "${expected_confirmation}" &&
    "${confirmation}" != "${expected_confirmation}" ]]; then
    err "${stage} requires --confirm ${expected_confirmation}"
  fi
  if [[ "${stage}" == "created" ]]; then
    if ((${#command[@]} < 4)) \
      || [[ "${command[0]}" != "az" || "${command[1]}" != "iot" ||
        "${command[2]}" != "ops" || "${command[3]}" != "create" ]]; then
      err "created stage requires an az iot ops create command"
    fi
    runtime="$(state_value '.runtime')"
    case "${runtime}" in
      preview)
        array_contains "--use-preview" "${command[@]}" \
          || err "Preview runtime requires --use-preview on az iot ops create"
        append_progress_event \
          "created" "running" "Verify preview runtime support"
        if ! preview_help="$(az iot ops create --help)"; then
          err "Unable to verify --use-preview support in the installed extension"
        fi
        [[ "${preview_help}" == *"--use-preview"* ]] \
          || err "Installed azure-iot-ops extension does not support --use-preview"
        append_progress_event \
          "created" "succeeded" "Verify preview runtime support" \
          "The installed extension supports --use-preview." 0
        ;;
      stable)
        if array_contains "--use-preview" "${command[@]}"; then
          err "Stable runtime does not permit --use-preview"
        fi
        ;;
      *)
        err "Generic CLI runtime selection is missing or invalid"
        ;;
    esac
  fi

  update_state \
    ".status = \$stage | .error = null" \
    --arg stage "${stage}"
  run_with_progress "${stage}" "${label}" "${command[@]}"
  if [[ "${complete_stage}" == true ]]; then
    set_stage "${stage}"
  fi
}

command_status() {
  require_state
  jq '.' "${STATE_FILE}"
}

main() {
  local command_name="${1:-}"
  local -a command_args=()

  [[ -n "${command_name}" ]] || {
    usage
    exit 1
  }
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --)
        # Arguments after the separator belong to the wrapped command.
        command_args+=("$@")
        break
        ;;
      --state)
        STATE_ARGUMENT="${2:-}"
        shift 2
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *)
        command_args+=("$1")
        shift
        ;;
    esac
  done

  resolve_state_file
  ACTION="${command_name}"

  case "${command_name}" in
    catalog) command_catalog "${command_args[@]}" ;;
    select) command_select "${command_args[@]}" ;;
    select-cli) command_select_cli "${command_args[@]}" ;;
    auth) command_auth "${command_args[@]}" ;;
    prepare) command_prepare "${command_args[@]}" ;;
    validate) command_validate "${command_args[@]}" ;;
    plan) command_plan "${command_args[@]}" ;;
    apply) command_apply "${command_args[@]}" ;;
    verify) command_verify "${command_args[@]}" ;;
    run) command_run "${command_args[@]}" ;;
    status) command_status "${command_args[@]}" ;;
    help) usage ;;
    *)
      usage
      err "Unknown command: ${command_name}"
      ;;
  esac
}

main "$@"
