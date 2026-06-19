---
title: Factory Tool Live-Data Path
description: How live oven telemetry is added to the factory ontology without changing the agent tool interface
ms.date: 2026-06-15
ms.topic: concept
---

## Factory Tool Live-Data Path

This document describes the future live-data path for the `query_factory_ontology`
tool. The key property is interface stability: adding live telemetry is an
*entity* change, not a *tool* change. The agent tool name and its input
parameters do not change (Option A). See the worked example in
[cora-corax-dim-timeseries.yaml](../../../000-cloud/033-fabric-ontology/definitions/examples/cora-corax-dim-timeseries.yaml).

### Data Flow

Live oven telemetry reaches the ontology read layer over this path:

```text
AIO MQTT broker                Fabric                         Read layer
azure-iot-operations/data/oven ─▶ Eventstream ─▶ Eventhouse ─▶ KQL query
        (custom endpoint)            (KQL table)   (join on
                                                    correlationColumn)
```

* **Source topic**: `azure-iot-operations/data/oven` (111-assets oven simulator).
* **Payload shape**: each data point is an object with a timestamp and value:

  ```json
  {
    "Temperature": { "SourceTimestamp": "2026-06-15T12:00:00Z", "Value": 210.4 },
    "FillWeight":  { "SourceTimestamp": "2026-06-15T12:00:00Z", "Value": 4.2 },
    "EnergyUse":   { "SourceTimestamp": "2026-06-15T12:00:00Z", "Value": 5.1 }
  }
  ```

* **MQTT → Eventstream hop**: a Fabric Eventstream custom endpoint source consumes
  the MQTT topic and lands rows in an Eventhouse KQL table.

### Interface Stability (Option A)

The agent's `query_factory_ontology` tool name and input parameters are unchanged.
The only confirmed change to the read layer is a KQL join on the binding's
`correlationColumn`, ordered by `timestampColumn`, to select the most recent
reading. The tool response payload widens additively (live properties appear
alongside the existing static fields); no caller or prompt change is required.

A separate "live telemetry" tool was considered and rejected: the binding is
entity-scoped, so a second tool would add surface area without benefit.

### Open Deployment Items

These are resolved when the live-data path is deployed, not by the current Tier 2
work:

* **KQL `database` / `table` names** are Eventstream-configured (032-fabric-rti
  `properties.tableName`, auto-created when unspecified). The example YAML uses
  placeholder names.
* **`correlationColumn` projection**: the MQTT payload has no explicit entity-key
  field, so the correlation value (e.g., the oven asset id) must be derived from
  the topic or asset name during Eventstream / KQL processing.
