#!/usr/bin/env python3

"""
AIO Version Checker

This script compares the version and train of components in either Terraform or
Bicep configuration files with AIO components defined in remote JSON files. It
outputs any mismatches found and is useful for build systems to ensure that the
most recent released versions of AIO components and trains are being used.

Functionality:
        - Checks Terraform variables in
            ./src/040-iot-ops/terraform/variables.init.tf
        - Checks Terraform instance variables in
            ./src/040-iot-ops/terraform/variables.instance.tf
        - Checks Bicep variables in ./src/040-iot-ops/bicep/types.bicep
                - Resolves latest release via the GitHub API and derives
                    manifest URLs
            - If JSON assets are not present in the release, falls back to the
                release branch/tag to fetch the JSON files
        - Compares with latest versions and trains from remote manifest files
        - Reports any mismatches in versions or trains

Parameters:
    --error-on-mismatch: Exit with error code 1 if versions don't match
    -v, --verbose: Enable verbose output
    -t, --iac-type: Type of IaC files to check (terraform, bicep, or all)
    --strict-latest: Fail if latest release cannot be resolved; do not use
                     legacy fallbacks
    --require-asset-files: Require JSON manifests to be present as release
                           assets; if missing, exit instead of using branch
                           fallback
    --print-manifest-urls: Resolve and print only the two manifest URLs
                           (enablement and instance) as JSON to stdout and exit
    --release-tag TAG:     Resolve URLs for a specific release tag (e.g. v1.2.36)
    --channel {stable,preview}: When no tag is provided, choose latest stable
                           (default) or latest preview release

Returns:
    JSON array: Outputs a list of mismatches found, with each mismatch
    containing details about the component, local and remote versions/trains

Raises:
    Exception: If manifests cannot be downloaded or parsed
    SystemExit: If script terminates due to errors or mismatches

Dependencies:
    - requests: For downloading remote manifest files
    - hcl2: For parsing Terraform configuration files

Example:
    # Check all IaC types for version mismatches
    python aio-version-checker.py

    # Check only Terraform files with verbose output
    python aio-version-checker.py -t terraform -v

    # Check all IaC types and exit with error if mismatches found
    python aio-version-checker.py --error-on-mismatch

Notes:
    The script is designed to ensure that infrastructure code in a repository
    stays up-to-date with the latest released versions of Azure IoT Operations
    components.

See Also:
        - Azure IoT Operations docs:
            https://learn.microsoft.com/azure/iot-operations
        - AIO manifest files (raw):
            https://raw.githubusercontent.com/Azure/azure-iot-operations/main/
            release/azure-iot-operations-enablement.json
            https://raw.githubusercontent.com/Azure/azure-iot-operations/main/
            release/azure-iot-operations-instance.json
"""

import argparse
import os
import json
import logging
import re
import sys
from typing import Dict, List, Any, Literal, Union, Tuple, Optional

import hcl2
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="[%(levelname)s] %(message)s", stream=sys.stderr
)
logger = logging.getLogger("aio-version-checker")

# Constants
# Legacy default URLs (used only as last-resort fallback if requested)
AIO_MANIFEST_VERSIONS_URL = "https://raw.githubusercontent.com/Azure/azure-iot-operations/main/release/azure-iot-operations-enablement.json"
AIO_MANIFEST_INSTANCE_VERSIONS_URL = "https://raw.githubusercontent.com/Azure/azure-iot-operations/main/release/azure-iot-operations-instance.json"
TERRAFORM_VARS_FILE = "./src/100-edge/110-iot-ops/terraform/variables.init.tf"
TERRAFORM_VARS_INSTANCE_FILE = (
    "./src/100-edge/110-iot-ops/terraform/variables.instance.tf"
)
BICEP_VARS_FILE = "./src/100-edge/110-iot-ops/bicep/types.bicep"

# IaC type definition (discriminated union)
IaCType = Literal["terraform", "bicep"]

# Component mappings for Terraform (local_name:remote_name)
TERRAFORM_COMPONENTS = [
    "platform:platform",
    "secret_sync_controller:secretStore",
    "edge_storage_accelerator:containerStorage",
    "azure-iot-operations:iotOperations",  # Maps to iotOperations in manifest
]

