#!/usr/bin/env bash
set -euo pipefail

# generate-env-config.sh
# Generates or updates the .env configuration file for the ROS2 components.
# Existing user customizations are preserved; only missing keys are appended.
# To force regeneration, delete the .env file first.

usage() {
	cat <<EOF
Usage: $0 [--help]

Generate or update the component .env with required defaults. Existing values are preserved; new keys appended.
Delete the existing .env to force a fresh file (with interactive ACR_NAME prompt when tty).

After success:
	Build images: ./scripts/build-ros-img.sh
	Deploy:       ./scripts/deploy-ros2-simulator.sh / deploy-ros2-connector.sh
EOF
}

# Help flag (must precede any side effects)
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

info(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*"; }
error(){ echo "[ERROR] $*" >&2; exit 1; }

# Key/value defaults (aligned with deployment plan)
declare -A DEFAULTS=(
	# Build and deployment configuration (required)
	[ACR_NAME]="" # Azure Container Registry name, REQUIRED - set to your ACR name
	[BUILD_PLATFORM]="linux/amd64" # Target platform for deployment
	# ROS2 Configuration
	[ROS_DOMAIN_ID]="0"
	[RMW_IMPLEMENTATION]="rmw_cyclonedds_cpp"
	[LOG_LEVEL]="INFO"
	[TOPIC_FILTER_PATTERNS]="*"
	[EXCLUDE_SYSTEM_TOPICS]="true"
	[ROS_LOCALHOST_ONLY]="0"
	[CYCLONEDDS_PEERS]="ros2-simulator" # Comma or space separated list, e.g. udp/10.0.0.10,udp/10.0.0.11
	[CYCLONEDDS_INTERFACES]="eth0" # Comma or space separated list of network interfaces, e.g. eth0,eth1
	[USE_HOST_NETWORK]="false" # Use host network for ROS2 communication (true/false)
	# External Dependencies
	[MQTT_BROKER]="aio-broker-anon.azure-iot-operations"
	[MQTT_PORT]="18884"
	[MQTT_TOPIC_PREFIX]="robot"
	# Images (Kubernetes)
	[CONNECTOR_IMAGE]="ros2-connector"
	[SIMULATOR_IMAGE]="ros2-simulator"
	[IMAGE_TAG]="latest"
	# Simulator Configuration
	[SIMULATOR_PUBLISH_RATE]="5.0"
	[USE_BAG_PLAYBACK]="false"
	[LOCAL_PATH]="/resources/data" # Local file/dir to copy into PVC (optional)
	[BAG_PATH]="/app/data/data"
	[TARGET_PATH]="/app/data" # Mount path inside loader pod
	# Kubernetes and PVC Configuration
	[NAMESPACE]="azure-iot-operations" # Namespace for PVC and simulator deployment
	[PVC_NAME]="rosbag-pvc" # PVC name for rosbag storage
	[PVC_SIZE]="5Gi" # Requested size for PVC creation
)

create_header() {
	cat <<'HDR'
# ROS2 Connector Configuration
# Generated / updated by scripts/generate-env-config.sh
# Missing keys appended; edit values as needed. Delete file to fully regenerate.

# ----------------------------
# Application Configuration
# ----------------------------
HDR
}

prompt_for_acr_name() {
	if [[ -t 0 ]]; then  # Check if running in an interactive terminal
		echo ""
		echo "ACR_NAME is required for building and pushing container images."
		echo "Please enter your Azure Container Registry name (without .azurecr.io):"
		echo "Example: if your ACR is 'mycompany.azurecr.io', enter 'mycompany'"
		echo ""
		read -r -p "ACR_NAME: " user_acr_name
		if [[ -n "${user_acr_name}" ]]; then
			# Update the DEFAULTS array with the user-provided value
			DEFAULTS[ACR_NAME]="${user_acr_name}"
			info "ACR_NAME set to: ${user_acr_name}"
		else
			warn "No ACR_NAME provided. You'll need to set it manually in the .env file."
		fi
	else
		warn "Running in non-interactive mode. ACR_NAME must be set manually in the .env file."
	fi
}

generate_fresh() {
	info "Creating new .env with defaults"

	# Prompt for ACR_NAME if not set
	if [[ -z "${DEFAULTS[ACR_NAME]}" ]]; then
		prompt_for_acr_name
	fi

	create_header >"${ENV_FILE}"
	cat >>"${ENV_FILE}" <<EOF

# Build and Deployment Configuration (REQUIRED)
ACR_NAME=${DEFAULTS[ACR_NAME]}
BUILD_PLATFORM=${DEFAULTS[BUILD_PLATFORM]}

# ROS2 Configuration
ROS_DOMAIN_ID=${DEFAULTS[ROS_DOMAIN_ID]}
RMW_IMPLEMENTATION=${DEFAULTS[RMW_IMPLEMENTATION]}
LOG_LEVEL=${DEFAULTS[LOG_LEVEL]}
TOPIC_FILTER_PATTERNS=${DEFAULTS[TOPIC_FILTER_PATTERNS]}
EXCLUDE_SYSTEM_TOPICS=${DEFAULTS[EXCLUDE_SYSTEM_TOPICS]}
ROS_LOCALHOST_ONLY=${DEFAULTS[ROS_LOCALHOST_ONLY]}
CYCLONEDDS_PEERS=${DEFAULTS[CYCLONEDDS_PEERS]}
CYCLONEDDS_INTERFACES=${DEFAULTS[CYCLONEDDS_INTERFACES]}
USE_HOST_NETWORK=${DEFAULTS[USE_HOST_NETWORK]}

# External Dependencies
MQTT_BROKER=${DEFAULTS[MQTT_BROKER]}
MQTT_PORT=${DEFAULTS[MQTT_PORT]}
MQTT_TOPIC_PREFIX=${DEFAULTS[MQTT_TOPIC_PREFIX]}

# Images (Kubernetes)
CONNECTOR_IMAGE=${DEFAULTS[CONNECTOR_IMAGE]}
SIMULATOR_IMAGE=${DEFAULTS[SIMULATOR_IMAGE]}
IMAGE_TAG=${DEFAULTS[IMAGE_TAG]}

# Simulator Configuration
SIMULATOR_PUBLISH_RATE=${DEFAULTS[SIMULATOR_PUBLISH_RATE]}
USE_BAG_PLAYBACK=${DEFAULTS[USE_BAG_PLAYBACK]}
LOCAL_PATH=${DEFAULTS[LOCAL_PATH]}
BAG_PATH=${DEFAULTS[BAG_PATH]}
TARGET_PATH=${DEFAULTS[TARGET_PATH]}

# Kubernetes and PVC Configuration
NAMESPACE=${DEFAULTS[NAMESPACE]}
PVC_NAME=${DEFAULTS[PVC_NAME]}
PVC_SIZE=${DEFAULTS[PVC_SIZE]}

EOF
}

update_missing_keys() {
	info "Updating existing .env (adding any missing keys)"
	for k in "${!DEFAULTS[@]}"; do
		if ! grep -q "^${k}=" "${ENV_FILE}"; then
			echo "${k}=${DEFAULTS[$k]}" >> "${ENV_FILE}"
			info "Added missing key: ${k}"
		fi
	done
}

validate_required_vars() {
	if [[ -f "${ENV_FILE}" ]]; then
		local acr_name_value
		acr_name_value=$(grep -E "^ACR_NAME=" "${ENV_FILE}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
		if [[ -z "${acr_name_value}" ]]; then
			error "ACR_NAME is required but not set in ${ENV_FILE}. Please set ACR_NAME to your Azure Container Registry name (e.g., ACR_NAME=myregistry)"
		fi
	fi
}

check_acr_name_after_generation() {
	# Always check ACR_NAME after generation/update to ensure it's properly set
	local acr_name_value
	acr_name_value=$(grep -E "^ACR_NAME=" "${ENV_FILE}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
	if [[ -z "${acr_name_value}" ]]; then
		warn "IMPORTANT: ACR_NAME is not set in ${ENV_FILE}"
		warn "This is REQUIRED for building and pushing container images."
		warn "Please edit ${ENV_FILE} and set: ACR_NAME=your-registry-name"
		warn "Example: ACR_NAME=mycompanyregistry"
		echo ""
		echo "After setting ACR_NAME, you can:"
		echo "  1. Build images: ./scripts/build-ros-img.sh"
		return 1
	else
		info "✓ ACR_NAME is set to: ${acr_name_value}"
		return 0
	fi
}

if [[ ! -f "${ENV_FILE}" ]]; then
	generate_fresh
else
	update_missing_keys
fi

# Always validate required variables after generation/update
validate_required_vars
check_acr_name_after_generation

info ".env ready at ${ENV_FILE}"

# Only show next steps if ACR_NAME is properly set
acr_name_value=$(grep -E "^ACR_NAME=" "${ENV_FILE}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
if [[ -n "${acr_name_value}" ]]; then
	echo "Next steps:"
	echo "  1. Review and adjust values in ${ENV_FILE}"
	echo "  2. Build images: ./scripts/build-ros-img.sh"
	echo "  3a. (Optional) Deploy simulator: ./scripts/deploy-ros2-simulator.sh"
	echo "  3b. Deploy connector: ./scripts/deploy-ros2-connector.sh"
fi
