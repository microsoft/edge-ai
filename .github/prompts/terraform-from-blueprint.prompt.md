---
mode: 'agent'
description: 'Creates new Terraform IaC or adds to an existing one from a specified blueprint.'
---

# Create or Update Terraform IaC from Blueprint

## Core Directives

You are an expert in Terraform and Infrastructure as Code (IaC) management.

You WILL ALWAYS analyze the specified blueprint and the target IaC directory thoroughly.

You WILL ALWAYS follow best practices for Terraform code structure, module referencing, and variable management.

You WILL NEVER introduce breaking changes to existing IaC in the target path without explicit instruction.

You WILL ALWAYS ensure that module paths are correctly updated to reflect their new location relative to this project's `src` directory.

You WILL ALWAYS generate a comprehensive `terraform.auto.tfvars` file with clear documentation for each variable.

You WILL ALWAYS verify that required inputs are provided and prompt for them if missing.

## User Inputs

This prompt requires the following input variables:

- `${input:blueprint}`: The name of the blueprint to use as a source (e.g., `full-multi-node-cluster`).
- `${input:toPath}`: The relative or absolute path to the target IaC directory where the Terraform files will be copied and updated (e.g., `../my-iac-proj/deploy/env-name`).

### Handling Missing Inputs

If `${input:blueprint}` is not provided:

- You WILL list all available blueprints from the `blueprints/` directory.
  - You WILL provide a one sentence summary of what the blueprint is for EACH blueprint.
  - You WILL determine the one sentence summary from the `blueprints/*/README.md`.
- You WILL prompt the user to specify a blueprint name from the available options.
- You WILL wait for the user to provide a valid blueprint name before proceeding.

If `${input:toPath}` is not provided:

- You WILL prompt the user to specify a target path.
- You WILL explain that the path can be:
  - Relative to the `edge-ai` directory (e.g., `../my-sibling-project/terraform/dev`)
  - An absolute path (e.g., `/Users/username/Projects/my-project/terraform/dev`)
- You WILL provide an example showing how to specify a folder in a sibling directory, such as:

```
../my-deploy-repo/environments/dev-environment
```

## Process Overview

1. **Identify Blueprint Source**:

   - You WILL locate the Terraform files within the specified blueprint directory: `blueprints/${input:blueprint}/terraform/`.

2. **Copy Blueprint Files**:

   - You WILL copy all `*.tf` files from the blueprint's Terraform directory to the directory specified by `${input:toPath}`.
     - You WILL exclude all files from `.terraform`, `.terraform.*`, or `*.tfvars` from the blueprint.
   - You WILL create the target directory `${input:toPath}` if it does not already exist.
   - If the `${input:toPath}` directory already exists and contains Terraform files (`*.tf`), you WILL proceed to copy all files from the blueprint. You WILL NOT delete any existing files in `${input:toPath}` unless they are explicitly overwritten by a file with the same name from the blueprint. You WILL effectively merge the blueprint's files into the existing directory.

3. **Update Module Source Paths**:

   - You WILL analyze all copied `*.tf` files in the `${input:toPath}` directory.
   - For every `module` block, you WILL update the `source` attribute.
   - The original blueprint paths are relative (e.g., `../../../src/000-cloud/000-resource-group/terraform`).
   - You WILL calculate the new relative path from the `${input:toPath}` directory back to the `src` directory of *this current project*.
   - **CRITICAL**: You WILL assume the `${input:toPath}` can be at any arbitrary depth. The path adjustment MUST be dynamic. For example, if `${input:toPath}` is `../my-iac-proj/deploy/env-name`, then a module originally at `../../../src/` (relative to `blueprints/blueprint-name/terraform/`) would need its path adjusted. If `my-iac-proj` is a sibling to `edge-ai`, the new path might look like `../../../project-a/src/`.

4. **Manage `terraform.auto.tfvars`**:

   - You WILL create a `terraform.auto.tfvars` file in the `${input:toPath}` directory if one does not exist.
   - If it exists, you WILL read its content to avoid overwriting existing user-defined variables.
   - You WILL identify all unique variables defined in the `variables.tf` files of the copied blueprint and its referenced modules (from this project's `src` directory).
   - For each variable, you WILL add an entry to `terraform.auto.tfvars` unless it already exists in the file.
   - You WILL provide a sensible default value for each new variable.
     - You WILL infer `resource_prefix` from the last component of the `${input:toPath}` (e.g., if `${input:toPath}` is `../my-iac-proj/deploy/env-name`, then `resource_prefix` could be `env-name`).
     - You WILL infer `environment` (e.g., `dev`, `test`, `prod`) from the `${input:toPath}` or `resource_prefix` if possible, otherwise default to a common value like `dev`.
   - **MANDATORY**: Every variable entry in `terraform.auto.tfvars` (new or existing that you might add comments to) WILL have a preceding comment explaining its purpose, in the following format:

     ```terraform
     // Description of the variable
     variable_name = "value"
     ```

   - You WILL group related variables logically using blank lines and/or comments (e.g., `// General Settings`, `// Network Configuration`).

5. **Final Verification**:

   - You WILL ensure all copied Terraform files are correctly formatted.
   - **CRITICAL**: You WILL confirm that all module `source` paths are valid and point to the correct locations within this project's `src` directory, relative to the new `${input:toPath}`.

## Examples

### Module Path Update Example

If `${input:toPath}` is `../my-iac-project/deploy/example-demo` and the current project is `edge-ai`:

Original path in blueprint's `main.tf`:
```terraform
source = "../../../src/000-cloud/010-security-identity/terraform"
```

Updated path in `${input:toPath}/main.tf`:
```terraform
source = "../../../edge-ai/src/000-cloud/010-security-identity/terraform"
```

(This is an illustrative example; the actual number of `../` will depend on the exact directory structure and depth of `${input:toPath}` relative to the `edge-ai` root).

### terraform.auto.tfvars Example

If `${input:toPath}` is `../my-iac-project/deploy/example-cell-demo` and the `${input:blueprint}` is `full-arc-multi-node-cluster` (not-exclusive):

```terraform
// Core variables for naming resources, combined should be a unique name
environment = "demo"
resource_prefix = "examplecell"
location = "eastus2"
instance = "001"

// Tags that match the requirements for the tenant
resource_group_tags = {
  blueprint = "full-arc-multi-node-cluster"
}

// The resource group for all new resources
resource_group_name = "rg-examplecell-demo-001"

// IP address to give to the cluster nodes for connecting to the cluster
cluster_server_ip = "10.0.1.19"
// The username for the Arc servers
cluster_server_host_machine_username = "examplecell"

// The prefix name used with the Arc servers (example-server-1, example-server-2, example-server-3)
arc_machine_name_prefix = "example-server-"
// The number of Arc servers
arc_machine_count = 3
// The resource group for the Arc servers
arc_machine_resource_group_name = "rg-examplecell-demo-001"

// Getting Custom Locations OID requires elevated privileges so it is provided up-front
custom_locations_oid = ""
// Skip getting Custom Locations OID from terraform
should_get_custom_locations_oid = false

// Creating anonymous broker for testing and verification for demo or dev environment
should_create_anonymous_broker_listener = true
// Installs the OPC UA Simulator with kubectl into the cluster
should_enable_opc_ua_simulator = true
// Installs the OTel Collector Helm chart into the cluster
should_enable_otel_collector = true
```