# Component mappings for Bicep (bicep_name:remote_name)
BICEP_COMPONENTS = [
    "aioPlatformExtensionDefaults:platform",
    "secretStoreExtensionDefaults:secretStore",
    "containerStorageExtensionDefaults:containerStorage",
    "aioExtensionDefaults:iotOperations",  # Maps to iotOperations in manifest
]


def parse_args() -> argparse.Namespace:
    """
    Parse command-line arguments for the version checker.

    Returns:
        argparse.Namespace: An object containing the parsed command-line arguments.
            --error-on-mismatch: Exit with error code 1 if versions don't match
            --verbose (-v): Enable verbose output
            --iac-type: Type of IaC files to check (terraform, bicep, or all)
    """
    parser = argparse.ArgumentParser(
        description="Check AIO component versions against latest releases."
    )
    parser.add_argument(
        "--error-on-mismatch",
        action="store_true",
        help="Exit with error code 1 if versions don't match",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose output"
    )
    parser.add_argument(
        "-t",
        "--iac-type",
        choices=["terraform", "bicep", "all"],
        default="all",
        help="Type of IaC files to check (terraform, bicep, or all) [default: all]",
    )
    parser.add_argument(
        "--strict-latest",
        action="store_true",
        help=(
            "Fail if latest release information cannot be resolved via GitHub API; "
            "do not fall back to legacy URLs."
        ),
    )
    parser.add_argument(
        "--require-asset-files",
        action="store_true",
        help=(
            "Require JSON manifests to be present as release assets; if missing, "
            "exit with error instead of falling back to tag branch URLs."
        ),
    )
    parser.add_argument(
        "--print-manifest-urls",
        action="store_true",
        help=(
            "Print only the resolved manifest URLs as JSON and exit. Useful for external tooling."
        ),
    )
    parser.add_argument(
        "--release-tag",
        dest="release_tag",
        default=None,
        help=(
            "Specific release tag to resolve (e.g., v1.2.36). If provided, overrides --channel."
        ),
    )
    parser.add_argument(
        "--channel",
        choices=["stable", "preview"],
        default="stable",
        help=(
            "When no --release-tag is provided, resolve the latest release from this channel."
        ),
    )
    return parser.parse_args()


