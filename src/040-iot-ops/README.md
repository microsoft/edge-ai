# Overview

Component to deploy Azure IoT Operations to an Arc Connected K3s Kubernetes cluster and required dependencies.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

### Customer Managed Trust - TLS

If you wish to configure custom trust settings for `Issuer` and trust bundle `ConfigMap`, you have two options:

- Option 1 - If you wish to manage and provide trust with a TLS certificate from Key Vault along with having all
  AIO MQ trust and issuer resources __automatically__ generated from this certificate, update the following variables
  into your `terraform.tfvars` file before deploying AIO:

  ```hcl
  trust_config_source = "CustomerManagedGenerateIssuer"
  ```

  Update the following variable to provide your own certificate (rather than self-signed):

  ```hcl
  aio_ca = {
    # Root CA certificate in PEM format, used as the trust bundle.
    root_ca_cert_pem  = "<>"
    # CA certificate chain, can be the same as root_ca_cert_pem or a chain with any number of intermediate certificates.
    # Chain direction must be: ca -> intermediate(s) --> root ca
    ca_cert_chain_pem = "<>"
    # Root or intermediate CA private key in PEM format. If using intermediates, must provide the private key of the first cert in the chain.
    ca_key_pem        = "<>"
  }
  ```

- Option 2 - If you already have cert-manager, trust-manager, one of Issuer or ClusterIssuer, and a ConfigMap
  for AIO TLS trust settings already deployed into your cluster as, refer to [Bring your own issuer](https://learn.microsoft.com/azure/iot-operations/secure-iot-ops/concept-default-root-ca#bring-your-own-issuer),
  then update the following variables into your `terraform.tfvars` file:

  ```hcl
  trust_config_source       = "CustomerManagedByoIssuer"

  byo_issuer_trust_settings = {
      iissuer_name    = "<>"
      iissuer_kind    = "<>"
      cconfigmap_name = "<>"
      cconfigmap_key  = "<>"
  }
  aio_platform_config = {
      install_cert_manager  = false
      install_trust_manager = false
  }
  ```

  > ⚠️ __Warning__: The scripts are not able to detect if your resources exist on the cluster, and installation will fail before completion. Error message may be unclear.
  > We recommend you have `kubectl` access to the cluster and run `kubectl get` commands to validate the resources before continuing with this option.

## Test OPC UA connectivity with MQTT Broker

If you deployed the OPC UA broker simulator, you can test the connectivity by following this tutorial: [Test OPC UA connectivity with MQTT Broker](https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-broker/howto-test-connection?tabs=bicep#connect-to-the-default-listener-inside-the-cluster)

To test with the simulator, just modify the `mosquitto_sub`s `--topic` parameter to be the topic of the OPC UA broker simulator, which is `azure-iot-operations/data/oven` by default.

The output should be similar to the following:

```sh
mosquitto_sub --host aio-broker --port 18883 --topic "azure-iot-operations/data/oven" --debug --cafile /var/run/certs/ca.crt -D CONNECT authentication-method 'K8S-SAT' -D CONNECT authentication-data $(cat /var/run/secrets/tokens/broker-sat)

# > Client $server-generated/930bf917-b418-44e0-bb9d-b5020ed7e9ef received PUBLISH (d0, q0, r0, m0, 'azure-iot-operations/data/oven', ... (235 bytes))
# {"Temperature":{"SourceTimestamp":"2025-01-21T15:47:54.4126889Z","Value":10969},"FillWeight":{"SourceTimestamp":"2025-01-21T15:47:54.4129477Z","Value":10969},"EnergyUse":{"SourceTimestamp":"2025-01-21T15:47:54.4129567Z","Value":10969}}
```
