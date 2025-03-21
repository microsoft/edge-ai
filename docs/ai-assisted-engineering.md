# AI-Assisted Engineering Resources

This document outlines resources within our repository that enhance AI-assisted engineering workflows, particularly when using GitHub Copilot. Understanding these resources helps maximize productivity when leveraging AI assistance for development tasks.

## Table of Contents

- [AI-Assisted Engineering Resources](#ai-assisted-engineering-resources)
  - [Table of Contents](#table-of-contents)
  - [GitHub Copilot Instructions](#github-copilot-instructions)
  - [Copilot Prompt Files](#copilot-prompt-files)
  - [Azure Copilot for Bicep (and Terraform)](#azure-copilot-for-bicep-and-terraform)
  - [Project Structure and Conventions](#project-structure-and-conventions)
  - [Documentation Resources](#documentation-resources)
  - [Template Files and Examples](#template-files-and-examples)
  - [Real-World Example: Documentation Generation with Copilot](#real-world-example-documentation-generation-with-copilot)
    - [Documentation Generation Process](#documentation-generation-process)
    - [Benefits of This Approach](#benefits-of-this-approach)
  - [Best Practices for AI-Assisted Engineering](#best-practices-for-ai-assisted-engineering)

## GitHub Copilot Instructions

The repository contains dedicated instructions for GitHub Copilot in [.github/copilot-instructions.md](/.github/copilot-instructions.md). These instructions help Copilot provide more contextually relevant suggestions by outlining:

- Repository orientation guidance (links, tips, and explanations)
- Parameter handling best practices (asking questions rather than making assumptions)
- Solution deployment workflows using Blueprints
- Component and Blueprint development patterns
- Terraform best practices specific to this project

## Copilot Prompt Files

The repository includes dedicated guidance in [copilot-prompt-files.md](./copilot-prompt-files.md) that explains how to effectively use GitHub Copilot with specific prompts to optimize AI usage when contributing to this project. Review the document for detailed instructions on setting up and using prompt files.

The specialized prompt files in the [.github/prompts](/.github/prompts/) directory provide language-specific guidance to GitHub Copilot for IaC Terraform and Bicep development, as well as documentation generation. These prompt files are designed to enhance the AI's understanding of the project's structure, conventions, and best practices.

## Azure Copilot for Bicep (and Terraform)

We recommend installing the [Azure Copilot (Preview)](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.copilot) extension for Visual Studio Code.
This extension provides additional context and suggestions for Bicep and Terraform files.

This extension extends the current GitHub Copilot Chat experience by providing more accurate suggestions and context-aware assistance for Bicep files.
While some models in Edits mode may generate incorrect Bicep code, we have seen good results in improving the code by interacting with the Azure Copilot.

To use the extension, ensure you are in Chat mode and start your chat prompt with `@azure`. It is currently not available in Edits mode.

## Project Structure and Conventions

Our [Coding Conventions](./coding-conventions.md) document provides comprehensive guidance that helps Copilot understand the project structure and expected code patterns. Key aspects include:

1. **Folder Structure and Naming Conventions**:
   - Root-level organization (`/src`, `/blueprints`, `/docs`, etc.)
   - Source component organization with decimal naming (e.g., `000-subscription`, `010-vm-host`)
   - Blueprint structure and documentation requirements
   - Script and workflow organization

2. **Infrastructure as Code Standards**:
   - Terraform module organization and variable definition patterns
   - Bicep conventions and parameter definitions
   - Testing requirements and patterns
   - Documentation expectations for IaC components

3. **Git Workflow Practices**:
   - Conventional commits format
   - Pull request conventions
   - Work item association guidelines

These conventions provide Copilot with a structured understanding of how code should be organized and formatted throughout the project, enabling more accurate and contextually appropriate suggestions.

## Documentation Resources

The project includes several types of documentation that help Copilot understand the system architecture and implementation details:

1. **Component Documentation**: Each component in `/src` includes a `README.md` that explains its purpose, usage, and configuration options.

2. **Blueprint Documentation**: Each blueprint in `/blueprints` contains deployment instructions and parameter requirements.

3. **Architectural Decision Records (ADRs)**: Located in `/docs`, these provide context on significant architectural decisions.

4. **Technical Specifications**: These include diagrams and detailed implementation guidance.

5. **Auto-Generated Documentation**: The repository uses tools like `terraform-docs` to maintain consistent documentation across modules.

Copilot can reference these resources to understand implementation patterns, expected configurations, and architectural constraints when making suggestions.

## Template Files and Examples

The project contains various template files and examples that help Copilot understand expected patterns:

1. **Terraform Module Templates**: Example implementations in `/src` demonstrate proper module structure, variable definitions, and output formatting.

2. **Blueprint Templates**: Examples in `/blueprints` show how components are composed into complete solutions.

3. **CI/CD Templates**: Pipeline definitions in `/.azdo` and `/.github/workflows` demonstrate expected automation patterns.

4. **Issue and PR Templates**: These define expected formats for contributions.

These templates provide concrete examples that help Copilot generate code and documentation that follows established project patterns.

## Real-World Example: Documentation Generation with Copilot

This section describes a real-world process used in this project to generate comprehensive documentation for build templates using GitHub Copilot:

### Documentation Generation Process

The following process was used to create consistent, comprehensive documentation for build templates:

1. **Template Extraction and Context Setup**:
   - Extract the template from the main build into a new file
   - Prepare context by adding three files to the editor:
     - The template file (YAML)
     - An empty markdown document (for Copilot to write into)
     - The azure-pipelines file that uses the template

2. **Initial Documentation Generation**:
   - Use this specific prompt for Copilot:

     ```text
     Hey Copilot, can you look across these three files, and create some documentation for me that comprehensively covers parameters, inputs, outputs, and anything else you think is useful (like links to MS Learn Documentation).
     ```

   - Let Copilot draft the markdown documentation
   - Repeat this process for each template being documented

3. **Documentation Template Creation**:
   - After generating all individual docs, provide the entire `.azdo` folder as context
   - Use this prompt:

     ```text
     Hey Copilot, can you look across all the markdown you wrote me here and create a template for all build template documentation
     ```

   - Edit the resulting template for clarity and consistency
   - Store the template in the `.azdo/templates` folder

4. **Standardizing Documentation**:
   - For each previously generated document, use this prompt:

     ```text
     Hey Copilot, using this template you made me, can you update XYZ to have the same structure as this template file?
     ```

   - This ensures all documentation follows the same structure and formatting

5. **Cross-Referencing Related Templates**:
   - Add a "Related Templates" section to the template
   - Use this prompt to generate cross-references:

     ```text
     Now that all the docs are updated can you add links to the other markdown in the .azdo folder showing which documents should link to other documents
     ```

   - This creates a network of linked documentation that improves navigability

### Benefits of This Approach

This approach delivered several key benefits:

1. **Consistency**: All documentation follows the same structure and style
2. **Comprehensiveness**: Each template's documentation covers parameters, inputs, outputs, and usage examples
3. **Efficiency**: Generated documentation from code context without manual effort
4. **Improved Navigation**: Cross-references between related templates enhance discoverability
5. **Sustainability**: The process can be repeated as new templates are added

This process demonstrates how Copilot can be used as an effective documentation assistant when provided with appropriate context and clear prompts.

## Best Practices for AI-Assisted Engineering

To maximize the effectiveness of GitHub Copilot when working with this repository:

1. **Start with Context**: Begin your prompts by referencing specific files, components, or patterns you want to follow.

2. **Be Specific About Standards**: When requesting code, explicitly mention you want to follow the project's coding conventions.

3. **Request Explanations**: Ask Copilot to explain the purpose and structure of generated code, particularly for complex infrastructure components.

4. **Validate Generated Code**: Always review and test code generated by AI tools before committing or deploying.

5. **Iterative Refinement**: Use follow-up prompts to refine generated code that doesn't fully meet requirements.

6. **Reference Documentation**: Ask Copilot to incorporate specific patterns from existing documentation or templates.

7. **Use Appropriate Prompt Files**: Select the language-specific prompt file (Terraform or Bicep) when working on related components.

8. **Include Multiple Files as Context**: When working on complex features, include related files as context to help Copilot understand dependencies and patterns.

9. **Specify Model Preferences**: For certain tasks, experiment with different AI models as they may have different strengths.

10. **Check for Convention Compliance**: Always verify that generated code follows alphabetical ordering of variables and other project standards.

11. **Iterate and re-experiment**: AI models as well as GitHub Copilot features are constantly evolving! Keep experimenting and be curious about iterating on similar tasks as new features and models become available.

By leveraging these resources effectively, GitHub Copilot can help accelerate development while maintaining consistency with project standards and architectural patterns.
