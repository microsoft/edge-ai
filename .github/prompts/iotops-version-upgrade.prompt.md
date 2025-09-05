---
mode: 'agent'
description: 'Guides through the process of updating Azure IoT Operations components to the latest version - Brought to you by microsoft/edge-ai'
model: 'Claude Sonnet 4'
---

# Azure IoT Operations Version Upgrade Prompt

## Overview

Update Azure IoT Operations components in this repository to a specified version. Fetch target version configuration, create an update plan, and apply changes to Bicep and Terraform code.

Work in a directory named `.copilot-tracking/iotops/{current_date}/`, where `{current_date}` is the current date in `YYYY-MM-DD` format (e.g., `2025-06-24`).

Before anything else, use the `todos` tool to plan the work by enumerating all the major 16 sections in phases 1, 2 and 3 in this prompt as tasks.

### Components Analyzed by This Prompt

This prompt analyzes and updates the following IoT Operations-related components:
- **110-iot-ops**: Core IoT Operations instance, brokers, authentication, and listeners
- **111-assets**: Azure Device Registry assets and endpoint profiles
- **130-messaging**: Dataflow endpoints, profiles, and messaging integration

### Workflow Overview

The prompt follows a three-phase approach:
1. **Phase 1: Immediate Analysis** - Gather all necessary information through analysis and discovery (no implementation)
2. **Phase 2: Planning and Documentation** - Create comprehensive plan document and await approval (no implementation)
3. **Phase 3: Implementation** - Execute the approved plan changes (implementation begins only after approval)

<!-- <important-version-parameter> -->
**VERSION PARAMETER**: Ask the user which version to upgrade to. Accept:
- "latest" or "latest-stable" for the most recent stable release
- "latest-preview" for the most recent pre-release
- Specific version like "v1.2.36" for exact version targeting
- If no version specified, default to "latest"
<!-- </important-version-parameter> -->

## PHASE 1: IMMEDIATE ANALYSIS (Analysis Only - No Implementation)

These steps must be completed immediately to gather all necessary information before creating the implementation plan. **NO IMPLEMENTATION is allowed in this phase** - only data gathering, analysis, and discovery.

### Execution Requirements for Phase 1:
- **Sequential Execution**: Complete steps 1-6 in order before proceeding to Phase 2
- **Component Coverage**: Analyze ALL three components (110-iot-ops, 111-assets, 130-messaging)
- **API Validation**: Cross-validate with REST specifications to catch breaking changes
- **Complete Analysis**: Do not skip to planning until all immediate analysis is complete
- **No Implementation**: Only gather information - do not make any code changes

## 1. Fetch Target Version Configuration

**FIRST CRITICAL PREREQUISITE**: Download the target release information for Azure IoT Operations.

1. Determine the current date in `YYYY-MM-DD` format (e.g., June 24, 2025 becomes `2025-06-24`).
2. Create directory `.copilot-tracking/iotops/{current_date}/` if it doesn't exist.
3. **Resolve manifest URLs with helper script**:
   Use the repository's helper script to resolve the correct JSON URLs for the chosen version/channel.

   - Use `scripts/aio-version-checker.py --print-manifest-urls` with one of the following inputs:
     - For "latest" or "latest-stable": add `--channel stable` (default)
     - For "latest-preview": add `--channel preview`
     - For a specific version (e.g., `v1.2.36`): add `--release-tag v1.2.36`

   Optional flags:
   - `--strict-latest` to fail instead of falling back to legacy URLs if the GitHub API fails
   - `--require-asset-files` to require that JSONs are present as release assets (no branch fallback)

   The script prints a JSON object to stdout like:
   `{ "enablement_url": "...", "instance_url": "...", "meta": { "source": "assets|branch|legacy", ... } }`

4. **Download the configuration files**: Using the two URLs returned by the helper script, download into the tracking directory:
   - `azure-iot-operations-enablement.json`
   - `azure-iot-operations-instance.json`

   Use `curl -L -o` with the resolved URLs from step 3:

