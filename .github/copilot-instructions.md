---
description: 'Comprehensive coding guidelines and instructions for edge ai - Brought to you by microsoft/edge-ai'
---

# General Instructions

Items in **HIGHEST PRIORITY** sections from attached instructions files override any conflicting guidance.

## **HIGHEST PRIORITY**

**Breaking changes:** Do not add backward-compatibility layers or legacy support unless explicitly requested. Breaking changes are acceptable.
**Artifacts:** Do not create or modify tests, scripts, or one-off markdown docs unless explicitly requested.
**Comment policy:** Never include thought processes, step-by-step reasoning, or narrative comments in code.
  - Keep comments brief and factual; describe **behavior/intent, invariants, edge cases**.
  - Remove or update comments that contradict the current behavior. Do not restate obvious functionality.
**Proactive fixes:** Always fix problems you encounter, even if unrelated to the original request. Prefer root-cause, constructive fixes over symptom-only patches.

### CRITICAL - Required Prompts & Instruction Compliance

**Context-first:** Evaluate the current user prompt, any attachments, target folders, repo conventions, and files already read.
**Discover & match (do this BEFORE any edit):**
  - Run `<search-for-prompts-files>` using the rules below (see table).
  - For each matched prompts/instructions/copilot file:
    - If it is NOT already provided as a full, non-summarized `<attachment>` in this conversation and NOT already fetched via `read_file`, then read it now.
    - Use read_file to **page through the entire file**: read **2,000 lines per call**; make additional calls until EOF.
    - If the file references other prompts/instructions/copilot files, **recursively read those** to completion under the same paging rule.
**Apply instructions:** Treat the union of all matched files as **HIGHEST PRIORITY** for this task.
**Re-check cadence:** Re-run discovery and re-read all matched instruction files if missing **before each major editing phase**.

<!-- <search-for-prompts-files> -->
## Prompts Files Search Process

When working with specific types of files or contexts, you must:

1. Detect patterns and contexts that match the predefined rules
2. Search for and read the corresponding prompts files
3. Read a minimum of 2000 lines from these files before proceeding with any changes

### Matching Patterns and Files for Prompts

| Pattern/Context                   | Required Prompts Files                                 |
|-----------------------------------|--------------------------------------------------------|
| Any deployment-related context    | `./.github/prompts/deploy.prompt.md`                   |
| Any getting started context       | `./.github/prompts/getting-started.prompt.md`          |
| Any pull request creation context | `./.github/prompts/pull-request.prompt.md`             |
| Any terraform context             | `./.github/instructions/terraform.instructions.md`     |
| Any bicep context                 | `./.github/instructions/bicep.instructions.md`         |
| Any shell or bash context         | `./.github/instructions/shell.instructions.md`         |
| Any bash in src context           | `./.github/instructions/bash.instructions.md`          |
| Any python context                | `./.github/instructions/python-script.instructions.md` |
| Any C# or csharp context          | `./.github/instructions/csharp.instructions.md`        |

<!-- </search-for-prompts-files> -->

<!-- <component-and-blueprint-structure> -->
## Component and Blueprint Structure Understanding

Components follow a decimal naming convention for deployment order and are organized into discrete, self-contained units with specific deployment patterns.
Blueprints orchestrate multiple components to create complete infrastructure solutions.

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
│   ├── README.md               # Generated document for component including variables and parameters (auto-generated, never edit)
│   ├── modules/                # Internal modules (component-scoped only)
│   └── tests/                  # Component tests
└── ci/                         # Minimal deployment configurations
    └── {framework}/            # CI-specific parameters
```

**Supported Frameworks**: `terraform`, `bicep`, `kubernetes`, `scripts`

### Blueprint Organization Structure

Blueprints are Infrastructure as Code composition mechanisms that combine multiple components into end-to-end deployable solutions.

```
blueprints/{solution_name}/
├── README.md                    # Blueprint documentation and deployment instructions
└── {framework}/                 # Framework-specific implementation
    ├── README.md               # Generated document for blueprint including variables and parameters (auto-generated, never edit)
    ├── main.{tf|bicep}         # Main orchestration file calling component modules
    ├── variables.{tf}          # Input parameter definitions with validation (Terraform only)
    ├── outputs.{tf|bicep}      # Blueprint-level outputs for integration
    ├── types.core.{bicep}      # Core type definitions (Bicep only)
    └── versions.tf             # Provider version constraints (Terraform only)
