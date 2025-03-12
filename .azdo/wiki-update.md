# Wiki Update Integration

This document explains how the wiki update process is integrated into our build system through a reusable Azure DevOps pipeline template.

## Overview

The wiki update process synchronizes documentation from the main repository into the Azure DevOps wiki. This ensures that documentation stays up-to-date with code changes and is available in a user-friendly format within Azure DevOps.

## How the Wiki Update Process Works

The process:

1. **Checks out two repositories**:
   - The main code repository
   - The wiki repository

2. **Builds wiki content** using the `wiki-build.sh` script which:
   - Processes all markdown documentation files from the code repository
   - Formats them for the wiki
   - Generates a structured wiki hierarchy

3. **Syncs the content** to the wiki repository:
   - Replaces existing wiki content
   - Preserves wiki structure through `.order` files
   - Commits and pushes changes

4. **Only runs on successful builds** of the main branch to ensure only validated content is published

## Using the Wiki Update Template

The template is available at [`.azdo/wiki-update-template.yml`](./wiki-update-template.yml) and can be included in your project's pipeline.

### Parameters

| Parameter          | Type   | Default                                 | Description                              |
|--------------------|--------|-----------------------------------------|------------------------------------------|
| `dependsOn`        | object | `[]`                                    | Jobs this wiki update job depends on     |
| `displayName`      | string | 'Wiki Documentation Update'             | Custom display name for the job          |
| `condition`        | string | succeeded()                             | Condition to run this job                |
| `branchRepoFolder` | string | 'branch'                                | Folder name for the main branch checkout |
| `wikiRepoFolder`   | string | 'wiki'                                  | Folder name for the wiki branch checkout |
| `wikiRepo`         | string | 'git://edge-ai/edge-ai@refs/heads/wiki' | Wiki repository reference                |
| `wikiBranch`       | string | 'wiki'                                  | Wiki branch name                         |

### Example Usage

Include the template in your pipeline:

```yaml
stages:
  - stage: Documentation
    jobs:
      - template: .azdo/wiki-update-template.yml
        parameters:
          dependsOn: [BuildAndTest]
          condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
```

## Implementation Details

The template:

1. Creates directories for both repository checkouts
2. Performs the checkouts with credential persistence
3. Runs the wiki build script
4. Copies generated content to the wiki repository
5. Commits and pushes changes

The implementation ensures that the wiki is only updated when builds are successful, maintaining documentation quality and consistency with the codebase.

## Requirements

To use this template, you need:

1. A ["code" wiki](https://learn.microsoft.com/azure/devops/project/wiki/publish-repo-to-wiki) associated with your Azure DevOps project
2. The `wiki-build.sh` script to iterate over documentation and build the wiki contents

## Learn More

- [Azure DevOps Wiki Documentation](https://learn.microsoft.com/azure/devops/project/wiki/wiki-create-repo)
- [Wiki Markdown Syntax](https://learn.microsoft.com/azure/devops/project/wiki/markdown-guidance)