<!-- <example-download-commands> -->
```bash
# Resolve URLs (stable latest)
urls_json=$(python3 scripts/aio-version-checker.py --print-manifest-urls --channel stable)
enablement_url=$(echo "$urls_json" | jq -r '.enablement_url')
instance_url=$(echo "$urls_json" | jq -r '.instance_url')

curl -L -o ".copilot-tracking/iotops/{current_date}/azure-iot-operations-enablement.json" "$enablement_url"
curl -L -o ".copilot-tracking/iotops/{current_date}/azure-iot-operations-instance.json" "$instance_url"

# For latest-preview instead:
# urls_json=$(python3 scripts/aio-version-checker.py --print-manifest-urls --channel preview)

# For a specific tag (e.g., v1.2.36):
# urls_json=$(python3 scripts/aio-version-checker.py --print-manifest-urls --release-tag v1.2.36)
```
<!-- </example-download-commands> -->

   - If download fails, inform the user and stop processing

## 2. Fetch REST API Specifications - EXECUTE IMMEDIATELY

**EXECUTE IMMEDIATELY**: Download and analyze REST API specifications to validate all `Microsoft.IoTOperations/*` and `Microsoft.DeviceRegistry/*` resource types referenced in this repository. This ensures new properties or requirement changes (e.g., `defaultSecretProviderClassRef` on instance) are caught and analyzed before planning.

**Scope**:
- Resource types under `Microsoft.IoTOperations/*` or `Microsoft.DeviceRegistry` including (but not limited to): `instance`, `assets`, `dataflows`, `namespaces`, `devices`, etc.

**Download Process**:
1. **Create specifications directory**: Create `.copilot-tracking/iotops/{current_date}/specifications/` for storing downloaded spec files.

2. **Determine API version channel**: Based on the selected release type from step 1:
   - For "latest" or "latest-stable": Use `stable` channel (latest dated folder without `-preview`)
   - For "latest-preview" or preview versions: Use `preview` channel (latest `-preview` dated folder)

3. **Download IoT Operations specifications**:
   - Use `fetch_webpage` to identify available API versions in: `https://github.com/Azure/azure-rest-api-specs/tree/main/specification/iotoperations/resource-manager/Microsoft.IoTOperations/`
   - Select the latest dated folder matching the channel (stable/preview)
   - Download specification files using `curl` commands:

<!-- <example-spec-download-commands-iotops> -->
```bash
# For stable channel (example with 2024-09-15):
curl -L -o ".copilot-tracking/iotops/{current_date}/specifications/iotoperations-2024-09-15.json" "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/iotoperations/resource-manager/Microsoft.IoTOperations/stable/2024-09-15/iotoperations.json"

# For preview channel (example with 2024-11-01-preview):
curl -L -o ".copilot-tracking/iotops/{current_date}/specifications/iotoperations-2024-11-01-preview.json" "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/iotoperations/resource-manager/Microsoft.IoTOperations/preview/2024-11-01-preview/iotoperations.json"
```
<!-- </example-spec-download-commands-iotops> -->

4. **Download Device Registry specifications**:
   - Use `fetch_webpage` to identify available API versions in: `https://github.com/Azure/azure-rest-api-specs/tree/main/specification/deviceregistry/resource-manager/Microsoft.DeviceRegistry/`
   - Select the latest dated folder matching the channel (stable/preview)
   - Download specification files using `curl` commands:

<!-- <example-spec-download-commands-deviceregistry> -->
```bash
# For stable channel (example with 2024-09-15):
curl -L -o ".copilot-tracking/iotops/{current_date}/specifications/deviceregistry-2024-09-15.json" "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/deviceregistry/resource-manager/Microsoft.DeviceRegistry/stable/2024-09-15/deviceregistry.json"

# For preview channel (example with 2024-11-01-preview):
curl -L -o ".copilot-tracking/iotops/{current_date}/specifications/deviceregistry-2024-11-01-preview.json" "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/deviceregistry/resource-manager/Microsoft.DeviceRegistry/preview/2024-11-01-preview/deviceregistry.json"
```
<!-- </example-spec-download-commands-deviceregistry> -->

