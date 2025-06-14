---
title: Using build-docs.md.template with Copilot
description: Step-by-step guide for using the standardized documentation template with GitHub Copilot to create docs for reusable workflows and pipeline templates
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: how-to
keywords:
  - documentation
  - github copilot
  - template usage
  - workflow documentation
  - pipeline templates
  - automation
estimated_reading_time: 6
---

## Using build-docs.md.template with Copilot

Quick guide for leveraging the standardized documentation template with GitHub Copilot to create consistent, comprehensive documentation for new GitHub Actions workflows or Azure DevOps pipeline templates.

## In this guide

- [Quick start](#quick-start)
- [Copilot prompting strategies](#copilot-prompting-strategies)
- [Template adaptation](#template-adaptation)
- [Quality checklist](#quality-checklist)

## Quick start

### Step 1: Prepare your workflow/template

Before documenting, ensure you have:

- ✅ A working GitHub Actions workflow or Azure DevOps pipeline template
- ✅ Clear understanding of its inputs, outputs, and dependencies
- ✅ At least one practical usage example

### Step 2: Copy and reference the template

1. Copy `build-docs.md.template` to your new documentation file
2. Open both files in VS Code
3. Have your actual workflow/template YAML file open as well

### Step 3: Engage Copilot effectively

Use this proven prompt pattern:

```text
@workspace Using the build-docs.md.template as a structure guide, help me create documentation for [WORKFLOW_NAME].

Context:
  - This is a [GitHub Actions reusable workflow / Azure DevOps pipeline template]
  - Location: [path/to/your/template.yml]
  - Purpose: [brief description of what it does]

Please:
1. Follow the template structure exactly
2. Replace all placeholder content with specifics for this workflow
3. Generate realistic parameter tables and usage examples
4. Focus on practical implementation details
```

## Copilot prompting strategies

### For GitHub Actions workflows

**Effective prompt template:**

```text
@workspace I need to document the reusable GitHub Actions workflow at [PATH]. Using build-docs.md.template as the structure:

1. Analyze the workflow inputs, outputs, and secrets
2. Create a parameters table with accurate types and descriptions
3. Generate 2-3 practical usage examples
4. Explain the workflow's integration patterns with other workflows
5. Identify any required permissions or environment setup

Focus on: [specific aspects like security, matrix builds, composite actions, etc.]
```

**Key elements to specify:**

- Workflow triggers (`workflow_call`, `workflow_dispatch`)
- Input parameters and their constraints
- Output variables and how to access them
- Required secrets and permissions
- Integration with composite actions

### For Azure DevOps templates

**Effective prompt template:**

```text
@workspace Document this Azure DevOps pipeline template at [PATH] using build-docs.md.template structure:

1. Extract all template parameters with types and defaults
2. Identify template outputs and how to reference them
3. Create usage examples for different scenarios (basic, advanced, matrix)
4. Document required service connections, extensions, or agent capabilities
5. Show integration patterns with other templates

Template type: [stage/job/task template]
Primary function: [validation/deployment/utility]
```

**Key elements to specify:**

- Template type and scope
- Parameter validation and constraints
- Dependencies on other templates or resources
- Stage/job/task organization
- Conditional execution patterns

## Template adaptation

### Section customization

The template includes sections that may not apply to every workflow/template:

#### Always include

- **Overview**: Purpose and context
- **Parameters**: Input specifications
- **Usage**: Basic and advanced examples

#### Include if applicable

- **Outputs**: For workflows that produce consumable outputs
- **Dependencies**: For templates requiring specific setup
- **Implementation Details**: For complex internal logic
- **Troubleshooting**: For common issues or gotchas

#### Skip if not relevant

- **Features**: If functionality is straightforward
- **Examples**: Multiple examples if usage is simple
- **Related Templates**: If the template is standalone

### Header adaptation

Update the template header for your specific documentation:

```yaml
---
title: [Your Workflow/Template Name]
description: [Concise description of purpose and functionality]
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: reference
estimated_reading_time: 3
keywords:
  - [relevant keywords for discoverability]
---
```

## Quality checklist

Before finalizing your documentation:

### Content accuracy

- [ ] All parameters accurately documented with correct types
- [ ] Examples are tested and functional
- [ ] Dependencies and requirements are complete
- [ ] Integration patterns are realistic

### Structure consistency

- [ ] Follows template section order
- [ ] Uses consistent formatting (tables, code blocks, lists)
- [ ] Maintains standardized header format
- [ ] Includes proper cross-references

### Copilot verification prompts

Use these follow-up prompts to validate your documentation:

```text
@workspace Review this documentation against the original template at [PATH]:
1. Are all parameters correctly documented?
2. Do the usage examples actually work?
3. Are there any missing dependencies or requirements?
4. Is the documentation consistent with our template standards?
```

```text
@workspace Compare this documentation to similar ones in the repository:
  - Does it follow the same patterns as [github-workflow-templates.md / azure-pipeline-templates.md]?
  - Is the level of detail appropriate?
  - Are there any sections that could be more concise?
```

## Quick reference

### Common Copilot commands for template documentation

| Task                       | Prompt Pattern                                                                                           |
|----------------------------|----------------------------------------------------------------------------------------------------------|
| **Extract parameters**     | `@workspace Analyze [FILE] and create a parameters table following build-docs.md.template format`        |
| **Generate examples**      | `@workspace Create 2-3 usage examples for this [workflow/template] showing basic and advanced scenarios` |
| **Document outputs**       | `@workspace Identify all outputs from [FILE] and document how to access them in dependent jobs`          |
| **Create troubleshooting** | `@workspace Based on this [workflow/template], what are likely issues users might encounter?`            |
| **Validate structure**     | `@workspace Does this documentation follow the build-docs.md.template structure correctly?`              |

### Template file locations

- **Template**: `docs/build-cicd/templates/build-docs.md.template`
- **Examples**:
- `docs/build-cicd/templates/github-workflow-templates.md`
- `docs/build-cicd/templates/azure-pipeline-templates.md`

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