def get_latest_manifest_urls(
    require_asset_files: bool = False,
    strict_latest: bool = False,
    timeout: int = 10,
    release_tag: Optional[str] = None,
    channel: Literal["stable", "preview"] = "stable",
) -> Tuple[str, str, Dict[str, str]]:
    """
    Resolve URLs for the enablement and instance manifests from the latest GitHub release.

    Logic:
    - If release_tag is provided, call releases/tags/{tag}.
    - Else if channel == 'preview', call releases and pick the latest prerelease.
    - Else call releases/latest to get tag_name and target_commitish.
    - If assets include the two JSON files, use their browser_download_url.
    - Otherwise, fall back to raw.githubusercontent.com using target_commitish
      (typically 'release/<tag>') and known paths under /release/.
    - If require_asset_files is True and assets are missing, raise.
    - If strict_latest is True and API call fails, raise.

    Returns:
        (enablement_url, instance_url, meta)
        meta includes keys: 'source' ('assets' or 'branch'), 'tag_name', 'target_commitish'.
    """
    # Prepare optional auth header to avoid rate limits when GITHUB_TOKEN is set
    headers = {}
    github_token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if github_token:
        headers["Authorization"] = f"Bearer {github_token}"

    # Determine which API endpoint to call based on inputs
    if release_tag:
        api_url = f"https://api.github.com/repos/Azure/azure-iot-operations/releases/tags/{release_tag}"
        context_desc = f"release tag {release_tag}"
    elif channel == "preview":
        api_url = "https://api.github.com/repos/Azure/azure-iot-operations/releases"
        context_desc = "latest preview (pre-release)"
    else:
        api_url = "https://api.github.com/repos/Azure/azure-iot-operations/releases/latest"
        context_desc = "latest stable release"
    logger.debug(f"Querying GitHub API for {context_desc}: {api_url}")
    try:
        resp = requests.get(api_url, timeout=timeout, headers=headers)
        if resp.status_code == 403:
            logger.warning(
                "GitHub API rate limited. Set GITHUB_TOKEN to increase limits."
            )
        resp.raise_for_status()
        data = resp.json()
        # If preview channel requested, pick first prerelease from list
        if not release_tag and channel == "preview":
            if isinstance(data, list):
                preview = next((r for r in data if r.get("prerelease")), None)
                if preview is None:
                    raise RuntimeError("No preview releases found.")
                data = preview
            else:
                raise RuntimeError("Unexpected response for releases list.")
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to query latest release from GitHub API: {e}")
        if strict_latest:
            raise
        # Attempt to fall back to legacy constants
        return (
            AIO_MANIFEST_VERSIONS_URL,
            AIO_MANIFEST_INSTANCE_VERSIONS_URL,
            {"source": "legacy", "tag_name": "", "target_commitish": ""},
        )
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON response from GitHub API: {e}")
        if strict_latest:
            raise
        # Attempt to fall back to legacy constants
        return (
            AIO_MANIFEST_VERSIONS_URL,
            AIO_MANIFEST_INSTANCE_VERSIONS_URL,
            {"source": "legacy", "tag_name": "", "target_commitish": ""},
        )

    tag_name = data.get("tag_name") or ""
    target_commitish = data.get("target_commitish") or ""
    assets: List[Dict[str, Any]] = data.get("assets", []) or []

    logger.debug(
        f"Latest release tag: {tag_name}, target_commitish: {target_commitish}, assets: {len(assets)}"
    )

    # Try assets first
    asset_map = {a.get("name"): a for a in assets if isinstance(a, dict)}
    enablement_asset = asset_map.get("azure-iot-operations-enablement.json")
    instance_asset = asset_map.get("azure-iot-operations-instance.json")

    if enablement_asset and instance_asset:
        enablement_url = enablement_asset.get("browser_download_url") or ""
        instance_url = instance_asset.get("browser_download_url") or ""
        if enablement_url and instance_url:
            logger.debug("Resolved manifest URLs from release assets.")
            return (
                enablement_url,
                instance_url,
                {"source": "assets", "tag_name": tag_name,
                    "target_commitish": target_commitish},
            )

    # Assets missing
    if require_asset_files:
        raise RuntimeError(
            "Required manifest JSON files not found in release assets."
        )

    # Fall back to branch path using target_commitish if present; otherwise, derive from tag
    if not target_commitish and not tag_name:
        raise RuntimeError(
            "Cannot construct fallback URL: both target_commitish and tag_name are empty.")
    ref = target_commitish or f"release/{tag_name}".lstrip("/")
    # Build raw URLs to the files in the repository at the release branch/ref
    base_repo_raw = "https://raw.githubusercontent.com/Azure/azure-iot-operations"
    enablement_url = f"{base_repo_raw}/{ref}/release/azure-iot-operations-enablement.json"
    instance_url = f"{base_repo_raw}/{ref}/release/azure-iot-operations-instance.json"
    logger.debug(
        "Assets not found. Falling back to branch URLs: "
        f"enablement={enablement_url}, instance={instance_url}"
    )
    return (
        enablement_url,
        instance_url,
        {"source": "branch", "tag_name": tag_name,
            "target_commitish": target_commitish},
    )


