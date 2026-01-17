<!-- BEGIN_TF_DOCS -->
# Azure IoT Operations OPC UA Simulator

Deploy and configure the OPC UA Simulator

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |

## Modules

| Name                               | Source           | Version |
|------------------------------------|------------------|---------|
| aio\_apply\_scripts\_pre\_instance | ../apply-scripts | n/a     |

## Inputs

| Name                     | Description                                                                   | Type                                        | Default | Required |
|--------------------------|-------------------------------------------------------------------------------|---------------------------------------------|---------|:--------:|
| connected\_cluster\_name | The name of the connected cluster to deploy Azure IoT Operations to           | `string`                                    | n/a     |   yes    |
| resource\_group          | Resource group object containing name and id where resources will be deployed | ```object({ id = string name = string })``` | n/a     |   yes    |
<!-- END_TF_DOCS -->
