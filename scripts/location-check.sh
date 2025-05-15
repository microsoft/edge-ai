#!/usr/bin/env bash

set -e

# Display usage information
function show_usage {
  echo
  echo "Usage $0 [-b, --blueprint <directory>] [-m, --method <bicep, terraform>]"
  echo
  echo "Flags:"
  echo "  -b, --blueprint : blueprint directory (e.g. full-multi-node-cluster)"
  echo "  -m, --method    : deployment method [bicep, terraform]"
  echo "  -h, --help      : show this text"
  exit 1
}

# =============================================================================
# crawls a given bicep file (and all referenced module files) to find all
# referenced resource types in format Microsoft.Namespace/type
# =============================================================================
bicep_get_resources () {
  # check that the provided argument is a file
  if [[ ! -f "$1" ]]
  then
    return 1
  fi

  mapfile -t resources < <(grep -E "^resource " "$1" | cut -d "'" -f 2 - | cut -d "@" -f 1 -)
  mapfile -t modules < <(grep -E "^module " "$1" | cut -d "'" -f 2 -)

  directory=$(dirname "$1")

  for module in "${modules[@]}"
  do
    mapfile -t -O "${#resources[@]}" resources < <(bicep_get_resources "$directory/$module")
  done

  for resource in "${resources[@]}"; do echo "${resource}"; done
}

# =============================================================================
# crawls a given terraform file (and all referenced module files) to find all
# referenced resource types - but they are in terraform names...
# =============================================================================
terraform_get_resources() {
  # check that the provided argument is a directory
  if [[ ! -d "$1" ]]
  then
    return 1
  fi

  directory=$(dirname "$1/.")
  mapfile -t resources < <(grep -E "^resource " "$directory/main.tf" | cut -d '"' -f 2 -)
  mapfile -t modules < <(grep -E "^\s+source " "$directory/main.tf" | cut -d '"' -f 2 -)

  for module in "${modules[@]}"
  do
    if [[ $module == *json ]]
    then
      continue
    fi
    mapfile -t -O "${#resources[@]}" resources < <(terraform_get_resources "$directory/$module")
  done

  for resource in "${resources[@]}"; do echo "${resource}"; done
}

# =============================================================================
# Execution starts here
# =============================================================================

# =============================================================================
# Check for required tooling
# =============================================================================

for tool in sort comm grep az
do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: Missing required tool, $tool" >&2
    exit 1
  fi
done

# =============================================================================
# Get command line arguments
# =============================================================================
blueprint=""
method=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      show_usage
      ;;
    -b | --blueprint)
      shift
      blueprint=$1
      shift
      ;;
    -m | --method)
      shift
      method=$1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      ;;
  esac
done

# =============================================================================
# Check provided values
# =============================================================================

# gets script directory
script_dir=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

cd "$script_dir/../blueprints"

if [[ -z "$blueprint" ]]
then
  echo "Please provide a blueprint"
  show_usage
elif [[ ! -d "$blueprint" ]]
then
  echo "Cannot find blueprint directory $1"
  show_usage
fi

if [[ -z "$method" ]]
then
  echo "Please provide a deployment method"
  show_usage
elif [[ "$method" != "bicep" && "$method" != "terraform" ]]
then
  echo "Invalid method $1"
  show_usage
fi

# =============================================================================
# Output provided values
# =============================================================================
echo ">>> Input"
echo "================================================================"
echo "> Blueprint: $blueprint"
echo "> Method:    $method"
echo "================================================================"
echo

cd "$blueprint/$method"

# =============================================================================
# Find resources
# =============================================================================
declare -a resources=()

case "$method" in
  "bicep" | "bicep/")
    mapfile -t resources < <(bicep_get_resources "main.bicep" | sort -u)
    ;;
  "terraform" | "terraform/")
    mapfile -t resources < <(terraform_get_resources "." | sort -u)
    ;;
esac

# return value of 1 indicates failure
if [[ ${#resources[@]} -eq 0 ]]
then
  echo "failed to find resources"
  exit 1
fi

# =============================================================================
# Report resources
# =============================================================================
echo ">>> Resources found"
echo "================================================================"
for resource in "${resources[@]}"; do echo "${resource}"; done
echo "================================================================"

# =============================================================================
# Fail on terraform
# =============================================================================
if [[ $method == "terraform/" || $method == "terraform" ]]
then
  echo
  echo "terraform is not currently supported for location checking"
exit 1
fi

# =============================================================================
# Get locations and find intersection
# =============================================================================
echo
echo "Finding workable locations..."

az account list-locations --query "[].displayName" -o tsv \
  | sort > "regions.txt"

for resource in "${resources[@]}"
do
  namespace=$(echo "$resource" | cut -d "/" -f 1 -)
  resourceType=$(echo "$resource" | cut -d "/" -f 2 -)

  cp "regions.txt" "oldRegions.txt"

  az provider show --namespace "$namespace" \
    --query "resourceTypes[?resourceType=='$resourceType'].locations | [0]" \
    --out tsv \
    | sort > "newRegions.txt"

  # roleAssignments etc have no regions, and should be ignored
  if [[ $(wc -l "newRegions.txt" | cut -d " " -f 1 -) -eq 0 ]]
  then
    continue
  fi

  # intersection of two files
  comm -12 "oldRegions.txt" "newRegions.txt" > "regions.txt"
done

# =============================================================================
# Report locations
# =============================================================================
echo "================================================================"
echo
echo ">>> Available regions"
echo "================================================================"
cat regions.txt

echo "================================================================"
echo
echo "Regions written to $(pwd)/regions.txt"
rm oldRegions.txt newRegions.txt
