---
title: JavaScript API Documentation
description: JSDoc-generated API documentation for edge-ai JavaScript modules and utilities
author: Edge AI Team
ms.date: 2025-08-02
ms.topic: reference
keywords:
  - jsdoc
  - javascript
  - api-docs
  - frontend
  - edge-ai
  - documentation
  - modules
  - utilities
estimated_reading_time: 3
---

## JavaScript API Documentation

This directory contains JavaScript source files and generates comprehensive API documentation using JSDoc for all JavaScript modules, classes, and functions used throughout the edge-ai project.

## Overview

The JavaScript documentation system provides comprehensive API documentation for frontend utilities, configuration helpers, and development tools. Documentation is automatically generated from JSDoc comments in source files across the project.

## Directory Structure

```text
docs/assets/js/
├── README.md           # This documentation file
├── .jsdoc.json        # JSDoc configuration
├── Generate-JSDocs.ps1 # PowerShell documentation generation script
└── docs/              # Generated API documentation (output)
    └── api/
        └── index.html # Main API documentation page
```

## Generated Documentation

The API documentation includes:

- **Module Documentation** - Overview of each JavaScript module with purpose and dependencies
- **Class References** - Detailed class documentation with constructors, methods, and properties
- **Function References** - Function signatures, parameters, return values, and usage examples
- **Usage Examples** - Code examples and implementation patterns
- **Type Definitions** - TypeScript-style type annotations and interfaces

## Generation Process

Documentation is generated using the PowerShell script `Generate-JSDocs.ps1`:

```powershell
# Generate documentation with default settings
./Generate-JSDocs.ps1

# Generate with custom output directory
./Generate-JSDocs.ps1 -OutputDir "./custom-docs"

# Enable verbose logging for troubleshooting
./Generate-JSDocs.ps1 -Verbose
```

### Requirements

- Node.js (v14 or later)
- JSDoc (installed globally via npm)
- PowerShell 5.1 or later

### Configuration

JSDoc configuration is defined in `.jsdoc.json` and includes:

- Source file patterns and inclusion rules
- Output directory and template settings
- Plugin configurations for enhanced documentation features
- README inclusion for main documentation landing page

## Documentation Maintenance

Documentation should be regenerated whenever JavaScript source files are modified:

1. **Manual Generation** - Run the PowerShell script locally during development
2. **CI/CD Pipeline** - Automated generation during build and deployment processes
3. **Pre-commit Hooks** - Generate updated docs before code commits to ensure consistency

## Viewing Documentation

Once generated, open `docs/api/index.html` in a web browser to view the complete API documentation. The documentation is also deployable to static hosting platforms for team-wide access and integration with project wikis.

## Module Architecture

The codebase follows ES6 module standards with the following organization:

- `core/` - Core system modules (error handling, navigation, progress tracking)
- `features/` - Feature-specific modules (learning paths, assessments, forms)
- `ui/` - User interface components (dashboards, selectors, visualizers)
- `utils/` - Utility functions and shared helpers
- `plugins/` - Docsify plugin integrations and extensions

All modules use ES6 import/export syntax and are loaded dynamically through `main.js`.

## Related Resources

- [Edge AI Documentation](../../README.md) - Main project documentation
- [Contributing Guidelines](../../../CONTRIBUTING.md) - How to contribute to the project
- [Development Setup](../../getting-started/README.md) - Getting started with development

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
