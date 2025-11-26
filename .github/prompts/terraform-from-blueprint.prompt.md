---
mode: 'agent'
description: 'Creates new Terraform IaC or adds to an existing one from a specified blueprint - Brought to you by microsoft/edge-ai'
model: 'Claude Sonnet 4'
---

# Create or Update Terraform IaC from Blueprint

## Core Directives

You are an expert in Terraform and Infrastructure as Code (IaC) management.

**CRITICAL RULES**:

- ALWAYS analyze the specified blueprint and target directory thoroughly
- NEVER modify existing content unless required for blueprint integration
- NEVER add modification comments to unchanged code
- ALWAYS preserve custom modules, resources, variables, and outputs
- ALWAYS validate paths and configurations before completion
- ALWAYS work with external directories and absolute paths when specified
- ALWAYS handle cross-repository and out-of-workspace operations
- **ALWAYS intelligently update component parameters while preserving manual modifications**

**WORKSPACE LOCATION REQUIREMENTS**:

- **ALWAYS locate the `edge-ai` directory** first to access blueprints and source components
- **BLUEPRINTS LOCATION**: All blueprints are located in `{edge-ai-path}/blueprints/`
- **COMPONENTS LOCATION**: All source components are in `{edge-ai-path}/src/`
- **GIT SHA ACQUISITION**: Always run `git rev-parse HEAD` from within the `edge-ai` directory to get the correct SHA

## Required Inputs

This prompt requires the following input variables:

- `${input:blueprint}`: Blueprint name (e.g., `full-single-node-cluster`)
- `${input:toPath}`: Target directory path (supports absolute paths, relative paths, and external directories)

### Input Validation

If blueprint is missing:

- List available blueprints from `blueprints/` directory
- Provide one-sentence summary from each `README.md`
- Wait for user selection

If target path is missing:

- Prompt for path (absolute, relative to current directory, or external)
- Examples:
  - Absolute: `/Users/username/my-project/terraform/dev`
  - Relative to workspace: `../my-deploy-repo/environments/dev-environment`
  - External repo: `/path/to/external-repo/infrastructure/terraform`

## Process Steps

### 1. Locate Edge-AI Directory and Validate Blueprint

- First, locate the `edge-ai` directory (may be current workspace or need to be found)
- Verify `{edge-ai-path}/blueprints/${input:blueprint}/terraform/` exists
- Confirm contains `*.tf` files
- Show files for confirmation

### 2. Analyze Target Directory

**Path Resolution**:

- Resolve absolute paths directly
- Convert relative paths to absolute paths
- Use `list_dir` to validate external directory accessibility
- Use `create_directory` to create target directory structure if it doesn't exist

**Existing Target Analysis**:
If target exists:

- Identify `*.tf` files at target path
- Read all existing `*.tf` files at target location
- Identify custom modules, resources, locals, variables, outputs
- **PRESERVE ALL** custom logic during merge
- Handle files outside workspace boundaries appropriately

### 3. Determine Target Type

**Module Detection** (either condition = module):

- Path contains `module` or `modules`
- Check if `versions.tf` exists with no `provider` blocks

**Result**:

- Module → Skip `terraform.auto.tfvars` generation
- Deployment → Generate `terraform.auto.tfvars`

### 4. Apply Blueprint

**New Target**:

- Create directory structure with absolute paths
- Copy all blueprint `*.tf` files with absolute target paths

**Existing Target**:

- Merge blueprint files with existing files at absolute paths
- Add new modules/resources from blueprint
- Preserve ALL existing custom content
- Update only module source paths
- **Apply intelligent parameter updates (see Step 8)**

### 5. Update Module Sources

**Path Calculation Strategy**:

- Evaluate relative path complexity from target directory to edge-ai directory
- Handle cross-repository and external absolute path references appropriately
- Support both local file-based and Git-based source strategies

**Strategy Selection Logic**:

- **Use Local Paths**: When target is within or relative to edge-ai directory
- **Use Git Strategy**: When target is external absolute path or cross-repository
- **Mixed Scenarios**: Prefer Git strategy for complex relative path calculations

**Local File-based Strategy**:

