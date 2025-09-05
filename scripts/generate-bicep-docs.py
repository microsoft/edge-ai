#!/usr/bin/env python3

"""
Bicep Documentation Generator with Jinja2

This script generates documentation for Bicep modules using Jinja2 templates.
It parses ARM JSON output of Bicep files and creates standardized markdown
documentation based on a template.

Example usage:
    # Basic usage with default template
    python generate-bicep-docs-jinja.py ./src/005-onboard-reqs/bicep/main.json ./src/005-onboard-reqs/README.md

    # Using a custom template
    python generate-bicep-docs-jinja.py ./src/005-onboard-reqs/bicep/main.json ./src/005-onboard-reqs/README.md -t ./templates/custom-template.md

    # Specifying nesting level for module processing
    python generate-bicep-docs-jinja.py ./src/005-onboard-reqs/bicep/main.json ./src/005-onboard-reqs/README.md -n 2

    # Enable verbose output
    python generate-bicep-docs-jinja.py ./src/005-onboard-reqs/bicep/main.json ./src/005-onboard-reqs/README.md -v

Args:
    arm_json_file: Path to the ARM JSON file (compiled Bicep)
    output_md_file: Path where the generated markdown documentation will be saved
    -t, --template-file: Optional path to a custom Jinja2 template file (default: ./templates/bicep-docs-template.md.template)
    -n, --modules-nesting-level: Optional maximum number of nested module levels to process (default: 1)
    -v, --verbose: Enable verbose output with additional processing information

Exit Codes:
    0 - Success
    1 - Failure (missing files, JSON parsing error, etc.)
"""

import argparse
import json
import sys
import re
from pathlib import Path
from typing import Dict, List, Any
from jinja2 import Environment, FileSystemLoader, Template


def parse_arguments() -> argparse.Namespace:
    """Parse and return command line arguments."""
    parser = argparse.ArgumentParser(
        description="Generate documentation for Bicep modules from ARM JSON output using Jinja2 templates."
    )

    # Get the directory of the current script for relative path resolution
    script_dir = Path(__file__).parent
    default_template_path = script_dir / \
        "templates" / "bicep-docs-template.md.template"

    # Required arguments
    parser.add_argument(
        "arm_json_file",
        help="Path to the ARM JSON file (compiled Bicep)"
    )
    parser.add_argument(
        "output_md_file",
        help="Path where the generated markdown documentation will be saved"
    )
    parser.add_argument(
        "-t", "--template-file",
        default=str(default_template_path),
        help="Path to the Jinja2 template file for documentation (default: ./templates/bicep-docs-template.md.template)"
    )

    # Optional arguments
    parser.add_argument(
        "-n", "--modules-nesting-level",
        type=int,
        default=1,
        help="Maximum number of nested module levels to process (default: 1)"
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose output with additional processing information"
    )

    args = parser.parse_args()

    return args


def load_json_file(file_path: str, verbose: bool = False) -> Dict[str, Any]:
    """
    Load JSON data from file.

    Args:
        file_path: Path to the JSON file
        verbose: Whether to output additional information

    Returns:
        Dictionary containing the JSON data

    Raises:
        FileNotFoundError: If the file doesn't exist
        json.JSONDecodeError: If the file isn't valid JSON
    """
    try:
        if verbose:
            print(f"Loading JSON file: {file_path}")

        path = Path(file_path)  # Convert to Path object
        with path.open('r', encoding='utf-8') as file:
            data = json.load(file)

            if verbose:
                print(
                    f"JSON file loaded successfully: {len(data)} top-level keys found")

            return data
    except FileNotFoundError:
        print(f"Error: File not found: {file_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {file_path}: {e}")
        sys.exit(1)


