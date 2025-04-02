#!/usr/bin/env python3

"""
Bicep Documentation Generator

This script generates documentation for Bicep modules by parsing the ARM JSON output
of Bicep files. The script creates standardized markdown documentation with information
about parameters, resources, modules, user-defined types, and outputs.

Example usage:
    python generate-bicep-docs.py ./src/005-onboard-reqs/bicep/main.json ./src/005-onboard-reqs/README.md

Args:
    arm_json_file: Path to the ARM JSON file (compiled Bicep)
    output_md_file: Path where the generated markdown documentation will be saved

Exit Codes:
    0 - Success
    1 - Failure (missing files, JSON parsing error, etc.)
"""

import argparse
import json
import os
import sys
import re
from typing import Dict, List, Any
from mdutils.mdutils import MdUtils


def parse_arguments() -> argparse.Namespace:
    """Parse and return command line arguments."""
    parser = argparse.ArgumentParser(
        description="Generate documentation for Bicep modules from ARM JSON output."
    )

    # Required arguments
    parser.add_argument(
        "arm_json_file",
        help="Path to the ARM JSON file (compiled Bicep)"
    )
    parser.add_argument(
        "output_md_file",
        help="Path where the generated markdown documentation will be saved"
    )

    # Optional arguments
    parser.add_argument(
        "-n", "--modules-nesting-level",
        type=int,
        default=1,
        help="Maximum number of nested module levels to process (default: 1)"
    )

    return parser.parse_args()


def load_json_file(file_path: str) -> Dict[str, Any]:
    """
    Load JSON data from file.

    Args:
        file_path: Path to the JSON file

    Returns:
        Dictionary containing the JSON data

    Raises:
        FileNotFoundError: If the file doesn't exist
        json.JSONDecodeError: If the file isn't valid JSON
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return json.load(file)
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

        # Extract description
        if "metadata" in param_info and "description" in param_info["metadata"]:
            param_data["description"] = param_info["metadata"]["description"]

        # Check if there's a default value
        if "defaultValue" in param_info:
            param_data["default"] = json.dumps(param_info["defaultValue"])
            param_data["required"] = False

        # Check if the parameter is nullable
        if "nullable" in param_info and param_info["nullable"]:
            param_data["required"] = False

        parameters.append(param_data)

    return parameters


def extract_resources(json_data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    Extract resources information from the ARM JSON.

    Args:
        json_data: The ARM JSON data

    Returns:
        List of dictionaries with resource information
    """
    resources = []

    if "resources" not in json_data:
        return resources

    for res_name, res_info in json_data["resources"].items():
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
                                param_data["default"] = json.dumps(param_info["defaultValue"])
                                param_data["required"] = False
                            except (TypeError, ValueError):
                                # Handle case where defaultValue isn't serializable
                                param_data["default"] = str(param_info["defaultValue"])
                                param_data["required"] = False

                        mod_data["parameters"].append(param_data)

                # Extract module resources
                if "resources" in template:
                    for res_name, res_info in template["resources"].items():
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
                    nested_modules = extract_modules(template, max_nested_level, current_level + 1)

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
                    if "value" in param_value:
                        mod_data["parameter_values"][param_name] = json.dumps(param_value["value"])

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
    result = re.sub(code_block_pattern, code_block_replacement, description, flags=re.DOTALL)

    # Then replace regular newlines with breaks for other parts of the text
    result = result.replace('\n', '<br>')

    return result


