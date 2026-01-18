#!/usr/bin/env bash
# shellcheck disable=SC1091
# deploy-cora-corax-dim.sh - Deploy CORA/CORAX dimensional robotics ontology
#
# Wrapper script for deploying the IEEE 1872 CORA/CORAX robotics ontology
# with optional seed data for demonstration purposes.
#
# Dependencies: Azure CLI authenticated, deploy.sh
#
# Usage:
#   ./deploy-cora-corax-dim.sh --workspace-id <guid> [--with-seed-data]

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/logging.sh"

DEFINITION_FILE="${COMPONENT_DIR}/definitions/examples/cora-corax-dim.yaml"
SEED_DIR="${COMPONENT_DIR}/fabric-ontology-dim/seed"

WORKSPACE_ID=""
LAKEHOUSE_ID=""
WITH_SEED_DATA="false"
PASSTHROUGH_ARGS=()

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy the IEEE 1872 CORA/CORAX robotics ontology to Microsoft Fabric.

This script deploys a dimensional schema with 12 entity types and 7 relationships
based on the CORA (Core Ontology for Robotics and Automation), CORAX, and POS
standards from IEEE 1872-2015.

Required Arguments:
  --workspace-id <id>       Fabric workspace ID (GUID)

Optional Arguments:
  --lakehouse-id <id>       Use existing Lakehouse (skips Lakehouse creation)
  --with-seed-data          Load sample robotics data for demonstration
  --dry-run                 Show deployment plan without making changes
  -h, --help                Show this help message

Examples:
  # Deploy ontology schema only (bind to existing tables)
  $(basename "$0") --workspace-id abc123 --lakehouse-id def456

  # Deploy with sample robotics data (ABB, KUKA, Fanuc robots)
  $(basename "$0") --workspace-id abc123 --with-seed-data

  # Preview deployment without making changes
  $(basename "$0") --workspace-id abc123 --with-seed-data --dry-run

Schema Contents:
  Entity Types (12):
    CORA: Robot, RobotGroup, RoboticSystem, RoboticEnvironment, RobotInterface
    CORAX: ProcessingDevice, PhysicalEnvironment
    POS: PositionCoordinateSystem, OrientationCoordinateSystem,
         PositionMeasure, OrientationMeasure, PoseMeasure

  Relationships (7):
    member, partOf, equippedWith, transform,
    hasPosition, hasOrientation, hasPose
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-id)
      WORKSPACE_ID="$2"
      shift 2
      ;;
    --lakehouse-id)
      LAKEHOUSE_ID="$2"
      shift 2
      ;;
    --with-seed-data)
      WITH_SEED_DATA="true"
      shift
      ;;
    --dry-run)
      PASSTHROUGH_ARGS+=("$1")
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      PASSTHROUGH_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "${WORKSPACE_ID}" ]]; then
  err "--workspace-id is required"
fi

if [[ ! -f "${DEFINITION_FILE}" ]]; then
  err "Definition file not found: ${DEFINITION_FILE}"
fi

log "Deploying CORA/CORAX Dimensional Ontology"
info "Definition: ${DEFINITION_FILE}"
info "Workspace: ${WORKSPACE_ID}"
info "With Seed Data: ${WITH_SEED_DATA}"

if [[ "${WITH_SEED_DATA}" == "true" ]]; then
  if [[ ! -d "${SEED_DIR}" ]]; then
    err "Seed directory not found: ${SEED_DIR}"
  fi

  info "Seed Directory: ${SEED_DIR}"

  "${SCRIPT_DIR}/deploy.sh" \
    --definition "${DEFINITION_FILE}" \
    --workspace-id "${WORKSPACE_ID}" \
    --data-dir "${SEED_DIR}" \
    ${LAKEHOUSE_ID:+--lakehouse-id "${LAKEHOUSE_ID}"} \
    "${PASSTHROUGH_ARGS[@]}"
else
  if [[ -z "${LAKEHOUSE_ID}" ]]; then
    err "--lakehouse-id is required when not using --with-seed-data"
  fi

  "${SCRIPT_DIR}/deploy.sh" \
    --definition "${DEFINITION_FILE}" \
    --workspace-id "${WORKSPACE_ID}" \
    --lakehouse-id "${LAKEHOUSE_ID}" \
    --skip-data-sources \
    "${PASSTHROUGH_ARGS[@]}"
fi

ok "CORA/CORAX deployment complete"