def download_manifests(
    enablement_url: str,
    instance_url: str,
    timeout: int = 15,
) -> Dict[str, Dict[str, Any]]:
    """
    Download both AIO manifests (enablement and instance) from GitHub.

    The enablement manifest contains version information for platform components like
    secretStore, containerStorage, etc., while the instance manifest contains
    version information specific to the IoT Operations instance.

    Returns:
        Dict[str, Dict[str, Any]]: A dictionary containing both manifests with keys:
            'enablement': The enablement manifest data
            'instance': The instance manifest data

    Raises:
        Exception: If either manifest fails to download or parse
    """
    manifest_data = {}

    # Download the enablement manifest
    logger.debug(
        f"Downloading AIO enablement manifest from {enablement_url}"
    )
    try:
        response = requests.get(enablement_url, timeout=timeout)
        response.raise_for_status()
        manifest_data["enablement"] = response.json()

        # Enhanced debug logging for enablement manifest
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug("Enablement manifest structure:")
            if "variables" in manifest_data["enablement"]:
                vars_section = manifest_data["enablement"]["variables"]
                if "VERSIONS" in vars_section:
                    logger.debug(
                        "  VERSIONS keys found: "
                        + ", ".join(vars_section["VERSIONS"].keys())
                    )
                if "TRAINS" in vars_section:
                    logger.debug(
                        "  TRAINS keys found: "
                        + ", ".join(vars_section["TRAINS"].keys())
                    )
    except Exception as e:
        logger.error(f"Failed to download enablement manifest: {e}")
        raise

    # Download the instance manifest
    logger.debug(
        f"Downloading AIO instance manifest from {instance_url}"
    )
    try:
        response = requests.get(instance_url, timeout=timeout)
        response.raise_for_status()
        manifest_data["instance"] = response.json()

        # Enhanced debug logging for instance manifest
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug("Instance manifest structure:")
            if "variables" in manifest_data["instance"]:
                vars_section = manifest_data["instance"]["variables"]
                if "VERSIONS" in vars_section:
                    logger.debug(
                        "  VERSIONS keys found: "
                        + ", ".join(vars_section["VERSIONS"].keys())
                    )
                if "TRAINS" in vars_section:
                    logger.debug(
                        "  TRAINS keys found: "
                        + ", ".join(vars_section["TRAINS"].keys())
                    )
    except Exception as e:
        logger.error(f"Failed to download instance manifest: {e}")
        raise

    return manifest_data


def extract_tf_variables(tf_file: str) -> List[Dict[str, str]]:
    """
    Extract component information from the Terraform variables file using HCL2 parser.

    This function parses standard Terraform variable blocks with defaults containing
    version and train information, such as:

    variable "platform" {
      default = {
        version = "0.7.6"
        train = "preview"
      }
    }

    Args:
        tf_file (str): Path to the Terraform variables file to parse

    Returns:
        List[Dict[str, str]]: A list of dictionaries, each containing:
            'name': Component name
            'version': Component version
            'train': Component train

    Raises:
        SystemExit: If the file cannot be parsed
    """
    logger.debug(f"Reading Terraform variables file: {tf_file}")

    try:
        with open(tf_file, "r") as f:
            parsed = hcl2.load(f)
    except Exception as e:
        logger.error(f"Failed to parse Terraform file: {e}")
        sys.exit(1)

    variable_blocks = []

    # Process the parsed HCL
    if "variable" in parsed:
        variables = parsed["variable"]

        # Based on the provided structure, variables is a list of dictionaries
        if isinstance(variables, list):
            for var_item in variables:
                # Each item has a single key (the variable name)
                if isinstance(var_item, dict) and len(var_item) == 1:
                    var_name = list(var_item.keys())[0]
                    var_props = var_item[var_name]

                    # Check if default exists and contains version/train
                    if isinstance(var_props, dict) and "default" in var_props:
                        defaults = var_props["default"]
                        if isinstance(defaults, dict):
                            version = defaults.get("version", "")
                            train = defaults.get("train", "")

                            if version or train:
                                variable_blocks.append(
                                    {
                                        "name": var_name,
                                        "version": version,
                                        "train": train,
                                    }
                                )

    return variable_blocks


def extract_tf_instance_variables(tf_instance_file: str) -> List[Dict[str, str]]:
    """
    Extract AIO instance component information from the Terraform instance variables file.

    This function specifically looks for the 'operations_config' variable that contains
    version and train information for the Azure IoT Operations instance.

    Args:
        tf_instance_file (str): Path to the Terraform instance variables file

    Returns:
        List[Dict[str, str]]: A list with a single dictionary containing:
            'name': 'azure-iot-operations'
            'version': The AIO instance version
            'train': The AIO instance train
            'namespace': The namespace where AIO is deployed

    Raises:
        SystemExit: If the file cannot be parsed
    """
    logger.debug(
        f"Reading Terraform instance variables file: {tf_instance_file}")

    try:
        with open(tf_instance_file, "r") as f:
            parsed = hcl2.load(f)
    except Exception as e:
        logger.error(f"Failed to parse Terraform instance file: {e}")
        sys.exit(1)

    variable_blocks = []

    # Process the parsed HCL
    if "variable" in parsed:
        variables = parsed["variable"]

        # Look for operations_config
        for var_item in variables:
            if isinstance(var_item, dict) and "operations_config" in var_item:
                ops_config = var_item["operations_config"]

                if isinstance(ops_config, dict) and "default" in ops_config:
                    defaults = ops_config["default"]

                    if isinstance(defaults, dict):
                        version = defaults.get("version", "")
                        train = defaults.get("train", "")
                        namespace = defaults.get("namespace", "")

                        if version or train:
                            variable_blocks.append(
                                {
                                    "name": "azure-iot-operations",
                                    "version": version,
                                    "train": train,
                                    "namespace": namespace,
                                }
                            )
                            break

    return variable_blocks


