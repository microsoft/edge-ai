# 🔗 Beads & Beads MCP Documentation

This documentation covers the Beads integration for the edge-ai project, enabling dependency-aware issue tracking and AI-assisted development workflows.

## What is Beads?

Beads (`bd`) is a lightweight, git-versioned issue tracker designed for AI-supervised coding workflows. Issues link together like beads on a string through four dependency types (blocks, related, parent-child, discovered-from), making it easy for AI agents to follow complex task streams over long horizons.

> **Note:** Beads is in active development (currently v0.9.x alpha). The core features work well, but expect API changes before 1.0. Use with discretion for development and internal projects. The JSONL format ensures data portability for future migrations.

Key features:

* 🎯 **Dependency-aware**: Four dependency types keep work properly sequenced
* 🤖 **Agent-friendly**: JSON output and ready work detection designed for AI
* 📦 **Git-versioned**: JSONL records sync across machines automatically
* ⚡ **Zero setup**: `bd init` creates a project-local database instantly
* 🔍 **Ready work detection**: Automatically finds unblocked issues

Learn more at [steveyegge/beads](https://github.com/steveyegge/beads).

## Why Use Beads in edge-ai?

Beads provides an alternative to the `task-planner` custom agent and `.copilot-tracking/plans` Markdown files for tracking GitHub Copilot implementation work:

* Structured tracking instead of Markdown
* Dependency graphs instead of linear task lists
* Automatic discovery of new work during implementation
* MCP server for GitHub Copilot integration

## What's in This Documentation?

This guide covers:

* 🚀 [Getting Started](#getting-started) - Install bd CLI and configure MCP
* 🎯 [Using bd Commands](#-using-bd-commands) - Essential CLI commands
* 🔄 [Typical Beads Workflow](#-typical-beads-workflow) - Complete development cycle
* 📚 [Reference](#-reference) - Custom agents, prompts, and additional resources

## Getting Started

**Recommended:** Use the [Beads DevContainer](#-quick-start-use-the-beads-devcontainer-recommended) for the fastest setup.

**Alternative:** Follow the [Manual Installation](#-alternative-manual-installation) steps if you prefer not to use devcontainers.

### 🚀 Quick Start: Use the Beads DevContainer (Recommended)

The fastest way to get started with beads is to use the pre-configured Beads devcontainer that includes:

* Beads CLI (`bd`) pre-installed
* Beads MCP server pre-configured
* All required dependencies (uv, Go toolchain)
* Beads-specific chat settings (instructions, prompts, custom agents)

#### Launch the Beads DevContainer

1. Open the Command Palette (`Cmd+Shift+P` on macOS, `Ctrl+Shift+P` on Windows/Linux)
2. Run **Dev Containers: Reopen in Container**
3. Select **beads-tracking-devcontainer** from the list
4. Wait for the container to build and start

#### What You Get

When the devcontainer starts:

* ✅ Beads CLI available: `bd --version`
* ✅ MCP server automatically configured in agent mode
* ✅ Beads custom agents, instructions, and prompts ready to use
* ✅ All GitHub Copilot settings configured for beads workflow

#### Verify Setup

1. Open Chat view and switch to **Agent** mode
2. Click the **Tools** button
3. Look for beads tools (`beads_create`, `beads_ready`, `beads_show`, etc.)
4. Trust the beads MCP server when prompted

You're ready to use beads! Skip to [🎯 Using bd Commands](#-using-bd-commands).

---

### 📦 Alternative: Manual Installation

If you prefer not to use the devcontainer, you can install beads manually.

#### Install Beads CLI

Quick install:

```bash
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/install.sh | bash
```

The installer places `bd` in `~/.local/bin/bd` and adds it to your PATH.

#### Install uv Package Manager

The `uv` package manager is required to run the beads MCP server:

```bash
pip install uv
```

Alternative installation methods:

| Method             | Command           | Notes                    |
|--------------------|-------------------|--------------------------|
| pipx (recommended) | `pipx install uv` | Isolated installation    |
| pip (global)       | `pip install uv`  | System-wide installation |
| brew (macOS)       | `brew install uv` | Via Homebrew             |

#### Optional: Configure MCP Server Manually

If not using the devcontainer, you can optionally configure the beads MCP server in VS Code:

1. Open the Command Palette (`Cmd+Shift+P` on macOS, `Ctrl+Shift+P` on Windows/Linux)
2. Run **MCP: Open User Configuration** (for all workspaces) or **MCP: Open Workspace Folder Configuration** (for current workspace)
3. Add the beads server configuration:

```json
{
  "servers": {
    "beads": {
      "command": "uvx",
      "args": ["beads-mcp"]
    }
  }
}
```

Configuration file locations:

| Configuration | Scope                  | File Path                                                   |
|---------------|------------------------|-------------------------------------------------------------|
| User          | All workspaces         | `~/.config/Code/User/globalStorage/github.copilot/mcp.json` |
| Workspace     | Current workspace only | `<workspace>/.vscode/mcp.json`                              |

**Note:** The Beads devcontainer includes this configuration automatically, so manual setup is only needed if you're not using the devcontainer.

## 🎯 Using bd Commands

While you can use the `bd` CLI directly, we recommend using **💬 GitHub Copilot Chat** with the beads MCP server for a more intuitive experience. Copilot can help you understand bead status, create issues with proper formatting, and maintain dependencies.

### Essential Commands Quick Reference

| Command      | Purpose                 | Example                                     |
|--------------|-------------------------|---------------------------------------------|
| `bd init`    | Initialize beads        | `bd init` or `bd init --prefix myapp`       |
| `bd create`  | Create a new issue      | `bd create "Fix login bug" -p 1 -t bug`     |
| `bd list`    | List all issues         | `bd list` or `bd list --status open`        |
| `bd show`    | Show issue details      | `bd show edge-ai-1`                         |
| `bd update`  | Update issue            | `bd update edge-ai-1 --status in_progress`  |
| `bd close`   | Complete an issue       | `bd close edge-ai-1 --reason "Implemented"` |
| `bd ready`   | Find unblocked work     | `bd ready` or `bd ready --limit 5`          |
| `bd dep add` | Add dependency          | `bd dep add edge-ai-2 edge-ai-1`            |
| `bd stats`   | Show project statistics | `bd stats`                                  |

### Common Usage Patterns

Initialize a new project:

```bash
bd init
# Issues will be named: edge-ai-1, edge-ai-2, etc.
```

Create different issue types:

```bash
bd create "Add authentication" -p 1 -t feature
bd create "Fix crash on startup" -p 0 -t bug
bd create "Write documentation" -p 2 -t task
```

Filter and search:

```bash
bd list --status open --priority 1
bd list --type bug
bd ready --priority 0  # Find highest priority unblocked work
```

Work with dependencies:

```bash
# Make edge-ai-2 block edge-ai-1 (edge-ai-1 depends on edge-ai-2)
bd dep add edge-ai-2 edge-ai-1 --type blocks

# Add related work
bd dep add edge-ai-5 edge-ai-3 --type related

# Create parent-child relationship
bd dep add edge-ai-10 edge-ai-11 --type parent-child
```

Update issue status and fields:

```bash
# Claim work
bd update edge-ai-5 --status in_progress --assignee <your-username>

# Change priority
bd update edge-ai-7 --priority 0

# Add notes
bd update edge-ai-3 --notes "Blocked on API availability"
```

Get JSON output for scripting:

```bash
bd list --json
bd show edge-ai-1 --json
bd ready --json
```

### 💬 Using GitHub Copilot Chat (Recommended)

Instead of remembering CLI syntax, use Copilot Chat in agent mode:

* "List all open beads"
* "Create a bug for the login issue with high priority"
* "Show me edge-ai-5 details"
* "Mark edge-ai-3 as in progress"
* "Find ready work to do next"

Copilot will use the beads MCP server to execute commands and provide friendly, formatted responses.

## 🔄 Typical Beads Workflow

This workflow guides you from initial research through implementation and commit, using beads to track everything along the way.

### Phase 1: 📝 Research & Discovery

Use the `task-researcher` custom agent to build comprehensive research before creating beads.

1. Switch to `task-researcher` mode in Copilot Chat
2. Provide a research prompt with specific tools

Example Prompt:

```text
Research Azure IoT Operations deployment patterns deeply using microsoft-docs,
context7, and github_repo tools. Focus on authentication requirements,
network configuration, and observability setup. Think hard and build a
concise research document.
```

1. Review the generated research document
2. Save or attach the research for the next phase

### Phase 2: 🎯 Planning with bd-task-planner

Convert research into actionable beads with proper dependencies.

1. `/clear` your Copilot Chat context to start fresh
2. Switch to `bd-task-planner` custom agent
3. Invoke the planner with your research

Example:

```text
/bd-planner-plan
```

Then attach or reference your research document from Phase 1.

1. Review the proposed epic/feature/task/bug structure
2. Let Copilot create the beads with proper:
   * Descriptions and design notes
   * Acceptance criteria
   * Dependencies and priorities
   * Labels for filtering
3. Make adjustments by chatting with the planner:
   * "Update edge-ai-5 to add dependency on edge-ai-3"
   * "Change priority of edge-ai-7 to 0"
   * "Add more detail to edge-ai-4 acceptance criteria"

### Phase 3: ⚡ Implementation Loop

Work through beads systematically using agent mode.

#### Start a Bead

1. `/clear` the Copilot Chat context
2. Switch to **Agent** mode
3. Start work on the next ready bead

Without specific bead:

```text
/bd-start
```

With specific bead ID:

```text
/bd-start bead=edge-ai-5
```

Agent mode will:

* Fetch the bead details
* Review related beads and dependencies
* Read relevant instruction files
* Implement all required changes
* Update or create new beads for discoveries
* Complete the bead with summary

#### Review and Commit

1. Review all changes made by the agent
2. Test and validate the implementation
3. Work with the agent for adjustments if needed
4. Commit using the suggested commit message

Suggested workflow:

```bash
# Agent provides a commit message following conventions
git add .
git commit -m "feat(component): description from agent"
git push
```

#### Continue Next Bead

1. Go back to step 1 (clear context)
2. Start the next bead with `/bd-start`

### Phase 4: 🔍 Track Progress

Check your progress at any time:

```bash
bd ready              # See unblocked work
bd list --status open # All open issues
bd stats              # Project statistics
```

Or ask Copilot:

* "Show me all open beads"
* "What's ready to work on next?"
* "Show statistics for this project"

### Tips for Success

✅ Always `/clear` context between beads to avoid confusion

✅ Let agent mode discover and create new beads as work progresses

✅ Review agent changes before committing

✅ Use descriptive bead titles and detailed acceptance criteria

✅ Keep dependencies updated as you learn more

✅ Commit after each completed bead

❌ Don't skip the research phase for complex work

❌ Don't manually edit beads when agent mode can do it

❌ Don't ignore new discoveries—create beads for them

❌ Don't commit without reviewing agent changes

## 📚 Reference

### Project Files

| File                                                                                | Purpose                                                         |
|-------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| [bd-task-planner.agent.md](agents/bd-task-planner.agent.md)                         | Custom agent for planning work and creating beads from research |
| [bd-implementation.instructions.md](instructions/bd-implementation.instructions.md) | Instructions for agent mode implementation using beads          |
| [bd-planner-plan.prompt.md](prompts/bd-planner-plan.prompt.md)                      | Prompt template for bead planning workflow                      |
| [bd-start.prompt.md](prompts/bd-start.prompt.md)                                    | Prompt template for starting bead implementation                |

### External Resources

| Resource                                                                                          | Description                                   |
|---------------------------------------------------------------------------------------------------|-----------------------------------------------|
| [Beads Repository](https://github.com/steveyegge/beads)                                           | Official beads source code and documentation  |
| [Beads README](https://github.com/steveyegge/beads/blob/main/README.md)                           | Comprehensive beads documentation             |
| [Beads Workflow Guide](https://github.com/steveyegge/beads/blob/main/WORKFLOW.md)                 | Detailed workflow patterns and best practices |
| [VS Code MCP Documentation](https://code.visualstudio.com/docs/copilot/customization/mcp-servers) | Official VS Code MCP server documentation     |
| [Model Context Protocol](https://modelcontextprotocol.io/)                                        | MCP specification and documentation           |
| [beads-mcp PyPI](https://pypi.org/project/beads-mcp/)                                             | Python package for beads MCP server           |

### Getting Help

* Review existing beads: `bd list` or ask Copilot "show me all beads"
* Check bead details: `bd show <id>` or ask Copilot "show details for edge-ai-5"
* Find examples: Browse custom agents and prompts in this directory
* Ask Copilot: Use agent mode for interactive help with beads

🎉 **Ready to start?** Launch the Beads DevContainer and initialize beads:

```bash
bd init
```

Then use `/bd-planner-plan` in GitHub Copilot Chat to create your first set of beads!
