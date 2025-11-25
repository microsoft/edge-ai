---
description: 'Comprehensive coding guidelines and instructions for edge ai - Brought to you by microsoft/edge-ai'
---

# General Instructions

Items in **HIGHEST PRIORITY** sections from attached instructions files override any conflicting guidance.

## **HIGHEST PRIORITY**

**Breaking changes:** Do not add backward-compatibility layers or legacy support unless explicitly requested. Breaking changes are acceptable.

**Artifacts:** Do not create or modify tests, scripts, or one-off markdown docs unless explicitly requested.

**Comment policy:** Never include thought processes, step-by-step reasoning, or narrative comments in code.
* Keep comments brief and factual; describe **behavior/intent, invariants, edge cases**.
* Remove or update comments that contradict the current behavior. Do not restate obvious functionality.
* Do NOT add temporal or plan-phase markers (e.g. "Phase 1 cleanup", "... after migration", dates, or task references) to code files. When editing or updating any code files, always remove or replace these types of comments.

**Conventions and Styling:** Always follow conventions and styling in this codebase FIRST for all changes, edits, updates, and new files.
* Conventions and styling are in instruction files and must be read in with the `read_file` tool if not already added as an `<attachment>`.

**Proactive fixes:** Always fix problems and errors you encounter, even if unrelated to the original request. Prefer root-cause, constructive fixes over symptom-only patches.
* Always correct conventions and styling and comments.

**Deleting files and folders:** Use `rm` with the run_in_terminal tool when needing to delete files or folders.

**Edit tools:** Never use `insert_edit_into_file` tool when other edit and file modification tools are available.

### CRITICAL - Required Prompts & Instruction Compliance

**Context-first:** Evaluate the current user prompt, any attachments, target folders, repo conventions, and files already read.

**Discover & match (do this BEFORE any edit):**
* Run `<search-for-prompts-files>` using the rules below (see table).
* For each matched prompts/instructions/copilot file:
  * If it is NOT already provided as a full, non-summarized `<attachment>` in this conversation and NOT already fetched via `read_file`, then read it now.
  * Use read_file to **page through the entire file**: read **2,000 lines per call**; make additional calls until EOF.
  * If the file references other prompts/instructions/copilot files, **recursively read those** to completion under the same paging rule.

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

* **Template**: `**/src/{000}-{grouping_name}/**`
* **Cloud Infrastructure**: `**/src/000-cloud/**` - Azure cloud resources (000-099 range)
* **Edge Infrastructure**: `**/src/100-edge/**` - Edge cluster and IoT operations (100-199 range)
* **Applications**: `**/src/500-***/**` - Application workloads (500-599 range)
* **Utilities**: `**/src/900-***/**` - Tools and utilities (900-999 range)

### Component Organization Structure Template

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

### Blueprint Organization Structure Template

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
* **Main Configuration**: Root module orchestrating component deployment with explicit dependency management
* **Module References**: Direct component source references using relative paths to `/src` components
* **State Management**: Local state by default, configurable for remote backends
* **Dependency Control**: Uses `depends_on` meta-argument for explicit ordering

**Bicep Blueprints**:
* **Main Configuration**: Orchestrates component modules with declarative dependency management
* **Type Definitions**: Shared type definitions such as `types.core.bicep` (duplicated) or `../../../src/{grouping}/{component}/bicep/types.bicep` for parameter consistency
* **Module References**: Component source references using relative paths to `/src` components
* **Dependency Control**: Uses `dependsOn` property for module deployment ordering

### Blueprint Conventions and Standards

**Common Parameter Object Pattern**:
* **Terraform**: Standard variables (`environment`, `resource_prefix`, `location`, `instance`) passed to all components
* **Bicep**: `Common` type object containing standardized properties for consistent resource naming (`environment`, `resource`, `location`, `instance`)
* **Conventions**:
  * Not all standard variables and parameters are required for each component and are then not required for each blueprint
  * Variables and parameters from components must match `name`, `description`, `type`, and `validation` exactly when provided in a blueprint
  * Sensible defaults should always be provided

**Blueprint Naming Convention**:
* **Descriptive Names**: Clear indication of deployment scope and architecture pattern
* **Hyphenated Format**: Use hyphens for multi-word blueprint names
* **Scope Indicators**: Include deployment scope (`single-node`, `multi-node`, `cloud-only`, `edge-only`)
* **Purpose Indicators**: Include deployment purpose (`full`, `minimum`, `partial`, `fabric-rti`)

**Blueprint Categories**:
* **Complete Deployments**: Full infrastructure solutions (`full-single-node-cluster`, `full-multi-node-cluster`)
* **Partial Deployments**: Subset of components (`only-cloud-single-node-cluster`, `only-edge-iot-ops`)
* **Specialized Solutions**: Domain-specific implementations (`fabric`, `fabric-rti`)
* **Utility Blueprints**: Script generation and development tools (`only-output-cncf-cluster-script`)

