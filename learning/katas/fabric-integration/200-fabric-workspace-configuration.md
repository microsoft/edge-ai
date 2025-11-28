---
title: 'Kata: 200 - Fabric Workspace Configuration'
description: Configure Microsoft Fabric workspace and Real-Time Intelligence capabilities for edge data integration
author: Edge AI Team
ms.date: 2025-01-20
kata_id: 'fabric-integration-200-fabric-workspace-configuration'
kata_category:
  - fabric-integration
kata_difficulty: 2
estimated_time_minutes: 90
learning_objectives:
  - Provision Microsoft Fabric capacity with appropriate SKU selection
  - Create Fabric workspace with Real-Time Intelligence capabilities enabled
  - Configure role-based access control for workspace security
  - Deploy Eventhouse with KQL database for time-series analytics
prerequisite_katas:
  - 'fabric-integration-200-prerequisite-full-deployment'
technologies:
  - Microsoft Fabric
  - Azure Portal
  - Azure CLI
  - KQL (Kusto Query Language)
success_criteria:
  - Successfully provision Fabric capacity in target Azure region
  - Create Fabric workspace with RTI capabilities enabled
  - Configure RBAC with principle of least privilege
  - Deploy Eventhouse with operational KQL database
ai_coaching_level: guided
scaffolding_level: medium-heavy
hint_strategy: progressive
common_pitfalls:
  - Capacity region mismatch - Ensure Fabric capacity is in same region as edge infrastructure to minimize latency and egress costs
  - RBAC permission gaps - Verify workspace Admin role for identity that will deploy RTI blueprint before starting deployment
  - Eventhouse naming conflicts - Use unique names avoiding reserved keywords when creating Eventhouse instances
requires_azure_subscription: true
requires_local_environment: false
tags:
  - fabric-integration
search_keywords:
  - fabric-workspace
  - eventhouse
  - kql-database
  - fabric-capacity
---

## Quick Context

**You'll Learn**: Configure the Microsoft Fabric workspace and Real-Time Intelligence infrastructure required for edge-to-cloud data integration. This kata establishes the cloud analytics foundation needed before deploying the fabric-rti blueprint.

**Prerequisites**: Completed **01 - Prerequisite Full Deployment** kata with all edge infrastructure validated, Azure subscription with permissions to create Fabric resources, basic understanding of data analytics concepts

**Real Challenge**: Microsoft Fabric RTI integration requires pre-configured workspace, capacity, and Eventhouse resources that cannot be created via the fabric-rti Terraform blueprint. You need to provision these cloud analytics components through the Azure Portal and Azure CLI before infrastructure-as-code deployment can connect edge data sources.

**Your Task**: Provision Fabric capacity, create a workspace with RTI capabilities, configure secure access, and deploy an Eventhouse with KQL database ready for streaming data ingestion.

## Essential Setup

**Complete these checks before starting** - verifying your setup ensures successful kata completion:

**Required** (check these first):

- [ ] Completed **01 - Prerequisite Full Deployment** kata (edge infrastructure deployed)

- [ ] Azure subscription with Owner or Contributor role

- [ ] Access to Azure Portal (portal.azure.com)

- [ ] Azure CLI installed and logged in

- [ ] Microsoft Fabric trial or paid capacity entitlement (or approval to create capacity)

**Quick Validation**: Verify you can run `az account show`, install/upgrade the Fabric extension with `az extension add --name fabric --upgrade`, and confirm your resource group exists.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 02 - Fabric Workspace Configuration kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Provision Microsoft Fabric Capacity (15 minutes)

**What You'll Do**: Create Fabric capacity with appropriate SKU for development/learning environment

**SKU Selection Guidance**:

| SKU | vCores | Memory | Use Case             | Approximate Monthly Cost |
|-----|--------|--------|----------------------|--------------------------|
| F2  | 2      | 16 GB  | Development/Learning | ~$263                    |
| F4  | 4      | 32 GB  | Small Production     | ~$525                    |
| F8  | 8      | 64 GB  | Production           | ~$1,050                  |
| F16 | 16     | 128 GB | High Performance     | ~$2,100                  |

**Steps**:

