---
applyTo: '**/*.js'
---
# JavaScript Instructions

You will ALWAYS think hard about JavaScript instructions and established conventions

- **CRITICAL**: You MUST ALWAYS read and follow ALL instructions from ALL files from:
  - [copilot/javascript/javascript.md](../../copilot/javascript/javascript.md)
  - [copilot/javascript/javascript-standards.md](../../copilot/javascript/javascript-standards.md)
  - [copilot/javascript/javascript-tests.md](../../copilot/javascript/javascript-tests.md)

## Context-Specific Requirements

### Backend JavaScript (Node.js - docs/_server/**, src/**)

- Use **ES6 modules** (import/export) for consistency with existing backend code
- Apply **Vitest** testing framework for all backend testing (API, integration, unit tests)
- Use **Node.js environment** for backend tests with appropriate mocking patterns
- Follow Express.js application architecture patterns
- Implement proper error handling, logging, and security middleware

### Frontend JavaScript (docs/assets/js/**, public/**)

- **Gradually migrate to ES6 modules** for new components while maintaining compatibility
- Use **Vitest with Happy DOM** for browser-based testing when test infrastructure is established
- Follow modern DOM manipulation and event handling patterns
- Maintain backward compatibility with existing IIFE patterns when extending functionality

### Universal JavaScript (utilities, shared modules)

- Prefer **ES6 modules** for new utility modules and shared code
- Use modern JavaScript features (ES2015+) with appropriate transpilation if needed
- Follow comprehensive JSDoc documentation standards
- Implement proper error handling with try/catch patterns

## Implementation Requirements

When implementing any JavaScript-related functionality:

- You must have read the complete JavaScript documentation before proceeding
- You must adhere to all guidelines provided in the JavaScript documentation
- You must implement all instructions exactly as specified
- You must **detect the context** (backend/frontend/utility) and apply appropriate patterns
- You must **maintain consistency** with existing code patterns in the same directory/module
- You must apply appropriate testing frameworks based on context and existing setup (**Vitest** for all JavaScript testing)
- You must **follow performance guidelines** for memory management, async operations, and DOM optimization
- You must **separate CSS from JavaScript**: ALWAYS place CSS styles in CSS files, never embed styles directly in JavaScript code. Use CSS classes and external stylesheets for all styling requirements

## Performance Requirements

All JavaScript code must follow performance best practices:

- **Memory Management**: Implement proper cleanup patterns to prevent memory leaks
- **Event Loop Awareness**: Use appropriate async patterns to avoid blocking operations
- **DOM Optimization**: Batch DOM operations and minimize reflows/repaints
- **Async Operation Optimization**: Choose appropriate patterns (Promise.all vs sequential) based on dependencies

## Migration Strategy

For existing code modifications:

- **Maintain existing module patterns** unless specifically modernizing
- **Add modern patterns gradually** without breaking existing functionality
- **Document migration decisions** in code comments when changing patterns
- **Test compatibility** when introducing new module systems

## Purpose

This document provides comprehensive prompt instructions for JavaScript implementation that ensure consistency, proper
 adherence to architectural principles, and alignment with established practices for both Node.js backend and frontend
 JavaScript development contexts while respecting existing codebase patterns.