**Validation Workflow**:
1. **Parse downloaded specifications**: Use `read_file` to examine the downloaded JSON specification files
2. **Extract resource schemas**: For each resource type (instance, assets, dataflows, etc.), extract:
   - Supported `apiVersion` values
   - Resource schema properties and requirement flags (required vs optional)
   - Newly introduced or deprecated properties
   - Property types, constraints, and validation rules
3. **Cross-compare with codebase**: Compare specification schemas with code usage across modules (`110-iot-ops`, `111-assets`, `130-messaging`, and any others referencing `Microsoft.IoTOperations` or `Microsoft.DeviceRegistry`)
4. **Identify discrepancies**: Look for:
   - `apiVersion` mismatches between specs and code
   - Missing newly required properties in code
   - Deprecated properties still present in code
   - Incorrect property types or constraint violations
5. **Plan validation entries**: Add plan entries for each discrepancy found

**Error Handling**:
- If specification files cannot be downloaded, document the failure and use `fetch_webpage` as fallback to manually review specifications
- If specification format is unexpected, document the issue and recommend manual review

<!-- <example-plan-entry-format-general-rest-specs> -->
```markdown
- [ ] Update `apiVersion` for `Microsoft.IoTOperations/instance` in `src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep` from `2024-11-01-preview` to `2025-04-01` (per downloaded REST specs stable).
- [ ] Add new required property `defaultSecretProviderClassRef` to Instance configuration in `src/100-edge/110-iot-ops/terraform/modules/iot-ops-instance/main.tf` and corresponding variables file, aligning with downloaded REST specs.
- [ ] Remove deprecated property `fooBar` from `src/100-edge/130-messaging/terraform/main.tf` if present; downloaded spec indicates it is no longer supported.
```
<!-- </example-plan-entry-format-general-rest-specs> -->

**Important**:
- Treat instance-level changes (e.g., `defaultSecretProviderClassRef`) as potential breaking changes; ensure Breaking Changes analysis captures them for user validation.
- When multiple apiVersions are available in the same channel, select the latest dated version.

Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 3. Create the Plan

Create or update a plan file named `iotops-update-plan.md` in the `.copilot-tracking/iotops/{current_date}/` directory.
Include `<!-- markdownlint-disable-file -->` at the top; `.copilot-tracking/**` markdown files are NOT required to pass `.mega-linter.yml` rules.

**IMPORTANT**: If a plan file for the current date already exists and contains the text "Finished adding all details needed for updating azure iot operations throughout the workspace.", and the user asks you to implement the plan, skip to Phase 3, step 16.

**SECOND CRITICAL PREREQUISITE**: Before creating any plan entries for Terraform or Bicep changes, read and follow ALL instructions from:
1. Read `.github/instructions/terraform.instructions.md` (for Terraform-related planning)
2. Read `.github/instructions/bicep.instructions.md` (for Bicep-related planning)
3. Ensure your planned changes comply with the coding standards specified in these files
4. Reference these instruction files when determining appropriate change approaches

Outline all necessary code changes in the plan file. Prefix each item requiring a code change with a markdown checkbox `[ ]`.

Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 4. Core IoT Operations Component Analysis (110-iot-ops) - EXECUTE IMMEDIATELY

**CRITICAL PREREQUISITE**: Before creating any plan entries for Terraform or Bicep changes, read and follow ALL instructions from:
1. Read `.github/instructions/terraform.instructions.md` (for Terraform-related planning)
2. Read `.github/instructions/bicep.instructions.md` (for Bicep-related planning)
3. Ensure your planned changes comply with the coding standards specified in these files
4. Reference these instruction files when determining appropriate change approaches

