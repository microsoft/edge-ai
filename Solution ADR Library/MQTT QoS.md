# Choosing QoS Level for the MQTT Bridge routes

## Status

[For this library of ADRs, mark the most applicable status at which it was stored in the original project. This can help provide context and validity for folks reviewing this ADR. If it has been deprecated you can add a note on why and date it.]

- [ ] Draft
- [X] Proposed
- [ ] Accepted
- [ ] Deprecated

## Context

This document lists the design considerations for selecting the appropriate Quality of Service (QoS) level for the MQTT Bridge. MQTT offers three QoS levels, each impacting message delivery guarantees and network overhead. This record will try to define the optimal QoS level based on each use case.

## Decision

The MQTT Bridge is responsible for duplicating data between the Local UNS and the Enterprise UNS. This data has not the same lifecycle, nor the same granularity and it's being duplicated from different sources to different targets.

The purpose of the ADR is to define a specific Quality of Service (QoS) level for each kind of data. Each choice of QoS level needs to be analyzed, to avoid any dysfunctions.

## Considered Options

### QoS levels

MQTT defines three QoS levels:

- **QoS 0 (At most once)**: also known as *fire and forget*. The message is sent only once. **Delivery is not guaranteed**. This is the fastest and most lightweight option, suitable for non-critical data where occasional message loss is acceptable.
- **QoS 1 (At least once)**: The publisher resends the message until an acknowledgment (called PUBACK) is received from the broker. This ensures delivery but might lead to duplicates. To be used for moderately important data where some redundancy is tolerable.
- **QoS 2 (Exactly once)**: A four-handshake process guarantees a single message delivery. This offers the highest reliability **but incurs the most overhead**. To be used for critical data requiring guaranteed delivery without duplicates.

> NOTE: QoS 2 is [not supported in Azure IoT Operations](https://learn.microsoft.com/en-us/azure/iot-operations/reference/mqtt-support).

### Data types

See descriptions for data flow data types below:

| Data Flow   | Source | Target | Cardinality | Lifecycle    |
|-------------|--------|--------|-------------|--------------|
| Metadata    | L4     | L3     | 1           | Boot phase   |
| Assets Data | L3     | L4     | N           | Continuously |

## Decision Conclusion

### Discarded level

We introduced the MQTT Bridge to our solution design to ensure reliable data transfer between PSNet (L3) and Corporate network (L4). This means data must be delivered from the source to the target without errors. Because of this requirement, we won't be using Quality of Service (QoS) level 0, as it doesn't guarantee delivery.

### Choosen levels

#### Metadata

The **Metadata** is:

- **needed at least Once**
- need to be retained as required for Data Pipelines
- **Duplication** of messages **will not impact** the execution of the Data Pipelines **[To be confirmed]**

> NB: the MQTT Bridge does not support to add Retention flag until now.

**Decision: QoS level 1 will be used for Metadata duplication.**

#### Assets Data

The Assets Data will be duplicated from L3 to L4 and it's:

- **needed at least Once**
- **Duplication** of messages **will not impact** the use of the data **[To be confirmed]**
- needed asynchronously

**Decision: QoS level 1 will be used for Assets Data duplication.**

> **Questions**

## QoS 2 Implications

The use of QoS level 2 may increase the load of the MQTT Broker in L4, due to the delivery verifications sequences. To overcome all harm, we can increase the number of instances of the MQTT Broker in L4.

This is can be done by increasing the `cardinality` of these `pods`:

- `Frontend`: MQTT gateway-like that will receive the requests and forward it to the `backend` chains.
- `Backend`: responsible for storing and delivering messages to the clients.

To configure the `cardinality` of the MQTT Broker elements, we can:

- define them in the Kubernetes workload definition for the MQTT Broker CRD:

  ```yaml
  apiVersion: mq.iotoperations.azure.com/v1beta1
  kind: Broker
  metadata:
    name: broker
    namespace: azure-iot-operations
  spec:
    ...
    mode: distributed
    cardinality:
      backendChain:
        partitions: 2
        redundancyFactor: 2
        workers: 2
      frontend: 
        replicas: 2
        workers: 2
    encryptInternalTraffic: false
    memoryProfile: medium 
  ```

  - the `distributed` mode is used to override the default values.
  - the `backendChain` is using **2 partitions** and **2 workers**.
  - the `frontend` is using **2 replicas** (number of `frontend` pods to deploy) and **2 workers** (number of workers to deploy per frontend).
  - the `memoryProfile` defines the settings profile for the **memory usage**. It's a very important value and needs good understanding of the targeted use cases. It has a huge impact on performance/infrastructure resource. For example, it can cause memory usage to go from `99 MiB` max to `4.9 GiB` max per `frontend replica`.

> NB: All these settings are covered in details in the [Configure core Azure IoT MQ Preview MQTT broker settings](https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-connectivity/howto-configure-availability-scale)

- or we can define the `cardinality` and `memoryProfile` while deploying the `mq` extension during the AIO Install.

    ```bash
    az iot ops init ... \
        --mq-mode distributed
        --mq-backend-workers
        --mq-broker
        --mq-frontend-replicas
        --mq-frontend-server
        --mq-frontend-workers
        --mq-mem-profile
        ....
    ```

> **Very Important:**
> There is no optimal MQTT broker pre-configuration.
> Testing with real data is crucial to determine the ideal settings for L4 MQTT Broker. This testing will help you define the actual load on the broker and size the Kubernetes infrastructure accordingly.

## Related Documentation

- [MQTT Bridge configuration](../how-to/mqtt-bridge.md)
- [Publishing data into the Local and Enterprise UNS](../how-to/datapipeline-publish-data-uns.md)

## References

- [Configure scaling settings - Configure core Azure IoT MQ](https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-connectivity/howto-configure-availability-scale#configure-scaling-settings)
- [az iot ops - Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/iot/ops?view=azure-cli-latest#az-iot-ops-init)
- [Secure Azure IoT MQ Preview communication using BrokerListener](https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-connectivity/howto-configure-brokerlistener)