def extract_bicep_variables(bicep_file: str) -> List[Dict[str, str]]:
    """
    Extract component information from the Bicep file using regex pattern matching.

    This function searches for Bicep variable declarations that match the component patterns
    defined in BICEP_COMPONENTS, and extracts version and train information from them.
    It looks for structures like:

    var aioPlatformExtensionDefaults = {
      release: {
        version: '0.7.6'
        train: 'preview'
      }
    }

    Args:
        bicep_file (str): Path to the Bicep file to parse

    Returns:
        List[Dict[str, str]]: A list of dictionaries, each containing:
            'name': The mapped component name (for comparison with Terraform components)
            'version': The component version
            'train': The component train

    Raises:
        SystemExit: If the file cannot be read
    """
    logger.debug(f"Reading Bicep variables file: {bicep_file}")

    try:
        with open(bicep_file, "r") as f:
            content = f.read()
    except IOError as e:
        logger.error(f"Failed to read Bicep file: {e}")
        sys.exit(1)

    variable_blocks = []

    # Use the specific Bicep component names for searching
    for bicep_component in BICEP_COMPONENTS:
        bicep_name, remote_name = bicep_component.split(":")

        # Find the component definition block
        var_pattern = f"var {bicep_name} = {{([\\s\\S]*?)}}"
        var_match = re.search(var_pattern, content)

        if var_match:
            full_block = var_match.group(0)  # Get the full matched block

            # Extract version using a direct pattern
            version_pattern = r"version: ['\"]?([^'\",\s]+)['\"]?"
            version_match = re.search(version_pattern, full_block)

            # Extract train using a direct pattern
            train_pattern = r"train: ['\"]?([^'\",\s]+)['\"]?"
            train_match = re.search(train_pattern, full_block)

            version = ""
            train = ""

            if version_match:
                version = version_match.group(1)

            if train_match:
                train = train_match.group(1)

            if version or train:
                # Create a mapping from remote name to Terraform component name
                remote_to_tf_map = {
                    comp.split(":")[1]: comp.split(":")[0]
                    for comp in TERRAFORM_COMPONENTS
                }

                # Map the Bicep component's remote name to the corresponding Terraform component name
                component_name = remote_to_tf_map.get(remote_name, remote_name)

                # Special case for aioExtensionDefaults
                if bicep_name == "aioExtensionDefaults":
                    component_name = "azure-iot-operations"

                variable_blocks.append(
                    {"name": component_name, "version": version, "train": train}
                )

    return variable_blocks


def extract_variables(iac_type: IaCType, file_path: str) -> List[Dict[str, str]]:
    """
    Extract variables from the appropriate files based on IaC type.

    This function is a dispatcher that calls the appropriate extraction function
    based on the specified IaC type. For Terraform, it extracts from both the
    standard variables file and the instance variables file and combines the results.

    Args:
        iac_type (IaCType): The type of IaC file to parse ('terraform' or 'bicep')
        file_path (str): Path to the file to parse

    Returns:
        List[Dict[str, str]]: A list of dictionaries containing component information

    Raises:
        ValueError: If an unsupported IaC type is specified
    """
    if iac_type == "terraform":
        # Get variables from both files and combine them
        variables = extract_tf_variables(TERRAFORM_VARS_FILE)
        instance_variables = extract_tf_instance_variables(
            TERRAFORM_VARS_INSTANCE_FILE)
        return variables + instance_variables
    elif iac_type == "bicep":
        return extract_bicep_variables(file_path)
    else:
        raise ValueError(f"Unsupported IaC type: {iac_type}")


