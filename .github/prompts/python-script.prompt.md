# Python Script Conventions

You are an expert in Python scripting best practices and conventions. When writing Python scripts for this project, always follow these guidelines.
You understand this project by looking at the [README.md](../../README.md), `CONTRIBUTING.md` and other coding convention files.
These conventions apply specifically to utility scripts in the `./scripts` directory, not full Python applications.

## Script Structure and Organization

Scripts should follow this general structure:

```python
#!/usr/bin/env python3

"""
Brief description of the script's purpose.

Detailed explanation including:
- What the script does
- Key features and functionality
- Example usage instructions
- Dependencies
- Exit codes and their meaning
"""

import standard_libraries  # Alphabetized
import more_standard_libraries

import third_party_libraries  # Alphabetized
import more_third_party_libraries

import local_modules  # Alphabetized


def main():
    """Main function docstring explaining functionality."""
    # Initialize variables and parse arguments
    # Execute main logic
    # Handle output
    # Return appropriate exit code


def supporting_function(param1, param2):
    """
    Supporting function docstring.

    Args:
        param1: Description of param1
        param2: Description of param2

    Returns:
        Description of return value

    Raises:
        ExceptionType: When and why this exception might be raised
    """
    # Function implementation
    return result


if __name__ == "__main__":
    main()
```

- Scripts should be standalone and executable from the command line
- Place shebang line `#!/usr/bin/env python3` at the top of each script
- Include comprehensive docstrings in triple quotes at the module level
- Place imports at the top, grouped and alphabetized by type (standard library, third-party, local)
- Define a `main()` function to contain the primary script logic
- Include the `if __name__ == "__main__":` idiom to allow both direct execution and importing

## Command Line Arguments

Use `argparse` for command line argument handling:

```python
import argparse

def parse_arguments():
    """Parse and return command line arguments."""
    parser = argparse.ArgumentParser(
        description="Description of the script's purpose."
    )

    # Required arguments
    parser.add_argument("required_arg", help="Description of required argument")

    # Optional arguments
    parser.add_argument("-o", "--optional", help="Description of optional argument")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Increase output verbosity")

    # Arguments with default values
    parser.add_argument("-n", "--number", type=int, default=10,
                        help="Number of items (default: %(default)s)")

    return parser.parse_args()
```

- Use meaningful argument names with both short (`-v`) and long (`--verbose`) versions when appropriate
- Include helpful descriptions for each argument
- Set appropriate types and default values
- Group related arguments logically
- Always include help documentation

## Error Handling and Logging

Implement robust error handling:

```python
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger(__name__)

def main():
    """Main function with error handling."""
    try:
        # Script logic here
        if args.verbose:
            logger.setLevel(logging.DEBUG)
            logger.debug("Debug logging enabled")

        # Potentially raising exceptions
        result = risky_operation()
        logger.info(f"Operation completed: {result}")

    except FileNotFoundError as e:
        logger.error(f"Required file not found: {e}")
        return 1
    except PermissionError:
        logger.error("Insufficient permissions to perform operation")
        return 2
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return 3

    return 0

if __name__ == "__main__":
    sys.exit(main())
```

