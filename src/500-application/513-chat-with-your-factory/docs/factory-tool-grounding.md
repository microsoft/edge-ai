---
title: Factory Tool Grounding
description: Entity catalog and canonical sample questions for the query_factory_ontology tool
ms.date: 2026-06-15
ms.topic: reference
---

## Factory Tool Grounding

The `query_factory_ontology` function tool answers robot questions by reading the
static CORA/CORAX ontology from the `RoboticsOntologyLH` Fabric lakehouse. This
document enumerates the seed entities the tool can answer over and the canonical
sample questions, keeping demo flows and the agent prompt aligned with the seed
data.

### Tool Intents

| Intent           | Required arguments | Returns                                              |
|------------------|--------------------|------------------------------------------------------|
| `list_robots`    | none               | Id, Name, Description for every robot on the line     |
| `robot_position` | `robotName`        | Current pose (X, Y, Z, Roll, Pitch, Yaw) for a robot |

### Seed Entity Catalog

#### Robots (`dbo.robot`)

| Id       | Name          | Description    |
|----------|---------------|----------------|
| `robot1` | ABB IRB 6700  | ABB robot      |
| `robot2` | KUKA KR 16    | KUKA robot     |
| `robot3` | Fanuc M-20iA  | Fanuc robot    |

#### Pose (`dbo.posemeasure`)

| Id      | Name            | X   | Y   | Z   | Roll | Pitch | Yaw   |
|---------|-----------------|-----|-----|-----|------|-------|-------|
| `pose1` | ABB Home Pose   | 1.5 | 2.0 | 0.8 | 0    | 0     | 1.57  |
| `pose2` | KUKA Home Pose  | 4.5 | 2.0 | 0.6 | 0    | 0     | 0     |
| `pose3` | Fanuc Home Pose | 7.5 | 3.5 | 0.7 | 0    | 0     | -1.57 |

#### Relationship (`dbo.robot_posemeasure`)

| Id          | From (robot) | To (pose) |
|-------------|--------------|-----------|
| `rel_pose1` | `robot1`     | `pose1`   |
| `rel_pose2` | `robot2`     | `pose2`   |
| `rel_pose3` | `robot3`     | `pose3`   |

Each of the three robots has a seeded home pose, so `robot_position` returns a
pose for any of them. A `robotName` that matches no robot returns no pose data,
and the agent states that plainly.

### Canonical Sample Questions

| Question                                          | Intent           | Arguments                       | Expected answer                          |
|---------------------------------------------------|------------------|---------------------------------|------------------------------------------|
| "What robots do we have?"                         | `list_robots`    | none                            | ABB IRB 6700, KUKA KR 16, Fanuc M-20iA   |
| "What is the current position of the KUKA KR 16?" | `robot_position` | `robotName` = `KUKA KR 16`      | X 4.5, Y 2.0, Z 0.6, Roll/Pitch/Yaw 0    |
