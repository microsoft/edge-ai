
# Fabric Ontology Dimensional Schema - CORA/CORAX Starter Kit

IEEE 1872 CORA/CORAX Robotics Ontology implementation for Microsoft Fabric Ontology (preview).

## Overview

This starter kit provides a complete dimensional schema based on IEEE 1872 robotics standards:

- **CORA** (Core Ontology for Robotics and Automation): Robot, RobotGroup, RoboticSystem, RoboticEnvironment
- **CORAX** (CORA Extensions): RobotInterface, ProcessingDevice, PhysicalEnvironment
- **POS** (Position Ontology): PositionMeasure, OrientationMeasure, PoseMeasure, CoordinateSystems

### Schema Statistics

| Category            | Count |
|---------------------|-------|
| Entity Tables       | 12    |
| Relationship Tables | 7     |
| Total Tables        | 19    |

## Quick Start Deployment

### Prerequisites

- Azure CLI authenticated (`az login`)
- Fabric workspace with capacity
- Bash shell (Git Bash on Windows)

### Deploy with Seed Data

```bash
cd src/000-cloud/033-fabric-ontology/scripts

# Deploy ontology with sample robotics data
./deploy-cora-corax-dim.sh \
  --workspace-id <your-workspace-guid> \
  --with-seed-data

# Dry run (preview without changes)
./deploy-cora-corax-dim.sh \
  --workspace-id <your-workspace-guid> \
  --with-seed-data \
  --dry-run
```

### What Gets Deployed

1. **Lakehouse**: `RoboticsOntologyLH` with 19 Delta tables
2. **Semantic Model**: `CORA_CORAX_DimensionalModel` (Direct Lake)
3. **Ontology**: `CORA_CORAX_Dimensional` with entity types and relationships

## Sample Questions

Use these questions to test your deployed ontology. They range from simple lookups to complex multi-hop analytics.

### Entity Lookups

| Question                                       | Tests                  |
|------------------------------------------------|------------------------|
| What robots do we have?                        | Basic entity retrieval |
| Show me all robotic systems                    | Entity type query      |
| List the physical environments in our facility | CORAX entity query     |

### Relationship Traversal

| Question                                                   | Tests                       |
|------------------------------------------------------------|-----------------------------|
| Which robots are in the Assembly Line group?               | `member` relationship       |
| What robotic system is the ABB IRB 6700 part of?           | `partOf` relationship       |
| Which robotic systems are equipped in Factory Floor North? | `equippedWith` relationship |

### Measurement Queries

| Question                                                  | Tests                                 |
|-----------------------------------------------------------|---------------------------------------|
| What is the current position of the KUKA KR 16?           | `hasPosition` + PositionMeasure       |
| Show me the orientation (roll, pitch, yaw) for all robots | `hasOrientation` + OrientationMeasure |
| Which robot has the highest Z position?                   | Aggregation on measures               |

### Multi-Hop Queries

| Question                                                              | Tests                                               |
|-----------------------------------------------------------------------|-----------------------------------------------------|
| Show me all robots in robotic systems equipped in Factory Floor North | 3-hop: Robot → RoboticSystem → RoboticEnvironment   |
| What are the positions of robots in the Welding Cell group?           | 2-hop: Robot → RobotGroup + Robot → PositionMeasure |
| List robots and their coordinate systems                              | Traverse through measures to coordinate systems     |

### Aggregations

| Question                                                   | Tests                |
|------------------------------------------------------------|----------------------|
| What is the average X position across all robots?          | Numeric aggregation  |
| How many robots are in each robot group?                   | Group-by counting    |
| What is the range of Z positions for Assembly Line robots? | Filtered aggregation |

### Complex Analytics

| Question                                                         | Tests                              |
|------------------------------------------------------------------|------------------------------------|
| Compare the pose measurements between ABB and KUKA robots        | Multi-entity comparison            |
| Which robots have moved more than 1 meter from origin?           | Calculated field (X^2+Y^2+Z^2 > 1) |
| Show robots with roll angle > 0.5 radians and their environments | Filtered multi-hop                 |

### Cross-Entity Analysis

