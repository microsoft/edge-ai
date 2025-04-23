# Data Feed in Kubernetes on the Edge

Date: **2025-03-27**

## Status

- [ ] Draft
- [ ] Proposed
- [x] Accepted
- [ ] Deprecated

## Context

The solution is designed for managing data feeds from factory equipment to a Kubernetes environment at the edge.
The problem to solve is ensuring reliable data ingestion, processing, and validation from factory equipment to cloud storage, while addressing networking and connectivity challenges.

## Architecture

## Decision

The decision is to implement a data feed process using factory equipment, RabbitMQ, (MQTT)Mosquitto,and AIO(Azure IoT Operations) components in a Kubernetes environment.

## Decision Drivers

- Need for reliable data ingestion and processing at the edge.
- Integration with existing factory equipment and AIO components.

## Considered Options

### Option 1

**Technical Details:**

- Use RabbitMQ as the message broker with MQTT support.
- Deploy RabbitMQ, Ingest Service, and PostgreSQL as Kubernetes StatefulSets and Deployments.
- Use Mosquitto to bridge messages between RabbitMQ and AIO MQ.
- Implement AIO Data Processing pipelines and Cloud Connectors for data transport to cloud storage.

## Architecture Diagram

![Decision architecture](./images/Decision_architedcture.png)

We can query data from PostgreSQL  directly for detailed validation & comparison. May require a different set of networking &
connectivity challenges, but could be a fallback if AIO pipelines don’t work.

This would decouple proving 2 things:

1. Data flow from factory equipment to the edge
2. AIO data pipelines & cloud connectors

## Machine Data Feed Process

1. PLCs and factory equipment send data to the Machine devices inside the OT  network
2. Machine devices batch and send data up to the Machine cloud where it is made available through an API.
   This process exists today and is a black-box that we will leave unchanged.
3. Machine devices batch and send data to the Machine RabbitMQ broker in the IT  network.
4. The Machine Ingest Service processes the batch messages from the Machine devices.
5. The Machine Ingest Service places individual telemetry messages back into RabbitMQ.
   The Ingest service is a black-box that hosts proprietary Machine algorithms for handling batching and compression. PostgreSQL  is
   used to store time-series data needed for the Ingest Service.
6. The Mosquitto broker bridges topics from RabbitMQ. These are individual telemetry messages.
   Mosquitto is required to bridge topics due to incompatibilities between RabbitMQ’s MQTT  plugin and AIO’s MQ bridging.
7. The Mosquitto broker bridges topics into AIO MQ to be made available for AIO components.
8. AIO Data Processing pipelines or Cloud Connectors read messages from the AIO MQ.
   - The AIO MQ service may be redundant if AIO features can read messages directly from Mosquitto.
   - Machine and AIO components will be in their own namespaces

9. AIO Data Processing pipelines or Cloud Connectors write telemetry to Blob Storage in the cloud.
10. The Message Validation component reads individual messages from Blob Storage and the Machine API to compare and validate ST -
    One messages flowing through the Azure Stack HCI AKS cluster .

## Machine Kubernetes Components

The components that make up the Machine portion in Kubernetes include:

