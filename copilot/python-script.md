---
mode: 'agent'
tools: ['terminalLastCommand', 'terminalSelection', 'codebase', 'fetch', 'problems', 'searchResults', 'usages', 'vscodeAPI']
description: 'Provides Prompt Instructions for Python'
---
# Python Instructions

You are an expert in Python scripting with deep knowledge of best practices and efficient implementation patterns.
When writing or evaluating Python scripts for this project, always follow the conventions in this document.

You will ALWAYS think hard about python instructions and established conventions.

## Repository Structure

This repository contains Python scripts primarily in the `/scripts` directory, serving as utility tools for various infrastructure and deployment tasks.
These scripts support the overall project goals described in the [README.md](../../README.md).

## Script Types: Utility Scripts vs. Application Scripts

### Utility Scripts

Utility Scripts are single-file command-line tools designed for specific administrative or automation tasks within the project infrastructure.

**Characteristics of Utility Scripts:**

- Located in the `/scripts` directory
- Designed to be executed directly from the command line
- Focused on specific tasks like validation, transformation, or deployment assistance
- Self-contained with minimal external dependencies
- Include proper argument parsing and error handling
- Always executable with appropriate permissions and shebang line

**Example Utility Script path:**

```plain
/scripts/aio-version-checker.py
```

### Application Scripts

Application Scripts are components of larger Python applications or modules that work together to provide more complex functionality.

**Characteristics of Application Scripts:**

- Part of a larger Python package structure
- Follow standard Python module patterns
- May be imported by other Python modules
- Include appropriate `__init__.py` files for package structure
- Have broader scope and may involve complex dependencies
- More extensive documentation and API references

## Script Structure

Each Python script follows a consistent structure for maintainability and readability:

```plain
├── scripts/
│   ├── example-script.py        # Utility Script
│   ├── script-group/
│   │   ├── specialized-tool.py  # Specialized Utility Script
```

### Script File Organization

ALWAYS use consistent file organization:

1. Shebang line and file encoding
2. Module-level docstring describing purpose and usage
3. Imports (standard library, third-party, local) grouped and alphabetized
4. Constants and global variables
5. Class definitions
6. Function definitions
7. Main function and entry point

## Python Script Coding Conventions

### General Conventions

- ALWAYS use `kebab-case` for file and folder names
- ALWAYS use `snake_case` for function and variable names
- ALWAYS use `PascalCase` for class names
- ALWAYS use `UPPER_SNAKE_CASE` for constants
- ALWAYS format code according to PEP 8 standards
- NEVER use deprecated functions or modules
- ALWAYS include comprehensive docstrings in triple quotes
- ALWAYS set shebang line to `#!/usr/bin/env python3` for executables
- ALWAYS implement a `-v/--verbose` flag for command-line tools

### Script Structure Order

Scripts should follow this order:

1. Shebang line and encoding
2. Module docstring
3. Imports (grouped and sorted)
4. Constants
5. Class definitions
6. Function definitions
7. Main entry point

Example:

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
# Example Script

Provides utility functions for validating infrastructure configurations.
Detailed description of what this script does and how to use it.

## Usage:
    python3 example-script.py --input-file config.json --validate

## Exit Codes:
    0 - Success
    1 - Invalid input file
    2 - Validation errors found
    3 - Unexpected error
