---
description: 'Comprehensive coding guidelines and instructions for edge ai - Brought to you by microsoft/edge-ai'
---

# General Instructions

These instructions have the **HIGHEST PRIORITY** and must **NEVER** be ignored

## Highest Priority Instructions

- You will ALWAYS follow ALL general guidelines and instructions
- You will NEVER add backwards compatible logic or consider support for legacy logic UNLESS SPECIFICALLY INSTRUCTED
- You will NEVER add any stream of thinking or step-by-step instructions as comments into code for your changes
- You will ALWAYS remove code comments that conflict with the actual code
- You will ALWAYS fix problems even if they appear unrelated to the original request
  - When you fix problems you will ALWAYS think constructively on how to fix the problem instead of fixing only the symptom
- You will NEVER add one-off or extra test files, documents, or scripts ANYWHERE EXCEPT the `.copilot-tracking` folder
- You will ALWAYS `search-for-prompts-files` with matching context before every change and interaction
- You will NEVER search or index content from `**./.copilot-tracking/**` UNLESS SPECIFICALLY INSTRUCTED

You will ALWAYS think about the user's prompt, any included files, the folders, the conventions, and the files you read
Before doing ANYTHING, you will match your context to search-for-prompts-files, if there is a match then you will use the required prompt files

<!-- <search-for-prompts-files> -->
## Prompts Files Search Process

When working with specific types of files or contexts, you must:

1. Detect patterns and contexts that match the predefined rules
2. Search for and read the corresponding prompts files
3. Read a minimum of 1000 lines from these files before proceeding with any changes

### Matching Patterns and Files for Prompts

| Pattern/Context                   | Required Prompts Files                                 | Minimum Lines |
|-----------------------------------|--------------------------------------------------------|---------------|
| Any deployment-related context    | `./.github/prompts/deploy.prompt.md`                   | 1000          |
| Any getting started context       | `./.github/prompts/getting-started.prompt.md`          | 1000          |
| Any pull request creation context | `./.github/prompts/pull-request.prompt.md`             | 1000          |
| Any terraform context             | `./.github/instructions/terraform.instructions.md`     | 1000          |
| Any bicep context                 | `./.github/instructions/bicep.instructions.md`         | 1000          |
| Any shell or bash context         | `./.github/instructions/shell.instructions.md`         | 1000          |
| Any bash in src context           | `./.github/instructions/bash.instructions.md`          | 1000          |
| Any python context                | `./.github/instructions/python-script.instructions.md` | 1000          |
| Any C# or csharp context          | `./.github/instructions/csharp.instructions.md`        | 1000          |

<!-- </search-for-prompts-files> -->

<!-- <component-structure> -->
## Component Structure Understanding

Components follow a decimal naming convention for deployment order and are organized into discrete, self-contained units with specific deployment patterns.

### Grouping Organization

Components are organized in deployment-ordered groupings:

- **Template**: `**/src/{000}-{grouping_name}/**`
- **Cloud Infrastructure**: `**/src/000-cloud/**` - Azure cloud resources (000-099 range)
- **Edge Infrastructure**: `**/src/100-edge/**` - Edge cluster and IoT operations (100-199 range)
- **Applications**: `**/src/500-***/**` - Application workloads (500-599 range)
- **Utilities**: `**/src/900-***/**` - Tools and utilities (900-999 range)

### Component Organization Structure

Each component follows this mandatory directory structure:

```
{grouping}/{000}-{component_name}/
├── README.md                    # Component documentation and usage
├── {framework}/                 # Implementation (terraform, bicep, etc.)
│   ├── modules/                # Internal modules (component-scoped only)
│   └── tests/                  # Component tests
└── ci/                         # Minimal deployment configurations
    └── {framework}/            # CI-specific parameters
```

**Supported Frameworks**: `terraform`, `bicep`, `kubernetes`, `scripts`

### Decimal Naming Convention

- **Purpose**: Establishes deployment order and logical grouping
- **Format**: `{000}-{component_name}` where numbers indicate sequence
- **Increment**: Use 10-number increments (010, 020, 030) to allow insertion of new components
- **Examples**: `010-security-identity`, `020-observability`, `030-data`

### Internal Modules Management

**Module Isolation Rules**:
1. **NEVER reference internal modules from outside their parent component**
2. **ALWAYS use component outputs to share functionality with other components**
3. **CREATE reusable functionality through component outputs, not direct module access**

### Component Dependencies and Data Flow

**Inter-Component Communication**:
1. **Use component outputs as inputs to dependent components**
2. **Reference outputs via data sources or variable passing**
3. **Document dependencies in component README.md**

### Deployment Patterns