**EXECUTE IMMEDIATELY**: Analyze the downloaded JSON files and the existing 110-iot-ops codebase to identify necessary `apiVersion` updates.

**JSON Analysis Process**:
1. **Parse JSON structure**: Examine `resources` arrays in both JSON files
2. **Extract apiVersions**: Find `apiVersion` properties in each resource object
3. **Record resource types**: Note the `type` field for each resource (e.g., `Microsoft.IoTOperations/instance`)

**Codebase Analysis Process**:
1. **Read each file**: Use `read_file` to examine the files listed below
2. **Find apiVersion declarations**: Search for lines containing `apiVersion` or `api_version`
3. **Extract resource types**: Identify which resource type each apiVersion corresponds to

**Version Comparison Logic**:
- **Newer version criteria**: A version is newer if it has a later date (format: YYYY-MM-DD-preview)
- **Update requirement**: Plan updates only when JSON version date is later than codebase version date
- **Missing versions**: If apiVersion is missing in codebase but present in JSON, plan to add it

**Extension Categories to Analyze**:
- **Enablement Extensions** (from enablement JSON `VERSIONS`/`TRAINS`):
  - `platform` (Azure IoT Operations Platform)
  - `secretStore`/`secretSyncController` (Secret Sync Controller)
  - `containerStorage`/`edgeStorageAccelerator` (Container Storage)
- **Instance Extensions** (from instance JSON `VERSIONS`/`TRAINS`):
  - `iotOperations`/`aio` (Azure IoT Operations instance)

Check the following files within the `src/100-edge/110-iot-ops/` component:

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

<!-- <example-plan-entry-format> -->
```markdown
- [ ] Update `apiVersion` for `Microsoft.IoTOperations/instance` in `src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep` from `2024-11-01-preview` to `2025-06-24-preview`
- [ ] Update `aioPlatformExtensionDefaults.release.version` from "0.7.21" to "0.7.25" in `/workspaces/edge-ai/src/100-edge/110-iot-ops/bicep/types.bicep`
- [ ] Update `operations_config.train` from "integration" to "stable" in `/workspaces/edge-ai/src/100-edge/110-iot-ops/terraform/variables.instance.tf`
```
<!-- </example-plan-entry-format> -->

**Error Handling**: If a file doesn't exist, document this in the plan. If apiVersion format is unrecognizable, document the current value and recommend manual review.

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 5. Assets Component Analysis (111-assets) - EXECUTE IMMEDIATELY

**EXECUTE IMMEDIATELY**: Extend the same API version analysis to the Assets module to detect any API changes:

**Assets (`src/100-edge/111-assets/`):**
- Terraform: scan `terraform/**/*.tf` and module subfolders for `azapi_resource` blocks and `api_version` usage
- Bicep (if present): scan `bicep/**/*.bicep` for resource declarations and `apiVersion`

When scanning, capture for each matching resource:
- Resource `type` (e.g., contains `/assets` under `Microsoft.DeviceRegistry/...` or `Microsoft.IoTOperations/...`)
- The `apiVersion`/`api_version` currently used
- The file path and line reference

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 6. Messaging Component Analysis (130-messaging) - EXECUTE IMMEDIATELY

**EXECUTE IMMEDIATELY**: Extend the same API version analysis to the Messaging module to detect any API changes:

**Messaging (`src/100-edge/130-messaging/`):**
- Terraform: scan `terraform/**/*.tf` for `azapi_resource` blocks and `api_version`
- Bicep (if present): scan `bicep/**/*.bicep` for resource declarations and `apiVersion`

When scanning, capture for each matching resource:
- Resource `type` (e.g., contains `/dataflows` under `Microsoft.IoTOperations/...`)
- The `apiVersion`/`api_version` currently used
- The file path and line reference

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 7. Analysis Complete Checkpoint

**CHECKPOINT**: Before proceeding to planning phase, ensure all immediate analysis steps (1-6) are complete:
- ✅ Target version configuration downloaded
- ✅ REST API specifications cross-validated
- ✅ Core IoT Operations component (110-iot-ops) analyzed
- ✅ Assets component (111-assets) analyzed
- ✅ Messaging component (130-messaging) analyzed

