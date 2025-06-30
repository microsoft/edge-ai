# Azure IoT Operations Version Upgrade Prompt

## Overview

This prompt guides you through the process of updating the Azure IoT Operations components in this repository to the latest version. This involves fetching the latest configuration, creating an update plan, and then applying the changes to the Bicep and Terraform code.

You will be working with a directory named `.copilot-tracking/iotops/{current_date}/`, where `{current_date}` is the current date in `YYYY-MM-DD` format (e.g., `2025-06-24`).

## 1. Fetch Latest Configuration

**FIRST CRITICAL PREREQUISITE**: Your first task is to download the latest release information for Azure IoT Operations.

1.  Determine the current date in `YYYY-MM-DD` format (e.g., June 24, 2025 becomes `2025-06-24`).
2.  Create a directory `.copilot-tracking/iotops/{current_date}/` if it doesn't exist using `create_directory`.
3.  **Get the latest release information**: Use `fetch_webpage` to get the latest release information from `https://api.github.com/repos/Azure/azure-iot-operations/releases/latest` with the query "latest release information".
4.  **Download the configuration files**: From the latest release, download the following files into the directory using the direct download URLs from the release:
    *   Download `azure-iot-operations-instance.json` from the latest release assets
    *   Download `azure-iot-operations-enablement.json` from the latest release assets

    **Process**:
    - First fetch the latest release API to get the current version number
    - Then use `curl -L -o` commands to download both JSON files from the release assets:
      ```bash
      curl -L -o ".copilot-tracking/iotops/{current_date}/azure-iot-operations-enablement.json" "https://github.com/Azure/azure-iot-operations/releases/download/v{version}/azure-iot-operations-enablement.json"
      curl -L -o ".copilot-tracking/iotops/{current_date}/azure-iot-operations-instance.json" "https://github.com/Azure/azure-iot-operations/releases/download/v{version}/azure-iot-operations-instance.json"
      ```
    - Replace `{version}` with the actual version from the latest release API response
    - If download fails, inform the user and stop processing

## 2. Create or Update the Plan

Next, you will create or update a plan file named `iotops-update-plan.md` in the `.copilot-tracking/iotops/{current_date}/` directory.

**IMPORTANT**: If a plan file for the current date already exists and contains the text "Finished adding all details needed for updating azure iot operations throughout the workspace.", and the user asks you to implement the plan, you must skip to step 8.

**SECOND CRITICAL PREREQUISITE**: Before creating any plan entries for Terraform or Bicep changes, you MUST:
1. Use `read_file` to read and understand ALL instructions from:
   - `.github/instructions/terraform.instructions.md` (for Terraform-related planning)
   - `.github/instructions/bicep.instructions.md` (for Bicep-related planning)
2. Ensure your planned changes will comply with the coding standards specified in these files
3. Reference these instruction files when determining appropriate change approaches

The plan will outline all the necessary code changes. Each item in the plan that requires a code change must be prefixed with a markdown checkbox `[ ]`.

## 3. Analyze and Plan API Version Updates

Analyze the downloaded JSON files and the existing codebase to identify necessary `apiVersion` updates.

**JSON Analysis Process**:
1. **Parse JSON structure**: Look for `resources` arrays in both JSON files
2. **Extract apiVersions**: Find `apiVersion` properties in each resource object
3. **Record resource types**: Note the `type` field for each resource (e.g., `Microsoft.IoTOperations/instance`)

**Codebase Analysis Process**:
1. **Read each file**: Use `read_file` to examine the files listed below
2. **Find apiVersion declarations**: Search for lines containing `apiVersion` or `api_version`
3. **Extract resource types**: Identify which resource type each apiVersion corresponds to

**Version Comparison Logic**:
- **Newer version criteria**: A version is newer if it has a later date (format: YYYY-MM-DD-preview)
- **Update requirement**: Only plan updates when JSON version date is later than codebase version date
- **Missing versions**: If apiVersion is missing in codebase but present in JSON, plan to add it

