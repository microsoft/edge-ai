#!/bin/bash
# Helper script to run deployment tests for both Terraform and Bicep

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [terraform|bicep|both] [options]"
    echo ""
    echo "Arguments:"
    echo "  terraform    Run only Terraform deployment tests"
    echo "  bicep        Run only Bicep deployment tests"
    echo "  both         Run both Terraform and Bicep tests (default)"
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Enable verbose test output"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ARM_SUBSCRIPTION_ID    Azure subscription ID (auto-detected if not set)"
    echo "  ADMIN_PASSWORD         (Required for Bicep) VM admin password"
    echo "  CUSTOM_LOCATIONS_OID   Custom Locations OID (auto-detected if not set)"
    echo ""
    echo "Examples:"
    echo "  $0 terraform"
    echo "  $0 bicep -v"
    echo "  $0 both"
}

# Parse arguments
DEPLOYMENT_TYPE="both"
VERBOSE_FLAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        terraform|bicep|both)
            DEPLOYMENT_TYPE="$1"
            shift
            ;;
        -v|--verbose)
            VERBOSE_FLAG="-v"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Auto-detect ARM_SUBSCRIPTION_ID if not set
if [[ -z "${ARM_SUBSCRIPTION_ID}" ]]; then
    echo -e "${YELLOW}ARM_SUBSCRIPTION_ID not set, detecting from Azure CLI...${NC}"
    ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
    if [[ -z "${ARM_SUBSCRIPTION_ID}" ]]; then
        echo -e "${RED}Error: Could not auto-detect ARM_SUBSCRIPTION_ID. Please run 'az login' or set ARM_SUBSCRIPTION_ID${NC}"
        exit 1
    fi
    echo -e "${GREEN}Detected subscription: ${ARM_SUBSCRIPTION_ID}${NC}"
    export ARM_SUBSCRIPTION_ID
fi

# Auto-detect CUSTOM_LOCATIONS_OID if not set (for Bicep tests)
if [[ -z "${CUSTOM_LOCATIONS_OID}" ]] && [[ "$DEPLOYMENT_TYPE" == "bicep" || "$DEPLOYMENT_TYPE" == "both" ]]; then
    echo -e "${YELLOW}CUSTOM_LOCATIONS_OID not set, detecting from Azure AD...${NC}"
    CUSTOM_LOCATIONS_OID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv 2>/dev/null)
    if [[ -z "${CUSTOM_LOCATIONS_OID}" ]]; then
        echo -e "${RED}Error: Could not auto-detect CUSTOM_LOCATIONS_OID. Please ensure you have permissions to query Azure AD${NC}"
        exit 1
    fi
    echo -e "${GREEN}Detected Custom Locations OID: ${CUSTOM_LOCATIONS_OID}${NC}"
    export CUSTOM_LOCATIONS_OID
fi

# Generate strong admin password if not provided (for Bicep tests)
if [[ -z "${ADMIN_PASSWORD}" ]] && [[ "$DEPLOYMENT_TYPE" == "bicep" || "$DEPLOYMENT_TYPE" == "both" ]]; then
    echo -e "${YELLOW}ADMIN_PASSWORD not set, generating strong password...${NC}"
    ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-24)
    # Ensure password meets Azure complexity requirements (uppercase, lowercase, digit, special char)
    ADMIN_PASSWORD="Aa1!${ADMIN_PASSWORD}"
    echo -e "${GREEN}Generated admin password (save this): ${ADMIN_PASSWORD}${NC}"
    export ADMIN_PASSWORD
fi

echo -e "${GREEN}=== Deployment Tests ===${NC}"
# Set default test configuration values
export TEST_ENVIRONMENT="${TEST_ENVIRONMENT:-dev}"
export TEST_LOCATION="${TEST_LOCATION:-eastus2}"
export TEST_RESOURCE_PREFIX="${TEST_RESOURCE_PREFIX:-t$RANDOM}"
export TEST_INSTANCE="${TEST_INSTANCE:-001}"

echo "Deployment Type: $DEPLOYMENT_TYPE"
echo "ARM Subscription: ${ARM_SUBSCRIPTION_ID}"
echo "Resource Prefix: ${TEST_RESOURCE_PREFIX}"
echo "Location: ${TEST_LOCATION}"
echo ""

run_terraform_tests() {
    export TEST_RESOURCE_GROUP_NAME="${TEST_RESOURCE_GROUP_NAME_PREFIX:-test-}terraform"
    echo "Resource Group: ${TEST_RESOURCE_GROUP_NAME}"

    echo -e "${YELLOW}Running Terraform deployment tests...${NC}"
    if go test $VERBOSE_FLAG -run TestTerraformFullSingleNodeClusterDeploy -timeout 2h; then
        echo -e "${GREEN}✓ Terraform tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Terraform tests failed${NC}"
        return 1
    fi
}

run_bicep_tests() {
    export TEST_RESOURCE_GROUP_NAME="${TEST_RESOURCE_GROUP_NAME_PREFIX:-test-}bicep"
    echo "Resource Group: ${TEST_RESOURCE_GROUP_NAME}"

    echo -e "${YELLOW}Running Bicep deployment tests...${NC}"
    if go test $VERBOSE_FLAG -run TestBicepFullSingleNodeClusterDeploy -timeout 2h; then
        echo -e "${GREEN}✓ Bicep tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Bicep tests failed${NC}"
        return 1
    fi
}

# Run tests based on deployment type
EXIT_CODE=0

case $DEPLOYMENT_TYPE in
    terraform)
        run_terraform_tests || EXIT_CODE=$?
        ;;
    bicep)
        run_bicep_tests || EXIT_CODE=$?
        ;;
    both)
        run_terraform_tests || EXIT_CODE=$?
        echo ""
        run_bicep_tests || EXIT_CODE=$?
        ;;
esac

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}=== All tests completed successfully ===${NC}"
else
    echo -e "${RED}=== Some tests failed ===${NC}"
fi

exit $EXIT_CODE