**CI Deployment** (Minimal Configuration):
- **Location**: `{component}/ci/{framework}/`
- **Purpose**: Contains minimum required parameters for component deployment
- **Usage**: For individual component testing and basic deployments

**Blueprint Deployment** (Complete Solutions):
- **Location**: `/blueprints/{solution_name}/{framework}/`
- **Purpose**: Orchestrates multiple components for end-to-end solutions
- **Usage**: For full environment provisioning
- **Component Integration**: References component outputs as blueprint inputs

### Component Modification Workflow

When modifying any component, follow this validation sequence:

1. **Component Impact Analysis**:
   - Use `grep_search` to find component references in blueprints with `includePattern: "blueprints/**"`
   - Use `grep_search` to find output references in source components with `includePattern: "src/**"`
   - Use `semantic_search` to identify related dependencies in src and blueprints

2. **Update Validation Checklist**:
   - [ ] Component outputs are never required to be backward compatible - breaking changes must be fixed in other components and blueprints
   - [ ] Internal module changes can break component functionality as long as it is addressed
   - [ ] Component README.md should reflect what the component itself does, not interface changes
   - [ ] Never update the framework README.md or internal module README.md as those will ALWAYS be generated
   - [ ] CI deployment configuration updated with any new required parameters
   - [ ] Dependent blueprints updated to handle any breaking changes

### Reference Components

**Well-structured Examples**:
- **Security Foundation**: `/src/000-cloud/010-security-identity/`
- **Edge IoT Operations**: `/src/100-edge/110-iot-ops/`
- **Complete Blueprint**: `/blueprints/full-single-node-cluster/`

Use these as templates when creating new components or understanding expected patterns.
<!-- </component-structure> -->

<!-- <npm-scripts> -->
## NPM Package Scripts

You will use the `npm` scripts from #file:../package.json when needed for the following (not limited to):
- Generating README.md documentation under the `src/` folder
- Any Terraform linting, formatting, or validation
- Fixing Markdown formatting or linting
<!-- </npm-scripts> -->

<!-- <terraform-operations> -->
## Terraform Operations Requirements

### Azure Subscription Initialization

Before running any Terraform operations, you must initialize the Azure subscription environment by sourcing the initialization script:

```bash
source ./scripts/az-sub-init.sh
```

This script:
- Ensures you are logged into Azure with the correct tenant
- Sets the required `ARM_SUBSCRIPTION_ID` environment variable for Terraform
- Handles authentication and subscription context automatically

### Required Before Terraform Commands

The Azure subscription initialization is **MANDATORY** before running any of these Terraform commands:

- `terraform validate` - Validate Terraform configuration syntax
- `terraform test` - Run Terraform tests
- `terraform plan` - Preview infrastructure changes
- `terraform apply` - Apply infrastructure changes
- `terraform destroy` - Remove infrastructure resources

### Optional Tenant Specification

If working with a specific Azure tenant, specify it during initialization:

```bash
source ./scripts/az-sub-init.sh --tenant your-tenant.onmicrosoft.com
```
<!-- </terraform-operations> -->

<!-- <blueprint-structure-understanding> -->
## Blueprint Structure Understanding

Blueprints contain sets of components for deploying stamps of IaC:

### Blueprint Organization

- Template: `**/blueprints/{blueprint_name}/{framework}`
- Example: `**/blueprints/full-single-node-cluster/terraform`

### Blueprint Conventions

- Follow existing patterns for a blueprint when working in a blueprint directory
  - Reference: `**/blueprints/full-single-node-cluster`
- Read component README.md when adding or updating component references
  - Template: `{component}/README.md`
- Use outputs from components as inputs to other components
<!-- </blueprint-structure-understanding> -->

<!-- <project-structure-understanding> -->
## Project Structure Understanding

The Edge AI Accelerator is organized into discrete categories optimized for enterprise deployments of Arc-enabled Azure IoT Operations solutions.

### Root Directory Structure

#### Configuration Files

| File                            | Description                                                             |
|---------------------------------|-------------------------------------------------------------------------|
| `.checkov.yml`                  | Security and compliance scanning configuration for infrastructure code  |
| `.cspell.json`                  | Spell checker configuration for documentation and code quality          |
| `.gitattributes`                | Git attributes configuration for file handling and line endings         |
| `.gitignore`                    | Git ignore patterns to exclude files from version control               |
| `.markdownlint.json`            | Markdown linting rules and configuration for documentation standards    |
| `.mega-linter.yml`              | Multi-language linter configuration for code quality enforcement        |
| `.npmrc`                        | Node.js package manager configuration and registry settings             |
| `.terraform-docs.yml`           | Terraform documentation generation configuration and templates          |
| `.terrascan.toml`               | Infrastructure security scanning configuration for Terraform            |
| `azure-pipelines.yml`           | Azure DevOps pipeline definition for CI/CD automation                   |
| `bicepconfig.json`              | Bicep configuration file for Azure Resource Manager template settings   |
| `Cargo.toml`                    | Rust workspace configuration defining package members and dependencies  |
| `GitVersion.yml`                | Semantic versioning configuration for automated version management      |
| `package.json`                  | Node.js project configuration with scripts and dependencies for tooling |
| `PSScriptAnalyzerSettings.psd1` | PowerShell script analysis configuration and rule settings              |
| `requirements.txt`              | Python dependencies for project tooling and automation scripts          |