def extract_remote_versions(
        manifests: Dict[str, Dict[str, Any]],
) -> Dict[str, Dict[str, str]]:
    """
    Extract remote versions and trains from the AIO manifests.

    This function processes both the enablement and instance manifests to extract
    version and train information for all components. Most components get their
    information from the enablement manifest, but IoT Operations gets its information
    from the instance manifest.

    Args:
        manifests (Dict[str, Dict[str, Any]]): Dictionary containing both manifests
            'enablement': The enablement manifest
            'instance': The instance manifest

    Returns:
        Dict[str, Dict[str, str]]: A dictionary mapping component names to their
            remote version and train information. Each entry contains:
            'version': The remote component version
            'train': The remote component train
    """
    remote_versions = {}

    # Debug log all component mappings
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Component mappings being checked:")
        for component in TERRAFORM_COMPONENTS:
            local_name, remote_name = component.split(":")
            logger.debug(f"  {local_name} -> {remote_name}")

    # Process standard components from enablement manifest
    enablement = manifests.get("enablement", {})
    instance = manifests.get("instance", {})

    # Debug log manifest structures
    if logger.isEnabledFor(logging.DEBUG):
        enablement_versions = enablement.get(
            "variables", {}).get("VERSIONS", {})
        instance_versions = instance.get("variables", {}).get("VERSIONS", {})
        logger.debug(
            f"Enablement manifest contains versions for: {list(enablement_versions.keys())}"
        )
        logger.debug(
            f"Instance manifest contains versions for: {list(instance_versions.keys())}"
        )

    for component in TERRAFORM_COMPONENTS:
        local_name, remote_name = component.split(":")

        # Check if this is the IoT Operations component
        if remote_name == "iotOperations":
            # Get IoT Operations version from instance manifest
            version = (
                instance.get("variables", {}).get(
                    "VERSIONS", {}).get(remote_name, "")
            )
            train = instance.get("variables", {}).get(
                "TRAINS", {}).get(remote_name, "")
            logger.debug(
                f"Found IoT Operations in instance manifest: version={version}, train={train}"
            )
        else:
            # Get other components from enablement manifest
            version = (
                enablement.get("variables", {}).get(
                    "VERSIONS", {}).get(remote_name, "")
            )
            train = (
                enablement.get("variables", {}).get(
                    "TRAINS", {}).get(remote_name, "")
            )
            logger.debug(
                f"Remote component {local_name} (remote: {remote_name}): version={version}, train={train}"
            )

        remote_versions[local_name] = {"version": version, "train": train}

    return remote_versions


def compare_versions(
        local_components: List[Dict[str, str]],
        remote_versions: Dict[str, Dict[str, str]],
        file_path: str,
        manifest_urls: Dict[str, str],
) -> List[Dict[str, str]]:
    """
    Compare local and remote versions to find mismatches.

    This function takes the local component information extracted from IaC files
    and compares them against the remote version information from the manifests.
    It identifies any version or train mismatches and returns details about them.

    Args:
        local_components (List[Dict[str, str]]): List of components from local IaC files
        remote_versions (Dict[str, Dict[str, str]]): Remote version information
        file_path (str): Path to the file the local components were extracted from
        manifest_urls (Dict[str, str]): URLs the remote versions were obtained from

    Returns:
        List[Dict[str, str]]: A list of dictionaries, each representing a mismatch with:
            'name': Component name
            'local_file': Path to the local file
            'remote_url': URL of the remote manifest
            'local_version': Local component version
            'remote_version': Remote component version
            'local_train': Local component train
            'remote_train': Remote component train
    """
    mismatches = []

    for component in local_components:
        name = component["name"]
        local_version = component["version"]
        local_train = component["train"]

        # Get remote values if they exist
        if name in remote_versions:
            remote_version = remote_versions[name]["version"]
            remote_train = remote_versions[name]["train"]

            # Determine which manifest URL was used for this component
            manifest_url = manifest_urls.get(
                name, manifest_urls.get("default", ""))

            version_mismatch = (
                local_version and remote_version and local_version != remote_version
            )
            train_mismatch = (
                local_train and remote_train and local_train != remote_train
            )

            if version_mismatch or train_mismatch:
                mismatches.append(
                    {
                        "name": name,
                        "local_file": file_path,
                        "remote_url": manifest_url,
                        "local_version": local_version,
                        "remote_version": remote_version,
                        "local_train": local_train,
                        "remote_train": remote_train,
                    }
                )

    return mismatches


