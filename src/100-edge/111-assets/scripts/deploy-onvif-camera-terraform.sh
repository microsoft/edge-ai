#!/bin/bash
################################################################################
# ONVIF Camera Deployment Script - Terraform
#
# This script automates the deployment of ONVIF cameras to Azure IoT Operations
# using Terraform and the 111-assets component.
#
# Prerequisites:
# - Azure IoT Operations deployed and running
# - ONVIF Connector installed
# - Camera accessible on network
# - Azure CLI installed and authenticated
# - kubectl configured for your cluster
# - Terraform installed
#
# Usage:
#   ./deploy-onvif-camera-terraform.sh
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${COMPONENT_DIR}/terraform"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    if [ -n "$default" ]; then
        read -p "$(echo -e "${YELLOW}${prompt}${NC} [${default}]: ")" value
        value="${value:-$default}"
    else
        read -p "$(echo -e "${YELLOW}${prompt}${NC}: ")" value
    fi

    eval "$var_name='$value'"
}

prompt_confirm() {
    local prompt="$1"
    read -p "$(echo -e "${YELLOW}${prompt}${NC} (y/n): ")" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

################################################################################
# Prerequisite Checks
################################################################################

check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing_tools=()

    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        missing_tools+=("Azure CLI (az)")
    else
        print_success "Azure CLI installed"
    fi

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    else
        print_success "kubectl installed"
    fi

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("Terraform")
    else
        print_success "Terraform installed ($(terraform version -json | jq -r '.terraform_version'))"
    fi

    # Check base64
    if ! command -v base64 &> /dev/null; then
        missing_tools+=("base64")
    else
        print_success "base64 installed"
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        exit 1
    fi

    # Check Azure CLI authentication
    if ! az account show &> /dev/null; then
        print_error "Azure CLI not authenticated. Run 'az login' first."
        exit 1
    else
        print_success "Azure CLI authenticated"
    fi

    # Check kubectl cluster access
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl not configured for cluster access"
        exit 1
    else
        print_success "kubectl cluster access confirmed"
    fi
}

################################################################################
# Gather Camera Information
################################################################################

gather_camera_info() {
    print_header "Camera Information"

    print_info "Provide information about your ONVIF camera."
    echo ""

    prompt_input "Camera name (unique identifier)" "camera-01" CAMERA_NAME
    prompt_input "Camera IP address" "192.168.1.100" CAMERA_IP
    prompt_input "ONVIF port" "80" CAMERA_PORT
    prompt_input "ONVIF path" "/onvif/device_service" CAMERA_PATH
    prompt_input "Camera username" "admin" CAMERA_USERNAME
    prompt_input "Camera password" "" CAMERA_PASSWORD

    # Construct full ONVIF URL
    CAMERA_URL="http://${CAMERA_IP}:${CAMERA_PORT}${CAMERA_PATH}"

    echo ""
    print_info "Camera Configuration Summary:"
    echo "  Name: ${CAMERA_NAME}"
    echo "  ONVIF URL: ${CAMERA_URL}"
    echo "  Username: ${CAMERA_USERNAME}"
    echo "  Password: ********"
    echo ""
}

################################################################################
# Test ONVIF Connectivity
################################################################################

test_onvif_connection() {
    print_header "Testing ONVIF Connection"

    print_info "Testing connection to ${CAMERA_URL}..."

    local soap_request='<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'

    if curl -s -X POST "${CAMERA_URL}" \
        -H "Content-Type: application/soap+xml" \
        -d "${soap_request}" \
        --max-time 10 \
        -o /dev/null -w "%{http_code}" | grep -q "200"; then
        print_success "ONVIF endpoint responding"
    else
        print_warning "ONVIF endpoint test failed - continuing anyway"
        print_info "Camera may still work if credentials are correct"
    fi
}

################################################################################
# Gather Azure Information
################################################################################

