# GitHub Copilot Resources

This directory contains GitHub Copilot configuration files, prompts, custom agents, and instructions to enhance AI-assisted development workflows for the Edge AI Platform.

## HVE Core Integration

Edge-ai integrates with [hve-core](https://github.com/microsoft/hve-core) for general-purpose prompt engineering artifacts. The `.vscode/settings.json` configuration loads hve-core agents, prompts, and instructions from the peer `../hve-core/.github/` directory. Install the `ise-hve-essentials.hve-core` VS Code extension or clone hve-core alongside this workspace to enable these resources.

## Directory Structure

### 📝 [AI Prompts](prompts/)

Reusable prompt templates for specific development tasks including deployment, testing, and project planning. General-purpose prompts (task planning, ADR creation, prompt engineering, work item management) are loaded from hve-core.

### 💬 [Custom Agents](agents/)

Custom agent configurations for specialized AI assistance patterns including kata coaching, code reviews, and technical guidance. General-purpose agents (prompt-builder, task-planner, TDD) are loaded from hve-core.

### 📋 [Instructions](instructions/)

Development workflow instructions and guidelines for AI-assisted engineering practices and project standards.

### ⚙️ [Workflows](workflows/)

GitHub Actions workflows with AI assistance integration.

## Getting Started

1. **Browse Prompts**: Explore the [prompts directory](prompts/) for task-specific AI assistance
2. **Try Custom Agents**: Use the specialized [custom agents](agents/) for guided AI interactions
3. **Follow Instructions**: Review [development instructions](instructions/) for best practices

## Key Features

- **Standardized Prompts**: Consistent, tested prompts for common development tasks
- **Specialized Custom Agents**: Tailored AI interactions for specific use cases like kata coaching
- **Development Guidelines**: Clear instructions for AI-assisted engineering workflows
- **Integration Ready**: Designed to work seamlessly with GitHub Copilot and other AI tools

## Usage Examples

### Using Prompts

Navigate to the [prompts directory](prompts/) and copy the appropriate prompt template for your task.

### Activating Custom Agents

Custom agents in the [agents directory](agents/) can be used with compatible AI tools that support custom interaction patterns.

### Following Instructions

The [instructions directory](instructions/) provides step-by-step guidance for AI-assisted development workflows.

## Contributing

When adding new resources:

1. Place prompts in the appropriate subdirectory under `prompts/`
2. Add custom agents to `agents/` with clear documentation
3. Update instructions in `instructions/` following the established format
4. Ensure all new content follows the project's AI assistance guidelines

For detailed contributing guidelines, see the main project [CONTRIBUTING.md](../CONTRIBUTING.md).