You must check the following files within the `src/100-edge/110-iot-ops/` component:

**Bicep:**
*   `bicep/modules/iot-ops-init.bicep`
*   `bicep/modules/iot-ops-instance.bicep`
*   `bicep/types.bicep`

**Terraform:**
*   `terraform/variables.init.tf`
*   `terraform/variables.instance.tf`
*   `terraform/modules/iot-ops-init/main.tf`
*   `terraform/modules/iot-ops-init/variables.tf`
*   `terraform/modules/iot-ops-instance/main.tf`
*   `terraform/modules/iot-ops-instance/variables.tf`

**Plan Entry Format**:
```markdown
- [ ] Update `apiVersion` for `Microsoft.IoTOperations/instance` in `src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep` from `2024-11-01-preview` to `2025-06-24-preview`.
```

**Error Handling**: If a file doesn't exist, document this in the plan. If apiVersion format is unrecognizable, document the current value and recommend manual review.

## 4. Analyze and Plan Variable and Parameter Updates

Review the downloaded JSON files for any changes in parameters, including new parameters, changed default values, or removed parameters.

**Parameter Analysis Process**:
1. **Extract JSON parameters**: Look for `parameters` or `properties` objects in the downloaded JSON files
2. **Read existing variables**: Use `read_file` to examine current parameter/variable definitions in the files listed in step 3
3. **Compare with name variation logic**: For each parameter in JSON, find potential matches in codebase using these strategies:
   - **Exact match**: Same name exactly
   - **Case conversion matches**:
     - `schemaRegistryId` ↔ `schema_registry_id` ↔ `SchemaRegistryId` ↔ `SCHEMA_REGISTRY_ID`
     - `userAssignedIdentity` ↔ `user_assigned_identity` ↔ `UserAssignedIdentity`
   - **Abbreviation matches**:
     - `schemaRegistryId` ↔ `schema_reg_id` ↔ `sr_id`
     - `userAssignedIdentity` ↔ `user_identity` ↔ `managed_identity`
   - **Contextual usage analysis**: If name matching fails, examine variable usage in code:
     - For Terraform: Look for variables used in `azapi_resource` blocks or similar
     - For Bicep: Look for parameters used in resource definitions
     - Match based on data type and context (e.g., resource IDs, boolean flags, string values)
4. **Identify changes**: Document parameters that are new, have different defaults, or are missing from JSON

**Change Categories**:
- **New parameters**: Present in JSON but not in codebase (no similar name found)
- **Updated defaults**: Parameter exists in both but with different default values
- **Removed parameters**: Present in codebase but not in JSON (mark for potential removal)
- **Renamed parameters**: Similar functionality but different names (requires mapping)

**Name Matching Algorithm**:
1. **Direct comparison**: Check for exact name match first
2. **Case normalization**: Convert both names to lowercase and compare
3. **Pattern transformation**: Apply common transformations:
   ```
   JSON: "schemaRegistryId"
   Possible matches: schema_registry_id, SchemaRegistryId, SCHEMA_REGISTRY_ID, schema_reg_id

   JSON: "userAssignedIdentity"
   Possible matches: user_assigned_identity, UserAssignedIdentity, user_identity, managed_identity_id

   JSON: "enableDiagnostics"
   Possible matches: enable_diagnostics, diagnostics_enabled, diag_enabled
   ```
4. **Semantic analysis**: If transformation fails, analyze variable usage:
   - **For resource IDs**: Look for variables ending in `_id`, containing `resource`, or used in dependency references
   - **For boolean flags**: Look for variables with `enable_`, `is_`, `has_` prefixes or `_enabled` suffix
   - **For configuration strings**: Look for variables matching the parameter's data type and context

**Usage Context Analysis**:
- **Terraform**: Search for variable usage in `body` blocks of `azapi_resource` or in `jsonencode()` functions
- **Bicep**: Search for parameter usage in resource `properties` sections or as `@description` annotations
- **Cross-reference**: Use variable names that appear in both Terraform and Bicep for the same resource type