| Question                                                                         | Tests                      |
|----------------------------------------------------------------------------------|----------------------------|
| For each robotic environment, show robot count and average positions             | Join + aggregation         |
| Which processing devices are associated with robots that have pose measurements? | Complex relationship chain |

## Seed Data Summary

### Robots (3 records)

| Robot        | Group         | System            |
|--------------|---------------|-------------------|
| ABB IRB 6700 | Welding Cell  | Production Line A |
| KUKA KR 16   | Assembly Line | Production Line B |
| Fanuc M-20iA | Assembly Line | Production Line B |

### Robotic Environments (2 records)

| Environment         | Equipped Systems  |
|---------------------|-------------------|
| Factory Floor North | Production Line A |
| Factory Floor South | Production Line B |

### Measurement Data

Each robot has sample position, orientation, and pose measurements with realistic robotics values (X/Y/Z in meters, Roll/Pitch/Yaw in radians).

## Directory Structure

```plaintext
fabric-ontology-dim/
├── README.md                    # This file
├── json-schema/                 # JSON Schema validation files
│   ├── Robot.schema.json
│   ├── RobotGroup.schema.json
│   ├── ...
│   └── Robot_PoseMeasure.schema.json
└── seed/                        # Sample CSV data
    ├── Robot.csv
    ├── RobotGroup.csv
    ├── ...
    └── Robot_PoseMeasure.csv
```

## Entity Type Reference

### CORA Entities

| Entity             | Key | Description                                        |
|--------------------|-----|----------------------------------------------------|
| Robot              | Id  | Agentive device performing physical actions        |
| RobotGroup         | Id  | Collection of robots working together              |
| RoboticSystem      | Id  | System containing robots and supporting components |
| RoboticEnvironment | Id  | Environment where robotic systems operate          |

### CORAX Entities

| Entity              | Key | Description                            |
|---------------------|-----|----------------------------------------|
| RobotInterface      | Id  | Communication/interaction interface    |
| ProcessingDevice    | Id  | Computational device for robot control |
| PhysicalEnvironment | Id  | Physical space containing robots       |

### POS Entities

| Entity                      | Key | Measurement Columns             |
|-----------------------------|-----|---------------------------------|
| PositionCoordinateSystem    | Id  | Reference frame for position    |
| OrientationCoordinateSystem | Id  | Reference frame for orientation |
| PositionMeasure             | Id  | X, Y, Z (meters)                |
| OrientationMeasure          | Id  | Roll, Pitch, Yaw (radians)      |
| PoseMeasure                 | Id  | X, Y, Z, Roll, Pitch, Yaw       |

## Relationship Reference

| Relationship   | From                     | To                          | Cardinality  |
|----------------|--------------------------|-----------------------------|--------------|
| member         | Robot                    | RobotGroup                  | Many-to-Many |
| partOf         | Robot                    | RoboticSystem               | Many-to-Many |
| equippedWith   | RoboticEnvironment       | RoboticSystem               | Many-to-Many |
| transform      | PositionCoordinateSystem | OrientationCoordinateSystem | Many-to-Many |
| hasPosition    | Robot                    | PositionMeasure             | Many-to-Many |
| hasOrientation | Robot                    | OrientationMeasure          | Many-to-Many |
| hasPose        | Robot                    | PoseMeasure                 | Many-to-Many |

## Extending the Schema

### Adding New Robots

1. Add row to `seed/Robot.csv`
2. Add relationships in `seed/Robot_RobotGroup.csv`, `seed/Robot_RoboticSystem.csv`
3. Add measurements in `seed/Robot_PositionMeasure.csv`, etc.
4. Re-run deployment with `--with-seed-data`

### Adding Telemetry Data

The measure tables (PositionMeasure, OrientationMeasure, PoseMeasure) include `Timestamp` and `CoordinateSystemId` columns ready for streaming telemetry from IoT Hub → Event Hubs → Eventhouse.

## IEEE 1872 Reference

- [IEEE 1872-2015](https://standards.ieee.org/standard/1872-2015.html) - Core Ontology for Robotics and Automation
- [IEEE 1872.2-2021](https://standards.ieee.org/standard/1872_2-2021.html) - Autonomous Robotics Ontology
