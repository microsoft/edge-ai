# Overview

This folder contains the Terraform configuration to deploy a Arc Connected K3s Kubernetes cluster on a single Azure Virtual Machine. The VM can be accessed via SSH using a certificate and has the K3s Kubernetes cluster pre-installed. The cluster can be connected to Azure Arc for management and monitoring. The which will be stored a `.ssh` directory in the root of the project by default

In additionally to the above the config will optionally deploy the following:

- Create a resource group to deploy the VM into if no existing resource group is provided
- Create a Service Principal with minimum required permissions to connect the cluster to Azure Arc, if no existing Service Principal is provided

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)

### Optionally create a Service Principal manually

If you want to create a Service Principal manually instead of letting Terraform create it, you can use the following command:

```sh
# Create a Service Principal and assign roles to connect the cluster to Azure Arc
resource_group_name=<resource-group-name>
resource_group_id=$(az group show --name $resource_group_name --query id --output tsv)

az ad sp create-for-rbac --name manual-azure-arc  --role "Kubernetes Cluster - Azure Arc Onboarding" --scopes $resource_group_id
```

Then add the Service Principal details to the `terraform.tfvars` file:

```hcl
service_principal_id     = "<service-principal-id>"
service_principal_secret = "<service-principal-secret>"
```

## Create resources

Set up terraform setting and apply it

1. cd into the `terraform` directory

    ```sh
    cd src/cluster_install/terraform
    ```

2. Set up env vars

    ```sh
    export ARM_SUBSCRIPTION_ID=<subscription-id>
    ```

3. Create a `terraform.tfvars` file with the at least the following minumum configuration:

    ```hcl
    environment     = "<environment>"
    resource_prefix = "<resource-prefix>"
    location        = "<location>"
    ```

4. Initalized and apply terraform

    ```sh
    terraform init
    terraform apply
    ```

5. Navigate to the deployed VM in Azure portal and Enable JIT (Just in time) access for your IP:
    Virtual Machines -> Select the VM -> Connect -> Native SSH -> VM Access -> Requests JIT access

6. The terraform output will contain the SSH command to connect to the VM
    Use the SSH command to connect to the VM or any preferred SSH client.

    ```sh
    ssh -i ../.ssh/id_rsa <vm_user_name>@<vm_dns_or_public_ip>
    ```

## Destroy resources

To destroy the resources created by Terraform, run the following command:

```sh
terraform destroy
```

## Troubleshooting

### Cloud-init

Check the cloud-init logs for errors:

```sh
cat /var/log/cloud-init-output.log
```

Cloud init script can be found at:

```sh
 sudo cat /var/lib/cloud/instance/scripts/runcmd
```
