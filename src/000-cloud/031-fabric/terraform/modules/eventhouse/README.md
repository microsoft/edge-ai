<!-- BEGIN_TF_DOCS -->
# Eventhouse Module

Creates a Microsoft Fabric Eventhouse and KQL database for real-time analytics.
The Eventhouse provides a high-performance analytics engine optimized for
time-series and telemetry data from IoT devices and streaming sources.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| fabric    | 1.3.0           |

## Providers

| Name   | Version |
|--------|---------|
| fabric | 1.3.0   |

## Resources

| Name                                                                                                                         | Type     |
|------------------------------------------------------------------------------------------------------------------------------|----------|
| [fabric_eventhouse.this](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/resources/eventhouse)           | resource |
| [fabric_kql_database.additional](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/resources/kql_database) | resource |

## Inputs

| Name                       | Description                                                 | Type                                                              | Default | Required |
|----------------------------|-------------------------------------------------------------|-------------------------------------------------------------------|---------|:--------:|
| eventhouse\_description    | The description of the Microsoft Fabric eventhouse          | `string`                                                          | n/a     |   yes    |
| eventhouse\_display\_name  | The display name of the eventhouse.                         | `string`                                                          | n/a     |   yes    |
| workspace\_id              | The ID of the workspace where the lakehouse will be created | `string`                                                          | n/a     |   yes    |
| additional\_kql\_databases | Additional KQL databases to create within the eventhouse.   | ```map(object({ display_name = string description = string }))``` | `{}`    |    no    |

## Outputs

| Name               | Description                                                |
|--------------------|------------------------------------------------------------|
| eventhouse         | The complete eventhouse object with all properties.        |
| eventhouse\_id     | The ID of the created eventhouse.                          |
| eventhouse\_name   | The display name of the created eventhouse.                |
| kql\_database\_ids | List of all KQL database IDs within the eventhouse.        |
| kql\_databases     | List of all KQL database objects with complete properties. |
<!-- END_TF_DOCS -->
