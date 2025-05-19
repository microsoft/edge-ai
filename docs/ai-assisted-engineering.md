# AI-Assisted Engineering Resources

This document outlines resources within our repository that enhance AI-assisted engineering workflows, particularly when using GitHub Copilot. Understanding these resources helps maximize productivity when leveraging AI assistance for development tasks.

## Table of Contents

- [AI-Assisted Engineering Resources](#ai-assisted-engineering-resources)
  - [Table of Contents](#table-of-contents)
  - [GitHub Copilot Instructions](#github-copilot-instructions)
  - [GitHub Copilot Reusable Prompt Files](#github-copilot-reusable-prompt-files)
  - [GitHub Copilot Reusable Prompt Files: Pull Requests](#github-copilot-reusable-prompt-files-pull-requests)
  - [GitHub Copilot Reusable Prompt Files: AI Assisted Task Planner and Implementer](#github-copilot-reusable-prompt-files-ai-assisted-task-planner-and-implementer)
    - [Using the Task Planner](#using-the-task-planner)
    - [Using the Task Implementer](#using-the-task-implementer)
    - [Best Practices](#best-practices)
  - [GitHub Copilot for Commit Messages](#github-copilot-for-commit-messages)
  - [GitHub Copilot for Azure (Preview) Extension](#github-copilot-for-azure-preview-extension)
  - [Project Structure and Conventions](#project-structure-and-conventions)
  - [Documentation Resources](#documentation-resources)
  - [Template Files and Examples](#template-files-and-examples)
  - [Real-World Example: Documentation Generation with Copilot](#real-world-example-documentation-generation-with-copilot)
    - [Documentation Generation Process](#documentation-generation-process)
    - [Benefits of This Approach](#benefits-of-this-approach)
  - [Best Practices for AI-Assisted Engineering](#best-practices-for-ai-assisted-engineering)

## GitHub Copilot Instructions

The repository also uses a general custom instructions approach found in [.github/copilot-instructions.md](../.github/copilot-instructions.md). This high-priority instruction file provides and applies at avery request:

- Global guidance that applies across the entire codebase
- Automatic context-aware prompt file discovery based on file patterns
- Detailed component and blueprint structure understanding
- Markdown formatting requirements for consistent documentation
- Automatic integration with GitHub Copilot to ensure all code changes follow project conventions

## GitHub Copilot Reusable Prompt Files

The repository includes reusable prompt files located in the `/.github/prompts` folder.
These files provide specific reusable prompts for Copilot to use when working on __specific__ tasks or types of activities.

The reusable prompts are typically useful for common tasks, for example when getting started with the repo,
when deploying your first blueprint, or when creating a pull request.

- First, ensure your chat context is set to a new Chat in __Agent__ mode.
- There are different ways of executing the reusable prompt files:
  - Use the Command Palette: __Chat: Run prompt > Select the prompt {file}__ command.
  - Type `/` in the chat input field and select the prompt file you want to use.
  - Type `/` in the chat input field and select the prompt file you want to use, and add specific parameters and details to the prompt.
- The agent will automatically start executing and you can interact with the agent to refine the task or answer questions.

## GitHub Copilot Reusable Prompt Files: Pull Requests

This repository contains specific instructions for Copilot to generate complete pull request description.

- Ensure you have a new Chat context open (click the `+` sign or __Chat: New Chat__).
- Invoke the prompt and pass in optional arguments if desired:
  - Type `/pull-request` directly in the chat input field to generate a standard pull request description
  - Type `/pull-request includeMarkdown=true` to generate a pull request description which includes changes to Markdown files
  - Type `/pull-request branch=feat/branch-name` to generate a pull request description which compares to a specific branch (`main` by default)
- Use the generated `pr.md` file at the root of this repository as the pull request description. This file will not be committed to git.

## GitHub Copilot Reusable Prompt Files: AI Assisted Task Planner and Implementer

Documenting and detailing a plan for a unit of work is an effective way to leverage GitHub Copilot to accelerate development tasks.
By creating structured plans with specific phases, files to modify, libraries to use, and required tools, you provide Copilot with the context needed to assist efficiently.

The repository includes two reusable prompt files to help with planning and implementing tasks:

1. `task-planner`: Creates a structured markdown plan and accompanying notes file
2. `task-implementer`: Executes the plan and tracks progress through each phase, keeping notes on progress and decisions made

Both prompt files are stored in the `.github/prompts` directory and work together to provide a complete workflow for AI-assisted task planning and execution.

Both of these prompt files are extended with a set of custom instructions to apply in plan and task creation and implementation.
The custom instructions file can be found in [`.github/instructions/task-plan.instructions.md`](../.github/instructions/task-plan.instructions.md) directory.

### Using the Task Planner

The Task Planner helps you create a detailed plan with clear phases, objectives, and implementation details before doing any coding:

1. Start with a clean chat context by creating a new chat (click the `+` sign or select __Chat: New Chat__)
2. Invoke the prompt through one of these methods:
   - Run the Command Palette command: __Chat: Run Prompt__ and select `task-planner`
   - Type `/task-planner` directly in the chat input field with additional prompting

3. Follow the conversation flow as the Task Planner guides you through creating:
   - A task plan markdown file with structured phases and tasks
   - A notes file to track progress and document decisions

4. Answer the planner's questions about your task's title, phases, objectives, resources needed, and implementation details
5. The files are stored in `./.copilot-tracking/` (excluded from git) to serve as your personal scratchpad

### Using the Task Implementer

Once you have your plan ready, use the Task Implementer to execute it:

1. Create a new chat session for a clean context
2. Select the desired plan markdown file as your context from the `./.copilot-tracking/plans` folder, make sure it's selected as 'Current file' in chat context
3. Invoke the implementer prompt via the chat input field, different options are available:
   - Type `/task-implementer` in the chat input field, you will be asked for more details
   - Provide additional phase parameters: `/task-implementer phase=2` or `/task-implementer phase=2 task=1`

4. The implementer will:
   - Read your task plan
   - Execute phases and tasks as defined in the plan, depending on the context or parameters provided
   - Implement changes in the codebase according to the plan
   - Update the notes file with progress and results
   - Pause after each phase for your review and approval

Alternatively, you can select your task plan markdown file as your Chat context and ask Copilot to execute it directly:

```text
Execute the plan and start with Phase 1. Stop after completing Phase 1 and wait for my approval before proceeding to Phase 2.
```

### Best Practices

- Use Claude Sonnet 3.7 model when available for optimal results
- Be specific in your plan about files to modify, libraries to use, and implementation details
- Break complex tasks into clear, manageable phases
- Pause between phases to review progress and make adjustments
- Manually edit the task plan file as needed before implementation
- Request that the agent document decisions, challenges, and solutions in the notes file

The `.copilot-tracking` folder is intentionally excluded from git, providing a private workspace for your AI-assisted development process without cluttering your repository.

## GitHub Copilot for Commit Messages

This repository contains specific instructions for using GitHub Copilot to assist with commit messages, see [./.vscode/settings.json](./.vscode/settings.json) section `github.copilot.chat.commitMessageGeneration.instructions`.

- Ensure you review the generated message and adjust it as it may contain incomplete information.
- Currently we add a `Generated by Copilot` comment in the commit message to indicate that the message was generated by Copilot. Remove this if you tweaked the message significantly.

Leverage Copilot when creating your commit messages: open the *Source Control panel* > click the  *Generate Commit Message with Copilot 🌟* and edit as desired before committing.

## GitHub Copilot for Azure (Preview) Extension

When using the Dev Container the extension [GitHub Copilot for Azure (Preview)](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azure-github-copilot) for Visual Studio Code will be automatically installed.
This extension provides additional context and suggestions for Bicep and Terraform files, or when working with Azure resources.
It also extends the current GitHub Copilot Chat experience by providing more accurate suggestions and context-aware assistance for Bicep files.

Especially useful is the addition of Agent aware tools using the `#azure...` tag in your prompts to get Azure-specific suggestions and context.

A few valuable examples when working with IaC files are:

- When working with Bicep files, use `#azureBicepGetResourceSchema` to get the latest resource schema for Azure resources.
- When working with Terraform files, use `#azureTerraformBestPractices`.
- Generic prompts that require Azure Microsoft Learn documentation can be grounded with up to date information by using `#azureRetrieveMsLearnDocumentations` to get the latest documentation for Azure resources.

Additionally, the extension also provides tools that interact with Azure resources and help you manage your Azure resources directly from Visual Studio Code.
This provides help when troubleshooting deployments, including the deployment of blueprints in this repository.

## Project Structure and Conventions

Our [Coding Conventions](./coding-conventions.md) document provides comprehensive guidance that helps Copilot understand the project structure and expected code patterns. Key aspects include:

1. __Folder Structure and Naming Conventions__:
   - Root-level organization (`/src`, `/blueprints`, `/docs`, etc.)
   - Source component organization with decimal naming (e.g., `000-subscription`, `010-vm-host`)
   - Blueprint structure and documentation requirements
   - Script and workflow organization

2. __Infrastructure as Code Standards__:
   - Terraform module organization and variable definition patterns
   - Bicep conventions and parameter definitions
   - Testing requirements and patterns
   - Documentation expectations for IaC components

3. __Git Workflow Practices__:
   - Conventional commits format
   - Pull request conventions
   - Work item association guidelines

These conventions provide Copilot with a structured understanding of how code should be organized and formatted throughout the project, enabling more accurate and contextually appropriate suggestions.

## Documentation Resources

The project includes several types of documentation that help Copilot understand the system architecture and implementation details:

1. __Component Documentation__: Each component in `/src` includes a `README.md` that explains its purpose, usage, and configuration options.

2. __Blueprint Documentation__: Each blueprint in `/blueprints` contains deployment instructions and parameter requirements.

3. __Architectural Decision Records (ADRs)__: Located in `/docs`, these provide context on significant architectural decisions.

4. __Technical Specifications__: These include diagrams and detailed implementation guidance.

5. __Auto-Generated Documentation__: The repository uses tools like `terraform-docs` to maintain consistent documentation across modules.

Copilot can reference these resources to understand implementation patterns, expected configurations, and architectural constraints when making suggestions.

## Template Files and Examples

The project contains various template files and examples that help Copilot understand expected patterns:

1. __Terraform Module Templates__: Example implementations in `/src` demonstrate proper module structure, variable definitions, and output formatting.

2. __Blueprint Templates__: Examples in `/blueprints` show how components are composed into complete solutions.

3. __CI/CD Templates__: Pipeline definitions in `/.azdo` and `/.github/workflows` demonstrate expected automation patterns.

4. __Issue and PR Templates__: These define expected formats for contributions.

These templates provide concrete examples that help Copilot generate code and documentation that follows established project patterns.

## Real-World Example: Documentation Generation with Copilot

This section describes a real-world process used in this project to generate comprehensive documentation for build templates using GitHub Copilot:

### Documentation Generation Process

The following process was used to create consistent, comprehensive documentation for build templates:

1. __Template Extraction and Context Setup__:
   - Extract the template from the main build into a new file
   - Prepare context by adding three files to the editor:
     - The template file (YAML)
     - An empty markdown document (for Copilot to write into)
     - The azure-pipelines file that uses the template

2. __Initial Documentation Generation__:
   - Use this specific prompt for Copilot:

     ```text
     Hey Copilot, can you look across these three files, and create some documentation for me that comprehensively covers parameters, inputs, outputs, and anything else you think is useful (like links to MS Learn Documentation).
     ```

   - Let Copilot draft the markdown documentation
   - Repeat this process for each template being documented

3. __Documentation Template Creation__:
   - After generating all individual docs, provide the entire `.azdo` folder as context
   - Use this prompt:

     ```text
     Hey Copilot, can you look across all the markdown you wrote me here and create a template for all build template documentation
     ```

   - Edit the resulting template for clarity and consistency
   - Store the template in the `.azdo/templates` folder

4. __Standardizing Documentation__:
   - For each previously generated document, use this prompt:

     ```text
     Hey Copilot, using this template you made me, can you update XYZ to have the same structure as this template file?
     ```

   - This ensures all documentation follows the same structure and formatting

5. __Cross-Referencing Related Templates__:
   - Add a "Related Templates" section to the template
   - Use this prompt to generate cross-references:

     ```text
     Now that all the docs are updated can you add links to the other markdown in the .azdo folder showing which documents should link to other documents
     ```

   - This creates a network of linked documentation that improves navigability

### Benefits of This Approach

This approach delivered several key benefits:

1. __Consistency__: All documentation follows the same structure and style
2. __Comprehensiveness__: Each template's documentation covers parameters, inputs, outputs, and usage examples
3. __Efficiency__: Generated documentation from code context without manual effort
4. __Improved Navigation__: Cross-references between related templates enhance discoverability
5. __Sustainability__: The process can be repeated as new templates are added

This process demonstrates how Copilot can be used as an effective documentation assistant when provided with appropriate context and clear prompts.

## Best Practices for AI-Assisted Engineering

To maximize the effectiveness of GitHub Copilot when working with this repository:

1. __Create a Plan Document First__: Before diving into implementation, work with Copilot to create a markdown plan document that outlines the steps, files to modify, and approach for your task. This provides clarity and structure before any code changes are made.

2. __Iterate on the Plan__: Refine the plan document with Copilot by asking clarifying questions, adding more details, and validating the proposed approach against project standards and constraints.

3. __Execute According to the Plan__: Once your plan is finalized, use it as a guide when asking Copilot to implement specific parts of the solution, referencing the plan document for context and to maintain focus.

4. __Start with Context__: When implementing each step of your plan, begin your prompts by referencing specific files, components, or patterns you want to follow.

5. __Be Specific About Standards__: When requesting code, explicitly mention you want to follow the project's coding conventions as outlined in your plan.

6. __Request Explanations__: Ask Copilot to explain the purpose and structure of generated code, particularly for complex infrastructure components, ensuring it aligns with your plan.

7. __Include Multiple Files as Context__: When working on complex features identified in your plan, include related files as context to help Copilot understand dependencies and patterns.

8. __Reference Documentation__: Ask Copilot to incorporate specific patterns from existing documentation or templates that you've identified in your planning phase.

9. __Reference Copilot Tools for Updated Grounding__: Research the tools you can use to extend Copilot. Use tools such as `#githubRepo owner/repo-name` for GitHub based public docs, or a custom MCP server to ground Copilot with the latest documentation from external resources.

10. __Validate Generated Code__: Always review and test code generated by AI tools against your plan before committing or deploying.

11. __Iterative Refinement__: Use follow-up prompts to refine generated code that doesn't fully meet requirements or deviates from your plan.

12. __Use Appropriate Instructions Files__: Select the language-specific instructions file when working on related components as identified in your plan.

13. __Check for Convention Compliance__: Always verify that generated code follows alphabetical ordering of variables and other project standards specified in your plan.

14. __Update Your Plan as Needed__: As implementation progresses, update your plan document to reflect changes in approach or additional requirements discovered during development.

15. __Iterate and re-experiment__: AI models as well as GitHub Copilot features are constantly evolving! Keep experimenting and be curious about iterating on similar tasks as new features and models become available.