def extract_metadata(json_data: Dict[str, Any]) -> Dict[str, str]:
    """
    Extract metadata information from the ARM JSON.

    Args:
        json_data: The ARM JSON data

    Returns:
        Dictionary with metadata information
    """
    metadata = {}

    # Extract name and description from metadata if available
    if "metadata" in json_data:
        if "name" in json_data["metadata"]:
            metadata["name"] = json_data["metadata"]["name"]
        if "description" in json_data["metadata"]:
            metadata["description"] = json_data["metadata"]["description"]

    # If metadata is not available, try to derive from filename or path
    if not metadata.get("name"):
        # Default to module name based on directory
        metadata["name"] = "Bicep Module"

    return metadata


def extract_parameters(json_data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    Extract parameters information from the ARM JSON.

    Args:
        json_data: The ARM JSON data

    Returns:
        List of dictionaries with parameter information
    """
    parameters = []

    if "parameters" not in json_data:
        return parameters

    for param_name, param_info in json_data["parameters"].items():
        param_data = {
            "name": param_name,
            "description": "",
            "type": "",
            "default": "n/a",
            "required": True
        }

        # Extract type
        if "$ref" in param_info:
            # Handle type references
            ref_path = param_info["$ref"].split('/')[-1]
            param_data["type"] = f"[{ref_path}](#user-defined-types)"
        elif "type" in param_info:
            param_data["type"] = param_info["type"]

        # Extract description and sanitize markdown within it
        if "metadata" in param_info and "description" in param_info["metadata"]:
            description = param_info["metadata"]["description"]
            # Preserve markdown formatting but ensure it renders properly in tables
            param_data["description"] = description

        # Check if there's a default value
        if "defaultValue" in param_info:
            try:
                default_value = param_info["defaultValue"]
                # Format boolean values as markdown `true` or `false`
                if isinstance(default_value, bool):
                    default_value = "`true`" if default_value else "`false`"
                # Remove surrounding quotes if the default value is a string
                elif isinstance(default_value, str) and default_value.startswith('"') and default_value.endswith('"'):
                    default_value = default_value[1:-1]
                param_data["default"] = default_value
                param_data["required"] = False
            except (TypeError, ValueError):
                param_data["default"] = str(param_info["defaultValue"])
                param_data["required"] = False

        # Check if the parameter is nullable
        if "nullable" in param_info and param_info["nullable"]:
            param_data["required"] = False

        parameters.append(param_data)

    return parameters


def is_existing_resource(
    res_name: str, res_info: Dict[str, Any], verbose: bool = False
) -> bool:
    """
    Check if a resource is an existing resource reference (not a new resource created by this module).

    Args:
        res_name: The name of the resource
        res_info: The resource information dictionary
        verbose: Whether to output additional information

    Returns:
        True if the resource is an existing resource reference, False otherwise
    """
    # When Bicep 'existing' resources are compiled to ARM, they may have specific patterns
    # Note: This detection is best-effort. In some cases, existing resources in compiled ARM JSON
    # may not have clear indicators. For more reliable filtering, consider:
    # 1. Using naming conventions for existing resources
    # 2. Adding metadata to bicep files to mark existing resources
    # 3. Post-processing the ARM JSON to add explicit markers

    # Method 1: Check for explicit existing property
    if res_info.get("existing") is True:
        if verbose:
            print(f"Resource '{res_name}' marked as existing via 'existing' property.")
        return True

    # Method 2: Check if resource has deploymentScope or similar indicators of being a reference
    if "copy" not in res_info and "properties" in res_info:
        properties = res_info.get("properties", {})
        # If the resource has very minimal properties and no deployment configuration,
        # it might be a reference to an existing resource
        if len(properties) == 0 or (len(properties) == 1 and "mode" in properties):
            if verbose:
                print(
                    f"Resource '{res_name}' appears to be an existing resource reference (minimal properties)."
                )
            return True

    # Method 3: Check conditions that suggest existing resources
    condition = res_info.get("condition", True)
    if isinstance(condition, bool) and not condition:
        if verbose:
            print(
                f"Resource '{res_name}' has existing-related condition: {condition}"
            )
        return True
    elif isinstance(condition, str):
        condition_str = condition.lower()
        if "existing" in condition_str:
            if verbose:
                print(
                    f"Resource '{res_name}' has existing-related condition: {condition}"
                )
            return True

    return False


def extract_resources(
    json_data: Dict[str, Any], verbose: bool = False
) -> List[Dict[str, Any]]:
    """
    Extract resources information from the ARM JSON.

    Args:
        json_data: The ARM JSON data
        verbose: Whether to output additional information

    Returns:
        List of dictionaries with resource information
    """
    resources = []

    if "resources" not in json_data:
        return resources

    for res_name, res_info in json_data["resources"].items():
        # Skip attribution resources labeling the deployment
        if res_name == "attribution" and re.match(r"^pid-", res_info.get("name", "")):
            print(
                f"Skipping resource '{res_name}' with name 'pid' as it is an attribution."
            )
            continue

        # Skip existing resources (references to existing resources, not new resources created by this module)
        if is_existing_resource(res_name, res_info, verbose):
            if verbose:
                print(
                    f"Skipping existing resource '{res_name}' as it is a reference to an existing resource."
                )
            continue

        res_data = {
            "name": res_name,
            "type": "",
            "api_version": "",
            "condition": "true"
        }

        if "type" in res_info:
            res_data["type"] = res_info["type"]

        if "apiVersion" in res_info:
            res_data["api_version"] = res_info["apiVersion"]

        if "condition" in res_info:
            res_data["condition"] = res_info["condition"]

        resources.append(res_data)

    return resources


def extract_modules(json_data: Dict[str, Any], max_nested_level: int = 1, current_level: int = 0) -> List[Dict[str, Any]]:
    """
    Extract modules (nested deployments) information from the ARM JSON.

    Recursively processes nested modules up to the specified maximum depth.

    Args:
        json_data: The ARM JSON data
        max_nested_level: Maximum number of nested levels to process (default: 1)
        current_level: Current recursion level (used internally, default: 0)

    Returns:
        List of dictionaries with module information
    """
    modules = []

    if "resources" not in json_data or current_level > max_nested_level:
        return modules

    for module_name, module_info in json_data["resources"].items():
         # Skip attribution modules labeling the deployment
        if module_name == "attribution" and re.match(r"^pid-", module_info.get("name", "")):
            print(f"Skipping module '{module_name}' with name 'pid' as it is an attribution.")
            continue

        # Check if this resource is a deployment (module)
        if module_info.get("type") == "Microsoft.Resources/deployments":
            mod_data = {
                "name": module_name,
                "description": "",
                "parameters": [],
                "resources": [],
                "outputs": [],
                "level": current_level
            }

            # Extract module properties if available
            if "properties" in module_info and "template" in module_info["properties"]:
                template = module_info["properties"]["template"]

                # Extract module description
                if "metadata" in template and "description" in template["metadata"]:
                    mod_data["description"] = template["metadata"]["description"]

                # Extract module parameters
                if "parameters" in template:
                    for param_name, param_info in template["parameters"].items():
                        param_data = {
                            "name": param_name,
                            "description": "",
                            "type": "",
                            "default": "n/a",
                            "required": True
                        }

                        # Extract type
                        if "$ref" in param_info:
                            ref_path = param_info["$ref"].split('/')[-1]
                            param_data["type"] = f"[{ref_path}](#user-defined-types)"
                        elif "type" in param_info:
                            param_data["type"] = param_info["type"]

                        # Extract description
                        if "metadata" in param_info and "description" in param_info["metadata"]:
                            param_data["description"] = param_info["metadata"]["description"]

                        # Check if there's a default value
                        if "defaultValue" in param_info:
                            try:
                                default_value = param_info["defaultValue"]
                                # Format boolean values as markdown `true` or `false`
                                if isinstance(default_value, bool):
                                    default_value = (
                                        "`true`" if default_value else "`false`"
                                    )
                                # Remove surrounding quotes if the default value is a string
                                elif (
                                    isinstance(default_value, str)
                                    and default_value.startswith('"')
                                    and default_value.endswith('"')
                                ):
                                    default_value = default_value[1:-1]
                                param_data["default"] = default_value
                                param_data["required"] = False
                            except (TypeError, ValueError):
                                param_data["default"] = str(
                                    param_info["defaultValue"])
                                param_data["required"] = False

                        if "nullable" in param_info and param_info["nullable"]:
                            param_data["required"] = False

                        mod_data["parameters"].append(param_data)

                # Extract module resources
                if "resources" in template:
                    # Handle both dictionary-style and object-style resources
                    resources_data = template["resources"]
                    if isinstance(resources_data, dict):
                        # Process dictionary-style resources (with .items())
                        for res_name, res_info in resources_data.items():
                            # Skip attribution resources labeling the deployment
                            if res_name == "attribution" and re.match(
                                r"^pid-", res_info.get("name", "")
                            ):
                                print(
                                    f"Skipping resource '{res_name}' with name 'pid' as it is an attribution."
                                )
                                continue

                            # Skip existing resources (references to existing resources, not new resources created by this module)
                            if is_existing_resource(res_name, res_info):
                                continue

                            res_data = {
                                "name": res_name,
                                "type": "",
                                "api_version": "",
                            }

                            if "type" in res_info:
                                res_data["type"] = res_info["type"]

                            if "apiVersion" in res_info:
                                res_data["api_version"] = res_info["apiVersion"]

                            mod_data["resources"].append(res_data)
                    elif isinstance(resources_data, list):
                        # Process array-style resources
                        for res_info in resources_data:
                            res_name = res_info.get("name", "unnamed-resource")

                            # Skip existing resources
                            if is_existing_resource(res_name, res_info):
                                continue

                            res_data = {
                                "name": res_name,
                                "type": res_info.get("type", ""),
                                "api_version": res_info.get("apiVersion", ""),
                            }
                            mod_data["resources"].append(res_data)
                    else:
                        # Bicep-style object resources with direct properties
                        for res_name in resources_data:
                            res_info = resources_data[res_name]

                            # Skip existing resources
                            if is_existing_resource(res_name, res_info):
                                continue

                            res_data = {
                                "name": res_name,
                                "type": "",
                                "api_version": "",
                            }

                            if "type" in res_info:
                                res_data["type"] = res_info["type"]

                            if "apiVersion" in res_info:
                                res_data["api_version"] = res_info["apiVersion"]

                            mod_data["resources"].append(res_data)

                # Extract module outputs
                if "outputs" in template:
                    for output_name, output_info in template["outputs"].items():
                        output_data = {
                            "name": output_name,
                            "description": "",
                            "type": ""
                        }

                        if "type" in output_info:
                            output_data["type"] = output_info["type"]

                        # Extract description
                        if "metadata" in output_info and "description" in output_info["metadata"]:
                            output_data["description"] = output_info["metadata"]["description"]

                        mod_data["outputs"].append(output_data)

                # Recursively process nested modules if not at max depth
                if current_level < max_nested_level and "resources" in template:
                    # Add nested modules with a namespace prefix to show hierarchy
                    nested_modules = extract_modules(
                        template, max_nested_level, current_level + 1)

                    for nested_module in nested_modules:
                        # Update name to show nesting hierarchy
                        nested_module["name"] = f"{module_name}/{nested_module['name']}"
                        nested_module["parent_module"] = module_name
                        modules.append(nested_module)

            # Extract expressions used when invoking this module
            if "properties" in module_info and "parameters" in module_info["properties"]:
                module_params = module_info["properties"]["parameters"]
                mod_data["parameter_values"] = {}

                for param_name, param_value in module_params.items():
                    # Fix: param_value may be a dict or a direct value
                    if isinstance(param_value, dict) and "value" in param_value:
                        mod_data["parameter_values"][param_name] = json.dumps(param_value["value"])
                    else:
                        mod_data["parameter_values"][param_name] = json.dumps(param_value)

            modules.append(mod_data)

    return modules


def extract_user_defined_types(json_data: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
    """
    Extract user-defined types from the ARM JSON.

    Args:
        json_data: The ARM JSON data

    Returns:
        Dictionary of user-defined types
    """
    types = {}

    if "definitions" not in json_data:
        return types

    for type_name, type_info in json_data["definitions"].items():
        type_data = {
            "name": type_name,
            "description": "",
            "properties": {}
        }

        # Extract description
        if "metadata" in type_info and "description" in type_info["metadata"]:
            type_data["description"] = type_info["metadata"]["description"]

        # Extract properties
        if "properties" in type_info:
            for prop_name, prop_info in type_info["properties"].items():
                prop_data = {
                    "type": "",
                    "description": ""
                }

                # Handle type reference
                if "$ref" in prop_info:
                    ref_name = prop_info["$ref"].split('/')[-1]
                    prop_data["type"] = f"[{ref_name}](#user-defined-types)"
                elif "type" in prop_info:
                    prop_data["type"] = prop_info["type"]

                # Extract description
                if "metadata" in prop_info and "description" in prop_info["metadata"]:
                    prop_data["description"] = prop_info["metadata"]["description"]

                type_data["properties"][prop_name] = prop_data

        types[type_name] = type_data

    return types


def extract_outputs(json_data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    Extract outputs information from the ARM JSON.

    Args:
        json_data: The ARM JSON data

    Returns:
        List of dictionaries with output information
    """
    outputs = []

    if "outputs" not in json_data:
        return outputs

    for output_name, output_info in json_data["outputs"].items():
        output_data = {
            "name": output_name,
            "description": "",
            "type": ""
        }

        if "type" in output_info:
            output_data["type"] = output_info["type"]

        # Extract description
        if "metadata" in output_info and "description" in output_info["metadata"]:
            output_data["description"] = output_info["metadata"]["description"]

        outputs.append(output_data)

    return outputs


def load_jinja_template(template_path: str) -> Template:
    """
    Load a Jinja2 template from file.

    Args:
        template_path: Path to the Jinja2 template file

    Returns:
        Loaded Jinja2 template object

    Raises:
        FileNotFoundError: If the template file doesn't exist
    """
    try:
        # Convert to Path object
        path = Path(template_path)

        # Get template directory and filename
        template_dir = path.parent
        template_file = path.name

        # Create Jinja2 environment with custom filters
        env = Environment(loader=FileSystemLoader(template_dir))

        # Add custom filter for handling inline code as <pre><code> blocks
        env.filters['format_description_for_table'] = format_description_for_table

        # Return the template
        return env.get_template(template_file)
    except FileNotFoundError:
        # Cannot continue
        print(f"Error: Template file not found: {template_path}")
        sys.exit(1)


def format_description_for_table(description: str) -> str:
    """
    Format a description string to display properly in a markdown table.

    Args:
        description: The original description text

    Returns:
        Formatted description safe for markdown tables
    """
    if not description:
        return ""

    # Special handling for code blocks in markdown tables
    # In markdown tables, code blocks need special treatment
    # Convert ```sh ... ``` blocks to HTML-friendly format
    code_block_pattern = r'```(\w*)\n(.*?)```'

    def code_block_replacement(match):
        lang = match.group(1) or ""
        code = match.group(2)
        # Format as inline code with line breaks preserved
        formatted_code = f"<pre><code class=\"language-{lang}\">{code}</code></pre>"
        return formatted_code

    # Replace code blocks first
    result = re.sub(code_block_pattern, code_block_replacement,
                    description, flags=re.DOTALL)

    # Then replace regular newlines with breaks for other parts of the text
    result = result.replace('\n', '<br>')

    return result


def render_markdown(template: Template, context: Dict[str, Any], verbose: bool = False) -> str:
    """
    Render the Jinja2 template with the provided context.

    Args:
        template: The Jinja2 template object
        context: Dictionary with variables to render in the template
        verbose: Whether to output additional information

    Returns:
        The rendered markdown content
    """
    if verbose:
        print("Rendering markdown with Jinja2 template...")
        print(f"Template context contains {len(context)} variables:")
        for key, value in context.items():
            if isinstance(value, list):
                print(f"  - {key}: List with {len(value)} items")
            elif isinstance(value, dict):
                print(f"  - {key}: Dictionary with {len(value)} items")
            else:
                print(f"  - {key}: {type(value).__name__}")

    return template.render(**context)


def save_markdown(content: str, output_path: str, verbose: bool = False) -> None:
    """
    Save markdown content to a file.

    Args:
        content: Markdown content to save
        output_path: Path where the file should be saved
        verbose: Whether to output additional information

    Raises:
        IOError: If there's an error writing to the file
    """
    try:
        # Convert to Path object
        path = Path(output_path)

        if verbose:
            print(f"Saving markdown file to: {path}")

        # Create directory if it doesn't exist
        if path.parent and not path.parent.exists():
            if verbose:
                print(f"Creating directory: {path.parent}")
            path.parent.mkdir(parents=True, exist_ok=True)

        # Write content to file
        path.write_text(content, encoding='utf-8')

        print(f"Documentation successfully written to {output_path}")
    except IOError as e:
        print(f"Error writing to {output_path}: {e}")
        sys.exit(1)


def main() -> int:
    """
    Main function for Bicep documentation generator.

    Returns:
        Exit code (0 for success, non-zero for failure)
    """
    # Parse command line arguments
    args = parse_arguments()

    if args.verbose:
        print("Verbose mode enabled")
        print(f"ARM JSON file: {args.arm_json_file}")
        print(f"Output markdown file: {args.output_md_file}")
        print(f"Template file: {args.template_file}")
        print(f"Module nesting level: {args.modules_nesting_level}")

    # Load ARM JSON file
    json_data = load_json_file(args.arm_json_file, verbose=args.verbose)

    # Convert user-provided 1-based nesting level to 0-based max_nested_level
    # Ensure value is at least 0
    max_nested_level = max(0, args.modules_nesting_level - 1)

    if args.verbose:
        print("\nExtracting data from ARM JSON file...")

    # Extract data from JSON
    metadata = extract_metadata(json_data)
    parameters = extract_parameters(json_data)
    resources = extract_resources(json_data, verbose=args.verbose)
    modules = extract_modules(json_data, max_nested_level=max_nested_level)
    types = extract_user_defined_types(json_data)
    outputs = extract_outputs(json_data)

    if args.verbose:
        print(f"\nExtracted metadata: {json.dumps(metadata, indent=2)}")
        print(f"Extracted {len(parameters)} parameters")
        print(f"Extracted {len(resources)} resources")
        print(
            f"Extracted {len(modules)} modules (with nesting level {args.modules_nesting_level})")
        print(f"Extracted {len(types)} user-defined types")
        print(f"Extracted {len(outputs)} outputs")

    # Filter resources to exclude conditionally false ones
    filtered_resources = [res for res in resources if res.get(
        "condition", "true") != "false"]

    if args.verbose:
        excluded_count = len(resources) - len(filtered_resources)
        if excluded_count > 0:
            print(
                f"Filtered out {excluded_count} conditionally false resources")

    # Load the Jinja template
    if args.verbose:
        print(f"\nLoading Jinja2 template from: {args.template_file}")
    template = load_jinja_template(args.template_file)

    # Prepare the context for the template
    context = {
        "metadata": metadata,
        "parameters": parameters,
        "resources": resources,
        "filtered_resources": filtered_resources,
        "modules": modules,
        "types": types,
        "outputs": outputs
    }

    # Render the markdown using the template
    rendered_markdown = render_markdown(
        template, context, verbose=args.verbose)

    if args.verbose:
        print(
            f"\nRendered markdown document with {len(rendered_markdown)} characters")

    # Save to output file
    if args.verbose:
        print(f"Saving markdown to: {args.output_md_file}")
    save_markdown(rendered_markdown, args.output_md_file, verbose=args.verbose)

    if args.verbose:
        print("Documentation generation completed successfully!")

    return 0


if __name__ == "__main__":
    sys.exit(main())