- Calculate relative path from target to edge-ai directory
- Update `source` attributes: `{relative-path-to-edge-ai}/src/{component-path}/terraform`
- Examples:
  - Internal: `../../../src/000-cloud/010-security-identity/terraform`
  - Near external: `../../../../edge-ai/src/000-cloud/010-security-identity/terraform`
- Preserve all other module parameters

**Git Strategy** (recommended for external deployments):

- Use: `git::https://ai-at-the-edge-flagship-accelerator@dev.azure.com/ai-at-the-edge-flagship-accelerator/edge-ai/_git/edge-ai//src/{component-path}/terraform?ref={sha}`
- Get SHA by running `git rev-parse HEAD` from within the edge-ai directory
- Recommended for external repositories, absolute paths, or complex relative path scenarios

### 6. Generate terraform.auto.tfvars (Deployments Only)

- Skip if target is a module
- Read existing file and preserve user values
- Add new variables only with sensible defaults:
  - `resource_prefix`: Extract from path (max 8 chars)
  - `environment`: "dev"/"test"/"prod" from path or default "dev"
  - `location`: "eastus2"
  - `instance`: "001"
- Add comment above each new variable
- Write to absolute target path

### 7. Validate Results

**Path and Access Validation**:

- Verify all module paths are accessible from target location
- Validate cross-repository references work correctly
- Check external directory permissions and accessibility

**Configuration Validation**:

- Use terraform CLI validation (`terraform validate`, `terraform plan -detailed-exitcode`)
- Confirm no circular dependencies
- Verify module source paths resolve correctly
- Report any issues with external path access

### 8. Intelligent Parameter Updates for Existing Components

**CRITICAL: Preservation-First Merging Strategy**
When updating existing deployments, **preserve all existing customizations** and only add new elements from blueprints:

#### Merging Analysis Phase

**For each existing module block:**

1. **Component Identification**: Extract component path from existing module source
2. **Blueprint Comparison**: Find same component usage in blueprint
3. **Parameter Inventory**:
   - **Existing Parameters**: All parameters currently in target deployment
   - **Blueprint Parameters**: All parameters used in blueprint for same component
   - **New Parameters**: Parameters in blueprint but not in existing deployment

#### Preservation Rules (ALWAYS FOLLOW)

**PRESERVE EXISTING** (Never modify unless explicitly broken):

- **All existing parameter values** - regardless of whether they match blueprint
- **All existing parameter names and assignments**
- **All existing complex object structures and their values**
- **All existing variable references** (`var.something`)
- **All existing hardcoded values** (strings, numbers, booleans)
- **All existing conditional logic** (`condition ? value : other`)

