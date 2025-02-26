#!/usr/bin/env python3

"""
This script validates Terraform variable definitions across modules for consistency.
It scans all Terraform files in the specified directory (default: ../src), extracts
input and output variable definitions, and checks for inconsistencies.

The script generates a JSON array of inconsistencies found in variable definitions.
Each inconsistency is reported as a warning with details about the current and expected values.

Dependencies:
    - terraform-docs: https://terraform-docs.io/

Exit Codes:
    0 - Success
    1 - Failure (e.g., missing dependencies, errors during execution)
"""

import json
import os
import shutil
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from typing import List, Set


def check_dependencies() -> None:
    """
    Verify that terraform-docs is installed and accessible in the system PATH.

    Raises:
        SystemExit: If terraform-docs is not found, exits with code 1 after printing installation instructions.
    """
    if not shutil.which("terraform-docs"):
        print("terraform-docs could not be found.")
        print("Please install terraform-docs and ensure it is in your PATH.")
        print(
            "Installation instructions can be found at: https://terraform-docs.io/user-guide/installation/"
        )
        print()
        sys.exit(1)


def find_terraform_files(base_paths: List[Path]) -> Set[Path]:
    """
    Locate all directories containing Terraform files in the given paths.

    Args:
        base_paths: List of root directories to search for Terraform files

    Returns:
        Set[Path]: Set of directory paths containing .tf files, excluding tests and .terraform directories
    """
    tf_dirs = set()
    for base_path in base_paths:
        for root, dirs, files in os.walk(base_path):
            dirs[:] = [d for d in dirs if d not in ["tests", ".terraform"]]
            if any(f.endswith(".tf") for f in files):
                tf_dirs.add(root)
    return tf_dirs


def get_terraform_docs(folder: Path) -> str:
    """
    Generate JSON documentation for Terraform files in the specified folder.
    Grab all the output from terraform-docs and return it as a string for
    each file.

    Args:
        folder: Path to the directory containing Terraform files

    Returns:
        str: JSON string containing the terraform-docs output

    Raises:
        ValueError: If terraform-docs fails to generate documentation
    """
    proc = subprocess.run(
        # fmt: off
        [
            "terraform-docs",
            "json",
            "--output-template", "{{ .Content }}",
            "--hide", "header",
            "--hide", "footer",
            "--hide", "providers",
            "--hide", "resources",
            "--hide", "requirements",
            folder,
        ],
        # fmt: on
        capture_output=True,
        check=True,
        # We want this to run from the directory of this script
        # so that it does not pick up the terraform-docs config
        # from the root of the repo.
        cwd=os.path.dirname(os.path.realpath(__file__))
    )

    if proc.returncode != 0:
        raise ValueError(
            f"terraform-docs at {folder} failed with return code {proc.returncode}:"
            f" {proc.stdout.decode()} {proc.stderr.decode()}"
        )
    return proc.stdout.decode()

class TFVars:
    """
    Class for tracking and comparing Terraform variable definitions across modules.

    Attributes:
        var_dirs: Mapping of variable names to the directories where they're defined
        var_descriptions: Mapping of variable names to their set of unique descriptions
        var_description_issues: Set of variable names with inconsistent descriptions
        issues: List of detected inconsistencies
    """

    def __init__(self):
        """Initialize collections for tracking variable definitions and issues."""
        self.var_dirs = defaultdict(list)
        self.var_descriptions = defaultdict(set)
        self.var_description_issues = set()
        self.issues = []

    def _check_description(self, name: str, description: str) -> None:
        """
        Check if a variable's description is consistent across all uses.
        and report inconsistencies for each variable.

        Args:
            name: Name of the variable
            description: Description string to check

        Note:
            Adds variable to var_description_issues if inconsistencies are found
        """
        existing = self.var_descriptions[name]
        existing.add(description)
        # File an issue if there is more than one description.
        if len(existing) > 1:
            self.var_description_issues.add(name)

    def _check_variables(self, folders: Set[Path]) -> None:
        """
        Process all variables in the given folders to find inconsistencies.

        Args:
            folders: Set of directories to check for Terraform files
        """
        for folder in folders:
            docs_str = get_terraform_docs(folder)
            docs = json.loads(docs_str)
            for var in docs.get("inputs", []):
                name = var["name"]
                self.var_dirs[name].append(folder)
                self._check_description(name, var.get("description", ""))

    def build_issues(self, folders: Set[Path]) -> List[dict]:
        """
        Generate a list of all variable consistency issues found.

        Args:
            folders: Set of directories to check for Terraform files

        Returns:
            List[dict]: List of issues found, each containing:
                - variable: Name of the variable
                - differences: List of different descriptions found
                - folders: List of folders where the variable is defined
        """
        self._check_variables(folders)
        for var in self.var_description_issues:
            self.issues.append(
                {
                    "variable": var,
                    "differences": list(self.var_descriptions[var]),
                    "folders": self.var_dirs[var],
                }
            )

        return self.issues

def main():
    """
    Main function that:
    1. Checks required dependency (terraform-docs)
    2. Grabs output from subprocess call and stores locally
    3. Processes variables to find inconsistencies in definitions
    4. Outputs warnings as JSON for build system
    """
    check_dependencies()

    script_dir = Path(__file__).parent
    src_dir = script_dir.parent / "src"
    blueprints_dir = script_dir.parent / "blueprints"

    folders = find_terraform_files([src_dir, blueprints_dir])
    tfvars = TFVars()
    warnings = tfvars.build_issues(folders)

    # Output warnings as JSON
    if warnings:
        print(json.dumps(warnings, indent=2, default=str))

if __name__ == "__main__":
    main()
