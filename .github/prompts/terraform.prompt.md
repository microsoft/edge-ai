# Terraform IaC Conventions

You are expert in Terraform IaC conventions and best practices. When writing Terraform, always validate suggestions and code against the following guidelines.
You understand this project by looking at the [README.md](../../README.md), [CONTRIBUTING.md](../../CONTRIBUTING.md) and [coding conventions](../../docs/coding-conventions.md) files.

## Source Components Structure Components and Modules (`/src`)

### Directory Organization

- You understand the structure of [`/src` Components structure] by looking at the [README.md](../../README.md) file.
- Components use decimal naming for deployment order: `000-subscription`, `010-vm-host`
- Each component must include:
  - `/terraform` directory for implementation, `/terraform/modules` for reusable modules
  - `/ci/terraform` directory for CI/CD pipeline configuration

- Use consistent file organization:
  - `main.tf` - Primary resource definitions
  - `variables.tf` - Optional variables with defaults
  - `variables.deps.tf` - Required dependency variables (objects from other modules)
  - `variables.core.tf` - Required core variables (strings, numbers, etc.)
  - `outputs.tf` - Module outputs
  - `versions.tf` - Provider requirements

## Variable Conventions

- Organize variables alphabetically within each `variables file, always reorder after editing!
- Apply rfc2119 to all variable names when applicable
- Use `snake_case` for variable names
- Always include descriptive `description` attribute
- Variables MUST specify their type
- Required variables MUST NOT have defaults
- Add validation rules for constraints

## Resource Naming

- Resource names in code should match Azure resource naming conventions
- Use `snake_case` for resource names

### Module Design

- Each module in separate directory with meaningful name under a component
- Use `./modules/module-name` for module directory
- Keep modules focused on a single responsibility

### Test Structure and Organization

- `/terraform/tests` directory with Terraform tests at the component level, never at the module level
- Don't create new test files for each module, use the existing test file and add a new `run` block
- Create a setup module for reusable test prerequisites and variables
- Structure tests as separate run blocks with clear naming conventions
- Use `command = plan` for non-destructive testing when possible

#### Assertions

- Test default configurations first, then create separate runs for custom configurations
- Test one aspect of functionality per assertion block with descriptive error messages
- Use alltrue() for multiple conditions in a single assertion
- Confirm critical attributes using direct value comparisons
- Verify conditional resource creation with existence checks (e.g., length() > 0)

## Blueprints Structure (`/blueprints`)

You understand the structure of [`/blueprints` Blueprints structure] by looking at the [blueprints README](../../blueprints/README.md) file.
Blueprints combine multiple components from `/src` to create deployable solutions

### Implementation

- Each blueprint must include Terraform implementation in `/terraform` subdirectory

## Code Quality

- Run `terraform fmt` before committing
- Follow HashiCorp style conventions
- Use 2-space indentation
- Group related resources logically
- Use descriptive resource names and IDs

## Critical Rules (Always Follow)

- ALWAYS alphabetically sort variables in ALL variables files after adding new variables
  ❌ BAD: Leaving new variables at the end of the file
  ✓ GOOD: Reordering the complete variable list alphabetically

## Implementation Checklist

Before finalizing code changes, verify:

- [ ] Have all variables been alphabetically sorted in ALL variables files?
- [ ] Have new tests been added as run blocks to EXISTING test files rather than new files?
- [ ] Have you organized any new files in the correct Directory Organization?