def generate_markdown(metadata: Dict[str, str],
                     parameters: List[Dict[str, Any]],
                     resources: List[Dict[str, Any]],
                     modules: List[Dict[str, Any]],
                     types: Dict[str, Dict[str, Any]],
                     outputs: List[Dict[str, Any]]) -> str:
    """
    Generate markdown documentation from extracted data using mdutils.

    Args:
        metadata: Dictionary with module metadata
        parameters: List of parameter dictionaries
        resources: List of resource dictionaries
        modules: List of module dictionaries
        types: Dictionary of user-defined types
        outputs: List of output dictionaries

    Returns:
        Generated markdown content as string
    """
    # Create the markdown object with the module name as title
    title = metadata.get('name', 'Bicep Module')
    md_file = MdUtils(file_name='', title='')  # We'll write to a string, not a file

    # Add special headers for the beginning
    header_text = "<!-- BEGIN_BICEP_DOCS -->\n<!-- markdown-table-prettify-ignore-start -->\n<!-- markdownlint-disable MD033 -->"
    md_file.new_header(level=1, title=title, add_table_of_contents=False)

    # Add description if available
    if "description" in metadata:
        md_file.new_line(metadata['description'])
        md_file.new_line('')

    # Parameters section
    if parameters:
        md_file.new_header(level=2, title="Parameters", add_table_of_contents=False)

        # Create parameters table
        param_table_data = ["Name", "Description", "Type", "Default", "Required"]

        for param in parameters:
            default_value = param.get("default", "n/a")
            if default_value == "n/a" or default_value is None:
                default_value = "n/a"
            elif isinstance(default_value, str):
                if default_value.startswith('"') and default_value.endswith('"'):
                    default_value = default_value[1:-1]  # Remove quotes for display

            param_table_data.extend([
                param.get('name', ''),
                format_description_for_table(param.get('description', '')),
                param.get('type', ''),
                default_value,
                'yes' if param.get('required', True) else 'no'
            ])

        md_file.new_table(columns=5, rows=len(parameters)+1, text=param_table_data, text_align='left')

    # Resources section
    if resources:
        md_file.new_header(level=2, title="Resources", add_table_of_contents=False)

        # Filter out conditionally excluded resources
        filtered_resources = [res for res in resources if res.get("condition", "true") != "false"]

        if filtered_resources:
            # Create resources table
            resources_table_data = ["Name", "Type", "API Version"]

            for res in filtered_resources:
                resources_table_data.extend([
                    res.get('name', ''),
                    res.get('type', ''),
                    res.get('api_version', '')
                ])

            md_file.new_table(columns=3, rows=len(filtered_resources)+1, text=resources_table_data, text_align='left')

    # Modules section
    if modules:
        md_file.new_header(level=2, title="Modules", add_table_of_contents=False)

        # Create modules table
        modules_table_data = ["Name", "Description"]

        for mod in modules:
            modules_table_data.extend([
                mod.get('name', ''),
                mod.get('description', '')
            ])

        md_file.new_table(columns=2, rows=len(modules)+1, text=modules_table_data, text_align='left')

        # Detailed modules sections
        md_file.new_header(level=2, title="Module Details", add_table_of_contents=False)

        for mod in modules:
            mod_name = mod.get('name', '')
            md_file.new_header(level=3, title=mod_name, add_table_of_contents=False)

            if mod.get('description', ''):
                md_file.new_line(mod['description'])
                md_file.new_line('')

            # Module parameters
            if mod.get('parameters', []):
                md_file.new_header(level=4, title=f"Parameters for {mod_name}", add_table_of_contents=False)

                # Create module parameters table
                mod_params_table_data = ["Name", "Description", "Type", "Default", "Required"]

                for param in mod['parameters']:
                    default_value = param.get("default", "n/a")
                    if default_value == "n/a" or default_value is None:
                        default_value = "n/a"
                    elif isinstance(default_value, str):
                        if default_value.startswith('"') and default_value.endswith('"'):
                            default_value = default_value[1:-1]  # Remove quotes for display

                    mod_params_table_data.extend([
                        param.get('name', ''),
                        format_description_for_table(param.get('description', '')),
                        param.get('type', ''),
                        default_value,
                        'yes' if param.get('required', True) else 'no'
                    ])

                md_file.new_table(columns=5, rows=len(mod['parameters'])+1, text=mod_params_table_data, text_align='left')

            # Module resources
            if mod.get('resources', []):
                md_file.new_header(level=4, title=f"Resources for {mod_name}", add_table_of_contents=False)

                # Create module resources table
                mod_resources_table_data = ["Name", "Type", "API Version"]

                for res in mod['resources']:
                    mod_resources_table_data.extend([
                        res.get('name', ''),
                        res.get('type', ''),
                        res.get('api_version', '')
                    ])

                md_file.new_table(columns=3, rows=len(mod['resources'])+1, text=mod_resources_table_data, text_align='left')

            # Module outputs
            if mod.get('outputs', []):
                md_file.new_header(level=4, title=f"Outputs for {mod_name}", add_table_of_contents=False)

                # Create module outputs table
                mod_outputs_table_data = ["Name", "Type", "Description"]

                for output in mod['outputs']:
                    mod_outputs_table_data.extend([
                        output.get('name', ''),
                        output.get('type', ''),
                        output.get('description', '')
                    ])

                md_file.new_table(columns=3, rows=len(mod['outputs'])+1, text=mod_outputs_table_data, text_align='left')

    # User-defined types section
    if types:
        md_file.new_header(level=2, title="User Defined Types", add_table_of_contents=False)

        for type_name, type_info in types.items():
            md_file.new_header(level=3, title=f"`{type_name}`", add_table_of_contents=False)

            if type_info.get("description"):
                # md_file.new_paragraph(type_info["description"])
                md_file.new_line(type_info['description'])
                md_file.new_line('')

            if type_info.get("properties"):
                # Create type properties table
                type_props_table_data = ["Property", "Type", "Description"]

                for prop_name, prop_info in type_info["properties"].items():
                    type_props_table_data.extend([
                        prop_name,
                        prop_info.get('type', ''),
                        prop_info.get('description', '')
                    ])

                md_file.new_table(columns=3, rows=len(type_info["properties"])+1, text=type_props_table_data, text_align='left')

    # Outputs section
    if outputs:
        md_file.new_header(level=2, title="Outputs", add_table_of_contents=False)

        # Create outputs table
        outputs_table_data = ["Name", "Type", "Description"]

        for output in outputs:
            outputs_table_data.extend([
                output.get('name', ''),
                output.get('type', ''),
                output.get('description', '')
            ])

        md_file.new_table(columns=3, rows=len(outputs)+1, text=outputs_table_data, text_align='left')

    # Get markdown content
    markdown_content = md_file.get_md_text()

    # Add special footer
    footer_text = "\n<!-- markdown-table-prettify-ignore-end -->\n<!-- END_BICEP_DOCS -->\n"

    # Combine header, content, and footer
    return header_text + markdown_content + footer_text


def save_markdown(content: str, output_path: str) -> None:
    """
    Save markdown content to a file.

    Args:
        content: Markdown content to save
        output_path: Path where the file should be saved

    Raises:
        IOError: If there's an error writing to the file
    """
    try:
        # Create directory if it doesn't exist
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)

        with open(output_path, 'w', encoding='utf-8') as file:
            file.write(content)

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

    # Load ARM JSON file
    json_data = load_json_file(args.arm_json_file)

    # Convert user-provided 1-based nesting level to 0-based max_nested_level
    # Ensure value is at least 0
    max_nested_level = max(0, args.modules_nesting_level - 1)

    # Extract data from JSON
    metadata = extract_metadata(json_data)
    parameters = extract_parameters(json_data)
    resources = extract_resources(json_data)
    modules = extract_modules(json_data, max_nested_level=max_nested_level)
    types = extract_user_defined_types(json_data)
    outputs = extract_outputs(json_data)

    # Generate markdown
    generated_content = generate_markdown(
        metadata, parameters, resources, modules, types, outputs
    )

    # Save to output file
    save_markdown(generated_content, args.output_md_file)

    return 0


if __name__ == "__main__":
    sys.exit(main())