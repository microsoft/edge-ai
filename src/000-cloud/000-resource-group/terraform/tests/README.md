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

## Testing the "Existing Resource Group" Functionality

Testing the `use_existing_resource_group` functionality presents unique challenges because it requires referencing an actual Azure resource. We provide multiple approaches to testing this feature.

### Option 1: Using the Test Script

We've provided a test script that automates the process of testing the existing resource group functionality:

```sh
cd ./src/000-cloud/000-resource-group/terraform/
./tests/test-existing-resource-group.sh
```

The script performs the following actions:

1. Creates a temporary resource group
2. Runs a Terraform apply with `use_existing_resource_group = true`
3. Verifies outputs correctly reference the existing resource group
4. Cleans up resources

### Option 2: Manual Testing with Actual Resources

1. Create a resource group in Azure:

   ```sh
   az group create --name existing-rg-name --location eastus
   ```

2. Uncomment the test case in `onboard-reqs.tftest.hcl`

3. Run the tests:

   ```sh
   terraform test
   ```

4. Delete the resource group when done:

   ```sh
   az group delete --name existing-rg-name --yes
   ```

### Option 3: Integration Testing in CI/CD Pipeline

For automated testing, consider creating an integration test that:

1. Creates a resource group
2. Runs the module with `use_existing_resource_group = true`
3. Verifies the output references the existing resource group
4. Cleans up the resource group

This approach requires custom scripting but provides more reliable automated testing.
