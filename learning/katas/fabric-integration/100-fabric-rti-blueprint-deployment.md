---
title: 'Kata: 100 - Fabric RTI Blueprint Deployment'
description: Deploy fabric-rti Terraform blueprint to connect Edge AI infrastructure with Microsoft Fabric Real-Time Intelligence
author: Edge AI Team
ms.date: 2025-01-20
kata_id: 'fabric-integration-100-fabric-rti-blueprint-deployment'
kata_category:
  - fabric-integration
kata_difficulty: 1
estimated_time_minutes: 90
learning_objectives:
  - Configure Terraform variables referencing existing Azure and Fabric resources
  - Deploy fabric-rti blueprint using infrastructure-as-code
  - Validate EventStream and dataflow endpoint creation
  - Test end-to-end data flow from edge to Fabric Eventhouse
prerequisite_katas:
  - 'fabric-integration-200-prerequisite-full-deployment'
  - fabric-integration-200-fabric-workspace-configuration
technologies:
  - Terraform
  - Microsoft Fabric
  - Azure IoT Operations
  - EventStream
  - KQL (Kusto Query Language)
  - MQTT
success_criteria:
  - Successfully deploy fabric-rti blueprint with terraform apply
  - Verify EventStream created in Fabric workspace
  - Confirm AIO dataflow endpoint configured
  - Validate data flowing from MQTT to Eventhouse with KQL query
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls:
  - "Resource reference errors": Ensure all variable values match exact resource names from previous katas
  - "RBAC permission issues": Managed identity must have Admin role in workspace before deployment
  - "Data flow delays": Allow 2-5 minutes after deployment for EventStream to activate
requires_azure_subscription: true
requires_local_environment: true
tags:
  - fabric-integration
search_keywords:
  - fabric-rti-blueprint
  - terraform-fabric
  - eventstream-deployment
  - edge-to-cloud
---

## Quick Context

**You'll Learn**: Deploy the minimal fabric-rti Terraform blueprint that creates the EventStream and dataflow endpoint connecting your Edge AI infrastructure to Microsoft Fabric Real-Time Intelligence. This kata demonstrates infrastructure-as-code deployment of cloud integration components.

**Prerequisites**: Completed **01 - Prerequisite Full Deployment** (edge infrastructure) and **02 - Fabric Workspace Configuration** (Fabric workspace, capacity, Eventhouse), Terraform and Azure CLI installed, documented resource names from previous katas

**Real Challenge**: The fabric-rti blueprint is a **minimal additive deployment** that only creates 2 resources (EventStream + AIO dataflow endpoint) to bridge existing edge and cloud infrastructure. You must accurately reference 8 prerequisite resources in Terraform variables - any incorrect resource name or ID will cause deployment failure.

**Your Task**: Configure Terraform variables with existing resource references, deploy the blueprint, and validate data flows end-to-end from MQTT messages on edge to KQL queries in Eventhouse.

## Essential Setup

**Complete these checks before starting** - verifying your setup ensures successful kata completion:

**Required** (check these first):

- [ ] Completed **01 - Prerequisite Full Deployment** kata (edge infrastructure deployed)

- [ ] Completed **02 - Fabric Workspace Configuration** kata (Fabric workspace and Eventhouse created)

- [ ] Terraform CLI installed and Azure CLI logged in

- [ ] Documented resource names from previous katas (workspace, eventhouse, resource group, AIO instance, etc.)

- [ ] Managed identity has Admin role in Fabric workspace

**Quick Validation**: Verify you can run `az account show`, `terraform version`, and access your saved resource details from previous katas (`fabric-integration-prereqs.json`, `fabric-workspace-config.txt`).

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 03 - Fabric RTI Blueprint Deployment kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Analyze Blueprint Architecture and Configure Variables (15 minutes)

**What You'll Do**: Understand the fabric-rti blueprint structure and prepare Terraform variable configuration with existing resource references

**Steps**:

1. **Analyze blueprint structure** using AI assistance

   ```copilot-prompt
   Analyze the fabric-rti blueprint architecture:

   1. Read blueprints/fabric-rti/terraform/main.tf
   2. List what resources this blueprint creates (should be only 2-3 resources)
   3. Identify what existing resources it references via data sources or variables
   4. Explain the purpose of each module being deployed
   5. Show the EventStream → AIO dataflow connection architecture

   Provide a simple architecture diagram showing: Edge (AIO) → EventStream → Eventhouse
   ```

   - [ ] **Expected result**: Understanding that blueprint creates **only** EventStream and dataflow endpoint, not the prerequisite infrastructure