**CRITICAL**: Do not proceed to Phase 2 until ALL analysis is complete. The following are common execution pitfalls to avoid:
- ❌ **Don't skip component analysis**: All three components must be analyzed, not just 110-iot-ops
- ❌ **Don't defer REST validation**: API specifications must be validated immediately, not marked as "future work"
- ❌ **Don't mix analysis with planning**: Complete all discovery before creating implementation plans

Only proceed to Phase 2 when all analysis is complete.

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

---

## PHASE 2: PLANNING AND DOCUMENTATION (Planning Only - No Implementation)

These steps update the implementation plan based on the analysis completed in Phase 1. **NO IMPLEMENTATION is allowed in this phase** - only planning, documentation, and preparation for approval.

## 8. Plan Variable and Parameter Updates

Review the downloaded JSON files for changes in parameters, including new parameters, changed default values, or removed parameters.

**Parameter Analysis Process**:
1. **Extract JSON parameters**: Examine `parameters` or `properties` objects in the downloaded JSON files
2. **Read existing variables**: Use `read_file` to examine current parameter/variable definitions in the files listed in step 4
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

<!-- <example-name-transformations> -->
```
JSON: "schemaRegistryId"
Possible matches: schema_registry_id, SchemaRegistryId, SCHEMA_REGISTRY_ID, schema_reg_id

JSON: "userAssignedIdentity"
Possible matches: user_assigned_identity, UserAssignedIdentity, user_identity, managed_identity_id

JSON: "enableDiagnostics"
Possible matches: enable_diagnostics, diagnostics_enabled, diag_enabled
```
<!-- </example-name-transformations> -->

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

<!-- <example-parameter-plan-entries> -->
```markdown
- [ ] In `src/100-edge/110-iot-ops/terraform/variables.instance.tf`, update the default value for the `log_level` variable from `"info"` to `"debug"`.
- [ ] In `src/100-edge/110-iot-ops/bicep/modules/iot-ops-instance.bicep`, add new parameter `enable_diagnostics` with type `bool` and default value `false` (maps to JSON parameter `enableDiagnostics`).
- [ ] In `src/100-edge/110-iot-ops/terraform/variables.instance.tf`, rename variable `user_identity` to `user_assigned_identity` to match JSON parameter `userAssignedIdentity` (keep existing default value to preserve logic).
- [ ] In `src/100-edge/110-iot-ops/terraform/variables.instance.tf`, remove deprecated variable `legacy_mode` (no longer in JSON schema).
```
<!-- </example-parameter-plan-entries> -->

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

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 9. Plan Dependency Updates

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
Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 10. Plan Blueprint and CI Updates

Update any blueprints and CI configurations that use the `110-iot-ops` component.

**Search Process**:
1. **Find blueprint references**: Use `file_search` with pattern `blueprints/**/*.{tf,bicep}` and then `grep_search` with query `110-iot-ops` to find files that reference the component.
2. **Find CI references**: Use `file_search` to examine `src/100-edge/110-iot-ops/ci/` directory for configuration files.
3. **Identify parameter usage**: For each file found, use `read_file` to examine how the `110-iot-ops` component is currently configured.

**Analysis Requirements**:
- **New parameters**: If Step 9 identified new parameters that were added to the component, check if blueprints/CI need to pass values for these parameters.
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

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 11. Analyze for Breaking Changes and Impact Assessment

Identify potentially breaking changes that require special attention and user validation.

**Breaking Changes Analysis Process**:
1. **Identify new required parameters**: From step 8 analysis, flag any new parameters that are marked as required in JSON schema
2. **Detect property requirement changes**: Look for parameters that changed from optional to required
3. **Check for removed properties**: Identify deprecated or removed parameters that may break existing configurations
4. **Assess default value changes**: Flag changes in default values that could alter behavior
5. **Validate API specification changes**: Use `fetch_webpage` to get the target API version specification for detailed property requirements

