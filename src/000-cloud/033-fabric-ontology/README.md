---
title: Fabric Ontology Deployment Component
description: Schema-driven deployment of Microsoft Fabric Ontology resources from portable YAML definitions
author: Edge AI Team
ms.date: 2026-01-09
ms.topic: reference
keywords:
  - fabric
  - ontology
  - lakehouse
  - eventhouse
  - semantic-model
  - robotics
  - ieee-1872
estimated_reading_time: 10
---

## Fabric Ontology Deployment Component

Generic, schema-driven Fabric ontology deployment component that provisions Lakehouse, Eventhouse, Semantic Model, and Ontology resources from a portable YAML definition file.

**Microsoft Documentation:**

- [Ontology Overview](https://learn.microsoft.com/fabric/iq/ontology/overview) - Concepts and capabilities
- [Ontology Definition API](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition) - REST API reference

### Quick Start - Deploy IEEE 1872 Robotics Ontology

Deploy a complete IEEE 1872 CORA/CORAX robotics ontology with sample robots, environments, and position measurements:

```bash
cd src/000-cloud/033-fabric-ontology/scripts

# Deploy ontology with sample robotics data (19 tables)
./deploy-cora-corax-dim.sh \
  --workspace-id <YOUR_WORKSPACE_GUID> \
  --with-seed-data

# Dry run (preview without changes)
./deploy-cora-corax-dim.sh \
  --workspace-id <YOUR_WORKSPACE_GUID> \
  --with-seed-data \
  --dry-run
```

This deploys:

- **Lakehouse** `RoboticsOntologyLH` with 19 Delta tables (12 entities + 7 relationships)
- **Semantic Model** `CORA_CORAX_DimensionalModel` (Direct Lake)
- **Ontology** `CORA_CORAX_Dimensional` with IEEE 1872 entity types

**Prerequisites**: `az login`, `yq`, `jq`, `curl`, Fabric workspace with **capacity assigned** and Ontology preview enabled.

**Sample Questions to Test:**

- "What robots do we have?"
- "Which robots are in the Welding Cell group?"
- "What is the current position of the KUKA KR 16?"
- "Show robots in robotic systems equipped in Factory Floor North"

See [fabric-ontology-dim/README.md](fabric-ontology-dim/README.md) for complete documentation, seed data details, and more sample questions.

### Quick Start - Deploy Custom Ontology

Deploy your own ontology with local data using the generic deployment script:

```bash
cd src/000-cloud/033-fabric-ontology

# Deploy custom ontology with local CSV/Parquet data
./scripts/deploy.sh \
  --definition ./my-ontology.yaml \
  --workspace-id <YOUR_WORKSPACE_GUID> \
  --data-dir ./my-data/
```

This creates everything from scratch:

- **Lakehouse** with tables loaded from your `--data-dir`
- **Semantic Model** (Direct Lake) for Power BI
- **Ontology** with entity types and relationships

File names in `--data-dir` must match table names in your YAML (e.g., `robot.csv` for table `robot`).

See [definitions/examples/cora-corax-dim.yaml](definitions/examples/cora-corax-dim.yaml) for a complete example definition.

### Overview

This component enables deployment of complete Microsoft Fabric ontologies using a declarative YAML definition format. Rather than hardcoding specific entities and relationships, you define your ontology schema in YAML and the deployment scripts automatically:

1. Create Lakehouse and load CSV/Parquet data as Delta tables (optional)
2. Create Eventhouse and KQL database with time-series data (optional)
3. Generate and deploy Direct Lake Semantic Model (optional)
4. Create Ontology with entity types, properties, data bindings, and relationships

### Deployment Modes

#### Generic Deployment (Recommended for Custom Ontologies)

Use `deploy.sh` for one-command deployment of any ontology definition with local data:

```bash
# Deploy everything: Lakehouse, data, semantic model, ontology
./scripts/deploy.sh \
  --definition ./my-ontology.yaml \
  --workspace-id <workspace-guid> \
  --data-dir ./my-data/

# Skip specific steps
./scripts/deploy.sh \
  --definition ./my-ontology.yaml \
  --workspace-id <workspace-guid> \
  --data-dir ./my-data/ \
  --skip-semantic-model        # Don't create semantic model

# Use existing Lakehouse (skip data loading)
./scripts/deploy.sh \
  --definition ./my-ontology.yaml \
  --workspace-id <workspace-guid> \
  --skip-data-sources \
  --lakehouse-id <lakehouse-guid>

# Dry run to preview deployment
./scripts/deploy.sh \
  --definition ./my-ontology.yaml \
  --workspace-id <workspace-guid> \
  --data-dir ./my-data/ \
  --dry-run
```

#### Bind to Existing Data (Most Common)

If your Lakehouse tables already exist, you only need to deploy the ontology with bindings. The `dataSources` section in the YAML describes which tables to bind to - it does **not** create them.

```bash
# Deploy ontology that binds to existing Lakehouse tables
./scripts/deploy-ontology.sh \
  --definition definitions/examples/cora-corax-dim.yaml \
  --workspace-id <workspace-guid> \
  --lakehouse-id <lakehouse-guid>
```

**Requirements:**

- Lakehouse must already exist with tables matching the `dataBinding.table` names in the definition
- Column names must match the `sourceColumn` values in entity properties

#### Full Deployment (Create Everything)

If you need to create data sources and load sample data:

```bash
# 1. Deploy data sources (creates Lakehouse, uploads CSV, converts to Delta)
./scripts/deploy-data-sources.sh \
  --definition definitions/examples/cora-corax-dim.yaml \
  --workspace-id <workspace-guid> \
  --data-dir ../fabric-ontology-dim/seed/

# 2. Deploy semantic model (optional, for Power BI)
./scripts/deploy-semantic-model.sh \
  --definition definitions/examples/cora-corax-dim.yaml \
  --workspace-id <workspace-guid> \
  --lakehouse-id <lakehouse-guid>

# 3. Deploy ontology
./scripts/deploy-ontology.sh \
  --definition definitions/examples/cora-corax-dim.yaml \
  --workspace-id <workspace-guid> \
  --lakehouse-id <lakehouse-guid>
```

### Usage

The component can be used standalone against any Fabric workspace.

#### Bind to Existing Data

```bash
# Validate definition before deployment
./scripts/validate-definition.sh --definition definitions/examples/cora-corax-dim.yaml

# Deploy ontology with Lakehouse bindings only
./scripts/deploy-ontology.sh \
  --definition definitions/examples/cora-corax-dim.yaml \
  --workspace-id <workspace-guid> \
  --lakehouse-id <lakehouse-guid>

# Deploy ontology with Lakehouse + Eventhouse bindings (for time-series data)
./scripts/deploy-ontology.sh \
  --definition my-ontology.yaml \
  --workspace-id <workspace-guid> \
  --lakehouse-id <lakehouse-guid> \
  --eventhouse-id <eventhouse-guid> \
  --cluster-uri https://xyz.kusto.fabric.microsoft.com
```

### Tutorial: Deploying the CORA/CORAX Robotics Ontology

This walkthrough deploys a complete IEEE 1872 robotics ontology with sample data.

#### One-Command Deployment

```bash
cd src/000-cloud/033-fabric-ontology/scripts

# Deploy everything with a single command
./deploy-cora-corax-dim.sh --workspace-id <YOUR_WORKSPACE_GUID> --with-seed-data
```

This script orchestrates all steps automatically. For manual step-by-step deployment, continue reading.

#### Step 1: Prerequisites

1. **Azure CLI**: Install and authenticate

   ```bash
   az login
   ```

2. **Tools**: Install `yq` and `jq`

   ```bash
   # Windows (winget)
   winget install jqlang.jq
   winget install MikeFarah.yq

   # Windows (choco)
   choco install jq yq

   # Ubuntu/WSL
   sudo apt-get install jq
   sudo snap install yq

   # macOS
   brew install jq yq
   ```

3. **Fabric Workspace**: You need an existing Fabric workspace. Get the workspace ID from the URL:

   ```text
   https://app.fabric.microsoft.com/groups/<WORKSPACE_ID>/...
   ```

4. **Fabric Capacity**: The workspace must have Fabric capacity assigned:
   - Open workspace settings → License info
   - Under "License mode", select **Fabric capacity** (not Pro or PPU)
   - Assign an F-SKU capacity (F2 minimum for ontology features)
   - Without capacity, Lakehouse and Ontology APIs will fail

5. **Tenant Settings**: Ensure these are enabled in Fabric Admin Portal:
   - Ontology (Preview)
   - XMLA read-write endpoints
   - Graph and Copilot for Ontology

#### Step 2: Validate the Definition

```bash
cd src/000-cloud/033-fabric-ontology

# Validate the definition file
./scripts/validate-definition.sh --definition definitions/examples/cora-corax-dim.yaml
```

Expected output:

```text
✓ API version valid: fabric.ontology/v1
✓ Metadata valid: CORA_CORAX_Dimensional
✓ Entity types valid: 12 entities
✓ Relationships valid: 7 relationships
✓ Definition is valid
```

#### Step 3: Deploy with Seed Data

```bash
cd scripts

./deploy-cora-corax-dim.sh \
  --workspace-id <YOUR_WORKSPACE_ID> \
  --with-seed-data
```

The script will:

1. Create Lakehouse `RoboticsOntologyLH` (or use existing)
2. Upload 19 CSV files from `fabric-ontology-dim/seed/`
3. Convert to Delta tables
4. Create Direct Lake Semantic Model
5. Create Ontology with 12 entity types and 7 relationships

#### Step 4: Verify in Fabric Portal

1. Go to your Fabric workspace
2. Find `CORA_CORAX_Dimensional` in the items list
3. Open it to see the entity types and relationships

#### Step 5: Create Data Agent (Manual)

The Data Agent provides natural language Q&A over your ontology. **This step must be done manually** - Fabric Data Agents do not have REST API support.

1. **Create the Data Agent**:
   - In your workspace, click **+ New item** → Search for **Data agent**
   - Name: `RoboticsOntologyAgent`
   - Click **Create**

2. **Add the Ontology as Data Source**:
   - Select `CORA_CORAX_Dimensional` from OneLake data hub
   - Click **Add** then wait for the agent to initialize

3. **Add Required Instruction** (IMPORTANT):
   - Click **Agent instructions** in the menu ribbon
   - Add this text at the bottom:

     ```text
     Support group by in GQL
     ```

   - This enables aggregation queries (known issue workaround per [Microsoft docs](https://learn.microsoft.com/fabric/iq/ontology/tutorial-4-create-data-agent#provide-agent-instructions))

4. **Test the Agent**:
   - "What robots do we have?"
   - "Which robots are in the Assembly Line group?"
   - "What is the current position of the KUKA KR 16?"

> **Tip**: If queries return "no data" errors, wait a few minutes for agent initialization then retry.
>
> **Note**: Data Agent is a preview feature requiring F2+ Fabric capacity and tenant admin settings for Fabric Data Agent, Cross-geo processing for AI, and Cross-geo storing for AI.

#### Data Sources Reference

The CORA/CORAX ontology uses IEEE 1872 robotics seed data:

| Entity Type        | Table              | Rows | Description                              |
|--------------------|--------------------|------|------------------------------------------|
| Robot              | robot              | 3    | ABB IRB 6700, KUKA KR 16, Fanuc M-20iA   |
| RobotGroup         | robotgroup         | 2    | Welding Cell, Assembly Line              |
| RoboticSystem      | roboticsystem      | 2    | Production Line A, Production Line B     |
| RoboticEnvironment | roboticenvironment | 2    | Factory Floor North, Factory Floor South |
| PositionMeasure    | positionmeasure    | 3    | X, Y, Z positions in meters              |
| OrientationMeasure | orientationmeasure | 3    | Roll, Pitch, Yaw in radians              |
| PoseMeasure        | posemeasure        | 3    | Combined position + orientation          |

See [fabric-ontology-dim/README.md](fabric-ontology-dim/README.md) for complete entity and relationship reference.

### Environment Variables

The deployment scripts use Azure CLI authentication. Set the following before running:

```bash
# Authenticate to Azure
az login

# Scripts automatically obtain tokens for:
# - https://api.fabric.microsoft.com (Fabric REST API)
# - https://storage.azure.com (OneLake DFS API)
```

### Prerequisites

- Azure CLI with logged-in session (`az login`)
- [`yq`](https://github.com/mikefarah/yq) - YAML parser
- `jq` - JSON processor
- `curl` - HTTP client
- Fabric workspace with **Fabric capacity assigned** (F2 or higher SKU)
  - Workspace Settings → License info → License mode: Fabric capacity
- Tenant admin settings enabled: Ontology preview, XMLA endpoints, Graph preview

### Creating New Ontologies

To deploy a new ontology, create a YAML definition file following the schema format.

#### Definition Schema

```yaml
apiVersion: fabric.ontology/v1
kind: OntologyDefinition

metadata:
  name: "MyOntology"           # Required: Ontology display name (letters, numbers, underscores only)
  description: "Description"   # Optional: Ontology description
  version: "1.0.0"             # Optional: Version string

dataSources:
  lakehouse:                   # Required for static data bindings
    name: "MyLakehouse"
    tables:
      - name: "tablename"
        format: "csv"          # csv or parquet
  eventhouse:                  # Optional: for time-series bindings
    name: "MyEventhouse"
    database: "MyKqlDatabase"
    tables:
      - name: "telemetry"
        format: "csv"

entityTypes:
  - name: "EntityName"         # Required: Entity type name
    key: "IdProperty"          # Required: Primary key property
    displayName: "NameProp"    # Optional: Display name property
    dataBinding:
      type: "static"           # static (Lakehouse) or timeseries (Eventhouse)
      source: "lakehouse"      # lakehouse or eventhouse
      table: "tablename"       # Source table name
    properties:
      - name: "PropertyName"   # Required: Property name
        type: "string"         # string, int, double, datetime, boolean
        sourceColumn: "Column" # Column name in source table

relationships:
  - name: "relName"            # Required: Relationship name
    from: "EntityA"            # Required: Source entity type
    to: "EntityB"              # Required: Target entity type
    cardinality: "one-to-many" # one-to-one, one-to-many, many-to-many
    binding:
      table: "jointable"       # Table containing relationship data
      fromColumn: "FromKey"    # Column for source entity key
      toColumn: "ToKey"        # Column for target entity key
```

> **Note**: Ontology names must start with a letter, be less than 90 characters, and contain only letters, numbers, and underscores. No hyphens allowed.

#### Supported Property Types

| Definition Type | Fabric Ontology Type | KQL Type   | TMDL Type  |
|-----------------|----------------------|------------|------------|
| `string`        | `String`             | `string`   | `String`   |
| `int`           | `Int64`              | `int`      | `Int64`    |
| `double`        | `Double`             | `real`     | `Double`   |
| `datetime`      | `DateTime`           | `datetime` | `DateTime` |
| `boolean`       | `Boolean`            | `bool`     | `Boolean`  |

#### Example Definition

See [definitions/examples/cora-corax-dim.yaml](definitions/examples/cora-corax-dim.yaml) - IEEE 1872 CORA/CORAX robotics ontology with 12 entity types and 7 relationships.

### Troubleshooting

#### Ontology Shows "Setting up your ontology" for Extended Period

This is **normal behavior**. Ontology creation is an asynchronous operation that can take **10-20 minutes** to complete, even though the API returns success immediately.

**What's happening:**

- The Fabric API creates the ontology shell immediately
- Entity types and relationships are provisioned asynchronously in the background
- The portal shows "Setting up your ontology" until all entity types are ready

**How to verify completion:**

```bash
# Get token and ontology ID
TOKEN=$(az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv)
WORKSPACE_ID="<your-workspace-id>"
ONTOLOGY_ID=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/ontologies" | jq -r '.value[0].id')

# Check if entity types exist (returns "EntityNotFound" while still processing)
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/ontologies/$ONTOLOGY_ID/entityTypes" | jq .
```

- **Still processing**: Returns `{"errorCode": "EntityNotFound", ...}`
- **Complete**: Returns array of entity types

**Recommendation**: Wait 10-20 minutes after deployment before checking the ontology in the Fabric portal or creating a Data Agent.

#### Common Errors

**BadArtifactCreateRequest - Item name must start with a letter**:

- Ontology names cannot contain hyphens
- Use underscores instead: `My_Ontology` not `My-Ontology`

**AADSTS50173: The provided grant has expired** (Kusto/Eventhouse operations):

- The Kusto API requires a different token scope than Fabric API
- Run `az logout` then `az login` to refresh all tokens
- If Lakehouse was already created, skip data sources: `--skip-data-sources --lakehouse-id <id>`

**ALMOperationImportFailed**: The ontology definition JSON format is incorrect.

- Ensure entity types have `$schema` property
- Ensure `.platform` has both `$schema` and `config` blocks
- Ensure Lakehouse bindings use `sourceSchema: null` (not `"dbo"`)

**Operation timeout**: Long-running operations may take 60-120 seconds.

- The scripts poll with a 300-second timeout
- Check Fabric portal for operation status

**Authentication failed**: Token acquisition issues.

- Run `az login` to refresh credentials
- Ensure you have Fabric workspace contributor access

**Definition validation failed**: YAML schema issues.

- Run `./scripts/validate-definition.sh --definition <file>` for details
- Check entity keys reference valid properties
- Check relationships reference valid entity types

### Component Structure

```text
033-fabric-ontology/
├── README.md                      # This documentation
├── definitions/                   # Ontology definition files
│   ├── schema.json               # JSON Schema for validation
│   └── examples/                 # Example definitions
│       └── cora-corax-dim.yaml   # IEEE 1872 CORA/CORAX robotics ontology
├── fabric-ontology-dim/           # CORA/CORAX starter kit
│   ├── README.md                 # Detailed documentation and sample questions
│   ├── json-schema/              # JSON Schema validation files
│   └── seed/                     # Sample CSV data (19 tables)
├── scripts/                       # Deployment scripts
│   ├── lib/                      # Shared libraries (logging, parser, API)
│   ├── deploy.sh                 # Generic one-command deployment
│   ├── deploy-cora-corax-dim.sh  # CORA/CORAX robotics deployment
│   ├── validate-definition.sh   # Schema validation
│   ├── deploy-data-sources.sh   # Lakehouse + Eventhouse creation
│   ├── deploy-semantic-model.sh # TMDL generation
│   ├── deploy-ontology.sh       # Ontology creation
│   └── dump-parts.sh            # Debug utility for ontology parts
└── templates/                     # Template files
    ├── semantic-model/           # TMDL templates
    ├── kql/                      # KQL templates
    └── ontology/                 # Ontology JSON templates
```