### Component Dependency Management

**Explicit Dependencies**:
* Terraform (*.tf): Use `depends_on` meta-argument when implicit dependencies are insufficient
* Bicep (*.bicep): Use `dependsOn` property for modules requiring specific deployment ordering
* **Resource Dependencies**: Components declare dependencies via input parameter requirements
* **Output Dependencies**: Components expose required outputs for dependent component consumption

**Inter-Component Communication Patterns**:
1. **Module Output to Input**: Primary component outputs become input parameters for dependent components
2. **Existing Resource**:
  * Terraform (*.tf): `data` resources passed as-is into component modules as inputs
  * Bicep (*.bicep): Resource name and scope used for `existing` Bicep resources, name passed to component modules for existing resources.
3. **Resource Reference Passing**:
  * Terraform (*.tf): Resource objects, IDs, and configurations passed via output references as objects, typically defined in variables.dep.tf as dependency variables
  * Bicep (*.bicep): Resource name and scope. Always avoid passing resource ID

**Component Dependency Analysis**:
1. **Blueprint and CI Impact Analysis**: Use `grep_search` with `includePattern: "**/{blueprints,ci}/**/{framework}/**"` to find component references
3. **Output Reference Analysis**: Use `grep_search` with `includePattern: "src/**"` to find output usage patterns

### Decimal Naming Convention

* **Purpose**: Establishes deployment order and logical grouping
* **Format**: `{000}-{component_name}` where numbers indicate sequence
* **Increment**: Use 10-number increments (010, 020, 030) to allow insertion of new components
* **Examples**: `010-security-identity`, `020-observability`, `030-data`

### Internal Modules Management

**Module Isolation Rules**:
1. **NEVER reference internal modules from outside their parent component**
2. **ALWAYS use component outputs to share functionality with other components**
3. **CREATE reusable functionality through component outputs, not direct module access**

**Internal Module Organization**:
* **Component-Scoped Modules**: Internal modules organized under `{component}/{framework}/modules/`
* **Functionality Grouping**: Related functionality grouped into logical internal modules
* **Output Abstraction**: Component main module abstracts internal module complexity via outputs
* **Testing Isolation**: Internal module tests contained within component test suites

### Blueprint Layering and Composition

**Blueprint Layering Support**:
* **Incremental Deployment**: Blueprints can be applied on top of existing infrastructure
  * Terraform (*.tf): Use `data` resources to reference resources from previously deployed blueprints
  * Bicep (*.bicep): Provide `name` parameters (and name of scope when needed) to reference resources from previously deployed blueprints
* **Parameters and Variables**: Provide the same parameters and variables from previously deployed blueprints to layer a blueprint deployment

**Composition Examples**:
* **Base + Extension**: Deploy `full-single-node-cluster` then layer `fabric-rti` for additional capabilities
* **Partial + Complete**: Start with `only-cloud-single-node-cluster` then add edge components
* **Combine Blueprints**: Build new blueprints by copying from existing blueprints

### Deployment Patterns

**CI Deployment** (Minimal Configuration):
* **Location**: `{component}/ci/{framework}/`
* **Purpose**: Contains minimum required parameters and variables for component deployment, never add parameters or variables to `{component}/ci/{framework}/` deployments if they specify default values
* **Usage**: For individual component testing and basic deployments

**Blueprint Deployment** (Complete Solutions):
* **Location**: `/blueprints/{solution_name}/{framework}/`
* **Purpose**: Orchestrates multiple components for end-to-end solutions
* **Usage**: For full or partial environment provisioning. Blueprints can be layered on top of each others (e.g. `blueprints/fabric-rti` can be applied after a `blueprints/full-single-node-cluster` with matching variables and parameters)
* **Component Integration**: References component outputs as blueprint inputs

### Component Modification Workflow

When modifying any component, follow this validation sequence:

**Component Impact Analysis**:
* Search component references in blueprints with `includePattern: "blueprints/**"`
* Search for output references in src components with `includePattern: "src/**"`

**Component Variable Analysis**:
* Search for same or similar named variables in blueprints and in src components
* Ensure consistent descriptions, usages, and any validation
* Internal Module variables should always be required and have no defaults

**Update Validation Checklist**:
* [ ] Component outputs are never required to be backward compatible - breaking changes must be fixed in other components and blueprints
* [ ] Internal module changes can break component functionality as long as it is addressed and corrected in the component
* [ ] Component README.md should reflect what the component itself does, not interface changes
* [ ] Never update the framework README.md or internal module README.md instead use generation tasks or npm scripts
* [ ] CI deployment are always updated with the minimal required variables to create the component
* [ ] Blueprints and Components updated after any breaking changes, problems, or errors