1. **Navigate to Fabric capacity creation** in Azure Portal

   ```copilot-prompt
   Provide step-by-step Azure Portal navigation to create Microsoft Fabric capacity:

   1. Starting from Azure Portal home
   2. Search for "Microsoft Fabric" or "Fabric capacity"
   3. Navigate to capacity creation blade
   4. List each menu/button to click

   Include what to look for if service is not immediately visible.
   ```

   **Portal Navigation**:
   - Azure Portal → Search "Microsoft Fabric" → "Fabric Capacities" → "+ Create"
   - OR: Azure Portal → "Create a resource" → Search "Microsoft Fabric Capacity"

   - [ ] **Expected result**: Fabric capacity creation form opened

2. **Configure capacity settings** with development-appropriate values

   Use AI assistance for configuration guidance:

   ```copilot-prompt
   Help me configure Fabric capacity creation settings:

   Based on my edge infrastructure in region <region> and resource group <rg-name>:
   1. Recommend SKU for learning/development (prioritize cost efficiency)
   2. Suggest capacity name following naming conventions
   3. Specify capacity admin assignments
   4. Explain region selection importance

   Provide form field values ready to paste.
   ```

   **Configuration Values** (customize for your environment):
   - **Subscription**: Your Azure subscription
   - **Resource Group**: Same as edge infrastructure (`<your-rg-name>`)
   - **Capacity Name**: `fabric-<resource-prefix>-<environment>` (e.g., `fabric-edgeai-dev`)
   - **Region**: **MUST match edge infrastructure region** for lowest latency
   - **SKU**: `F2` (for learning - sufficient for development workloads)
   - **Capacity Admin**: Your Azure AD user or managed identity

   - [ ] **Success check**: Capacity created and shows "Running" status (may take 2-5 minutes)

3. **Verify capacity deployment** using Azure CLI

   ```bash
   # List Fabric capacities in resource group
   az fabric capacity list --resource-group <your-rg-name> --output table

   # Check capacity status
   az fabric capacity show --name <capacity-name> --resource-group <your-rg-name> --query "state"
   ```

   - [ ] **Expected result**: Capacity shows "Active" or "Running" state

### Task 2: Create Fabric Workspace with RTI Capabilities (20 minutes)

**What You'll Do**: Create Fabric workspace, enable Real-Time Intelligence, and configure workspace settings

**Steps**:

