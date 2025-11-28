---
title: 'Kata: 100 - Configure Azure DevOps MCP Server'
description: Learn to configure the Azure DevOps Model Context Protocol server for GitHub Copilot integration with PAT token authentication and connection verification
author: Edge AI Team
ms.date: 2025-01-25
kata_id: ado-automation-100-configure-mcp-server
kata_category:
  - ado-automation
kata_difficulty: 1
estimated_time_minutes: 15
learning_objectives:
  - Configure Azure DevOps MCP server with proper authentication
  - Create PAT tokens with correct permission scopes for automation
  - Verify MCP server connectivity and test basic operations
prerequisite_katas: []
technologies:
  - Azure DevOps
  - MCP (Model Context Protocol)
  - GitHub Copilot
  - Azure CLI
success_criteria:
  - Successfully configure MCP server with correct PAT token scopes
  - Verify connection to Azure DevOps organization through MCP
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - ado-automation
search_keywords:
  - azure-devops-mcp
  - pat-token-authentication
  - mcp-server-configuration
---

## Quick Context

**You'll Learn**: Configure Azure DevOps MCP server for automated work item management through GitHub Copilot.

**Real Challenge**: You're a DevOps engineer at a software development company where teams spend significant time manually creating and updating Azure DevOps work items. Your infrastructure requires automated work item management to reduce overhead and improve velocity. This kata walks you through MCP server configuration using PAT token authentication.

## Essential Setup

**Required** (check these first):

- [ ] Visual Studio Code with GitHub Copilot extension installed
- [ ] Active GitHub Copilot subscription
- [ ] Access to an Azure DevOps organization (free tier works)
- [ ] Node.js and npm installed for MCP package

**Quick Validation**: Run `npx -v` to verify npm package runner is available.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on Configure Azure DevOps MCP Server kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Create Azure DevOps PAT Token (5 minutes)

**What You'll Do**: Generate a Personal Access Token with correct permission scopes for MCP automation.

**Steps**:

1. **Navigate** to Azure DevOps PAT token creation
   - [ ] Open your Azure DevOps organization in a browser
   - [ ] Click your profile icon (top right) → Personal access tokens
   - [ ] Click "New Token"
   - [ ] **Expected result**: PAT token creation dialog opens

2. **Configure** token permissions
   - [ ] Name: `MCP Automation Token`
   - [ ] Organization: Select your organization
   - [ ] Expiration: 90 days (or custom as needed)
   - Scopes: Click "Show all scopes" and enable — **Code** (Read), **Work Items** (Read & Write), **Build** (Read), **Project and Team** (Read)
   - **Pro tip**: These minimum scopes allow work item operations, PR linking, and build monitoring
   - [ ] **Expected result**: Four required scopes selected

3. **Generate** and save token securely
   - [ ] Click "Create" button
   - [ ] Copy token value immediately (shown only once)
   - [ ] Save to password manager or secure note
   - **Success check**: Token value saved - you cannot retrieve it again
   - [ ] **Expected result**: PAT token securely stored

### Task 2: Install and Configure MCP Server (5 minutes)

**What You'll Do**: Configure the Azure DevOps MCP server in VS Code using `.vscode/mcp.json` configuration file.

**Steps**:

1. **Create** MCP configuration file
   - [ ] In VS Code, create `.vscode` folder in your workspace if it doesn't exist
   - [ ] Create `.vscode/mcp.json` file with this content:

   ```json
   {
     "inputs": [
       {
         "id": "ado_org",
         "type": "promptString",
         "description": "Azure DevOps organization name (e.g. 'contoso')"
       }
     ],
     "servers": {
       "ado": {
         "type": "stdio",
         "command": "npx",
         "args": ["-y", "@azure-devops/mcp", "${input:ado_org}"]
       }
     }
   }
   ```

   - [ ] Replace organization name prompt with your actual organization when prompted
   - **Pro tip**: For filtered tools, add `-d` argument: `"args": ["-y", "@azure-devops/mcp", "${input:ado_org}", "-d", "core", "work", "work-items"]`
   - [ ] **Expected result**: Configuration file created with proper JSON structure