<!-- <example-breaking-change-detection> -->
**Critical change patterns to flag**:
- New required parameters without defaults (e.g., `defaultSecretProviderClassRef`)
- Authentication method changes or new certificate requirements
- Resource type changes or deprecated resource types
- Configuration schema structural changes
- Namespace enforcement or new mandatory relationships
<!-- </example-breaking-change-detection> -->

**API Specification Validation**:
- Use `microsoft_docs_search` with Microsoft documentation to understand property requirements
- Cross-reference JSON schema with REST API specifications
- Check for discrepancies between JSON templates and API requirements

**Impact Assessment Format**:
```markdown
- [ ] BREAKING CHANGE: New required parameter `defaultSecretProviderClassRef` in Instance resource - requires user attention for secret provider configuration.
- [ ] BREAKING CHANGE: Parameter `enableDiagnostics` changed from optional to required - existing deployments may fail without this value.
- [ ] IMPACT REVIEW: Default value change for `logLevel` from "info" to "debug" - may increase log volume in production.
```

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 12. Analyze Release Notes for Additional Changes

Beyond JSON configuration files, examine the release notes for changes that may require additional updates.

**Release Notes Analysis Process**:
1. **Fetch release notes**: Use `fetch_webpage` to get the full release notes from the target version's GitHub release page
2. **Search for breaking changes**: Look for sections marked "Breaking Changes" or similar warnings
3. **Identify new resource types**: Look for mentions of new Azure resource types not present in JSON files
4. **Find API changes**: Search for references to new REST API endpoints, authentication methods, or data structures
5. **Check connector updates**: Look for new connector types, configuration changes, or deprecated features
6. **Use `microsoft_docs_search`** tool to search for relevant updated documentation related to these changes, especially breaking changes

**Analysis Targets**:
- **New Azure Resource Types**: Resource types mentioned in release notes but not in JSON ARM templates
- **Authentication Changes**: New authentication methods or certificate requirements
- **Configuration Schema Changes**: New configuration formats or deprecated settings
- **Connector Templates**: New connector types or template structures
- **Namespace Changes**: ADR namespace enforcement or new namespace-related resources
- **API Endpoint Changes**: New REST endpoints or changed authentication for existing APIs

<!-- <example-release-analysis> -->
**Example findings to document**:
- "MQTT Broker Data Persistence" feature may require new Kubernetes storage configurations
- "Namespace enforcement" may require updating asset creation workflows
- "WebAssembly Support" may require new module deployment patterns
- "Azure Device Registry Integration" may require new authentication configurations
<!-- </example-release-analysis> -->

**Plan Entry Format**:
```markdown
- [ ] INVESTIGATE: Release notes mention "MQTT Broker Data Persistence" - check if new storage configurations are needed beyond JSON files.
- [ ] INVESTIGATE: "Namespace enforcement" mentioned - verify all asset references use namespace model.
- [ ] INVESTIGATE: New "REST/HTTP Connector" - check if new connector templates or configurations are needed.
```

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 13. Plan Additional Validation Areas

Plan validation steps to ensure comprehensive coverage of changes beyond the JSON file updates.

**Post-Implementation Validation Plan**:
1. **Test Configuration**: Ensure CI/test configurations account for new features or requirements
2. **Blueprint Compatibility**: Verify all blueprints work with the updated component versions

**Validation Areas to Plan**:

<!-- <important-validation-areas> -->
- **Example Configurations**: Sample files demonstrate new features properly
- **Dependency Compatibility**: Updated components work with existing dependencies
- **Blueprint Integration**: All blueprints deploy successfully with updated components
- **Test Coverage**: CI tests validate new parameters and resource types
<!-- </important-validation-areas> -->

**Plan Entry Format**:
```markdown
- [ ] VALIDATE: Test all blueprints that use `110-iot-ops` component deploy successfully.
- [ ] VALIDATE: Verify CI tests cover new parameters and resource types.
```

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 14. User Validation for Breaking Changes