gather_azure_info() {
    print_header "Azure Resource Information"

    # Get current subscription
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_info "Current subscription: ${SUBSCRIPTION_ID}"

    if ! prompt_confirm "Use this subscription?"; then
        prompt_input "Enter subscription ID" "" SUBSCRIPTION_ID
        az account set --subscription "${SUBSCRIPTION_ID}"
    fi

    # Resource Group
    print_info "Listing resource groups..."
    az group list --query "[].name" -o table
    echo ""
    prompt_input "Resource group name" "" RESOURCE_GROUP

    # Verify resource group exists
    if ! az group show --name "${RESOURCE_GROUP}" &> /dev/null; then
        print_error "Resource group '${RESOURCE_GROUP}' not found"
        exit 1
    fi
    print_success "Resource group verified"

    # Get resource group ID
    RESOURCE_GROUP_ID=$(az group show --name "${RESOURCE_GROUP}" --query id -o tsv)

    # Custom Location
    print_info "Listing custom locations in ${RESOURCE_GROUP}..."
    az customlocation list --resource-group "${RESOURCE_GROUP}" --query "[].name" -o table
    echo ""
    prompt_input "Custom location name" "" CUSTOM_LOCATION

    # Verify custom location exists
    if ! az customlocation show --name "${CUSTOM_LOCATION}" --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
        print_error "Custom location '${CUSTOM_LOCATION}' not found"
        exit 1
    fi
    print_success "Custom location verified"

    # Get custom location ID
    CUSTOM_LOCATION_ID=$(az customlocation show --name "${CUSTOM_LOCATION}" --resource-group "${RESOURCE_GROUP}" --query id -o tsv)

    # ADR Namespace
    print_info "Listing Device Registry namespaces..."
    az resource list --resource-type Microsoft.DeviceRegistry/namespaces --query "[].name" -o table
    echo ""
    prompt_input "ADR namespace name" "" ADR_NAMESPACE

    # Get ADR namespace ID
    ADR_NAMESPACE_ID=$(az resource list --resource-type Microsoft.DeviceRegistry/namespaces --query "[?name=='${ADR_NAMESPACE}'].id" -o tsv)

    if [ -z "${ADR_NAMESPACE_ID}" ]; then
        print_error "ADR namespace '${ADR_NAMESPACE}' not found"
        exit 1
    fi
    print_success "ADR namespace verified"

    # Location
    LOCATION=$(az group show --name "${RESOURCE_GROUP}" --query location -o tsv)
    print_info "Using location: ${LOCATION}"
}

################################################################################
# Create Kubernetes Secret
################################################################################

create_kubernetes_secret() {
    print_header "Creating Kubernetes Secret"

    local secret_name="${CAMERA_NAME}-credentials"

    # Check if secret already exists
    if kubectl get secret "${secret_name}" -n azure-iot-operations &> /dev/null; then
        print_warning "Secret '${secret_name}' already exists"
        if prompt_confirm "Delete and recreate?"; then
            kubectl delete secret "${secret_name}" -n azure-iot-operations
            print_success "Existing secret deleted"
        else
            print_info "Using existing secret"
            return 0
        fi
    fi

    # Encode credentials
    local username_b64=$(echo -n "${CAMERA_USERNAME}" | base64 -w 0)
    local password_b64=$(echo -n "${CAMERA_PASSWORD}" | base64 -w 0)

    # Create secret YAML
    local secret_yaml=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${secret_name}
  namespace: azure-iot-operations
data:
  username: ${username_b64}
  password: ${password_b64}
type: Opaque
EOF
)

    # Apply secret
    echo "${secret_yaml}" | kubectl apply -f -

    if [ $? -eq 0 ]; then
        print_success "Kubernetes secret created: ${secret_name}"
    else
        print_error "Failed to create Kubernetes secret"
        exit 1
    fi
}

################################################################################
# Determine PTZ Capabilities
################################################################################

determine_ptz_capabilities() {
    print_header "PTZ Capabilities"

    echo "Select camera PTZ capabilities:"
    echo "  1) Fixed (no PTZ)"
    echo "  2) Pan/Tilt only (PT)"
    echo "  3) Pan/Tilt/Zoom (PTZ)"
    echo "  4) PTZ with Home position"
    echo ""

    prompt_input "Select option" "2" PTZ_OPTION

    case $PTZ_OPTION in
        1)
            PTZ_TYPE="none"
            print_info "Camera configured as Fixed (no PTZ)"
            ;;
        2)
            PTZ_TYPE="pt"
            print_info "Camera configured as Pan/Tilt only"
            ;;
        3)
            PTZ_TYPE="ptz"
            print_info "Camera configured as Pan/Tilt/Zoom"
            ;;
        4)
            PTZ_TYPE="ptz_home"
            print_info "Camera configured as PTZ with Home"
            ;;
        *)
            print_warning "Invalid option, using Pan/Tilt only"
            PTZ_TYPE="pt"
            ;;
    esac
}

################################################################################
# Generate Terraform Configuration
################################################################################