```

### Blueprint Framework Patterns

**Terraform Blueprints**:
- **Main Configuration**: Root module orchestrating component deployment with explicit dependency management
- **Module References**: Direct component source references using relative paths to `/src` components
- **State Management**: Local state by default, configurable for remote backends
- **Dependency Control**: Uses `depends_on` meta-argument for explicit ordering

**Bicep Blueprints**:
- **Main Configuration**: Orchestrates component modules with declarative dependency management
- **Type Definitions**: Shared type definitions such as `types.core.bicep` (duplicated) or `../../../src/{grouping}/{component}/bicep/types.bicep` for parameter consistency
- **Module References**: Component source references using relative paths to `/src` components
- **Dependency Control**: Uses `dependsOn` property for module deployment ordering

### Blueprint Conventions and Standards

**Common Parameter Object Pattern**:
- **Terraform**: Standard variables (`environment`, `resource_prefix`, `location`, `instance`) passed to all components
- **Bicep**: `Common` type object containing standardized properties for consistent resource naming (`environment`, `resource`, `location`, `instance`)
- **Conventions**:
  - Not all standard variables and parameters are required for each component and are then not required for each blueprint
  - Variables and parameters from components must match `name`, `description`, `type`, and `validation` exactly when provided in a blueprint
  - Sensible defaults should always be provided

**Blueprint Naming Convention**:
- **Descriptive Names**: Clear indication of deployment scope and architecture pattern
- **Hyphenated Format**: Use hyphens for multi-word blueprint names
- **Scope Indicators**: Include deployment scope (`single-node`, `multi-node`, `cloud-only`, `edge-only`)
- **Purpose Indicators**: Include deployment purpose (`full`, `minimum`, `partial`, `fabric-rti`)

**Blueprint Categories**:
- **Complete Deployments**: Full infrastructure solutions (`full-single-node-cluster`, `full-multi-node-cluster`)
- **Partial Deployments**: Subset of components (`only-cloud-single-node-cluster`, `only-edge-iot-ops`)
- **Specialized Solutions**: Domain-specific implementations (`fabric`, `fabric-rti`)
- **Utility Blueprints**: Script generation and development tools (`only-output-cncf-cluster-script`)

### Component Dependency Management

**Explicit Dependencies**:
- Terraform (*.tf): Use `depends_on` meta-argument when implicit dependencies are insufficient
- Bicep (*.bicep): Use `dependsOn` property for modules requiring specific deployment ordering
- **Resource Dependencies**: Components declare dependencies via input parameter requirements
- **Output Dependencies**: Components expose required outputs for dependent component consumption

**Inter-Component Communication Patterns**:
1. **Module Output to Input**: Primary component outputs become input parameters for dependent components
2. **Existing Resource**:
  - Terraform (*.tf): `data` resources passed as-is into component modules as inputs
  - Bicep (*.bicep): Resource name and scope used for `existing` Bicep resources, name passed to component modules for existing resources.
3. **Resource Reference Passing**:
  - Terraform (*.tf): Resource objects, IDs, and configurations passed via output references as objects, typically defined in variables.dep.tf as dependency variables
  - Bicep (*.bicep): Resource name and scope. Always avoid passing resource ID

**Component Dependency Analysis**:
1. **Blueprint and CI Impact Analysis**: Use `grep_search` with `includePattern: "**/{blueprints,ci}/**/{framework}/**"` to find component references
3. **Output Reference Analysis**: Use `grep_search` with `includePattern: "src/**"` to find output usage patterns

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

**Internal Module Organization**:
- **Component-Scoped Modules**: Internal modules organized under `{component}/{framework}/modules/`
- **Functionality Grouping**: Related functionality grouped into logical internal modules
- **Output Abstraction**: Component main module abstracts internal module complexity via outputs
- **Testing Isolation**: Internal module tests contained within component test suites

### Blueprint Layering and Composition

**Blueprint Layering Support**:
- **Incremental Deployment**: Blueprints can be applied on top of existing infrastructure
  - Terraform (*.tf): Use `data` resources to reference resources from previously deployed blueprints
  - Bicep (*.bicep): Provide `name` parameters (and name of scope when needed) to reference resources from previously deployed blueprints
- **Parameters and Variables**: Provide the same parameters and variables from previously deployed blueprints to layer a blueprint deployment

**Composition Examples**:
- **Base + Extension**: Deploy `full-single-node-cluster` then layer `fabric-rti` for additional capabilities
- **Partial + Complete**: Start with `only-cloud-single-node-cluster` then add edge components
- **Combine Blueprints**: Build new blueprints by copying from existing blueprints

### Deployment Patterns

**CI Deployment** (Minimal Configuration):
- **Location**: `{component}/ci/{framework}/`
- **Purpose**: Contains minimum required parameters for component deployment
- **Usage**: For individual component testing and basic deployments

**Blueprint Deployment** (Complete Solutions):
- **Location**: `/blueprints/{solution_name}/{framework}/`
- **Purpose**: Orchestrates multiple components for end-to-end solutions
- **Usage**: For full or partial environment provisioning. Blueprints can be layered on top of each others (e.g. `blueprints/fabric-rti` can be applied after a `blueprints/full-single-node-cluster` with matching variables and parameters)
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
<!-- </component-and-blueprint-structure> -->

<!-- <npm-scripts> -->
## NPM Package Scripts

You will use the `npm` scripts from `package.json` when needed for the following (not limited to):
- `npm run tf-docs` and `npm run bicep-docs`: Generating README.md documentation under the `src/` folder
- `npm run tf-validate` and `npm run tflint-fix`: Any Terraform linting, formatting, or validation
- `npm run mdlint-fix`: Fixing Markdown formatting or linting; excluding (don't use for) `.copilot-tracking`, `.github`, `node_modules`, and `venv` folders
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

### Terraform Validation and Testing Steps

Final steps for ONLY terraform changes:
  - You will ITERATE with `npm run tf-validate` and `npm run tflint-fix` and fix all issues, continue to iterate until all issues are fixed
  - You will generate docs with `npm run tf-docs` and `npm run mdlint-fix`
  - You will NEVER add any tests unless specifically asked to add tests
    - All tests must ONLY EVER be for `command = plan` tests

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

### Important Repository Structure Tree

```plaintext
edge-ai/                                       # Root directory for Edge AI Accelerator project
├── .azdo/                                     # Azure DevOps pipeline configurations and automation scripts for CI/CD
├── .azure/                                    # Azure CLI configuration and cached authentication data
├── .cargo/                                    # Rust package manager configuration and build settings
├── .checkov.yml                               # Security and compliance scanning configuration for infrastructure code
├── .copilot-tracking/                         # GitHub Copilot workspace tracking and conversation history (workspace excluded)
├── .cspell-dictionary.txt                     # Custom dictionary words for spell checking
├── .cspell.json                               # Spell checker configuration for documentation and code quality
├── .devcontainer/                             # Development container configuration for VS Code remote development
├── .git/                                      # Git version control system metadata and configuration
├── .gitattributes                             # Git attributes configuration for file handling and line endings
├── .github/                                   # GitHub Actions workflows, issue templates, prompts, instructions, chatmodes, and repository automation
├── .gitignore                                 # Git ignore patterns to exclude files from version control
├── .markdownlint.json                         # Markdown linting rules and configuration for documentation standards
├── .mega-linter.yml                           # Multi-language linter configuration for code quality enforcement
├── .npmrc                                     # Node.js package manager configuration and registry settings
├── .terraform-docs.yml                        # Terraform documentation generation configuration and templates for terraform-docs
├── .terrascan.toml                            # Infrastructure security scanning configuration for Terraform
├── .vscode/                                   # Visual Studio Code workspace settings and extension recommendations
├── azure-pipelines.yml                        # Azure DevOps pipeline definition for CI/CD automation
├── bicepconfig.json                           # Bicep configuration file for Azure Resource Manager template settings including enabling experimental settings
├── blueprints/                                # Complete end-to-end infrastructure deployments combining multiple components
│   ├── README.md                              # Overview and usage instructions for blueprint deployments
│   ├── dual-peered-single-node-cluster/       # Dual-peered single node cluster deployment configuration for two clusters
│   ├── fabric/                                # Microsoft Fabric Only deployment blueprint
│   ├── fabric-rti/                            # Microsoft Fabric Real-Time Intelligence Only deployment blueprint
│   ├── full-arc-multi-node-cluster/           # Complete Arc-enabled multi-node cluster deployment
│   ├── full-multi-node-cluster/               # Complete multi-node cluster deployment without Arc-enabled for Servers requirements
│   ├── full-single-node-cluster/              # Complete single-node cluster deployment with all non-Fabric components
│   ├── minimum-single-node-cluster/           # Minimal single-node cluster deployment
│   ├── only-cloud-single-node-cluster/        # Cloud-only components for a single-node cluster deployment
│   ├── only-edge-iot-ops/                     # Edge-only IoT Operations only deployment
│   ├── only-output-cncf-cluster-script/       # Edge-only CNCF cluster script generation only deployment
│   └── partial-single-node-cluster/           # Partial cloud components and edge cncfe single-node cluster only deployment
├── Cargo.toml                                 # Rust workspace configuration defining package members and dependencies
├── CODE_OF_CONDUCT.md                         # Community guidelines and behavioral expectations for contributors
├── CONTRIBUTING.md                            # Guidelines and instructions for contributing to the project
├── copilot/                                   # GitHub Copilot instruction files and coding standards for different technologies
├── deploy/                                    # Deployment automation scripts and configuration for this edge-ai project
├── GitVersion.yml                             # Semantic versioning configuration for automated version management
├── LICENSE                                    # Legal license terms governing the use and distribution of the project
├── package.json                               # Node.js project configuration with scripts and dependencies for tooling
├── package-lock.json                          # Node.js dependency lock file for reproducible builds
├── PSScriptAnalyzerSettings.psd1              # PowerShell script analysis configuration and rule settings
├── README.md                                  # Main project documentation with overview and getting started instructions
├── requirements.txt                           # Python dependencies for project tooling and automation scripts
├── scripts/                                   # Utility scripts for automation, testing, and maintenance tasks
├── SECURITY.md                                # Security policy and vulnerability reporting guidelines
├── src/                                       # Core infrastructure as code components organized by deployment location
│   ├── README.md                              # Overview of source components and deployment patterns
│   ├── 000-cloud/                             # Cloud Infrastructure Components (000-099 range)
│   │   ├── README.md                          # Cloud components overview and deployment guidance
│   │   ├── 000-resource-group/                # Resource group provisioning and management for all Azure resources
│   │   ├── 010-security-identity/             # Identity and security infrastructure including Key Vault, managed identities, and RBAC
│   │   ├── 020-observability/                 # Cloud-side monitoring, logging, and observability resources
│   │   ├── 030-data/                          # Data storage, Schema Registry, and data management resources
│   │   ├── 031-fabric/                        # Microsoft Fabric resources for data warehousing and analytics
│   │   ├── 032-fabric-rti/                    # Microsoft Fabric Real-Time Intelligence resources
│   │   ├── 040-messaging/                     # Event Grid, Event Hubs, Service Bus, and messaging infrastructure
│   │   ├── 050-networking/                    # Virtual networks, subnets, and network security configurations
│   │   ├── 051-vm-host/                       # Virtual machine provisioning with configurable host operating systems
│   │   ├── 060-acr/                           # Azure Container Registry for container image management
│   │   ├── 070-kubernetes/                    # Kubernetes cluster configuration and management resources
│   │   └── 080-azureml/                       # Azure Machine Learning workspace and compute resources
│   ├── 100-edge/                              # Edge Infrastructure Components (100-199 range)
│   │   ├── README.md                          # Edge components overview and deployment guidance
│   │   ├── 100-cncf-cluster/                  # CNCF-compliant cluster installation (K3s) with Arc enablement and workload identity
│   │   ├── 110-iot-ops/                       # Azure IoT Operations core infrastructure deployment (MQ Broker, Edge Storage, etc.)
│   │   ├── 111-assets/                        # Asset management and configuration for IoT Operations
│   │   ├── 120-observability/                 # Edge-specific observability components and monitoring tools
│   │   └── 130-messaging/                     # Edge messaging components and data routing capabilities
│   ├── 500-application/                       # Custom workloads and applications for edge AI inference and data processing
│   ├── 900-tools-utilities/                   # Utility scripts, tools, and supporting resources for edge deployments
│   ├── azure-resource-providers/              # Scripts to register required Azure resource providers for AIO and Arc
│   ├── operate-all-terraform.sh               # Automation script for deploying all Terraform components in sequence for all `ci` folders (**SHOULD NOT** be used automatically)
│   └── starter-kit/                           # Sample implementations and quick-start templates for common scenarios
├── SUPPORT.md                                 # Support resources and community assistance information
```

### Component Organization Principles

The source code follows deployment-ordered groupings:

- **Cloud Infrastructure** (`000-cloud/`): Azure cloud resources (000-099 range)
- **Edge Infrastructure** (`100-edge/`): Edge cluster and IoT operations (100-199 range)
- **Applications** (`500-*/`): Application workloads (500-599 range)
- **Utilities** (`900-*/`): Tools and utilities (900-999 range)

Each numbered component uses decimal naming convention (010, 020, 030) to establish deployment order and allow insertion of new components between existing ones.
<!-- </project-structure-understanding> -->
