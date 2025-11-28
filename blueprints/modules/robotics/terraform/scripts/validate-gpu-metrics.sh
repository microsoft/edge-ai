#!/usr/bin/env bash

set -euo pipefail

info() {
  echo "[INFO] $1"
}

success() {
  echo "[PASS] $1"
}

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Required command '$1' not found in PATH"
  fi
}

info "Validating GPU metrics monitoring setup"

require_cmd kubectl

current_context=$(kubectl config current-context 2>/dev/null || echo "unknown")
info "Using kubectl context: ${current_context}"

if kubectl get podmonitor nvidia-dcgm-exporter -n kube-system >/dev/null 2>&1; then
  success "PodMonitor 'nvidia-dcgm-exporter' found in kube-system"
else
  fail "PodMonitor 'nvidia-dcgm-exporter' not found in kube-system"
fi

pod_list=$(kubectl get pods -n gpu-operator -l app=nvidia-dcgm-exporter --no-headers 2>/dev/null || true)
if [[ -z "${pod_list}" ]]; then
  fail "No NVIDIA DCGM exporter pods detected in namespace gpu-operator"
fi

echo "${pod_list}"
success "DCGM exporter pods detected in gpu-operator"

primary_pod=$(kubectl get pods -n gpu-operator -l app=nvidia-dcgm-exporter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [[ -n "${primary_pod}" ]]; then
  info "Sampling metrics endpoint on pod ${primary_pod}"
  if kubectl exec -n gpu-operator "${primary_pod}" -- wget -qO- http://localhost:9400/metrics >/dev/null 2>&1; then
    success "DCGM metrics endpoint responded on ${primary_pod}"
  else
    info "Unable to fetch metrics via kubectl exec; the exporter image may not contain wget or endpoint is restricted"
  fi
fi

if [[ -n "${AZMON_PROMETHEUS_ENDPOINT:-}" ]]; then
  require_cmd az
  require_cmd jq
  require_cmd curl
  info "Querying Prometheus endpoint ${AZMON_PROMETHEUS_ENDPOINT} for DCGM metrics"
  access_token=$(az account get-access-token --query accessToken -o tsv)
  query_payload="query=${AZMON_PROMETHEUS_QUERY:-DCGM_FI_DEV_GPU_UTIL}"
  response=$(curl -sS -X POST "${AZMON_PROMETHEUS_ENDPOINT}/api/v1/query" \
    -H "Authorization: Bearer ${access_token}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "${query_payload}" || true)

  status=$(echo "${response}" | jq -r '.status' 2>/dev/null || echo "error")
  if [[ "${status}" == "success" ]]; then
    result_count=$(echo "${response}" | jq -r '.data.result | length')
    if [[ "${result_count}" -gt 0 ]]; then
      success "Prometheus query returned ${result_count} series"
    else
      info "Prometheus query succeeded but returned no data; metrics may not have been scraped yet"
    fi
  else
    info "Prometheus query failed or returned unexpected response"
  fi
else
  info "Set AZMON_PROMETHEUS_ENDPOINT to enable Prometheus API validation"
fi

info "GPU metrics monitoring validation completed"