def main() -> int:
    """
    Main function to check component versions.

    This function orchestrates the entire version checking process:
    1. Parse command-line arguments
    2. Download manifests from GitHub
    3. Extract variables from local IaC files
    4. Compare local variables against remote versions
    5. Output results as JSON
    6. Return appropriate exit code

    Returns:
        int: Exit code (0 for success, 1 for error or version mismatch when --error-on-mismatch is set)
    """
    args = parse_args()

    # Set logging level based on verbose flag
    if args.verbose:
        logger.setLevel(logging.DEBUG)

    # Get IaC type, union here will all to be used in the future
    # to check all types of IaC files, but declarative for the supported
    # file types at the top of this file.
    iac_type: Union[IaCType, Literal["all"]] = args.iac_type
    logger.debug(f"Using {iac_type.upper()} mode")

    # If only manifest URLs are requested, resolve and print them, then exit
    if getattr(args, "print_manifest_urls", False):
        try:
            enablement_url, instance_url, meta = get_latest_manifest_urls(
                require_asset_files=args.require_asset_files,
                strict_latest=args.strict_latest,
                release_tag=args.release_tag,
                channel=args.channel,
            )
            output = {
                "enablement_url": enablement_url,
                "instance_url": instance_url,
                "meta": meta,
            }
            print(json.dumps(output, indent=2))
            return 0
        except Exception as e:
            logger.error(f"Failed to resolve manifest URLs: {e}")
            return 1

    # Step 1: Resolve latest manifest URLs via GitHub API and download manifests
    try:
        enablement_url, instance_url, meta = get_latest_manifest_urls(
            require_asset_files=args.require_asset_files,
            strict_latest=args.strict_latest,
            release_tag=args.release_tag,
            channel=args.channel,
        )
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug(
                f"Manifest resolution: source={meta.get('source')}, tag={meta.get('tag_name')}, "
                f"ref={meta.get('target_commitish')}, enablement_url={enablement_url}, instance_url={instance_url}"
            )
        manifests = download_manifests(enablement_url, instance_url)
    except Exception as e:
        logger.error(f"Failed to download manifests: {e}")
        return 1

    # Create a dictionary to track which component comes from which URL
    # Attribute mismatches to the actual source URLs used
    manifest_urls = {"default": enablement_url}
    # IoT Operations comes from the instance manifest
    manifest_urls["azure-iot-operations"] = instance_url

    # Step 2: Extract variables based on IaC type
    all_mismatches = []

    if iac_type in ["terraform", "all"]:
        logger.debug("Checking Terraform files")
        tf_components = extract_variables("terraform", TERRAFORM_VARS_FILE)
        remote_versions = extract_remote_versions(manifests)
        tf_mismatches = compare_versions(
            tf_components, remote_versions, TERRAFORM_VARS_FILE, manifest_urls
        )

        if tf_mismatches:
            for mismatch in tf_mismatches:
                # Move iac_type to the top of the dictionary
                mismatch_with_iac = {"iac_type": "terraform", **mismatch}
                all_mismatches.append(mismatch_with_iac)

    if iac_type in ["bicep", "all"]:
        logger.debug("Checking Bicep files")
        bicep_components = extract_variables("bicep", BICEP_VARS_FILE)
        remote_versions = extract_remote_versions(manifests)
        bicep_mismatches = compare_versions(
            bicep_components, remote_versions, BICEP_VARS_FILE, manifest_urls
        )

        if bicep_mismatches:
            for mismatch in bicep_mismatches:
                # Move iac_type to the top of the dictionary
                mismatch_with_iac = {"iac_type": "bicep", **mismatch}
                all_mismatches.append(mismatch_with_iac)

    # Step 3: Output results as JSON to stdout
    print(json.dumps(all_mismatches, indent=2))

    # Step 4: Return error code if mismatches found and error flag is set
    if all_mismatches and args.error_on_mismatch:
        logger.debug(
            "Exiting with error due to version mismatches and --error-on-mismatch flag"
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