**Plan Entry Requirements**:
- Include specific file path
- Specify exact parameter name
- Show old and new values for updates
- Include parameter type and description if available

**Plan Entry Format**:
```markdown
- [ ] In `src/100-edge/110-iot-ops/terraform/variables.instance.tf`, update the default value for the `log_level` variable from `"info"` to `"debug"`.
- [ ] In `src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep`, add new parameter `enable_diagnostics` with type `bool` and default value `false` (maps to JSON parameter `enableDiagnostics`).
- [ ] In `src/100-edge/110-iot-ops/terraform/variables.instance.tf`, rename variable `user_identity` to `user_assigned_identity` to match JSON parameter `userAssignedIdentity` (keep existing default value to preserve logic).
- [ ] In `src/100-edge/110-iot-ops/terraform/variables.instance.tf`, remove deprecated variable `legacy_mode` (no longer in JSON schema).
```

**Default Value Guidelines**:
- **Preserve null values**: Do NOT change `null` defaults to empty strings or other values unless explicitly required by the JSON schema
- **Maintain logic integrity**: Existing default values often have specific purposes in conditional logic
- **Only update when necessary**: Change defaults only when the JSON schema specifies a different required default
- **Appropriate change example**: If JSON schema shows `"logLevel": { "default": "debug" }` and codebase has `default = "info"`, then update to match schema
- **Inappropriate change example**: Do NOT change `default = null` to `default = ""` for resource ID variables, as null often indicates "not specified" in conditional logic

**Documentation Requirements**:
- Always note the original JSON parameter name when mapping is involved
- Include both old and new values for renames and updates
- Specify the reasoning for complex mappings (e.g., "based on usage in azapi_resource.instance body")

## 5. Analyze and Plan Dependency Updates

Analyze how new parameters from the downloaded JSONs map to existing dependencies of the `110-iot-ops` component.

**Dependency Analysis Process**:
1. **Identify new parameters**: Find parameters in the downloaded JSONs that are not present in the existing component variables/parameters.
2. **Read dependency files**:
   - For Terraform: Use `read_file` to examine `src/100-edge/110-iot-ops/terraform/variables.deps.tf`
   - For Bicep: Use `read_file` to examine parameter sections in `src/100-edge/110-iot-ops/bicep/modules/`
3. **Map parameters to dependencies**: For each new parameter, determine if it should reference an existing dependency variable:
   - `userAssignedIdentity` → likely maps to `var.managed_identity` or similar
   - `schemaRegistryId` → likely maps to `var.adr_schema_registry.id`
   - `keyVaultId` → likely maps to `var.key_vault.id`
4. **Verify current implementation**: Check the relevant `main.tf` or Bicep module files to see if these mappings already exist.

**Decision Logic**:
- **Add to plan ONLY IF**: A new JSON parameter should map to an existing dependency variable AND this mapping is missing from the current implementation
- **Skip if**: The parameter is already correctly wired to its dependency variable
- **Skip if**: The parameter doesn't correspond to any existing dependency

**Verification Process**:
1. Use `read_file` to examine implementation files:
   - `src/100-edge/110-iot-ops/terraform/modules/iot-ops-instance/main.tf`
   - `src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep`
2. Search for the parameter name in these files
3. Check if it's already sourced from the correct dependency variable

**Plan Entry Format** (only add if mapping is missing):
```markdown
- [ ] In `src/100-edge/110-iot-ops/terraform/modules/iot-ops-instance/main.tf`, update the `azapi_resource.instance` to source the `schemaRegistryId` property from `var.adr_schema_registry.id` instead of using a hardcoded value.
```

## 6. Analyze and Plan Blueprint and CI Updates

Update any blueprints and CI configurations that use the `110-iot-ops` component.

