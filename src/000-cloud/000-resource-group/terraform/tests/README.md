# Testing Terraform

To read more about how testing works in terraform, see [Tests | Terraform](https://developer.hashicorp.com/terraform/language/tests).

To run the tests navigate to the directory above this `/tests` directory and run the following command:

```sh
# Required by the azurerm terraform provider
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

terraform init
# Runs the tests if there is a tests folder in the same directory
terraform test
```
