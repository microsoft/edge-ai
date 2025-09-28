---
description: 'Required instructions for Terraform Variable Consistency including canonical definitions, requirements, and detailed instructions - Brought to you by microsoft/edge-ai'
applyTo: '.copilot-tracking/chore/tf-variable-check.md'
---

# Terraform Variable Consistency Manager Instructions

## Description Standards

You MUST follow these project standards:

- Single-line: You WILL use short, imperative style, capitalized first letter, no trailing period
- Multi-line: You WILL use heredoc with consistent delimiter and indentation preserved

## Canonical Variables (Single-line)

The table below is the authoritative source of canonical single-line descriptions. You MUST parse this table to build the canonical mapping.

<!-- <canonical-variables-table> -->

| Variable                                  | Description                                                                                                                                                                          |
|-------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| acr                                       | Azure Container Registry                                                                                                                                                             |
| acr_sku                                   | SKU for the Azure Container Registry. Valid values: Basic, Standard, Premium. Default is "Premium" (Premium is required for private endpoints).                                      |
| aio_dataflow_profile                      | The AIO dataflow profile                                                                                                                                                             |
| aio_identity                              | Azure IoT Operations managed identity for workspace access                                                                                                                           |
| aio_instance                              | The Azure IoT Operations instance                                                                                                                                                    |
| arc_onboarding_identity                   | The Principal ID for the identity that will be used for onboarding the cluster to Arc                                                                                                |
| arc_onboarding_principal_ids              | The Principal IDs for the identity or service principal that will be used for onboarding the cluster to Arc                                                                          |
| asset_endpoint_profiles                   | List of asset endpoint profiles to create. Otherwise, an empty list.                                                                                                                 |
| capacity_id                               | The capacity ID for the workspace                                                                                                                                                    |
| cluster_a_name                            | The name identifier for Cluster A                                                                                                                                                    |
| cluster_admin_oid                         | The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user Object ID if 'should_add_current_user_cluster_admin=true')       |
| cluster_admin_upn                         | The User Principal Name that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user UPN if 'should_add_current_user_cluster_admin=true')   |
| cluster_b_name                            | The name identifier for Cluster B                                                                                                                                                    |
| cluster_server_host_machine_username      | Username used for the host machines that will be given kube-config settings on setup.                                                                                                |
| cluster_server_ip                         | The IP Address for the cluster server that the cluster nodes will use to connect.                                                                                                    |
| cluster_server_token                      | The token that will be given to the server for the cluster or used by the agent nodes to connect them to the cluster. (ex. [K3s token documentation](https://docs.k3s.io/cli/token)) |
| custom_location_id                        | The resource ID of the Custom Location                                                                                                                                               |
| custom_locations_oid                      | The object id of the Custom Locations Entra ID application for your tenant.                                                                                                          |
| data_lake_data_contributor_principal_id   | The Principal ID that will be assigned the 'Storage Blob Data Contributor' role at the Storage Account scope                                                                         |
| data_lake_filesystem_name                 | Name of the Data Lake Gen2 filesystem to create                                                                                                                                      |
| environment                               | Environment for all resources in this module: dev, test, or prod                                                                                                                     |
| environment_config                        | Environment configuration settings for deployment                                                                                                                                    |
| eventhouse_description                    | The description of the Microsoft Fabric eventhouse                                                                                                                                   |
| eventhouse_workspace_id                   | The ID of the workspace where the eventhouse will be created                                                                                                                         |
| eventhub                                  | Values for the existing Event Hub namespace and Event Hub.                                                                                                                           |
| eventhub_endpoint                         | The Azure Eventhub endpoint to use as a source                                                                                                                                       |
| eventstream_description                   | Description of the Microsoft event stream                                                                                                                                            |
| extension_name                            | The name of the Arc machine extension                                                                                                                                                |
| fabric_capacity_id                        | The ID of the premium capacity to assign to the workspace (Run ./scripts/select-fabric-capacity.sh to choose one)                                                                    |
| fabric_eventhouse_name                    | The name of the Microsoft Fabric eventhouse. Otherwise, 'evh-{resource_prefix}-{environment}-{instance}'                                                                             |
| fabric_eventstream_endpoint               | Fabric RTI connection details from EventStream. If provided, creates a Fabric RTI dataflow endpoint.                                                                                 |
| fabric_workspace                          | Fabric workspace for RTI resources. Required when fabric_eventstream_endpoint is provided.                                                                                           |
| fabric_workspace_name                     | The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource_prefix}-{environment}-{instance}'                                                                               |
| file_share_name                           | Name of the file share to create                                                                                                                                                     |
| file_share_quota_gb                       | Maximum size of the file share in GB                                                                                                                                                 |
| host_machine_count                        | The number of host VMs to create if a multi-node cluster is needed                                                                                                                   |
| instance                                  | Instance identifier for naming resources: 001, 002, etc                                                                                                                              |
| k8s_bridge_principal_id                   | Optional. The principal ID of the K8 Bridge for Azure IoT Operations. Required only if enable_asset_discovery=true and automatic retrieval fails.                                    |
| key_vault                                 | The Key Vault object containing id, name, and vault_uri properties                                                                                                                   |
| key_vault_name                            | The name of the Key Vault to store secrets. If not provided, defaults to 'kv-{resource_prefix}-{environment}-{instance}'                                                             |
| lakehouse_description                     | The description of the Microsoft Fabric lakehouse                                                                                                                                    |
| lakehouse_workspace_id                    | The ID of the workspace where the lakehouse will be created                                                                                                                          |
| location                                  | Azure region where all resources will be deployed                                                                                                                                    |
| location_name                             | Location name for resources                                                                                                                                                          |
| os_type                                   | Operating system type (only linux supported)                                                                                                                                         |
| resource_group                            | Resource group object containing name and id where resources will be deployed                                                                                                        |
| resource_group_name                       | Name of the resource group                                                                                                                                                           |
| resource_prefix                           | Prefix for all resources in this module                                                                                                                                              |
| resource_prefix_new                       | Resource prefix for new deployment                                                                                                                                                   |
| resource_prefixes                         | Multiple resource prefixes                                                                                                                                                           |
| scrape_interval                           | Interval to scrape metrics from the cluster, valid values are between 1m and 30m (PT1M and PT30M)                                                                                    |
| should_create_anonymous_broker_listener   | Whether to enable an insecure anonymous AIO MQ Broker Listener. Should only be used for dev or test environments                                                                     |
| should_create_azure_functions             | Whether to create the Azure Functions resources including App Service Plan                                                                                                           |
| should_create_eventgrid_dataflows         | Whether to create EventGrid dataflows in the edge messaging component                                                                                                                |
| should_create_eventhub_dataflows          | Whether to create EventHub dataflows in the edge messaging component                                                                                                                 |
| should_deploy_resource_sync_rules         | Deploys resource sync rules if set to true                                                                                                                                           |
| should_enable_opc_ua_simulator            | Whether to deploy the OPC UA Simulator to the cluster. Default is false                                                                                                              |
| should_enable_otel_collector              | Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap                                                                                                            |
| should_get_custom_locations_oid           | Whether to get Custom Locations Object ID using Terraform's azuread provider.                                                                                                        |
| should_use_script_from_secrets_for_deploy | Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault                                                                            |
| subnet_id                                 | The ID of the subnet to deploy the VM host in                                                                                                                                        |
| tags                                      | Tags to apply to all resources                                                                                                                                                       |
| vm_sku_size                               | Size of the VM                                                                                                                                                                       |
| vm_username                               | Username for the VM admin account                                                                                                                                                    |
| workspace_description                     | The description of the Microsoft Fabric workspace                                                                                                                                    |
| workspace_id                              | The ID of the workspace where the lakehouse will be created                                                                                                                          |

<!-- </canonical-variables-table> -->

## Canonical Heredoc Descriptions (Multi-line)

The table below is the authoritative source for multi-line (heredoc) descriptions. For each variable, include the full multi-line description preserved as a code block in the table cell, and recommend a consistent delimiter (for example, EOF). You MUST parse this table to build the canonical mapping.

<!-- <canonical-heredoc-table> -->

| Variable                             | Heredoc Description                     | Delimiter | Notes                                                                           |
|--------------------------------------|-----------------------------------------|-----------|---------------------------------------------------------------------------------|
| cluster_server_host_machine_username | (uses multi-line canonical description) | EOF       | strip: true; source: src/100-edge/100-cncf-cluster/terraform/variables.tf       |
| custom_locations_oid                 | (uses multi-line canonical description) | EOF       | strip: true; source: src/100-edge/100-cncf-cluster/terraform/variables.tf       |
| eventhubs                            | (uses multi-line canonical description) | EOF       | strip: true; source: src/000-cloud/040-messaging/terraform/variables.tf         |
| eventstream_template_file_path       | (uses multi-line canonical description) | EOT       | strip: true; source: src/000-cloud/032-fabric-rti/terraform/variables.tf        |
| k8s_bridge_principal_id              | (uses multi-line canonical description) | EOT       | strip: false; source: src/100-edge/111-assets/terraform/variables.tf            |
| onboard_identity_type                | (uses multi-line canonical description) | EOF       | strip: true; source: src/000-cloud/010-security-identity/terraform/variables.tf |
| retention_days                       | (uses multi-line canonical description) | EOT       | strip: true; source: src/000-cloud/032-fabric-rti/terraform/variables.tf        |
| should_get_custom_locations_oid      | (uses multi-line canonical description) | EOF       | strip: true                                                                     |
| throughput_level                     | (uses multi-line canonical description) | EOT       | strip: true; source: src/000-cloud/032-fabric-rti/terraform/variables.tf        |

<!-- </canonical-heredoc-table> -->

## Table Maintenance Rules

CRITICAL: This document is the source of truth. You WILL update canonical values by editing the tables above.
You MUST parse rows between the `canonical-variables-table` and `canonical-heredoc-table` markers at runtime.
You WILL keep rows sorted by variable name for consistency.
If a variable is missing, You WILL add a new row to the appropriate table with a compliant description and, for heredocs, delimiter/strip guidance.
MANDATORY: During the variable consistency process, You MUST update these canonical tables whenever new variables are discovered or when variable descriptions are standardized to ensure the tables remain the authoritative source of truth.

## Canonical Table Parsing Instructions

You MUST build an in-memory canonical map by parsing both tables above. You WILL follow these rules strictly:

### Marker Requirements

- Single-line table: You MUST parse content between `<!-- <canonical-variables-table> -->` and `<!-- </canonical-variables-table> -->`
- Heredoc table: You MUST parse content between `<!-- <canonical-heredoc-table> -->` and `<!-- </canonical-heredoc-table> -->`

### Column Contract Requirements

- Single-line table columns (exact order): `Variable`, `Description`
  - Variable: You WILL treat as string key (no quotes). You MUST trim surrounding whitespace.
  - Description: You WILL use as canonical single-line description. You MUST preserve punctuation. You WILL trim surrounding whitespace only.
- Heredoc table columns (exact order): `Variable`, `Heredoc Description`, `Delimiter`, `Notes`
  - Variable: You WILL treat as string key. You MUST trim surrounding whitespace.
  - Heredoc Description: If a fenced code block (``` ... ```), You WILL capture content BETWEEN fences EXACTLY; else You WILL capture the cell text as-is. You WILL NOT normalize line endings beyond removing a single trailing newline.
  - Delimiter: You WILL default to `EOF` if empty. You MUST ensure UPPER_CASE alphanumeric (e.g., EOF, EOT). You WILL treat `<<-DELIM` variant as required when strip=true.
  - Notes: You MAY use optional content, supports `strip: true|false` and optional `source: <path>` hints. You WILL parse `strip` flag if present; You WILL ignore unknown keys.

### Precedence and Merge Rules

- If a variable appears in BOTH tables:
  - You WILL prefer the heredoc entry for description text and delimiter/strip behavior (heredoc overrides single-line).
  - You WILL keep the single-line entry as fallback for contexts demanding a single-line description.
- If a variable appears in ONLY one table, You WILL use that definition as the canonical description for all fixes.

### Style and Normalization Requirements

- Single-line descriptions: You WILL follow project style: capitalized first letter, no trailing period, 10-100 chars where practical. You WILL NOT auto-alter canonical text when building the map; style checks apply when proposing new entries.
- For heredoc descriptions: You MUST preserve indentation and internal formatting exactly as authored.

### Safety Check Requirements

- You MUST detect and warn on duplicate variable names within the same table.
- You WILL validate delimiter tokens: non-empty, UPPER_CASE. You WILL default to `EOF` if missing/invalid.
- If `strip` not specified in Notes, You WILL default to `true` (use `<<-DELIM`).

### Sorting and Stability Requirements

- Tables in this document SHOULD remain sorted by `Variable`. You MUST NOT depend on sort order for parsing; You WILL rely only on headers and markers.

### Error Handling Requirements

- If a marker block is missing, You MUST stop and report which block is absent. You WILL NEVER fall back to any external JSON.
- If a row is malformed (wrong column count), You WILL skip and report the offending line.

## Safety and Edge Cases

You WILL handle these scenarios appropriately:

- Empty/Null: You WILL skip variables with empty or whitespace-only descriptions; You WILL prompt to author a compliant one
- Large/Slow: You WILL chunk file edits per module to avoid timeouts
- Auth/Permissions: You WILL fail gracefully if files are read-only; You WILL present instructions
- Concurrency: You WILL avoid overlapping writes; You WILL serialize edits per file
- References: For renames, You MUST ensure no lingering `var.old` references remain; You WILL search within module and callers

## Process Workflow

Identify and fix all Terraform variable inconsistencies with the following workflow:

1. **Verify Prerequisites**: Ensure terraform-docs and Python 3.x are available
2. **Delete Existing Variable Tracking File**: Use list_dir on `.copilot-tracking/chore/`, if `tf-variable-check.md` exists then delete file without reading
3. **Create Variable Tracking File**: Create the `.copilot-tracking/chore/tf-variable-check.md` file with an initial preamble
4. **Execute Detection**: Run `python ./scripts/tf-vars-compliance-check.py`
5. **Parse Results**: Handle detection results according to instruction file rules
6. **Load Canonical Data**: Parse canonical tables from instruction file
7. **Apply Remediation**: Use context-aware decision making per instruction file rules
8. **Update Variables**: Apply fixes safely maintaining Terraform syntax
9. **Verify Zero Inconsistencies**: Re-run `python ./scripts/tf-vars-compliance-check.py` to confirm all inconsistencies are resolved
10. **Finalize Process**: Verify canonical tables are updated and summarize changes

## Detailed Requirements

### Prerequisites Verification

You MUST verify these prerequisites before proceeding:

- You WILL ensure `terraform-docs` is available in PATH
- You WILL ensure Python 3.x is available to run the checker

### Detection Process

You WILL execute the detection process as follows:

#### Step 1: Compliance Detection

- You MUST execute `python ./scripts/tf-vars-compliance-check.py`
- You WILL handle detection results according to these rules:
  - If the script exits with code 0 and stdout is empty, You WILL report "no inconsistencies" and stop
  - If the script exits with a non-zero code, You WILL surface the error (stderr/stdout) and stop
  - Otherwise, You WILL parse JSON from stdout and proceed with fixes
- CRITICAL: The JSON output contains a list of variable names that have inconsistent descriptions and the folders in which the inconsistencies exist. The folders have files in the format variable*.tf in which the variable is used, but has a description that is somehow different from the rest of the variable descriptions. The objective of the remediation is to match only the canonical description in each occurrence of the variable.

#### Step 2: Targeted Checklist Creation

- You WILL create a checklist file at `.copilot-tracking/chore/tf-variable-check.md`
- You MUST populate the checklist with the paths to the files in the JSON output from Step 1 for each variable.
- Use the following format for the checklist for each variable that has inconsistencies:

```markdown
# Terraform Variable Files Checklist

## Files to Process (Files with inconsistencies requiring remediation)

### Variable 1
- [ ] path to file 1
- [ ] path to file 2

- [ ] path to file n
```

#### Step 3: Individual File Processing

- You WILL process each checklist item one-by-one in sequential order
- For each file in the checklist:
  - You WILL apply the remediation rules to that specific entry
  - You MUST update the checklist by changing `- [ ]` to `- [x]` for the completed variable and folder combinations
  - You WILL move to the next checklist item
- You MUST continue until all checklist items are marked as completed `- [x]`

### Canonical Data Loading

You MUST use the embedded tables above as the single source of truth for variable descriptions:

- You WILL parse the canonical variables table for single-line descriptions
- You WILL parse the canonical heredoc table for multi-line descriptions
- You WILL NEVER reference external JSON files or other data sources

### Context and Remediation Rules

You WILL apply these remediation rules based on context analysis:

- If variable exists in canonical map and context/use matches → You WILL set canonical description
- If same name is used for different semantics → You WILL rename variable to a context-aligned name, then set description
- If variable missing from canonical map → You WILL create a canonical entry following description standards, You MUST update the appropriate canonical table (single-line or heredoc) with the new variable entry, then apply

### Update Application Requirements

You WILL apply updates safely following these rules:

- You MUST update description in variable blocks (`description = "..."` for single-line; heredoc for multi-line)
- For renames: You MUST update `variable "name" {}`, all `var.name` references, and calling module argument names
- You WILL preview diffs and confirm before writing
- You MUST ensure all changes maintain Terraform syntax validity

### Finalization Requirements

You WILL complete the process by:

- You MUST verify that any new variables discovered during the process have been added to the appropriate canonical tables
- You MUST summarize changes per file and variable
- You WILL offer to commit on a new branch and open a PR