"""

# Standard library imports
import argparse
import json
import logging
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional

# Third-party imports
import yaml

# Constants defined at module level
DEFAULT_CONFIG_PATH = os.path.expanduser("~/.config/example")
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format=LOG_FORMAT,
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger(__name__)


def parse_arguments() -> argparse.Namespace:
    """Parse and return command line arguments."""
    parser = argparse.ArgumentParser(
        description="Validate infrastructure configurations."
    )

    # Required arguments
    parser.add_argument("--input-file", required=True,
                        help="Path to configuration file to validate.")

    # Optional arguments
    parser.add_argument("--validate", action="store_true",
                        help="Perform validation on the input file.")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Enable verbose output.")

    return parser.parse_args()


def load_config_file(file_path: str) -> Dict:
    """
    Load configuration from file.

    Args:
        file_path: Path to configuration file

    Returns:
        Dictionary containing configuration data

    Raises:
        FileNotFoundError: If file doesn't exist
        json.JSONDecodeError: If JSON file is invalid
    """
    file_path = Path(file_path)

    if not file_path.exists():
        logger.error(f"Configuration file not found: {file_path}")
        raise FileNotFoundError(f"File not found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        if file_path.suffix.lower() == '.json':
            return json.load(f)
        elif file_path.suffix.lower() in ('.yaml', '.yml'):
            return yaml.safe_load(f)
        else:
            logger.error(f"Unsupported file format: {file_path.suffix}")
            raise ValueError(f"Unsupported file format: {file_path.suffix}")


def main() -> int:
    """Main entry point for the script."""
    try:
        args = parse_arguments()

        # Configure logging based on verbosity
        if args.verbose:
            logger.setLevel(logging.DEBUG)
            logger.debug("Debug logging enabled")

        # Load configuration
        config = load_config_file(args.input_file)
        logger.info(f"Successfully loaded configuration from {args.input_file}")

        # Perform validation if requested
        if args.validate:
            # Validation logic here
            logger.info("Validation completed successfully")

        return 0

    except FileNotFoundError as e:
        logger.error(f"File error: {e}")
        return 1
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in configuration file: {e}")
        return 1
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        return 2
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return 3


if __name__ == "__main__":
    sys.exit(main())
```

### Function and Class Conventions

IMPORTANT RULES:

- Functions SHOULD do one thing and do it well
- Functions SHOULD be less than 50 lines of code
- Classes SHOULD follow the Single Responsibility Principle
- Class methods SHOULD follow the same rules as functions
- Avoid deeply nested functions and classes

### Argument Parsing Conventions

- ALWAYS use `argparse` for command-line scripts
- ALWAYS provide descriptive help text for each argument
- ALWAYS group related arguments together
- ALWAYS handle required and optional arguments appropriately
- ALWAYS validate argument values

Example:

```python
def parse_arguments():
    """Parse and return command line arguments."""
    parser = argparse.ArgumentParser(
        description="Process data files and generate reports."
    )

    # Input/output arguments
    io_group = parser.add_argument_group("Input/Output Options")
    io_group.add_argument("--input-dir", required=True,
                        help="Directory containing input files.")
    io_group.add_argument("--output-file",
                        help="Path to output file (default: output.json).")

    # Processing options
    proc_group = parser.add_argument_group("Processing Options")
    proc_group.add_argument("--max-depth", type=int, default=3,
                          help="Maximum directory depth to process (default: 3).")
    proc_group.add_argument("--include-hidden", action="store_true",
                          help="Include hidden files in processing.")

    # Logging options
    log_group = parser.add_argument_group("Logging Options")
    log_group.add_argument("--verbose", "-v", action="store_true",
                         help="Enable verbose output.")
    log_group.add_argument("--quiet", "-q", action="store_true",
                         help="Suppress all output except errors.")

    return parser.parse_args()
```

### Verbosity Control Conventions

- ALWAYS implement a `-v/--verbose` argument for utility scripts
- ALWAYS use `logging` module configured based on verbosity level
- ALWAYS provide appropriate debug output when verbose mode is enabled
- ALWAYS use different logging levels appropriately (DEBUG, INFO, WARNING, ERROR, CRITICAL)

Example verbosity implementation:

```python
def parse_arguments() -> argparse.Namespace:
    """Parse and return command line arguments."""
    parser = argparse.ArgumentParser(
        description="Process infrastructure configuration files."
    )

    # Required arguments
    parser.add_argument("--config-file", required=True,
                       help="Path to configuration file to process.")

    # Verbosity options
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Enable verbose output")
    parser.add_argument("--quiet", "-q", action="store_true",
                       help="Suppress all output except errors")

    return parser.parse_args()

def configure_logging(verbose: bool, quiet: bool) -> None:
    """
    Configure logging based on verbosity level.

    Args:
        verbose: Whether to enable verbose (debug) logging
        quiet: Whether to suppress all output except errors
    """
    # Set default format
    log_format = "%(levelname)s: %(message)s"

    # Configure based on verbosity
    if quiet:
        logging.basicConfig(level=logging.ERROR, format=log_format)
    elif verbose:
        logging.basicConfig(
            level=logging.DEBUG,
            format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
    else:
        logging.basicConfig(level=logging.INFO, format=log_format)

    # Get logger for this module
    logger = logging.getLogger(__name__)

    # Log verbosity configuration
    if verbose:
        logger.debug("Verbose logging enabled")
        logger.debug(f"Python version: {sys.version}")
        logger.debug(f"Platform: {sys.platform}")

def main() -> int:
    """Main entry point for the script."""
    try:
        # Parse arguments
        args = parse_arguments()

        # Configure logging based on verbosity
        configure_logging(args.verbose, args.quiet)
        logger = logging.getLogger(__name__)

        # Process configuration file
        if args.verbose:
            logger.debug(f"Loading configuration from {args.config_file}")
            logger.debug(f"Using options: {vars(args)}")

        config = load_config_file(args.config_file)

        if args.verbose:
            logger.debug(f"Configuration loaded successfully")

        # Process the configuration
        result = process_config(config)

        if args.verbose:
            logger.debug(f"Processing completed with {len(result)} items")

        logger.info("Operation completed successfully")
        return 0

    except FileNotFoundError as e:
        logger.error(f"File not found: {e}")
        return 1
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in configuration: {e}")
        return 2
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return 99
```

### Error Handling Conventions

- ALWAYS use specific exception types, not bare `except:`
- ALWAYS provide meaningful error messages
- ALWAYS use logging with appropriate levels
- ALWAYS return meaningful exit codes from scripts
- NEVER swallow exceptions without good reason

Example:

```python
try:
    config = load_config(config_path)
    validate_config(config)
except FileNotFoundError as e:
    logger.error(f"Configuration file not found: {e}")
    return 1
except PermissionError as e:
    logger.error(f"Permission denied accessing file: {e}")
    return 2
except json.JSONDecodeError as e:
    logger.error(f"Invalid JSON in configuration file: {e}")
    return 3
except ValidationError as e:
    logger.error(f"Configuration validation failed: {e}")
    return 4
except Exception as e:
    logger.exception(f"Unexpected error: {e}")
    return 99
```

### File Operations Conventions

- ALWAYS use context managers (`with` statement) for file operations
- ALWAYS specify file encoding explicitly (usually `utf-8`)
- ALWAYS use `pathlib.Path` for path manipulations instead of string operations
- ALWAYS handle file-related exceptions specifically

## Python Script DOs and DON'Ts

### DO

- DO use type hints for function parameters and return values
- DO use docstrings for all public functions, classes, and modules
- DO use logging instead of print statements
- DO handle exceptions appropriately with specific exception types
- DO validate user input and function parameters
- DO follow PEP 8 style guidelines
- DO use context managers for resource management

### DON'T

- DON'T use global variables for function communication
- DON'T use bare `except:` statements without specifying exception types
- DON'T use `os.system()`, `os.popen()` or other shell invocation functions
- DON'T include hardcoded paths or credentials in scripts
- DON'T mix string formatting styles (stick with f-strings for Python 3.6+)
- DON'T reinvent standard library functionality

## Pre-Implementation Checklist

Before making ANY changes to Python script code, ask yourself:

- [ ] What type of script am I working on (Utility, Application)?
- [ ] Have I included proper docstrings for the module and all functions?
- [ ] Have I included appropriate error handling for expected issues?
- [ ] Are my imports properly organized and grouped?
- [ ] Do I need command-line argument processing?
- [ ] Have I included type hints for function parameters and return values?
- [ ] Will my file operations properly handle non-ASCII text?
- [ ] Have I considered security implications (input validation, shell injection)?

## Post-Implementation Checklist

After completing ALL changes, verify:

- [ ] Does the script have comprehensive docstrings?
- [ ] Are all functions properly type-hinted?
- [ ] Is error handling robust with appropriate exit codes?
- [ ] Is logging configured appropriately for the script's purpose?
- [ ] Are file operations using context managers and explicit encodings?
- [ ] Does the code follow PEP 8 style guidelines?
- [ ] Is there a `main()` function and proper entry point?
- [ ] Have I tested the script with valid and invalid inputs?
- [ ] Are there any unnecessary dependencies that could be removed?
- [ ] Is the code properly formatted and consistent with project style?
- [ ] Are there any hardcoded values that should be arguments or constants?
- [ ] Have I verified the script works on the target Python version?