2. **Start** MCP server
   - [ ] In VS Code, look for MCP server notification or click "Start" in status bar
   - [ ] Enter your Azure DevOps organization name when prompted
   - [ ] Browser window opens for authentication - sign in with Microsoft account
   - **Pro tip**: Use credentials matching your Azure DevOps organization access
   - [ ] **Expected result**: MCP server starts and authentication completes

3. **Enable** MCP tools in GitHub Copilot
   - [ ] Open GitHub Copilot Chat in VS Code
   - [ ] Switch to Agent Mode (click mode selector in chat)
   - [ ] Click "Select Tools" and choose Azure DevOps MCP tools
   - **Success check**: MCP server shows active with tools enabled
   - [ ] **Expected result**: MCP server ready for GitHub Copilot commands

### Task 3: Test MCP Connection (5 minutes)

**What You'll Do**: Verify MCP server functionality with basic Azure DevOps queries.

**Steps**:

1. **Test** project discovery
   - [ ] Open GitHub Copilot Chat in VS Code (ensure Agent Mode active)
   - [ ] Say: *"List ADO projects"*
   - [ ] Review the projects returned
   - **Pro tip**: MCP automatically uses authenticated user context from browser login
   - [ ] **Expected result**: MCP returns list of projects you have access to

2. **Test** work item discovery
   - [ ] Say: *"List my work items for project [YourProjectName]"*
   - [ ] Replace `[YourProjectName]` with a project from step 1
   - [ ] Review the work items returned
   - **Pro tip**: If no work items exist, create a simple task through Azure DevOps UI first
   - [ ] **Expected result**: MCP returns work item list with IDs and titles

3. **Verify** available tools
   - [ ] Click "Select Tools" in Copilot Chat Agent Mode
   - [ ] Review available Azure DevOps MCP tools
   - **Validation checkpoint**: Can you see tools for work items, repos, and pipelines?
   - [ ] **Expected result**: MCP tools visible and selectable for use

4. **Test** basic query
   - [ ] Say: *"List ADO Builds for '[YourProjectName]'"*
   - [ ] Review the build information returned (if builds exist)
   - **Success check**: MCP successfully queries Azure DevOps data
   - [ ] **Expected result**: Clear understanding of what MCP can do with Azure DevOps

## Completion Check

**You've Succeeded When**:

- [ ] PAT token created with correct scopes (Code, Work Items, Build, Project/Team)
- [ ] MCP server installed and connected to Azure DevOps organization
- [ ] GitHub Copilot can query work items and projects through MCP
- [ ] You understand MCP capabilities for Azure DevOps automation

**Next Steps**: Proceed to [Kata: Discover Single Work Item](./100-single-work-item-discovery.md) to learn targeted work item discovery patterns.

---

## Reference Appendix

### Help Resources

- **Microsoft Learn**: [Use Personal Access Tokens](https://learn.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate)
- **OAuth Scopes Reference**: [Azure DevOps OAuth Scopes](https://learn.microsoft.com/azure/devops/integrate/get-started/authentication/oauth#available-scopes)
- **GitHub Copilot**: Use for troubleshooting MCP connection issues

### Professional Tips

- Store PAT tokens in password managers, never commit to repositories
- Use minimal required scopes following principle of least privilege
- Set token expiration to 90 days or less for security
- Create separate tokens for different automation purposes

### Troubleshooting

**Issue**: MCP server installation fails with permission errors

- **Quick Fix**: Run VS Code with appropriate permissions, ensure Node.js installed correctly

**Issue**: PAT token authentication fails despite correct token

- **Quick Fix**: Verify token scopes match requirements, check token hasn't expired, confirm organization URL format

**Issue**: GitHub Copilot can't find MCP server

- **Quick Fix**: Restart VS Code, verify MCP extension installed, check workspace MCP settings

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
