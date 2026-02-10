#!/usr/bin/env bash
# Script to list Microsoft Fabric capacities and prompt user to select one
# The selected capacity ID is saved for use by Terraform

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Output directory for storing capacity ID
OUTPUT_DIR="../terraform"
OUTPUT_FILE="fabric_capacity.auto.tfvars"

echo -e "${BLUE}Authenticating with Azure CLI...${NC}"
# Check if user is logged in
az account show &>/dev/null || {
  echo "You need to log in to Azure first."
  az login
}

echo -e "${BLUE}Fetching Microsoft Fabric capacities...${NC}"

# Use the Microsoft Fabric API to list capacities
# This uses the Fabric REST API through Azure CLI auth tokens
TOKEN=$(az account get-access-token --resource "https://api.fabric.microsoft.com/" --query accessToken -o tsv)

# Call the Fabric API to list capacities
RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.fabric.microsoft.com/v1/capacities")

# Parse the JSON response
CAPACITIES=$(echo "${RESPONSE}" | jq -r '.value')

# Check if we got any capacities
if [ "$(echo "${CAPACITIES}" | jq 'length')" -eq "0" ]; then
  echo -e "${YELLOW}No Microsoft Fabric capacities found for your account.${NC}"
  echo -e "You can continue without specifying a capacity (using the Fabric free tier)."

  # Ask if they want to continue without a capacity
  read -r -p "Continue without a capacity? (y/n): " CONTINUE
  if [[ "${CONTINUE}" == "y" || "${CONTINUE}" == "Y" ]]; then
    mkdir -p "${OUTPUT_DIR}"
    echo "capacity_id = \"\"" >"${OUTPUT_DIR}/${OUTPUT_FILE}"
    echo -e "${GREEN}Configuration set to use Fabric free tier.${NC}"
    exit 0
  else
    echo "Operation cancelled."
    exit 1
  fi
fi

# Print a complete capacity for debugging
echo -e "${BLUE}Examining capacity structure...${NC}"
SAMPLE_CAPACITY=$(echo "${CAPACITIES}" | jq -r '.[0]')
echo "Sample capacity structure:"
echo "${SAMPLE_CAPACITY}" | jq '.'

# Filter capacities where user has write access
echo -e "${BLUE}Filtering capacities where you have write access...${NC}"

# Display available capacities
echo -e "${BLUE}Available Microsoft Fabric capacities you can use:${NC}"
echo "--------------------------------------------------------"
echo "ID  | Name | Access Role | SKU | State"
echo "--------------------------------------------------------"

# Use process substitution and readarray to avoid subshell issues
mapfile -t CAPACITY_ITEMS < <(echo "${CAPACITIES}" | jq -c '.[]')

# Initialize variables outside the loop
declare -A CAPACITY_IDS
declare -A CAPACITY_NAMES
COUNT=1
TOTAL_AVAILABLE=0

# Process each capacity and check for user access
for CAPACITY in "${CAPACITY_ITEMS[@]}"; do
  ID=$(echo "${CAPACITY}" | jq -r '.id')
  NAME=$(echo "${CAPACITY}" | jq -r '.displayName // "Unnamed"')

  # Try different possible paths for admin/roles information
  ADMIN=$(echo "${CAPACITY}" | jq -r '.roles[].principalId // .properties.administratorIds[] // .administrators[] // "unknown"' 2>/dev/null || echo "unknown")

  SKU=$(echo "${CAPACITY}" | jq -r '.sku // "unknown"')
  STATE=$(echo "${CAPACITY}" | jq -r '.properties.state // .state // "unknown"')

  # List all capacities since we're not sure how to filter by access
  echo "${COUNT} | ${NAME} | ${ADMIN} | ${SKU} | ${STATE}"
  CAPACITY_IDS["${COUNT}"]="${ID}"
  CAPACITY_NAMES["${COUNT}"]="${NAME}"
  COUNT=$((COUNT + 1))
  TOTAL_AVAILABLE=$((TOTAL_AVAILABLE + 1))
done

echo "--------------------------------------------------------"
echo -e "${YELLOW}Note: The actual access roles may not be accurately displayed.${NC}"
echo -e "${YELLOW}Select a capacity you know you have admin access to.${NC}"

# Now TOTAL_AVAILABLE is correctly tracked outside of any subshell
if [ "${TOTAL_AVAILABLE}" -eq 0 ]; then
  echo -e "${YELLOW}No Microsoft Fabric capacities found where you have write access.${NC}"
  echo -e "You can continue without specifying a capacity (using the Fabric free tier)."

  # Ask if they want to continue without a capacity
  read -r -p "Continue without a capacity? (y/n): " CONTINUE
  if [[ "${CONTINUE}" == "y" || "${CONTINUE}" == "Y" ]]; then
    mkdir -p "${OUTPUT_DIR}"
    echo "capacity_id = \"\"" >"${OUTPUT_DIR}/${OUTPUT_FILE}"
    echo -e "${GREEN}Configuration set to use Fabric free tier.${NC}"
    exit 0
  else
    echo "Operation cancelled."
    exit 1
  fi
fi

# Prompt user to select a capacity
echo -e "${YELLOW}Select a capacity by number (or enter 0 to use free tier):${NC}"
read -r SELECTION

# Validate selection
if [[ "${SELECTION}" -eq 0 ]]; then
  SELECTED_ID=""
  echo -e "${GREEN}Using Fabric free tier (no capacity).${NC}"
elif [[ "${SELECTION}" -ge 1 && "${SELECTION}" -lt "${COUNT}" ]]; then
  SELECTED_ID="${CAPACITY_IDS["${SELECTION}"]}"
  SELECTED_NAME="${CAPACITY_NAMES["${SELECTION}"]}"
  echo -e "${GREEN}Selected capacity: ${SELECTED_NAME} (${SELECTED_ID})${NC}"
else
  echo "Invalid selection."
  exit 1
fi

# Create the output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Write the selected capacity ID to the Terraform variables file
echo "capacity_id = \"${SELECTED_ID}\"" >"${OUTPUT_DIR}/${OUTPUT_FILE}"

echo -e "${GREEN}Capacity ID saved to ${OUTPUT_DIR}/${OUTPUT_FILE}${NC}"
echo -e "${BLUE}You can now run terraform apply to deploy using this capacity.${NC}"