2. **Review variable requirements** to identify all required references

   ```copilot-prompt
   Analyze the fabric-rti blueprint variable requirements:

   1. Read blueprints/fabric-rti/terraform/variables.tf
   2. List all required variables (no default value)
   3. For each variable, specify:
      - What prerequisite resource it references
      - Where to get the value (kata 01 vs kata 02 outputs)
      - Example value format
   4. Identify which variables reference Azure resources vs Fabric resources

   Create a checklist showing: Variable Name | Source Kata | How to Retrieve Value
   ```

   **Expected Variable Categories**:
   - Common variables: `environment`, `resource_prefix`, `location`, `instance`
   - Azure resource references: Resource group name, AIO instance name, managed identity ID
   - Fabric resource references: Workspace ID, Eventhouse name, KQL database name

   - [ ] **Expected result**: Complete variable checklist with retrieval methods for each value

3. **Create terraform.tfvars** configuration file

   ```copilot-prompt
   Help me create a terraform.tfvars file for fabric-rti blueprint deployment:

   Using my documented values:
   - Resource Group: <your-rg-name>
   - AIO Instance: <your-aio-instance-name>
   - Managed Identity: <your-identity-name>
   - Fabric Workspace ID: <your-workspace-id>
   - Eventhouse Name: <your-eventhouse-name>
   - KQL Database Name: <your-database-name>

   Generate complete terraform.tfvars content with:
   1. All required variables populated
   2. Comments explaining each variable's purpose
   3. Proper formatting for complex objects (if any)
   ```

   **Sample terraform.tfvars** structure (customize with your values):

   ```hcl
   # Common deployment variables
   environment      = "dev"
   resource_prefix  = "edgeai"
   location         = "eastus"
   instance         = "001"

   # Azure resource references (from kata 01)
   resource_group_name    = "<your-rg-name>"
   aio_instance_name      = "<your-aio-instance-name>"
   managed_identity_id    = "<your-identity-resource-id>"
   custom_location_id     = "<your-custom-location-id>"

   # Fabric resource references (from kata 02)
   fabric_workspace_id    = "<your-workspace-id>"
   eventhouse_name        = "<your-eventhouse-name>"
   kql_database_name      = "<your-kql-database-name>"
   ```

   - [ ] **Success check**: terraform.tfvars file created with all required variables populated from previous katas

### Task 2: Deploy Fabric RTI Blueprint (15 minutes)

**What You'll Do**: Execute Terraform deployment to create EventStream and configure AIO dataflow endpoint

**Steps**:

1. **Initialize Terraform** in blueprint directory

   ```bash
   # Navigate to fabric-rti blueprint
   cd blueprints/fabric-rti/terraform/

   # Initialize Terraform (downloads providers and modules)
   terraform init

   # Validate configuration syntax and variable references
   terraform validate
   ```

   - [ ] **Expected result**: `terraform init` and `terraform validate` succeed without errors

2. **Review deployment plan** before applying changes

   ```bash
   # Generate deployment plan
   terraform plan -out=tfplan

   # Review plan output carefully:
   # - Should show ~2-3 resources to be created
   # - Verify resource names match your naming conventions
   # - Check that data sources successfully read existing resources
   ```

   ```copilot-prompt
   Help me interpret my Terraform plan output:

   [Paste your terraform plan output here]

   1. Confirm the number of resources being created matches expectations (should be ~2-3)
   2. Identify which resources are EventStream and dataflow endpoint
   3. Check if any data sources failed to find existing resources
   4. Explain any warnings or notes in the plan output
   ```

   - [ ] **Success check**: Plan shows creating EventStream and AIO dataflow endpoint only (not recreating edge infrastructure)

3. **Execute deployment** and monitor progress

   ```bash
   # Apply the deployment plan
   terraform apply tfplan

   # Deployment should complete in 2-5 minutes
   # Watch for successful creation of:
   # - Fabric EventStream
   # - AIO dataflow endpoint
   ```

   - [ ] **Expected result**: `terraform apply` completes successfully with 2-3 resources created