1. **Create workspace in Fabric portal**

   ```copilot-prompt
   Provide detailed steps to create Microsoft Fabric workspace with RTI capabilities:

   1. How to access Fabric portal (powerbi.microsoft.com or fabric.microsoft.com)
   2. Navigation to workspace creation
   3. Required settings for Real-Time Intelligence enablement
   4. Capacity assignment process
   5. Workspace naming best practices

   Include screenshots descriptions of key UI elements to find.
   ```

   **Portal Steps**:
   - Navigate to [Microsoft Fabric Portal](https://app.fabric.microsoft.com/)
   - Left navigation → "Workspaces" → "New workspace"
   - **Workspace Name**: `edgeai-rti-<environment>` (e.g., `edgeai-rti-dev`)
   - **Description**: "Real-Time Intelligence workspace for edge AI data integration"
   - **Advanced** → **License mode**: Select "Fabric Capacity" and choose your created capacity
   - **Advanced** → Enable "Real-Time Intelligence" capability
   - Click "Apply" to create workspace

   - [ ] **Expected result**: Workspace created and appears in workspace list

2. **Verify RTI capabilities are enabled**

   ```copilot-prompt
   How do I verify Real-Time Intelligence capabilities are enabled in my Fabric workspace?

   1. Where to find capability settings in workspace
   2. What UI indicators show RTI is active
   3. How to enable RTI if it wasn't enabled during creation
   4. What features should be available in RTI-enabled workspace
   ```

   **Verification**:
   - In workspace → Settings → Check "Capabilities" section
   - Confirm "Real-Time Intelligence" is listed and enabled
   - Verify "Eventhouse" option appears in "+ New" menu

   - [ ] **Success check**: Eventhouse is available in workspace creation menu

3. **Document workspace details** for blueprint configuration

   ```bash
   # Get workspace ID using Fabric CLI (if available)
   # Note: Workspace ID is also visible in Fabric Portal URL when workspace is open

   # Capture workspace details for next kata:
   # - Workspace Name: <workspace-name>
   # - Workspace ID: <workspace-id> (from URL or portal)
   # - Capacity Name: <capacity-name>
   ```

   Save these values - they'll be needed for Terraform blueprint deployment in next kata.

   - [ ] **Expected result**: Workspace name and ID documented for blueprint configuration

### Task 3: Configure Workspace RBAC and Security (10 minutes)

**What You'll Do**: Set up role-based access control following principle of least privilege

**Steps**:

1. **Identify managed identity** from edge infrastructure

   ```copilot-prompt
   Help me retrieve the managed identity details from my edge infrastructure deployment:

   1. Read the Terraform outputs from kata 01 (fabric-integration-prereqs.json)
   2. Extract managed identity name and client ID
   3. Show Azure CLI commands to get identity resource ID
   4. Explain what roles this identity needs for Fabric RTI deployment
   ```

   ```bash
   # Get managed identity details
   az identity show --name <identity-name> --resource-group <your-rg-name> \
     --query "{name:name, clientId:clientId, principalId:principalId, resourceId:id}"
   ```

   - [ ] **Expected result**: Managed identity principal ID retrieved

2. **Assign workspace roles** to managed identity

   ```copilot-prompt
   Provide step-by-step instructions to assign Fabric workspace roles:

   1. How to access workspace role assignments in Fabric Portal
   2. What role is required for identity deploying fabric-rti blueprint (likely "Admin" or "Contributor")
   3. How to add Azure AD managed identity to workspace
   4. How to verify role assignment was successful

   Include both Portal UI steps and any Azure CLI alternatives.
   ```

   **Portal Steps**:
   - In Fabric workspace → "Manage access"
   - Click "+ Add people or groups"
   - Search for managed identity name: `<identity-name>`
   - Assign role: **Admin** (required for creating EventStreams and dataflows)
   - Click "Add"

   **Verification**:
   - Confirm managed identity appears in workspace access list with Admin role

   - [ ] **Success check**: Managed identity has Admin role in workspace

3. **Configure additional access** for your user account (optional but recommended)

   ```copilot-prompt
   I want to grant my own Azure AD user account access to this Fabric workspace for monitoring and troubleshooting.

   1. What role should I assign myself for read/write access?
   2. How do I add my user to workspace access list?
   3. What permissions will I have with "Admin" vs "Member" vs "Viewer" roles?
   ```

   - [ ] **Expected result**: Your user account has appropriate access (Admin or Member role)

### Task 4: Deploy Eventhouse with KQL Database (15 minutes)

**What You'll Do**: Create Eventhouse instance and configure KQL database for time-series data ingestion

**Steps**:

1. **Create Eventhouse** in Fabric workspace

   ```copilot-prompt
   Provide step-by-step instructions to create an Eventhouse in Microsoft Fabric:

   1. Navigation in Fabric workspace to Eventhouse creation
   2. Required configuration settings (name, description)
   3. Default KQL database creation options
   4. What to expect during Eventhouse provisioning
   5. How long deployment typically takes

   Include naming conventions for Eventhouse.
   ```

   **Portal Steps**:
   - In Fabric workspace → "+ New" → "Eventhouse"
   - **Name**: `eventhouse-<resource-prefix>` (e.g., `eventhouse-edgeai`)
   - **Description**: "Real-time data storage for edge AI telemetry"
   - Accept default settings
   - Click "Create"
   - Wait 2-5 minutes for provisioning to complete

   - [ ] **Expected result**: Eventhouse created with "Active" status

2. **Verify default KQL database** was created

   ```copilot-prompt
   How do I verify the default KQL database in my Eventhouse?

   1. Where to find database list in Eventhouse UI
   2. What properties should default database have
   3. How to test database connectivity
   4. What default retention policy is applied
   ```

   **Verification**:
   - Open Eventhouse in workspace
   - Check "Databases" section - should see one default database (usually named same as Eventhouse)
   - Verify database status is "Ready"

   - [ ] **Success check**: Default KQL database is operational

3. **Test KQL database connectivity** with basic query

   ```copilot-prompt
   Provide a simple KQL query to test database connectivity and readiness:

   1. Sample query to run in Eventhouse query editor
   2. Expected results for empty database
   3. How to access query editor in Fabric Portal

   Query should confirm database is accepting queries.
   ```

   **Test Query** (run in Eventhouse Query Editor):

   ```kql
   // Test query - lists all tables in database (should be empty for new database)
   .show tables

   // Verify database is responsive
   print timestamp=now(), message="Database connectivity test successful"
   ```

   **Access Query Editor**:
   - In Eventhouse → "Query" tab or "Explore your data"
   - Paste test query and run
   - Verify query executes without errors

   - [ ] **Expected result**: Query executes successfully, confirming database is operational

4. **Document Eventhouse details** for blueprint deployment

   Capture these values for use in next kata:

   ```copilot-prompt
   Help me document the Eventhouse configuration details needed for Terraform blueprint deployment:

   1. Eventhouse name
   2. KQL database name
   3. Eventhouse URI/endpoint (if visible in portal)
   4. How to retrieve these values if needed later

   Format as key-value pairs for easy reference.
   ```

   **Required Values**:
   - Eventhouse Name: `<eventhouse-name>`
   - KQL Database Name: `<database-name>`
   - Workspace Name: `<workspace-name>`
   - Workspace ID: `<workspace-id>`

   Save to file: `fabric-workspace-config.txt` or add to previous `fabric-integration-prereqs.json`

   - [ ] **Expected result**: All Fabric resource details documented for blueprint configuration

## Completion Check

**You've Succeeded When**:

- [ ] Microsoft Fabric capacity provisioned and showing "Active" state

- [ ] Fabric workspace created with Real-Time Intelligence capabilities enabled

- [ ] Managed identity from edge infrastructure has Admin role in workspace

- [ ] Eventhouse deployed with operational KQL database

- [ ] Workspace and Eventhouse details documented for next kata

- [ ] Test KQL query executes successfully in database

**What You've Built**:

You now have a complete Microsoft Fabric RTI foundation including:

- Fabric capacity providing compute resources for analytics workloads

- Workspace configured with Real-Time Intelligence capabilities

- RBAC configured for secure infrastructure-as-code deployment

- Eventhouse with KQL database ready for time-series data ingestion

- All cloud analytics prerequisites ready for fabric-rti blueprint deployment

**Next Steps**: Continue to **03 - Fabric RTI Blueprint Deployment** kata to deploy the Terraform blueprint that connects your edge AI infrastructure to the Fabric workspace you just configured.

---

## Reference Appendix

### Help Resources

- **Microsoft Fabric Documentation**: [Learn about Fabric capacities](https://learn.microsoft.com/fabric/enterprise/licenses)

- **Real-Time Intelligence**: [Eventhouse overview](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse)

- **KQL Query Language**: [Kusto Query Language reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)

- **Workspace Management**: [Fabric workspace roles](https://learn.microsoft.com/fabric/get-started/roles-workspaces)

### Professional Tips

- **Capacity Sizing**: Start with F2 for learning - you can scale up later without recreating resources

- **Region Selection**: Always deploy Fabric capacity in same region as edge infrastructure to minimize latency and data egress costs

- **RBAC Strategy**: Use managed identities for automation (IaC deployments), Azure AD users for manual operations and monitoring

- **Naming Conventions**: Use consistent prefixes across Azure and Fabric resources for easier management (`edgeai-`, `fabric-`, etc.)

- **Workspace Organization**: Create separate workspaces for dev/test/prod environments for better isolation

### Troubleshooting

**Issue**: Fabric capacity creation fails with quota error

```copilot-prompt
My Fabric capacity creation failed with quota error. How do I resolve this?

1. How to check current Fabric capacity quotas

2. Process to request quota increase

3. Alternative regions that might have capacity available

4. Workaround options while waiting for quota approval

```

**Issue**: Cannot find managed identity when assigning workspace roles

```copilot-prompt
I'm trying to assign workspace role to my managed identity but can't find it in search.

1. How are managed identities displayed in Fabric Portal search?

2. Do I search by name, principal ID, or client ID?

3. Are there prerequisites for managed identity to appear in Fabric?

4. Alternative methods to assign roles (Azure CLI, PowerShell)?

```

**Issue**: Eventhouse creation fails or stays in "Provisioning" state

- **Check Capacity Status**: Ensure Fabric capacity is "Running" - Eventhouse cannot deploy if capacity is paused or failed

- **Verify Workspace License**: Confirm workspace is assigned to Fabric capacity (not Pro or Premium)

- **Wait Longer**: First-time Eventhouse creation in new capacity can take 5-10 minutes

- **Retry**: Delete failed Eventhouse (if stuck) and recreate with same settings

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->

**Ready to practice?** 🚀 **Start with Essential Setup above**
