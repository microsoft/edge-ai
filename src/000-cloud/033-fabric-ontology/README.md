---
title: Fabric Ontology Publisher
description: Unsupported accelerator for publishing static Lakehouse ontologies into existing Microsoft Fabric resources
author: Edge AI Team
ms.date: 2026-08-18
ms.topic: reference
keywords:
  - fabric
  - ontology
  - lakehouse
  - robotics
estimated_reading_time: 5
---

## Fabric Ontology Publisher

Component 033 is an unsupported, nonproduction accelerator that publishes ontology
content into existing Microsoft Fabric resources. It consumes explicit workspace and
Lakehouse IDs. It does not own Fabric infrastructure.

Component 031 owns the workspace, Lakehouse, Eventhouse, and KQL database lifecycle.
Use its outputs as inputs to this publisher. Do not use component 033 to establish or
manage those resources for the supported profile.

> [!WARNING]
> Microsoft Fabric Ontology is a preview capability. This component has not completed
> the qualification gates required for production use, customer deployment, or
> reference architecture positioning.

Microsoft references:

* [Ontology overview](https://learn.microsoft.com/fabric/iq/ontology/overview)
* [Ontology definition API](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition)

### Supported Profile

The first supported profile is static Lakehouse ontology publication:

* Publish one YAML ontology definition into an existing Fabric workspace
* Bind entity and relationship data to tables in an existing Lakehouse
* Construct Fabric ontology definition parts programmatically in
  `scripts/deploy-ontology.sh`
* Preserve the CORA/CORAX table, column, and sample-value contract used by application
  516

The following capabilities are outside the supported profile:

* Lakehouse, Eventhouse, or KQL database infrastructure provisioning
* Eventhouse and time-series ontology bindings
* Semantic-model generation or updates
* Graph refresh and Graph readiness automation
* Production support, service-level guarantees, or customer rollout
* Complete IEEE 1872 conformance claims

Eventhouse and semantic-model fields retained in the definition schema describe
experimental scripts. They are not part of static Lakehouse qualification.

### Prerequisites

* An existing Fabric workspace and Lakehouse provisioned by component 031
* Fabric capacity assigned to the workspace
* Ontology preview enabled for the tenant
* Azure CLI authenticated with access to the target workspace
* `bash`, `az`, `curl`, `jq`, `yq`, and `uuidgen`

The publisher mutates content in the workspace and Lakehouse identified on the command
line. Confirm both IDs before publication.

### Publish the Static CORA/CORAX Definition

Run commands from `src/000-cloud/033-fabric-ontology`.

Validate the checked-in definition:

```bash
./scripts/validate-definition.sh \
  --definition definitions/examples/cora-corax-dim.yaml
```

Validation checks the local definition contract. It does not remove the qualification
and support restrictions above.

Preview ontology part generation without calling the Fabric mutation API:

```bash
./scripts/deploy-ontology.sh \
  --definition definitions/examples/cora-corax-dim.yaml \
  --workspace-id <workspace-guid> \
  --lakehouse-id <lakehouse-guid> \
  --dry-run
```

Publish the ontology into the existing resources:

```bash
./scripts/deploy-ontology.sh \
  --definition definitions/examples/cora-corax-dim.yaml \
  --workspace-id <workspace-guid> \
  --lakehouse-id <lakehouse-guid>
```

The Lakehouse must already contain every table referenced by entity bindings and
relationship contextualizations. Column names must match each `sourceColumn`,
`fromColumn`, and `toColumn` value.

See
[fabric-ontology-dim/README.md](fabric-ontology-dim/README.md) for the static robotics
table contract and sample data.

### Definition Contract

The supported profile uses these fields from
[definitions/schema.json](definitions/schema.json):

| Definition area         | Supported behavior                                                         |
|-------------------------|----------------------------------------------------------------------------|
| `metadata`              | Sets the ontology display name and description                             |
| `dataSources.lakehouse` | Declares the existing Lakehouse tables referenced by bindings              |
| `entityTypes`           | Generates entity types, properties, keys, display properties, and bindings |
| `relationships`         | Generates relationship types and Lakehouse contextualizations              |

The schema accepts a limited Eventhouse shape and a semantic-model name for the
existing experimental scripts. Eventhouse ingestion accepts CSV only. Unsupported
source options, semantic-model import mode, and semantic-model Lakehouse auto-detection
are not part of the contract.

The schema does not carry workspace or Lakehouse IDs. Resource IDs are deployment
inputs so one portable definition can target an explicitly selected environment.

### Construction Authority

`scripts/deploy-ontology.sh` is the single authority for emitted Fabric ontology
parts. Its `jq` builders own platform metadata, entity types, properties, data
bindings, relationship types, and contextualizations.

Generated parts contain target workspace and Lakehouse IDs in data-binding locations.
Logical comparisons must canonicalize JSON and exclude environment-specific resource
identifiers.

### Troubleshooting

#### Definition Validation Fails

Run the validator directly and address every reported schema or semantic error before
authentication or publication:

```bash
./scripts/validate-definition.sh --definition <definition-file>
```

#### Fabric Rejects the Definition

Confirm that the target workspace has Fabric capacity, Ontology preview is enabled,
and all Lakehouse table and column names match the definition exactly. Publication is
asynchronous, so an accepted API operation does not prove Graph readiness.

#### Authentication Fails

Refresh the Azure CLI session and verify contributor access to the explicit target
workspace:

```bash
az logout
az login
```

### Component Structure

```text
033-fabric-ontology/
├── README.md
├── definitions/
│   ├── schema.json
│   └── examples/
│       ├── cora-corax-dim.yaml
│       └── cora-corax-dim-timeseries.yaml
├── fabric-ontology-dim/
│   ├── README.md
│   └── seed/
└── scripts/
    ├── lib/
    ├── deploy-ontology.sh
    └── validate-definition.sh
```