generate_terraform_config() {
    print_header "Generating Terraform Configuration"

    local tfvars_file="${TERRAFORM_DIR}/${CAMERA_NAME}-deployment.tfvars"

    # Base configuration
    cat > "${tfvars_file}" <<EOF
# ONVIF Camera Deployment Configuration
# Generated on $(date)

# Location
location = "${LOCATION}"

# Resource Group (must include both name and id)
resource_group = {
  name = "${RESOURCE_GROUP}"
  id   = "${RESOURCE_GROUP_ID}"
}

# ADR Namespace (must include id)
adr_namespace = {
  id = "${ADR_NAMESPACE_ID}"
}

# Custom Location ID
custom_location_id = "${CUSTOM_LOCATION_ID}"

# Camera Device Configuration
namespaced_devices = [
  {
    name    = "${CAMERA_NAME}"
    enabled = true
    endpoints = {
      outbound = { assigned = {} }
      inbound = {
        "${CAMERA_NAME}-endpoint" = {
          endpoint_type = "Microsoft.Onvif"
          address       = "${CAMERA_URL}"
          version       = "1.0"
          authentication = {
            method = "UsernamePassword"
            usernamePasswordCredentials = {
              usernameSecretName = "${CAMERA_NAME}-credentials/username"
              passwordSecretName = "${CAMERA_NAME}-credentials/password"
            }
          }
        }
      }
    }
  }
]

EOF

    # Add PTZ asset if applicable
    if [ "${PTZ_TYPE}" != "none" ]; then
        cat >> "${tfvars_file}" <<EOF
# PTZ Control Asset
namespaced_assets = [
  {
    name    = "${CAMERA_NAME}-ptz"
    enabled = true
    device_ref = {
      device_name   = "${CAMERA_NAME}"
      endpoint_name = "${CAMERA_NAME}-endpoint"
    }
    data_points = [
      {
        name                     = "pan_left"
        data_source              = "pan_left"
        capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
        observability_mode       = "none"
        data_point_configuration = jsonencode({
          pan_tilt = { x = -0.5, y = 0.0 }
          zoom     = { x = 0.0 }
        })
      },
      {
        name                     = "pan_right"
        data_source              = "pan_right"
        capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
        observability_mode       = "none"
        data_point_configuration = jsonencode({
          pan_tilt = { x = 0.5, y = 0.0 }
          zoom     = { x = 0.0 }
        })
      },
      {
        name                     = "tilt_up"
        data_source              = "tilt_up"
        capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
        observability_mode       = "none"
        data_point_configuration = jsonencode({
          pan_tilt = { x = 0.0, y = 0.5 }
          zoom     = { x = 0.0 }
        })
      },
      {
        name                     = "tilt_down"
        data_source              = "tilt_down"
        capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
        observability_mode       = "none"
        data_point_configuration = jsonencode({
          pan_tilt = { x = 0.0, y = -0.5 }
          zoom     = { x = 0.0 }
        })
      },
      {
        name                     = "stop"
        data_source              = "stop"
        capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
        observability_mode       = "none"
        data_point_configuration = jsonencode({
          pan_tilt = { x = 0.0, y = 0.0 }
          zoom     = { x = 0.0 }
        })
      }
EOF

        # Add zoom controls if PTZ
        if [ "${PTZ_TYPE}" = "ptz" ] || [ "${PTZ_TYPE}" = "ptz_home" ]; then
            cat >> "${tfvars_file}" <<EOF
,
      {
        name                     = "zoom_in"
        data_source              = "zoom_in"
        capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
        observability_mode       = "none"
        data_point_configuration = jsonencode({
          pan_tilt = { x = 0.0, y = 0.0 }
          zoom     = { x = 0.5 }
        })
      },
      {
        name                     = "zoom_out"
        data_source              = "zoom_out"
        capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
        observability_mode       = "none"
        data_point_configuration = jsonencode({
          pan_tilt = { x = 0.0, y = 0.0 }
          zoom     = { x = -0.5 }
        })
      }
EOF
        fi

        # Add home position if PTZ with home
        if [ "${PTZ_TYPE}" = "ptz_home" ]; then
            cat >> "${tfvars_file}" <<EOF
,
      {
        name                     = "go_home"
        data_source              = "go_home"
        capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/GotoHomePosition"
        observability_mode       = "none"
        data_point_configuration = jsonencode({})
      }
EOF
        fi

        # Close data_points array
        cat >> "${tfvars_file}" <<EOF

    ]
  }
]
EOF
    else
        # No PTZ - empty assets array
        cat >> "${tfvars_file}" <<EOF
# No PTZ assets (fixed camera)
namespaced_assets = []
EOF
    fi

    print_success "Terraform configuration generated: ${tfvars_file}"
}

################################################################################
# Deploy with Terraform
################################################################################

