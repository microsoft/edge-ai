# Overview

Component to deploy Azure IoT Operations to an Arc Connected K3s Kubernetes cluster and required dependencies.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- K3s cluster connected to Azure Arc, can be done by following the [020-cncf-cluster/README.md](../020-cncf-cluster/README.md)

## Create resources

Login to Azure CLI using the below command:

```bash
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```

Set up terraform setting and apply it

1. cd into the `terraform` directory

    ```sh
    cd src/040-iot-ops/terraform
    ```

2. Set up env vars

    ```sh
    export ARM_SUBSCRIPTION_ID=<subscription-id>
    ```

3. Create a `terraform.tfvars` file with the at least the following minumum configuration:

    ```hcl
    resource_prefix = "<resource-prefix>"
    location        = "<location>"
    ```

4. Optionally, if you wish to configure custom trust settings for `Issuer` and trust bundle `ConfigMap`, you have two options:

    Option 1 - If `connectedk8s proxy` is enabled on the cluster for the user deploying terraform, and if you wish to deploy custom trust with TLS certificate in Key Vault and associated secrets for the broker and its required resources such as ClusterIssuer, all __automatically__ generated, add the following to the `terraform.tfvars` file:

    ```hcl
    trust_config_source = "CustomerManagedGenerateIssuer"
    ```

    The above will generate the custom trust as self signed certificates, if you wish to configure your own certificates from a PKI infrastructure, you can provide the following configuration:

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

   Option 2 - If you already have cert-manager, trust-manager, one Issuer or ClusterIssuer, and ConfigMap trust resources in your cluster such as described in [Bring your own issuer](https://learn.microsoft.com/azure/iot-operations/secure-iot-ops/concept-default-root-ca#bring-your-own-issuer), add the following to the `terraform.tfvars` file:

    ```hcl
    resource_group_name       = "<>" # validate the default generated value is correct, you might need to pass in an existing resource name instead
    connected_cluster_name    = "<>" # validate the default generated value is correct, you might need to pass in an existing resource name instead
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

5. Initalized and apply terraform

    ```sh
    terraform init
    terraform apply
    ```

6. Connect to the cluster as you normally would

## Test OPC UA connectivity with MQTT Broker

If you deployed the OPC UA broker simulator, you can test the connectivity by following this tutorial: [Test OPC UA connectivity with MQTT Broker](https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-broker/howto-test-connection?tabs=bicep#connect-to-the-default-listener-inside-the-cluster)

To test with the simulator, just modify the `mosquitto_sub`s `--topic` parameter to be the topic of the OPC UA broker simulator, which is `azure-iot-operations/data/oven` by default.

The output should be similar to the following:

```sh
$ mosquitto_sub --host aio-broker --port 18883 --topic "azure-iot-operations/data/oven" --debug --cafile
 /var/run/certs/ca.crt -D CONNECT authentication-method 'K8S-SAT' -D CONNECT authentication-data
Client $server-generated/930bf917-b418-44e0-bb9d-b5020ed7e9ef received PUBLISH (d0, q0, r0, m0, 'azure-iot-operations/data/oven', ... (235 bytes))
{"Temperature":{"SourceTimestamp":"2025-01-21T15:47:54.4126889Z","Value":10969},"FillWeight":{"SourceTimestamp":"2025-01-21T15:47:54.4129477Z","Value":10969},"EnergyUse":{"SourceTimestamp":"2025-01-21T15:47:54.4129567Z","Value":10969}}
```

## Destroy resources

To destroy the resources created by Terraform, run the following command:

```sh
terraform destroy
```