**ADD FROM BLUEPRINT** (Only add what's missing):

- **New parameters**: Parameters present in blueprint but missing from existing deployment
- **New module blocks**: Components used in blueprint but not in existing deployment
- **New variables**: Add to `terraform.auto.tfvars` only if they don't exist

**NEVER REPLACE** (Critical preservation rules):

- **Never change existing parameter values** - even if blueprint has different values
- **Never modify existing variable references** - preserve `var.custom_setting`
- **Never alter existing complex objects** - preserve custom `aio_features` configurations
- **Never update existing hardcoded values** - preserve intentional customizations

#### Safe Addition Logic

**When adding new parameters from blueprint:**

1. **Positional Addition**: Add new parameters at end of existing parameter list
2. **Preserve Formatting**: Maintain existing indentation and spacing patterns
3. **Context-Aware Defaults**: Use blueprint values for new parameters only
4. **Documentation**: Add inline comments for new parameters explaining their purpose

**Example Safe Merge:**

```hcl
# EXISTING (preserve exactly as-is):
module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"
  environment = "production"
  resource_prefix = "custom-app"
  should_create_anonymous_broker_listener = true
  custom_timeout = 600
  aio_features = {
    connectors = { settings = { preview = "Enabled", custom_flag = true } }
  }
}

# BLUEPRINT has same component with:
module "edge_iot_ops" {
  source = var.iot_ops_source
  environment = var.environment
  resource_prefix = var.resource_prefix
  should_deploy_resource_sync_rules = var.should_deploy_resource_sync_rules
  aio_features = var.aio_features
}

# RESULT after merge (adds only missing parameters):
module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"  # Preserved
  environment = "production"  # Preserved custom value
  resource_prefix = "custom-app"  # Preserved custom value
  should_create_anonymous_broker_listener = true  # Preserved custom setting
  custom_timeout = 600  # Preserved custom parameter
  aio_features = {  # Preserved entire custom object
    connectors = { settings = { preview = "Enabled", custom_flag = true } }
  }
  # New parameter from blueprint
  should_deploy_resource_sync_rules = var.should_deploy_resource_sync_rules
}
```

#### Variable File Safe Updates

**For `terraform.auto.tfvars` files:**

**PRESERVE ALL EXISTING** (Never modify):

- All existing variable assignments
- All existing values and their types
- All existing comments and formatting
- Custom variable names and their values

**ADD ONLY MISSING**:

- New variables required by new parameters from blueprint
- Default values for new variables only
- Explanatory comments for new variables

**Example tfvars safe update:**

```hcl
# EXISTING terraform.auto.tfvars (preserve exactly):
resource_prefix = "my-custom-app"
environment = "production"
custom_vm_size = "Standard_DS3_v2"
should_create_anonymous_broker_listener = true

# AFTER BLUEPRINT UPDATE (adds only new variables):
resource_prefix = "my-custom-app"  # Preserved exactly
environment = "production"  # Preserved exactly
custom_vm_size = "Standard_DS3_v2"  # Preserved custom variable
should_create_anonymous_broker_listener = true  # Preserved custom setting

# New variables added from blueprint requirements
should_deploy_resource_sync_rules = false  # New parameter default
```

#### Critical Preservation Checks

**Before making any changes, verify:**

1. **No Existing Values Modified**: Confirm no existing parameter values are changed
2. **No Existing Structure Altered**: Preserve object structures and nesting
3. **No Variable References Changed**: Keep existing `var.` references intact
4. **Only Additions Made**: Verify only new parameters/variables are added
5. **Formatting Respected**: Maintain existing code style and indentation

#### Error Prevention

**If merge would modify existing values:**

- **STOP**: Do not proceed with conflicting changes
- **REPORT**: List parameters that would be modified
- **RECOMMEND**: Manual review of specific parameters
- **PRESERVE**: Keep existing deployment unchanged except for safe additions

**Safe merge indicators:**

- ✅ Only adding new parameters that don't exist
- ✅ Preserving all existing parameter values
- ✅ Adding new variables to tfvars with defaults
- ✅ No modification of existing complex objects

**Unsafe merge indicators (AVOID):**

- ❌ Changing existing parameter values
- ❌ Modifying existing variable references
- ❌ Altering existing object structures
- ❌ Replacing hardcoded values with variables

#### Source Path Preservation

**Module source paths follow same preservation rules:**

**PRESERVE EXISTING** (Never modify working paths):

- Keep existing relative paths if they work
- Keep existing Git-based sources if they work
- Keep existing absolute paths if they work
- Only update source if path is broken or explicitly requested

**UPDATE ONLY IF** (Specific conditions):

- Existing source path is broken/inaccessible
- User explicitly requests source strategy change
- New deployment (no existing source to preserve)

**Example source preservation:**

```hcl
# EXISTING (keep if working):
module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"  # Keep this
  # ...existing code...
}

# BLUEPRINT suggests:
module "edge_iot_ops" {
  source = var.iot_ops_source  # Don't replace working source with this
  # ...existing code...
}

# RESULT (preserve working source):
module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"  # Preserved
  # ...add new parameters only...
}
```

#### Complex Object Preservation Details

**For nested objects and arrays, preserve entire structures:**

**Preserve Complete Objects**:

- Keep all existing keys and values
- Keep all nested structures intact
- Preserve array orders and contents
- Maintain custom validation logic

**Example complex preservation:**

```hcl
# EXISTING complex object (preserve entirely):
aio_features = {
  connectors = {
    settings = {
      preview = "Enabled",
      custom_feature = true,
      timeouts = { connect = 30, read = 60 }
    }
  },
  custom_extensions = ["ext1", "ext2"],
  validation_rules = {
    strict_mode = true
  }
}

# NEVER merge or modify - preserve exactly as-is
# Even if blueprint has different aio_features structure
```