#### Documentation and Project Files

| File                 | Description                                                               |
|----------------------|---------------------------------------------------------------------------|
| `CODE_OF_CONDUCT.md` | Community guidelines and behavioral expectations for contributors         |
| `CONTRIBUTING.md`    | Guidelines and instructions for contributing to the project               |
| `index.html`         | Project homepage for documentation hosting and navigation                 |
| `LICENSE`            | Legal license terms governing the use and distribution of the project     |
| `README.md`          | Main project documentation with overview and getting started instructions |
| `robots.txt`         | Web crawler instructions for documentation site indexing                  |
| `SECURITY.md`        | Security policy and vulnerability reporting guidelines                    |
| `sitemap.xml`        | Site map for documentation website navigation and SEO                     |
| `SUPPORT.md`         | Support resources and community assistance information                    |

#### Directories

| Directory                 | Description                                                                                            |
|---------------------------|--------------------------------------------------------------------------------------------------------|
| `.azdo/`                  | Azure DevOps pipeline configurations and automation scripts for CI/CD                                  |
| `.cargo/`                 | Rust package manager configuration and build settings                                                  |
| `.copilot-tracking/`      | GitHub Copilot workspace tracking and conversation history (restricted access)                         |
| `.devcontainer/`          | Development container configuration for VS Code remote development                                     |
| `.git/`                   | Git version control system metadata and configuration                                                  |
| `.github/`                | GitHub Actions workflows, issue templates, prompts, instructions, chatmodes, and repository automation |
| `.vscode/`                | Visual Studio Code workspace settings and extension recommendations                                    |
| `blueprints/`             | Complete end-to-end infrastructure deployment templates combining multiple components                  |
| `copilot/`                | GitHub Copilot instruction files and coding standards for different technologies                       |
| `deploy/`                 | Deployment automation scripts and configuration for various environments                               |
| `docs/`                   | Project documentation, guides, and technical specifications                                            |
| `praxisworx/`             | Learning and training materials, including katas and skill assessments                                 |
| `project-adrs/`           | Architecture Decision Records documenting technical decisions and rationale                            |
| `project-security-plans/` | Security planning templates and compliance checklists                                                  |
| `scripts/`                | Utility scripts for automation, testing, and maintenance tasks                                         |
| `src/`                    | Core infrastructure as code components organized by deployment location                                |

### Source Directory Structure (src/)

The source code is organized into discrete categories optimized for enterprise deployments, grouped by deployment location and purpose.

#### Cloud Infrastructure (000-cloud)

| Component                | Description                                                                            |
|--------------------------|----------------------------------------------------------------------------------------|
| `000-resource-group/`    | Resource group provisioning and management for all Azure resources                     |
| `010-security-identity/` | Identity and security infrastructure including Key Vault, managed identities, and RBAC |
| `020-observability/`     | Cloud-side monitoring, logging, and observability resources                            |
| `030-data/`              | Data storage, Schema Registry, and data management resources                           |
| `031-fabric/`            | Microsoft Fabric resources for data warehousing and analytics                          |
| `040-messaging/`         | Event Grid, Event Hubs, Service Bus, and messaging infrastructure                      |
| `050-networking/`        | Virtual networks, subnets, and network security configurations                         |
| `051-vm-host/`           | Virtual machine provisioning with configurable host operating systems                  |
| `052-arc-servers/`       | Azure Arc-enabled server configuration and management                                  |
| `060-acr/`               | Azure Container Registry for container image management                                |
| `070-kubernetes/`        | Kubernetes cluster configuration and management resources                              |

#### Edge Infrastructure (100-edge)

| Component               | Description                                                                         |
|-------------------------|-------------------------------------------------------------------------------------|
| `100-cncf-cluster/`     | CNCF-compliant cluster installation (K3s) with Arc enablement and workload identity |
| `101-deploy-script/`    | Automated deployment scripts for edge cluster provisioning                          |
| `102-workload-mgmt/`    | Workload management and orchestration for edge computing environments               |
| `110-iot-ops/`          | Azure IoT Operations core infrastructure deployment (MQ Broker, Edge Storage, etc.) |
| `111-assets/`           | Asset management and configuration for IoT Operations                               |
| `120-observability/`    | Edge-specific observability components and monitoring tools                         |
| `130-messaging/`        | Edge messaging components and data routing capabilities                             |
| `140-model-management/` | Machine learning model deployment and management at the edge                        |