- Use appropriate logging levels (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`)
- Configure logging with helpful formatting
- Handle exceptions specifically with meaningful error messages
- Return appropriate exit codes from `main()` function
- Use `sys.exit(main())` to ensure the script terminates with the correct exit code

## Code Style and PEP 8

Follow PEP 8 conventions with these specific guidelines:

- Line length: Limit lines to 88 characters (aligned with black formatter)
- Indentation: Use 4 spaces per indentation level
- Imports: One per line, grouped and alphabetically ordered
- String quotes: Prefer double quotes for docstrings, single quotes for simple strings
- Function names: Use lowercase with underscores (`snake_case`)
- Variable names: Use lowercase with underscores (`snake_case`)
- Constants: Use uppercase with underscores (`UPPER_SNAKE_CASE`)
- Comments: Begin with `#` (hash and space) and use complete sentences
- Docstrings: Include for all public modules, functions, classes, and methods
- Follow Pythonic approach for boolean checks

## Type Hints

Use type hints for function parameters and return values:

```python
from typing import Dict, List, Optional, Tuple, Union

def process_data(input_file: str, max_items: Optional[int] = None) -> Dict[str, List[str]]:
    """
    Process data from input file.

    Args:
        input_file: Path to input file
        max_items: Maximum items to process, or None for all items

    Returns:
        Dictionary containing processed data
    """
    result: Dict[str, List[str]] = {}
    # Implementation
    return result
```

- Use the `typing` module for complex types
- Include type hints for function parameters and return values
- Use `Optional[Type]` for parameters that may be `None`
- Use `Union[Type1, Type2]` for parameters that may be multiple types
- Add type declarations for complex variables within functions

## File Operations

Follow these best practices for file operations:

```python
import os
from pathlib import Path

# Use context managers for file operations
def read_data(file_path: str) -> List[str]:
    """Read lines from file."""
    with open(file_path, 'r', encoding='utf-8') as file:
        return file.read().splitlines()

# Use pathlib for path manipulations
def ensure_output_directory(output_dir: str) -> Path:
    """Ensure output directory exists."""
    path = Path(output_dir)
    path.mkdir(parents=True, exist_ok=True)
    return path
```

- Always use context managers (`with` statement) when working with files
- Specify encoding explicitly (`utf-8` recommended)
- Use `pathlib` for path manipulations instead of `os.path`
- Handle file-related exceptions specifically
- Check file existence and permissions before operations

## Subprocess Execution

Use `subprocess` module with these guidelines:

```python
import subprocess
from subprocess import PIPE, CalledProcessError

def run_command(command: List[str], verbose: bool = False) -> str:
    """Run command and return output."""
    try:
        if verbose:
            print(f"Running command: {' '.join(command)}")

        result = subprocess.run(
            command,
            check=True,
            text=True,
            stdout=PIPE,
            stderr=PIPE
        )
        return result.stdout
    except CalledProcessError as e:
        print(f"Command failed with exit code {e.returncode}")
        print(f"Error output: {e.stderr}")
        raise
```

- Use `subprocess.run()` rather than older functions
- Pass commands as lists to avoid shell injection vulnerabilities
- Set `check=True` to raise exceptions on non-zero exit codes
- Use `text=True` to get string output instead of bytes
- Capture both `stdout` and `stderr`
- Handle `CalledProcessError` exceptions properly

## JSON Handling

Process JSON data with appropriate error handling:

```python
import json

def load_json(file_path: str) -> dict:
    """Load JSON data from file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return json.load(file)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in {file_path}: {e}")
        raise

def save_json(data: dict, file_path: str, indent: int = 2) -> None:
    """Save data as formatted JSON."""
    with open(file_path, 'w', encoding='utf-8') as file:
        json.dump(data, file, indent=indent, ensure_ascii=False)
```

- Use context managers for file operations
- Handle `JSONDecodeError` exceptions specifically
- Set `indent` for human-readable output
- Use `ensure_ascii=False` to preserve non-ASCII characters

## Testing and Verification

Include basic self-tests or verification steps:

```python
def verify_prerequisites() -> bool:
    """Verify all prerequisites are met."""
    missing = []

    # Check for required commands
    for cmd in ['git', 'terraform']:
        if not shutil.which(cmd):
            missing.append(cmd)

    # Check for required environment variables
    for env_var in ['API_KEY', 'USER_ID']:
        if env_var not in os.environ:
            missing.append(f"Environment variable {env_var}")

    if missing:
        print("Missing prerequisites:")
        for item in missing:
            print(f"  - {item}")
        return False
    return True

def self_test() -> bool:
    """Run self-tests."""
    # Implement quick sanity checks
    return True

if __name__ == "__main__":
    if not verify_prerequisites():
        sys.exit(1)
    if not self_test():
        print("Self-test failed")
        sys.exit(1)
    sys.exit(main())
```

- Include prerequisite checks for required commands and environment variables
- Add simple self-tests for core functionality
- Exit with appropriate error codes if prerequisites or tests fail

## Examples from the Repository

The repository contains several examples that demonstrate these conventions:

### Example: Structured Error Handling and JSON Output

From [link-lang-check.py](../../scripts/link-lang-check.py):

### Example: Class-Based Organization

From [tf-vars-compliance-check.py](../../scripts/tf-vars-compliance-check.py):

## Critical Rules (Always Follow)

- ALWAYS check for Python 3.8+ compatibility
- ALWAYS include comprehensive docstrings for modules, classes, and functions
- ALWAYS handle exceptions appropriately and provide meaningful error messages
- ALWAYS use context managers for file operations
- ALWAYS specify character encoding explicitly in file operations
- ALWAYS include proper argument parsing for command line scripts
- ALWAYS return appropriate exit codes from scripts
- NEVER use bare `except:` statements without specifying exception types
- NEVER use `os.system()` or other functions that invoke the shell directly

## Implementation Checklist

Before finalizing script changes, verify:

- [ ] Does the script include a proper shebang line?
- [ ] Does the script have comprehensive docstrings?
- [ ] Are imports properly grouped and alphabetized?
- [ ] Is argument parsing robust with clear help documentation?
- [ ] Are errors handled properly with appropriate exit codes?
- [ ] Is logging configured appropriately for the script's purpose?
- [ ] Are file operations using context managers and explicit encodings?
- [ ] Do all functions have appropriate type hints?
- [ ] Does the code follow PEP 8 style guidelines?
- [ ] Is there a `main()` function and `if __name__ == "__main__":` idiom?
- [ ] Have prerequisite checks been included if needed?
