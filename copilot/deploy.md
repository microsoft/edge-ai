# Deploy Solution, CI, or Blueprint, Instructions

**MANDATORY**: Completely READ all of blueprints README.md, specifically [Detailed Deployment Workflow](../blueprints/README.md#detailed-deployment-workflow)

You will ALWAYS think hard about deploying blueprints or ci folder using established practices.

- You will ask the user if they need help with their environment setup and direct them to first run the prompt `.github/prompts/getting-started.prompt.md`
- You will wait longer for any `az` commands to finish as some take longer
  - You will always check the command window if you think the command did not finish before suggesting to run a different command
- You will use a Markdown checklist whenever getting or updating, defaults, parameters, or variables, from the user
  - If there is more than one, never ask for a specific single value to update, always use a Markdown checklist
- If needed ask the user if they want to deploy using terraform or bicep
  - If the user is unsure, suggest using terraform
- You will first do the following for deploying `blueprints`:
  - Unless a blueprint was specified, suggest the 'full-single-node-cluster' for learning deployments (but confirm)
  - Navigate to the Blueprint's IaC framework folder: use template `cd blueprints/{blueprint}/{framework}`
  - Read the Detailed Deployment Workflow from the blueprints' README.md
- You will first do the following for deploying `ci`:
  - First, ask the user which component to deploy
  - Next, navigate to the component's ci folder: use template `cd {component}/ci/{framework}`
  - Then, read all of the files in this ci directory
  - Read the Detailed Deployment Workflow from the blueprints' README.md
  - Verify with the user that they've already deployed all the required dependencies for this component ci, including resource group and identities
- You will then follow either (based on IaC framework):
  - ALL OF `deploying-terraform` in [Deploying Terraform](#deploying-terraform)
  - ALL OF `deploying-bicep` in [Deploying Bicep](#deploying-bicep)

## Deploying Terraform

<!-- <deploying-terraform> -->
- Ensure all commands are run from the `terraform` folder
- Fully read in and understand the `main.tf` and the `variables.tf` files that will be deployed
- ALWAYS build the `terraform.tfvars` file using `terraform-docs` first:
  - Run the command `terraform-docs tfvars hcl .` to generate the tfvars template
  - If failure, then instruct the user to install `terraform-docs` with "Installation instructions can
    be found at: [https://terraform-docs.io/user-guide/installation/](https://terraform-docs.io/user-guide/installation/)" or use the script at `./scripts/install-terraform-docs.sh`
  - Save the output to a new file named `terraform.tfvars`
  - Fully read in and understand the generated `*.tfvars` file
  - Provide defaults to these parameters for the user but be sure to ask for confirmation
  - Suggest a unique resource_prefix (5-8 alphanumeric characters), use something like `openssl rand -hex 4` to avoid naming conflicts
- If a `*.tfvars` already exists in the `terraform` folder:
  - Verify if they want to deploy with the already existing `*.tfvars` file
  - Otherwise, before creating a new `terraform.tfvars` file:
    - Look for existing `terraform.tfstate` files and offer to help reset deployment state if needed
    - Suggest checking existing resource groups in Azure to avoid conflicts
- Before executing any Terraform commands, verify:
  - Azure CLI is logged in (following deployment instructions)
  - Correct subscription is set (following deployment instructions)
  - Set the ARM_SUBSCRIPTION_ID environment variable (following deployment instructions)
- Run the deployment in sequence:
  - Initialize Terraform: `terraform init`
  - Plan the deployment: `terraform plan -var-file=terraform.tfvars`
  - Apply the deployment: `terraform apply -var-file=terraform.tfvars`
- While Terraform plan/apply operations are running, provide useful information about the deployment
- Handle deployment errors:
  - First, if you don't have the error message, request to see the specific error message before diagnosing
  - For state conflicts (403/409 errors), guide through proper cleanup:
    1. Offer to help remove Azure resources (via Portal or CLI)
    2. Clean up local Terraform state files
    3. Reinitialize with fresh state
  - For permissions errors, suggest checking Azure role assignments
  - For missing provider registrations, direct to the registration scripts
<!-- </deploying-terraform> -->

## Deploying Bicep

<!-- <deploying-bicep> -->
- Ensure all commands are run from the `bicep` folder
- Fully read in and understand the `main.bicep` file that will be deployed
- Offer to generate the `main.bicepparam` file that will be in the `bicep` folder
  - If the user already has a `main.bicepparam` file, offer to use it as is or help the user update it
  - Use the command `az bicep generate-params --file main.bicep --output-format bicepparam --include-params all` only if the user does not have a `main.bicepparam` file
  - If failure, then instruct the user to install or update Azure CLI
  - Fully read in and understand the `*.bicepparam` file that was generated
  - Provide defaults to these parameters for the user but be sure to ask for confirmation
  - Suggest the removal of parameters with default values to simplify the deployment work
  - Suggest a unique resourcePrefix (5-8 alphanumeric characters), use something like `openssl rand -hex 4` to avoid naming conflicts
- If a `*.bicepparam` already exists in the `bicep` folder, then offer to use it as is or help the user update it
- Before executing any deployment commands, verify:
  - Azure CLI is logged in (following deployment instructions)
  - Correct subscription is set (following deployment instructions)
  - Set the ARM_SUBSCRIPTION_ID environment variable (following deployment instructions)
  - For Custom Locations OID deployments, Set the CUSTOM_LOCATIONS_OID (following deployment instructions)
- Run the deployment:
  - Follow deployment instructions to deploy with either `az deployment sub create` or `az deployment group create`
  - Instruct the user to monitor deployment progress through the Azure Portal or CLI
- While deployment operations are running, provide useful information about the deployment
- Handle deployment errors:
  - First, if you don't have the error message, request to see the specific error message before diagnosing
  - For state conflicts (403/409 errors), guide through proper cleanup:
    1. Offer to help remove Azure resources (via Portal or CLI)
    2. For permissions errors, suggest checking Azure role assignments
    3. For missing provider registrations, direct to the registration scripts
<!-- </deploying-bicep> -->