**Search Process**:
1. **Find blueprint references**: Use `file_search` with pattern `blueprints/**/*.{tf,bicep}` and then `grep_search` with query `110-iot-ops` to find files that reference the component.
2. **Find CI references**: Use `file_search` to examine `src/100-edge/110-iot-ops/ci/` directory for configuration files.
3. **Identify parameter usage**: For each file found, use `read_file` to examine how the `110-iot-ops` component is currently configured.

**Analysis Requirements**:
- **New parameters**: If Step 4 identified new parameters that were added to the component, check if blueprints/CI need to pass values for these parameters.
- **Changed defaults**: If default values changed, determine if blueprints/CI explicitly set these values and need updates.
- **Required parameters**: If a parameter changed from optional to required, ensure blueprints/CI provide values.

**Update Decision Logic**:
- **Add to plan IF**: Blueprint/CI file needs to pass a new required parameter
- **Add to plan IF**: Blueprint/CI file explicitly sets a parameter whose default changed and should use the new default
- **Skip IF**: New parameters have reasonable defaults and don't need explicit values in blueprints/CI

**Plan Entry Format**:
```markdown
- [ ] Update the `110-iot-ops` component reference in `blueprints/full-single-node-cluster/terraform/main.tf` to pass the new required parameter `schema_registry_id = module.adr_schema_registry.id`.
- [ ] Remove explicit `log_level = "info"` parameter from `src/100-edge/110-iot-ops/ci/terraform/main.tf` to use new default value of `"debug"`.
```

## 7. Finalize Plan and Await Approval

Once you have added all the necessary update details to the plan, add the following text to the end of `iotops-update-plan.md`:

---
Finished adding all details needed for updating azure iot operations throughout the workspace.

Please review the plan. Let me know if you want to make any changes or additions. Once you approve, I will start implementing the plan.
---

After saving the plan, you MUST stop and wait for the user to tell you to proceed with the implementation.

## 8. Implement the Plan

When the user tells you to "implement the plan" or gives similar instruction, perform the changes outlined in `iotops-update-plan.md`.

**CRITICAL PREREQUISITE**: Before making ANY changes to Terraform or Bicep files, you MUST:
1. Use `read_file` to read and understand ALL instructions from:
   - `.github/instructions/terraform.instructions.md` (for any Terraform changes)
   - `.github/instructions/bicep.instructions.md` (for any Bicep changes)
2. Follow ALL guidelines specified in these instruction files during implementation
3. Ensure your changes comply with the coding standards and conventions specified

**Implementation Process**:
1. **Read instruction files**: Load the appropriate instruction files based on the types of changes in the plan
2. **Read the current plan**: Use `read_file` to load the complete plan from `.copilot-tracking/iotops/{current_date}/iotops-update-plan.md`.
3. **Find next unchecked item**: Look for the first line starting with `- [ ]` (unchecked checkbox).
4. **Apply instruction compliance**: Before implementing, verify the change follows the loaded instruction guidelines
5. **Implement the change**: Use `insert_edit_into_file` or `replace_string_in_file` to make the required change following instruction file standards
6. **Mark as complete**: Use `replace_string_in_file` to change `- [ ]` to `- [x]` for that specific line.
7. **Save progress**: The change should be automatically saved by the edit tool.
8. **Continue**: Repeat steps 3-7 until all items are checked.

**Error Handling**:
- **File not found**: Document the error in the plan and mark the item as `- [!]` with a note about the missing file.
- **Implementation failure**: If a change cannot be applied as planned, mark as `- [!]` and document the specific issue.
- **Conflicting changes**: If the target code has changed since planning, document the conflict and ask for guidance.

**Progress Tracking**:
- Use `- [x]` for successfully completed items
- Use `- [!]` for items that failed with documented reasons
- Always update the plan file to reflect current status

**Completion Criteria**:
The implementation is complete when all checkbox items in the plan are marked as either `[x]` (completed) or `[!]` (failed with documented reason).