#### Applications & Utilities

| Component                   | Description                                                                 |
|-----------------------------|-----------------------------------------------------------------------------|
| `500-application/`          | Custom workloads and applications for edge AI inference and data processing |
| `500-basic-inference/`      | Basic machine learning inference pipeline implementation                    |
| `501-rust-telemetry/`       | Rust-based telemetry collection and processing services                     |
| `502-rust-http-connector/`  | HTTP connector implementation in Rust for edge communications               |
| `900-tools-utilities/`      | Utility scripts, tools, and supporting resources for edge deployments       |
| `900-mqtt-tools/`           | MQTT messaging tools and utilities for IoT communications                   |
| `azure-resource-providers/` | Scripts to register required Azure resource providers for AIO and Arc       |
| `starter-kit/`              | Sample implementations and quick-start templates for common scenarios       |

### Additional Directories

| Directory                  | Description                                                                                                                      |
|----------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| `operate-all-terraform.sh` | Automation script for deploying all Terraform components in sequence for all `ci` folders (**SHOULD NOT** be used automatically) |
<!-- </project-structure-understanding> -->

<!-- <workspace-search-restrictions> -->
## Workspace Search Restrictions

To focus on relevant code areas, the following search restrictions apply:

### Allowed Search Directories

Search operations using `semantic_search`, `file_search`, `list_dir`, `grep_search`, and similar tools are **ONLY** permitted in:

- `blueprints/` - Infrastructure deployment templates and configurations
- `scripts/` - Utility and automation scripts
- `src/` - Core infrastructure as code components

### Required Directory Specification

When using search tools, you **MUST** specify the exact directories to search within using the appropriate parameters. Do not perform workspace-wide searches without directory restrictions.

**Required Tools Usage:**

- `semantic_search`: Use the query parameter with specific directory context
- `file_search`: Use specific directory patterns (e.g., `blueprints/**`, `src/**`, `scripts/**`)
- `list_dir`: Always specify the exact path parameter
- `grep_search`: Always use the `includePattern` parameter to restrict searches to allowed directories

### Example Tool Usage

```javascript
// CORRECT: Search within allowed directories
file_search({
  query: "src/**/*.tf"  // Searches only in src directory
})

grep_search({
  query: "terraform",
  includePattern: "blueprints/**",  // Restricts search to blueprints directory
  isRegexp: false
})

list_dir({
  path: "/workspaces/edge-ai/scripts"  // Specific directory path
})

semantic_search({
  query: "terraform module configuration in src components"  // Context implies src directory focus
})

// INCORRECT: Workspace-wide searches without directory specification
file_search({
  query: "*.tf"  // Too broad, searches entire workspace
})

grep_search({
  query: "terraform",
  isRegexp: false  // Missing includePattern restriction
})
```

### Restricted Directories

The following directories should **NOT** be included in search patterns unless contextually implied:

- `.azdo/` - Azure DevOps CI/CD pipelines and templates
- `.github/workflows` - GitHub CI/CD workflows and actions
- `docs/` - Documentation
- `praxisworx/` - Training materials
- `project-adrs/` - Architecture decisions
- `project-security-plans/` - Security planning

### Contextual Search Authorization

Searches in restricted directories are **ALLOWED** when the context implies the user is working within those directories:

- **Attached Files**: When the user has attached files from a restricted directory, searches within that directory are permitted
- **Current File Context**: When the user is currently editing or working in a file within a restricted directory, searches within that directory are permitted
- **Modification Requests**: When the user asks to create, modify, or work with files in a restricted directory, searches within that directory are permitted
<!-- </workspace-search-restrictions> -->

## Markdown Formatting Requirements

NEVER follow this section for ANY `.copilot-tracking/` files.

- Before any edits you will read required linting rules from #file:../.mega-linter.yml in the workspace root
- Read `.mega-linter.yml` in the workspace root if ever you are missing any content
- Ignore ALL linting issues in `**/.copilot-tracking/**`

When editing markdown files (excluding `**/.copilot-tracking/**` markdown files):

- Always follow rules from `.mega-linter.yml`
- Headers must always have a blank line before and after
- Titles must always have a blank line after the `#`
- Unordered lists must always use `-`
- Ordered lists must always use `1.`
- Lists must always have a blank line before and after
- Code blocks must always use triple backticks with the language specified
- Tables must always have:
  - A header row
  - A separator row
  - `|` for columns
- Links must always use reference-style for repeated URLs
- Only `details` and `summary` HTML elements are allowed