1. **RabbitMQ**: A message broker that [supports MQTT through a plugin](https://www.rabbitmq.com/docs/mqtt).
   - requires a 5GB mounted volume for storing queued messages.
   - Deployed as a single pod Kubernetes StatefulSet and configured with ConfigMaps and Secrets.
   - See [Deploying RabbitMQ to Kubernetes: What's Involved?](https://www.rabbitmq.com/blog/2020/08/10/deploying-rabbitmq-to-kubernetes-whats-involved)  for more details on deploying in Kubernetes.

2. **The Ingest Service**: A proprietary service that manages messages from the OT  network through RabbitMQ and includes custom batch
   decompression logic for placing individual telemetry messages back into RabbitMQ.
   - requires 5GB mounted volume to use for caching.
   - Deployed as a Kubernetes Deployment and configured with ConfigMaps and Secrets.

3. **Postgres**: Implemented as [timescaledb](https://docs.timescale.com/self-hosted/latest/install/)  to store time series data. This provides backing storage for the Ingest service.
   - requires 40GB mounted volume for longer term persistence.
   - Deployed as a single pod Kubernetes StatefulSet and configured with ConfigMaps and Secrets.
   - Timescale used to support a helm chart , but recently [deprecated it in favor of PostgreSQL operators for Kubernetes](https://docs.timescale.com/self-hosted/latest/install/installation-kubernetes/) .

## AIO Kubernetes Components

The components that make up the AIO portion in Kubernetes include:

1. **Mosquitto**: Not specific to AIO, but required to bridge messages with Machine’s RabbitMQ.
   - Requires a 5GB mounted volume for storing queued messages.
   - Deployed as a StatefulSet and configured with ConfigMaps and Secrets

2. **AIO MQ**: AIO’s MQTT  message broker. This component may be redundant with the mosquitto broker depending on whether AIO
   features can integrate well with mosquitto.
   - This is installed as part of AIO itself. There is no need to deploy additional pods.
   - AIO MQ can be configured to use persistent storage for storing queued messages , we will configure 5GB for this purpose.

3. **AIO Data Processor & Cloud Connector**: AIO’s features that can transport data from message brokers to the cloud (blob storage).
   - We would only need one of these options to send data from an MQTT  broker to Blob Storage.
   - [AIO Data Flow Processing](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/overview-dataflow)  runs generic no-code pipelines for processing data at the edge. We would not directly deploy the pods that
     these pipelines run on.
   - [AIO Data Flow Endpoints](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-configure-dataflow-endpoint) are no-code components the define connections that bridge data between a source and destination. We would
     not directly deploy the pods that these connectors run on.

## Container Images

The table below shows all of the container images that are required to power the system above. Platform-level components can pull from
[mcr.microsoft.com](http://mcr.microsoft.com/)  for images while custom components and open source images will be hosted in customer’s ACR to enable security
scanning, but we can pull from DockerHub for the POC.

| Kubernetes Component                 | Maintainer         | Image                                                                         | Public/Private | Container Registry    |
|--------------------------------------|--------------------|-------------------------------------------------------------------------------|----------------|-----------------------|
| RabbitMQ                             | Docker Community   | rabbitmq                                                                      | Public         | domainname.azurecr.io |
| Ingest Service                       | Machine            | ---                                                                           | Private        | domainname.azurecr.io |
| PostgreSQL                           | Timescale          | [timescale/timescaledb-ha](https://hub.docker.com/r/timescale/timescaledb-ha) | Public         | domainname.azurecr.io |
| Mosquitto                            | Eclipse Foundation | [eclipse-mosquitto](https://hub.docker.com/_/eclipse-mosquitto)               | Public         | domainname.azurecr.io |
| AIO MQ                               | Microsoft          | ---                                                                           | Public         | mcr.microsoft.com     |
| AIO Data Processor & Cloud Connector | Microsoft          | ---                                                                           | Public         | mcr.microsoft.com     |

**Pros:**

- Decouples machine data flow and AIO pipelines.
- Provides a fallback mechanism if AIO pipelines fail.
- Leverages existing Machine and AIO components.

**Cons:**

- Requires managing multiple components and configurations.
- Potential networking and connectivity challenges.

**Risks and Dependencies:**

- Dependency on RabbitMQ, Mosquitto, and AIO components.
- Networking and connectivity issues between OT and IT networks.

### Option 2

**Technical Details:**

- Directly query data from PostgreSQL for validation and comparison.
- Use AIO features to read messages directly from Mosquitto, bypassing AIO MQ.

**Pros:**

- Simplifies the architecture by reducing the number of components.
- Direct access to data for validation.

**Cons:**

- Limited fallback options if AIO features fail.
- Potential compatibility issues between Mosquitto and AIO components.

**Risks and Dependencies:**

- Dependency on PostgreSQL and Mosquitto.
- Compatibility issues between Mosquitto and AIO components.

## Consequences

The decision to implement the data feed process using the chosen components ensures reliable data ingestion, processing, and validation at the edge. It also provides flexibility and fallback mechanisms to handle potential failures in the data pipeline.

## Future Considerations

- Evaluate the performance and reliability of the implemented solution.[See here for more details]( https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/overview-broker).
- Consider potential updates or changes to the architecture based on evolving requirements and technologies.