### Reference Components

**Well-structured Examples**:
* **Security Foundation**: `/src/000-cloud/010-security-identity/`
* **Edge IoT Operations**: `/src/100-edge/110-iot-ops/`
* **Complete Blueprint**: `/blueprints/full-single-node-cluster/`

Use these as templates when creating new components or understanding expected patterns.
<!-- </component-and-blueprint-structure> -->

<!-- <terraform-operations> -->
## Terraform Operations Requirements

* Use `npm run tf-validate` for terraform validate and `npm run tflint-fix-fast` for terraform linting with tflint
  * Avoid running tflint immediately after adding any **unused** variables, locals, or data resources, that will eventually be used in later edits
  * tflint will remove all unused variables, locals, resources, and data resources if they have no usages
* `terraform init`, `terraform validate`, `terraform test`, `terraform plan`, `terraform apply`, requires `source [workspaceFolder]/scripts/az-sub-init.sh` ran at least once before any `run_in_terminal` commands to set the `ARM_SUBSCRIPTION_ID` env variable for terraform
  * If the user specifies their tenant then `source [workspaceFolder]/scripts/az-sub-init.sh --tenant <user-tenant-id>` or `source [workspaceFolder]/scripts/az-sub-init.sh --tenant <user-tenant-name>.onmicrosoft.com`
* Run the "Terraform Build" task after completing changes to any terraform

### Terraform Validation and Testing Steps

Final steps for ONLY terraform changes:
* Iterate with `npm run tf-validate` and `npm run tflint-fix-all` and fix all issues, continue to iterate until all issues are fixed
* NEVER add any tests unless specifically asked to add tests from the user
  * All tests must ONLY EVER be for `command = plan` tests

<!-- </terraform-operations> -->

<!-- <blueprint-structure-instructions> -->
## Blueprint Structure Instructions

Blueprints contain sets of components for deploying stamps of IaC:

### Blueprint Organization

* Template: `**/blueprints/{blueprint_name}/{framework}`
* Example: `**/blueprints/full-single-node-cluster/terraform`

### Blueprint Conventions

* Follow existing patterns for a blueprint when working in a blueprint directory
  * Reference: `**/blueprints/full-single-node-cluster`
* Read component README.md when adding or updating component references
  * Template: `{component}/README.md`
* Use outputs from components as inputs to other components
<!-- </blueprint-structure-instructions> -->

<!-- <project-structure-instructions> -->
## Project Structure Instructions

This project is organized into discrete categories optimized for enterprise IaC deployments.

### Component Organization Principles

The source code follows deployment-ordered groupings:

* **Cloud Infrastructure** (`000-cloud/`): Azure cloud resources (000-099 range)
* **Edge Infrastructure** (`100-edge/`): Edge cluster and IoT operations (100-199 range)
* **Applications** (`500-*/`): Application workloads (500-599 range)
* **Utilities** (`900-*/`): Tools and utilities (900-999 range)

Each numbered component uses decimal naming convention (010, 020, 030) to establish deployment order and allow insertion of new components between existing ones.

### Root Configuration Files

Configuration files that control project behavior, tooling, and metadata.

```plaintext
edge-ai/
├── .checkov.yml                               # Security and compliance scanning configuration
├── .cspell-dictionary.txt                     # Custom dictionary words for spell checking
├── .cspell.json                               # Spell checker configuration
├── .gitattributes                             # Git attributes configuration
├── .gitignore                                 # Git ignore patterns
├── .markdownlint.json                         # Markdown linting rules and configuration
├── .mega-linter.yml                           # Multi-language linter configuration
├── .npmrc                                     # NPM package manager configuration
├── .terraform-docs.yml                        # Terraform documentation generation configuration
├── .terrascan.toml                            # Infrastructure security scanning configuration
├── bicepconfig.json                           # Bicep configuration for Azure Resource Manager templates
├── Cargo.toml                                 # Rust workspace configuration
├── GitVersion.yml                             # Versioning configuration
├── package.json                               # NPM scripts for lint fixing, README.md (docs) generation, file formatting, validation
├── package-lock.json                          # NPM dependency lock file
├── PSScriptAnalyzerSettings.psd1              # PowerShell script analysis configuration
└── requirements.txt                           # Python dependencies for tooling
```

### Development Environment & CI/CD

Development containers, IDE settings, and continuous integration configurations.

```plaintext
edge-ai/
├── .azdo/                                     # Azure DevOps pipeline configurations
├── .azure/                                    # Azure CLI configuration and cached data
├── .cargo/                                    # Rust package manager configuration
├── .devcontainer/                             # VS Code development container configuration
├── .github/                                   # GitHub Actions, issue templates, prompts, instructions
├── .vscode/                                   # VS Code workspace settings and tasks
│   └── tasks.json                             # Project tasks that run in the background (use `npm run` directly unless told otherwise)
└── azure-pipelines.yml                        # Azure DevOps pipeline definition
```

