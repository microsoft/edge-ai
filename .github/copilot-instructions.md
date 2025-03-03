# Copilot Instructions

This is a large multi-faceted repo, so as you work in it, help the user ramp up by:

- Add links and short tips and explanations where it would help the user learn the organization of the repo or the structure of the deployed solution.
- Never guess or assume default options or parameters. Instead ask the user questions needed, provide a suggested set of defaults, but confirm these with the user (with alternatives where appropriate).

## Deploy the Solution (via a Blueprint)

- You can assist deploying the solution by running through the instructions from [the Blueprint README](../blueprints/README.md). (Use this carefully step-by-step and refer back to it as you go). Guidance for running the deployment:

- You will be using the Azure CLI to build a `terraform.tfvars` using Azure CLI to get the required info
- For a learning/sandbox deployment, the 'single-full-cluster' deployment is a good default, but please ask.
- For `resource-prefix` always ask the user what to use here (this ensures multiple deployments in the same RG won't conflict).
- The code in the repo works for a normal deployment. Do not modify any repo files during an assisted deployment. If there are issues with Azure Login/AAD, they are likely config issues.
- If running a CLI operation with an input prompt (e.g. Terraform operation with args that aren't in tf vars), fill these into the CLI so the shell operation doesn't prompt.

## Build a new Component

- Components are defined in the [src](../src/) directory. [Components README](../src/README.md). To create a new component, follow the examples in this folder.

## Build a new Blueprint

- Blueprints are defined in the [blueprints](../blueprints/) directory. [Blueprints README](../blueprints/README.md). Use an existing Blueprint as a starting point, usually [full-single-cluster](../blueprints/terraform/full-single-cluster/) and add/remove as needed.
- When building a new Blueprint, use the existing building blocks in `/src`.

## Terraform

- Always do a `terraform plan` before running `apply`.
- Always run `terraform fmt` to maintain consistent code formatting for project files (.gitignored files like tfvars files excluded).
- Organize infrastructure resources into reusable modules.
- Use versioned modules and provider version locks to ensure consistent deployments.
- Use `terraform state` commands to inspect, move, or remove resources in the state when necessary.
- Run `terraform refresh` to ensure that state reflects the current infrastructure.
- When building reusable modules (in the `/src` folder), always write tests in a `test` directory of the main terraform module.