Before finalizing the plan, explicitly call out breaking changes and potentially impactful changes for user review.

**Breaking Changes Validation Process**:
1. **List all breaking changes**: Extract all plan entries marked with "BREAKING CHANGE" or "IMPACT REVIEW"
2. **Provide context**: For each breaking change, explain the potential impact and required user action
3. **Request explicit approval**: Ask user to specifically acknowledge each breaking change
4. **Offer mitigation guidance**: Suggest steps to minimize impact or validate compatibility

<!-- <example-user-validation-format> -->
**User Validation Format**:
```markdown
## ⚠️ BREAKING CHANGES DETECTED - USER REVIEW REQUIRED

The following changes require your attention and approval:

### 1. New Required Parameter: defaultSecretProviderClassRef
- **Impact**: Instance resource now requires a secret provider class reference
- **Action Required**: Ensure secret provider class is configured in your environment
- **Validation**: Verify `kubectl get secretproviderclass` shows available resources

### 2. Default Value Change: logLevel
- **Impact**: Log level changes from "info" to "debug" - may increase log volume
- **Action Required**: Review if production environments can handle increased logging
- **Mitigation**: Consider explicitly setting logLevel in production blueprints

Please confirm you understand these impacts before proceeding.
```
<!-- </example-user-validation-format> -->

**Approval Requirements**:
- User must explicitly acknowledge each breaking change
- User must confirm they have validated their environment can handle the changes
- User must approve proceeding with implementation

Before moving to the next step:
- Update the plan file.
- Update the status of `todos` list as you complete this section, don't add new todos before Phase 3.

## 15. Finalize Plan and Await Approval

Once you have added all the necessary update details to the plan, add the following text to the end of `iotops-update-plan.md`:

---
Finished adding all details needed for updating azure iot operations throughout the workspace.

**IMPORTANT**: If breaking changes were detected above, please review each one carefully and confirm you understand the impact before approving implementation.

Please review the plan. Let me know if you want to make any changes or additions. Once you approve, I will start implementing the plan.
---

After saving the plan, stop and wait for the user to tell you to proceed with the implementation.

**END OF PHASE 2**: Do not proceed to Phase 3 until the user has reviewed the plan and given explicit approval to begin implementation, ensure `todos` list tracking is updated.

---

## PHASE 3: IMPLEMENTATION (Implementation Only - After Approval)

This phase contains the actual implementation of the approved plan. **Only proceed to this phase after the user has explicitly approved the plan from Phase 2.**

## 16. Implement the Plan

When the user tells you to "implement the plan" or gives similar instruction, perform the changes outlined in `iotops-update-plan.md`.

**CRITICAL PREREQUISITE**: Before making ANY changes to Terraform or Bicep files, read and understand ALL instructions from:
1. Read `.github/instructions/terraform.instructions.md` (for any Terraform changes)
2. Read `.github/instructions/bicep.instructions.md` (for any Bicep changes)
3. Follow ALL guidelines specified in these instruction files during implementation
4. Ensure your changes comply with the coding standards and conventions specified

**Implementation Process**:
1. **Read instruction files**: Load the appropriate instruction files based on the types of changes in the plan
2. **Read the current plan**: Use `read_file` to load the complete plan from `.copilot-tracking/iotops/{current_date}/iotops-update-plan.md`
3. **Find next unchecked item**: Look for the first line starting with `- [ ]` (unchecked checkbox)
4. **Apply instruction compliance**: Before implementing, verify the change follows the loaded instruction guidelines
5. **Implement the change**: Use `replace_string_in_file` to make the required change following instruction file standards
6. **Mark as complete**: Use `replace_string_in_file` to change `- [ ]` to `- [x]` for that specific line
7. **Save progress**: The change should be automatically saved by the edit tool
8. **Continue**: Repeat steps 3-7 until all items are checked

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
