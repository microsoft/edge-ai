#!/bin/bash
# Helper script to run contract tests for Terraform and Bicep
# Contract tests validate IaC outputs without deployment (fast, $0 cost)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    cat << EOF
Usage: $0 [terraform|bicep|both] [options]

Run static contract tests to validate IaC outputs match test requirements.
These tests run in seconds without deploying any Azure resources.

Arguments:
  terraform    Run only Terraform contract test
  bicep        Run only Bicep contract test
  both         Run both tests (default)

Options:
  -v, --verbose    Enable verbose test output
  -h, --help       Show this help message

Examples:
  $0               # Run both contract tests
  $0 terraform     # Run only Terraform contract test
  $0 bicep -v      # Run only Bicep with verbose output

Contract Tests:
  ✓ Terraform: Validates outputs.tf using terraform-docs
  ✓ Bicep:     Validates main.bicep outputs using az bicep build
  ✓ Fast:      Complete in <5 seconds
  ✓ Zero Cost: No Azure resources deployed

Dependencies:
  - terraform-docs (brew install terraform-docs)
  - az bicep (az bicep install)
  - Go toolchain (go test)
EOF
}

# Parse arguments
TEST_TYPE="both"
VERBOSE_FLAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        terraform|bicep|both)
            TEST_TYPE="$1"
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

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Contract Tests - Static Validation               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Test Type:${NC} $TEST_TYPE"
echo -e "${GREEN}Directory:${NC} $(basename "$(dirname "$SCRIPT_DIR")")/tests"
echo ""

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

# Check Go
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go not found. Please install Go toolchain.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Go:            $(go version | awk '{print $3}')${NC}"

# Check terraform-docs
if [[ "$TEST_TYPE" == "terraform" || "$TEST_TYPE" == "both" ]]; then
    if ! command -v terraform-docs &> /dev/null; then
        echo -e "${RED}✗ terraform-docs not found${NC}"
        echo -e "${YELLOW}  Install: brew install terraform-docs${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ terraform-docs: $(terraform-docs version | head -n1)${NC}"
fi

# Check az bicep
if [[ "$TEST_TYPE" == "bicep" || "$TEST_TYPE" == "both" ]]; then
    if ! command -v az &> /dev/null; then
        echo -e "${RED}✗ Azure CLI not found${NC}"
        echo -e "${YELLOW}  Install: https://docs.microsoft.com/cli/azure/install-azure-cli${NC}"
        exit 1
    fi

    # Check bicep is installed
    if ! az bicep version &> /dev/null; then
        echo -e "${RED}✗ Bicep not installed${NC}"
        echo -e "${YELLOW}  Install: az bicep install${NC}"
        exit 1
    fi
fi

echo ""

# Run tests
EXIT_CODE=0

run_test() {
    local test_name=$1
    local test_pattern=$2

    echo -e "${BLUE}──────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Running: $test_name${NC}"
    echo -e "${BLUE}──────────────────────────────────────────────────────────${NC}"

    if go test $VERBOSE_FLAG -run "$test_pattern" .; then
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
    else
        echo -e "${RED}✗ $test_name FAILED${NC}"
        EXIT_CODE=1
    fi
    echo ""
}

case $TEST_TYPE in
    terraform)
        run_test "Terraform Contract Test" "TestTerraformOutputsContract"
        ;;
    bicep)
        run_test "Bicep Contract Test" "TestBicepOutputsContract"
        ;;
    both)
        run_test "Terraform Contract Test" "TestTerraformOutputsContract"
        run_test "Bicep Contract Test" "TestBicepOutputsContract"
        ;;
esac

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${BLUE}║${GREEN}                   All Tests PASSED ✓                       ${BLUE}║${NC}"
else
    echo -e "${BLUE}║${RED}                   Some Tests FAILED ✗                      ${BLUE}║${NC}"
fi
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

exit $EXIT_CODE