4. **Verify deployment outputs** and save critical information

   ```bash
   # Display all Terraform outputs
   terraform output

   # Save outputs for testing in next task
   terraform output -json > fabric-rti-outputs.json
   ```

   **Critical Outputs** to verify:
   - EventStream name
   - EventStream ID
   - Dataflow endpoint name
   - Connection status

   - [ ] **Expected result**: Outputs show EventStream and dataflow endpoint successfully created

### Task 3: Validate EventStream and Dataflow Configuration (15 minutes)

**What You'll Do**: Verify EventStream exists in Fabric workspace and AIO dataflow endpoint is configured correctly

**Steps**:

1. **Verify EventStream in Fabric Portal**

   ```copilot-prompt
   Guide me through verifying EventStream deployment in Microsoft Fabric:

   1. How to navigate to my Fabric workspace EventStreams
   2. What should I see if EventStream deployed successfully
   3. What properties/settings to check to confirm it's operational
   4. How to view EventStream data flow graph
   ```

   **Portal Verification**:
   - Navigate to [Microsoft Fabric Portal](https://app.fabric.microsoft.com/)
   - Open your workspace: `<your-workspace-name>`
   - Left navigation → "Real-Time Intelligence" → "Eventstreams"
   - Confirm EventStream appears: `eventstream-<resource-prefix>-<environment>` or similar
   - Open EventStream → Verify data flow graph shows: AIO Source → Eventhouse Destination

   - [ ] **Success check**: EventStream visible in workspace with data flow configured

2. **Verify AIO dataflow endpoint** using Azure CLI

   ```copilot-prompt
   Provide Azure CLI commands to verify AIO dataflow endpoint configuration:

   1. List dataflow endpoints in AIO instance
   2. Show specific dataflow endpoint details
   3. Verify endpoint is connected to Fabric EventStream
   4. Check endpoint status (should be "Running" or "Ready")

   Include example output interpretation.
   ```

   ```bash
   # List AIO dataflow endpoints
   az iot ops dataflow endpoint list \
     --instance-name <your-aio-instance-name> \
     --resource-group <your-rg-name> \
     --output table

   # Show specific endpoint details
   az iot ops dataflow endpoint show \
     --name <dataflow-endpoint-name> \
     --instance-name <your-aio-instance-name> \
     --resource-group <your-rg-name>
   ```

   - [ ] **Expected result**: Dataflow endpoint shows "Succeeded" provisioning state and references Fabric EventStream

3. **Test data flow connectivity** with MQTT publish → KQL query validation

   ```copilot-prompt
   Help me test end-to-end data flow from edge to Fabric:

   1. Provide MQTT publish command to send test message to AIO broker
   2. Include sample JSON payload with timestamp and telemetry fields
   3. Provide KQL query to verify data arrived in Eventhouse
   4. Explain how long to wait between publish and query (data propagation delay)
   ```

   **MQTT Test Message** (run from VM or edge cluster with MQTT client access):

   ```bash
   # Install mosquitto_pub if not available
   # sudo apt-get install mosquitto-clients

   # Publish test message to AIO MQTT broker
   mosquitto_pub -h <aio-mqtt-broker-host> -p 1883 \
     -t "telemetry/test" \
     -m '{"timestamp":"2025-01-20T12:00:00Z","temperature":22.5,"humidity":45.3,"device_id":"test-device-001"}'
   ```

   **KQL Verification Query** (run in Fabric Eventhouse Query Editor):

   ```kql
   // Query EventStream table for recent test messages
   // Table name may vary - check EventStream configuration
   EventStreamData
   | where timestamp > ago(10m)
   | project timestamp, temperature, humidity, device_id
   | order by timestamp desc
   | take 10
   ```

   **Alternative if table name unknown**:

   ```kql
   // List all tables to find EventStream data table
   .show tables

   // Once you find the table, query it:
   <TableName>
   | take 10
   ```

   - [ ] **Success check**: KQL query returns test message data published via MQTT, confirming end-to-end flow

## Completion Check

**You've Succeeded When**:

- [ ] fabric-rti blueprint deployed successfully via `terraform apply`

- [ ] EventStream visible in Fabric workspace with AIO source configured

- [ ] AIO dataflow endpoint shows "Succeeded" status and references EventStream

- [ ] Test MQTT message published successfully to AIO broker

- [ ] KQL query in Eventhouse returns published telemetry data

- [ ] End-to-end data flow validated: Edge MQTT → AIO → EventStream → Eventhouse

**What You've Built**:

You now have an operational edge-to-cloud data integration pipeline:

- EventStream configured as bridge between AIO and Eventhouse

- AIO dataflow endpoint publishing telemetry to Fabric

- Real-time data flowing from edge devices to cloud analytics platform

- Infrastructure deployed as code (reproducible and version-controlled)

- Foundation ready for advanced data pipeline configuration and analytics

**Next Steps**: Continue to **04 - Edge to Cloud Data Pipeline** kata to design comprehensive integration architecture with advanced routing, transformation, and error handling patterns.

---

## Reference Appendix

### Help Resources

- **Blueprint Documentation**: Reference `blueprints/fabric-rti/README.md` for architecture and deployment details

- **Terraform Instructions**: Follow `.github/instructions/terraform.instructions.md` for best practices

- **EventStream Documentation**: [Microsoft Fabric EventStream overview](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/overview)

- **AIO Dataflow Endpoints**: [Configure dataflow endpoints](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-configure-dataflow-endpoint)

- **KQL Reference**: [Kusto Query Language quick reference](https://learn.microsoft.com/azure/data-explorer/kql-quick-reference)

### Professional Tips

- **Variable Organization**: Keep terraform.tfvars in secure location - it contains resource identifiers that shouldn't be committed to version control

- **Output Usage**: Save Terraform outputs to JSON for easy reference in subsequent automation or testing

- **Incremental Validation**: Verify each step (plan → apply → portal check → CLI check → data test) before moving to next

- **MQTT Testing**: Use `mosquitto_pub` for quick testing, but for production integrate with actual edge workloads publishing telemetry

- **KQL Query Development**: Start with simple queries (`take 10`) then add filters and projections once you confirm data flow works

### Troubleshooting

**Issue**: Terraform plan fails with "resource not found" for existing resources

```copilot-prompt
My Terraform plan is failing with errors about resources not being found:

[Paste error message here]

1. Which variable likely has incorrect value (resource name or ID)?

2. How do I verify the correct value in Azure Portal or Azure CLI?

3. What's the exact format expected (name only, resource ID, URI)?

4. Are there any case-sensitivity issues with resource names?

```

**Solution Checklist**:

- [ ] Verify resource group name matches exactly (case-sensitive)

- [ ] Check AIO instance name in `az iot ops list` output

- [ ] Confirm managed identity resource ID format: `/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{name}`

- [ ] Validate Fabric workspace ID (UUID format) from Fabric Portal URL

**Issue**: Terraform apply succeeds but EventStream not visible in Fabric Portal

- **Wait for Propagation**: Fabric resources can take 2-5 minutes to appear in portal after Azure Resource Manager reports success

- **Refresh Workspace**: Hard refresh browser (Ctrl+Shift+R) or sign out/in to Fabric Portal

- **Check Workspace**: Ensure you're viewing correct workspace (name matches variable `fabric_workspace_id`)

- **Verify RBAC**: Confirm your user account has Viewer/Member/Admin role in workspace

**Issue**: Data flow test fails - KQL query returns no results

```copilot-prompt
I published an MQTT message but my KQL query returns no results. Help troubleshoot:

1. How long should I wait between MQTT publish and Eventhouse query?

2. How do I verify MQTT message was received by AIO broker?

3. What AIO logs show dataflow endpoint processing messages?

4. How do I check EventStream ingestion metrics in Fabric Portal?

5. What are common causes of data not flowing end-to-end?

```

**Debugging Steps**:

- [ ] Wait 5 minutes after MQTT publish for data propagation

- [ ] Verify MQTT broker is reachable: `mosquitto_pub -h <broker> -p 1883 -t "test" -m "hello"`

- [ ] Check AIO dataflow logs: `kubectl logs -n azure-iot-operations <dataflow-pod-name>`

- [ ] View EventStream ingestion metrics in Fabric Portal (should show messages received)

- [ ] Confirm table name in KQL query matches EventStream configuration

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->

**Ready to practice?** 🚀 **Start with Essential Setup above**
