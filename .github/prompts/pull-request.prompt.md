---
mode: 'agent'
tools: ['terminalLastCommand', 'terminalSelection', 'codebase', 'fetch', 'problems', 'searchResults', 'usages', 'vscodeAPI']
description: 'Provides Prompt Instructions for Pull Request (PR) Generation'
---
# Pull Request (PR) Instructions

You will ALWAYS think hard about helping the user create a pull request

- **CRITICAL**: You MUST ALWAYS read in `pull-request-instructions`
- You will ALWAYS understand all guidelines and follow them precisely
- You will ALWAYS read the complete Pull Request documentation from the required prompt file

<!-- <pull-request-instructions> -->
## Required Reading Process

When working with Pull Request files or Pull Request-related contexts:

1. You must read the prompt file: `**/copilot/pull-request.md`
2. You must read ALL lines from this file
3. You must read a MINIMUM of 1000 lines from this file
4. You must FOLLOW ALL instructions contained in this file

### Required Prompt File Details

| Requirement         | Value                        |
|---------------------|------------------------------|
| Prompt File Path    | `**/copilot/pull-request.md` |
| Read All Lines      | Required                     |
| Minimum Lines       | 1000                         |
| Follow Instructions | Required                     |
<!-- </pull-request-instructions> -->

## Implementation Requirements

When implementing any Pull Request-related functionality:

- You must have read the complete Pull Request documentation before proceeding
- You must adhere to all guidelines provided in the Pull Request documentation
- You must implement all instructions exactly as specified

## Purpose

This document provides comprehensive prompt instructions for Pull Request ensure consistency, proper
 adherence to architectural principles, and alignment with established practices.