### Documentation & Project Governance

Project documentation, governance files, and community guidelines.

```plaintext
edge-ai/
├── CODE_OF_CONDUCT.md                         # Community guidelines and behavioral expectations
├── CONTRIBUTING.md                            # Guidelines for contributing to the project
├── LICENSE                                    # Legal license terms
├── README.md                                  # Main project documentation and getting started
├── SECURITY.md                                # Security policy and vulnerability reporting
├── SUPPORT.md                                 # Support resources and community assistance
├── copilot/                                   # GitHub Copilot instruction files for different technologies
├── docs/                                      # Comprehensive project documentation
├── project-adrs/                              # Architecture Decision Records
├── project-security-plans/                    # Security planning templates and examples
└── praxisworx/                                # Training materials and skill assessments
```

### Core Infrastructure Components (src/)

Modular infrastructure components organized by deployment location and purpose.

```plaintext
src/
├── README.md                                 # Overview of source components and patterns
├── 000-cloud/                                # Cloud Infrastructure Components (000-099 range)
│   ├── 000-resource-group/                   # Resource group provisioning
│   ├── 010-security-identity/                # Identity, Key Vault, managed identities, RBAC
│   ├── 020-observability/                    # Cloud monitoring and logging
│   ├── 030-data/                             # Data storage and Schema Registry
│   ├── 031-fabric/                           # Microsoft Fabric resources
│   ├── 032-fabric-rti/                       # Microsoft Fabric Real-Time Intelligence
│   ├── 040-messaging/                        # Event Grid, Event Hubs, Service Bus
│   ├── 050-networking/                       # Virtual networks and security
│   ├── 051-vm-host/                          # Virtual machine provisioning
│   ├── 060-acr/                              # Azure Container Registry
│   ├── 070-kubernetes/                       # Kubernetes cluster management
│   └── 080-azureml/                          # Azure Machine Learning workspace
├── 100-edge/                                 # Edge Infrastructure Components (100-199 range)
│   ├── 100-cncf-cluster/                     # CNCF-compliant cluster (K3s) with Arc
│   ├── 110-iot-ops/                          # Azure IoT Operations core infrastructure
│   ├── 111-assets/                           # Asset management for IoT Operations
│   ├── 120-observability/                    # Edge observability and monitoring
│   ├── 130-messaging/                        # Edge messaging and data routing
│   └── 140-azureml/                          # Edge Azure ML deployment and inference
├── 500-application/                          # Application workloads (500-599 range)
│   ├── 500-basic-inference/                  # Basic AI inference service
│   ├── 501-rust-telemetry/                   # Rust telemetry collection service
│   ├── 502-rust-http-connector/              # Rust HTTP connector service
│   └── 503-media-capture-service/            # Media capture and processing
├── 501-ci-cd/                                # CI/CD automation and deployment pipelines
└── 900-tools-utilities/                      # Utility scripts and tools (900-999 range)
    └── 900-mqtt-tools/                       # MQTT testing and diagnostic tools
```

### Deployment Blueprints

End-to-end infrastructure deployments combining multiple components.

```plaintext
blueprints/
├── README.md                                 # Blueprint overview and usage instructions
├── azureml/                                  # Azure Machine Learning deployment blueprint
├── dual-peered-single-node-cluster/          # Dual-peered single node cluster configuration
├── fabric/                                   # Microsoft Fabric only deployment
├── fabric-rti/                               # Microsoft Fabric Real-Time Intelligence only
├── full-multi-node-cluster/                  # Complete multi-node cluster (option for Arc servers)
├── full-single-node-cluster/                 # Complete single-node cluster (all non-Fabric)
├── minimum-single-node-cluster/              # Minimal single-node cluster
├── only-cloud-single-node-cluster/           # Cloud-only components
├── only-edge-iot-ops/                        # Edge-only IoT Operations
├── only-output-cncf-cluster-script/          # CNCF cluster script generation only
└── partial-single-node-cluster/              # Partial cloud + edge CNCF cluster
```

### Automation & Supporting Tools

Scripts, deployment automation, and supporting utilities.

```plaintext
edge-ai/
├── deploy/                                   # Deployment automation for edge-ai project
├── scripts/                                  # Utility scripts for automation and maintenance
├── src/azure-resource-providers/             # Azure resource provider registration scripts
├── src/operate-all-terraform.sh              # Terraform deployment automation (manual use only)
└── src/starter-kit/                          # Sample implementations and quick-start templates
```
<!-- </project-structure-instructions> -->
