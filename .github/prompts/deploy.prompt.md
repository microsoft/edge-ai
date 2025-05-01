---
mode: 'agent'
tools: ['terminalLastCommand', 'terminalSelection', 'codebase', 'fetch', 'problems', 'searchResults', 'usages', 'vscodeAPI']
description: 'Provides Prompt Instructions for Deploying Solution or Deploying Blueprints'
---
# Deploy Solution or Blueprint Instructions (deploy.prompt.md)

**MANDATORY**: Completely READ all of #file:../../blueprints/README.md

- Ask the user if they need help with their environment setup, direct them to first run the prompt getting-started.prompt.md
- Unless a Blueprint was specified, suggest the 'full-single-node-cluster' for learning deployments (but confirm)
- Ask the user if they want to deploy using Terraform or Bicep
- If the user is unsure, suggest using Terraform
- Terraform:
  - Ensure the commands are run from the `terraform` folder
  - Fully read in and understand the `main.tf` and the `variables.tf` files that will be deployed
  - ALWAYS build the `terraform.tfvars` file using `terraform-docs` first:
    - Navigate to the Blueprint's `terraform` folder: `cd <blueprint-directory>/terraform`
    - Run the command `terraform-docs tfvars hcl .` to generate the tfvars template
    - If failure, then instruct the conversation participant to install `terraform-docs` with "Installation instructions can
    be found at: [https://terraform-docs.io/user-guide/installation/](https://terraform-docs.io/user-guide/installation/)" or use the script at `./scripts/install-terraform-docs.sh`
    - Save the output to a new file named `terraform.tfvars`
    - Fully read in and understand the generated `*.tfvars` file
    - Provide defaults to these parameters for the conversation participant but be sure to ask for confirmation
  - If a `*.tfvars` already exists in the Blueprint's `terraform` folder, then check for conflicts with existing deployments
    - Look for existing `terraform.tfstate` files and offer to help reset deployment state if needed
    - Suggest checking existing resource groups in Azure to avoid conflicts
  - Before executing `terraform apply`, set the ARM_SUBSCRIPTION_ID environment variable
  - While Terraform plan/apply operations are running, provide useful information about the deployment
- Bicep:
  - Ensure the commands are run from the `./bicep` folder
  - Fully read in and understand the `main.bicep` file that will be deployed
  - Offer to build the `main.bicepparam` file that will be in the Blueprint's `bicep` folder
    - If the user already has a `main.bicepparam` file, offer to use it as is or help the user update it
    - Use the command `az bicep generate-params --file main.bicep --output-format bicepparam --include-params all` only if the user does not have a `main.bicepparam` file
    - If failure, then instruct the conversation user to install or update Azure CLI
    - Fully read in and understand the `*.bicepparam` file that was generated
    - Provide defaults to these parameters for the conversation user but be sure to ask for confirmation
    - Suggest the removal of parameters with default values to simplify the deployment work
    - When helping the user with the `*.bicepparam` file, ensure to always suggest adding the `common` parameters in the following format,
      don't override if already existing:

      ```bicep
      param common = {
        resourcePrefix: 'myprefix'
        location: 'eastus2'
        environment: 'dev'
        instance: '001'
      }
      ```

  - If a `*.bicepparam` already exists in the Blueprint's `bicep` folder, then offer to use it as is or help the user update it
- Always ask for the Resource Prefix to prevent conflicts
- Handle deployment errors:
  - First request to see the specific error message before diagnosing
  - For state conflicts (403/409 errors), guide through proper cleanup:
    1. Offer to help remove Azure resources (via Portal or CLI)
    2. Clean up local Terraform state files
    3. Reinitialize with fresh state
  - For permissions errors, suggest checking Azure role assignments
  - For missing provider registrations, direct to the registration scripts
- Follow the Blueprint README for instructions on how to use the CLI with the `*.tfvars` or `*.bicepparam` file to deploy