deploy_terraform() {
    print_header "Deploying with Terraform"

    cd "${TERRAFORM_DIR}"

    local tfvars_file="${CAMERA_NAME}-deployment.tfvars"

    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        print_info "Initializing Terraform..."
        if ! terraform init; then
            print_error "Terraform initialization failed"
            exit 1
        fi
        print_success "Terraform initialized"
    fi

    # Terraform plan
    print_info "Running terraform plan..."
    if ! terraform plan -var-file="${tfvars_file}" -out="${CAMERA_NAME}.tfplan"; then
        print_error "Terraform plan failed"
        exit 1
    fi
    print_success "Terraform plan completed"

    echo ""
    if prompt_confirm "Apply Terraform plan?"; then
        print_info "Applying Terraform configuration..."
        if terraform apply "${CAMERA_NAME}.tfplan"; then
            print_success "Terraform deployment completed successfully!"
        else
            print_error "Terraform apply failed"
            exit 1
        fi
    else
        print_info "Deployment cancelled. Plan saved to ${CAMERA_NAME}.tfplan"
        exit 0
    fi
}

################################################################################
# Verify Deployment
################################################################################

verify_deployment() {
    print_header "Verifying Deployment"

    # Check device in Azure
    print_info "Checking device in Azure..."
    local device_id="${ADR_NAMESPACE_ID}/devices/${CAMERA_NAME}"
    if az resource show --ids "${device_id}" &> /dev/null; then
        print_success "Device '${CAMERA_NAME}' found in Azure"

        local provisioning_state=$(az resource show --ids "${device_id}" --query "properties.provisioningState" -o tsv)
        print_info "Provisioning state: ${provisioning_state}"
    else
        print_warning "Device not found in Azure (may take a moment to appear)"
    fi

    # Check asset in Azure if PTZ
    if [ "${PTZ_TYPE}" != "none" ]; then
        print_info "Checking PTZ asset in Azure..."
        local asset_id="${ADR_NAMESPACE_ID}/assets/${CAMERA_NAME}-ptz"
        if az resource show --ids "${asset_id}" &> /dev/null; then
            print_success "Asset '${CAMERA_NAME}-ptz' found in Azure"

            local asset_state=$(az resource show --ids "${asset_id}" --query "properties.provisioningState" -o tsv)
            print_info "Asset provisioning state: ${asset_state}"
        else
            print_warning "Asset not found in Azure (may take a moment to appear)"
        fi
    fi

    # Check ONVIF connector logs
    print_info "Checking ONVIF connector logs..."
    if kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=20 2>/dev/null | grep -i "${CAMERA_NAME}"; then
        print_success "Camera activity found in ONVIF connector logs"
    else
        print_warning "No recent camera activity in logs (this may be normal)"
    fi
}

################################################################################
# Display Summary
################################################################################

display_summary() {
    print_header "Deployment Summary"

    echo "Camera Deployment Completed!"
    echo ""
    echo "Camera Information:"
    echo "  Name: ${CAMERA_NAME}"
    echo "  URL: ${CAMERA_URL}"
    echo "  PTZ Type: ${PTZ_TYPE}"
    echo ""
    echo "Azure Resources:"
    echo "  Subscription: ${SUBSCRIPTION_ID}"
    echo "  Resource Group: ${RESOURCE_GROUP}"
    echo "  Custom Location: ${CUSTOM_LOCATION}"
    echo "  ADR Namespace: ${ADR_NAMESPACE}"
    echo ""
    echo "Kubernetes:"
    echo "  Secret: ${CAMERA_NAME}-credentials (azure-iot-operations namespace)"
    echo ""
    echo "Terraform:"
    echo "  Config: ${TERRAFORM_DIR}/${CAMERA_NAME}-deployment.tfvars"
    echo ""
    echo "Next Steps:"
    echo "  1. Monitor ONVIF connector logs:"
    echo "     kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector -f"
    echo ""
    echo "  2. View device in Azure Portal:"
    echo "     https://portal.azure.com/#@/resource${ADR_NAMESPACE_ID}/devices/${CAMERA_NAME}"
    echo ""
    if [ "${PTZ_TYPE}" != "none" ]; then
        echo "  3. Test PTZ control via MQTT (example):"
        echo "     mosquitto_pub -h <mqtt-broker> -t \"cameras/${CAMERA_NAME}/ptz/pan_left\" -m \"1\""
        echo ""
    fi
    echo "For more information, see:"
    echo "  - ONVIF-CAMERA-QUICKSTART.md"
    echo "  - ONVIF-CAMERA-DEPLOYMENT.md"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "ONVIF Camera Deployment - Terraform"

    echo "This script will deploy an ONVIF camera to Azure IoT Operations"
    echo "using Terraform and the 111-assets component."
    echo ""

    if ! prompt_confirm "Continue?"; then
        echo "Deployment cancelled."
        exit 0
    fi

    check_prerequisites
    gather_camera_info
    test_onvif_connection
    gather_azure_info
    create_kubernetes_secret
    determine_ptz_capabilities
    generate_terraform_config
    deploy_terraform
    verify_deployment
    display_summary

    print_success "All done! 🎉"
}

# Run main function
main "$@"
