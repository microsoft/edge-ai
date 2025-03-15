# Documentation Quality Check Template

This template provides automated documentation quality checks to ensure consistent standards across the codebase. It focuses on two critical areas:

1. **Terraform Documentation Consistency**: Ensures Terraform module documentation is up-to-date with the actual code
2. **Link Language Path Detection**: Identifies URLs with language-specific paths ('en-us') that could cause internationalization issues

## How Documentation Checks Work in Our Build System

Documentation checks run as part of our CI/CD pipeline to validate documentation quality before changes are merged. The template:

1. **Validates Terraform documentation** matches the current state of the code
2. **Scans all tracked files** for language-specific URLs
3. **Generates build warnings or errors** for documentation issues
4. **Helps maintain documentation quality** across the codebase

### Related Tools and Scripts

The template leverages the following tools and scripts:

| Tool/Script                            | Purpose                                               |
|----------------------------------------|-------------------------------------------------------|
| `terraform-docs`                       | Tool to generate documentation from Terraform modules |
| `scripts/tf-docs-check.sh`             | Script that checks if Terraform docs need updating    |
| `scripts/update-all-terraform-docs.sh` | Script to update all Terraform documentation          |
| `scripts/link-lang-check.py`           | Script to detect and report URLs with language paths  |

## Using the Documentation Check Template

This reusable template simplifies the integration of documentation quality checks into your Azure DevOps pipelines and ensures consistent standards across all pipelines.

### Template Location

The template is available at [`.azdo/docs-check-template.yml`](./docs-check-template.yml)

### Parameters

| Parameter     | Type   | Default                       | Description                         |
|---------------|--------|-------------------------------|-------------------------------------|
| `dependsOn`   | object | `''`                          | Jobs this docs check job depends on |
| `displayName` | string | 'Documentation Quality Check' | Custom display name for the job     |
| `condition`   | string | 'succeeded()'                 | Condition to run this job           |

### Example Usage

Here's how to integrate the documentation check template into your Azure DevOps pipeline:

```yaml
# Basic usage
stages:
  - stage: Validate
    jobs:
      - template: .azdo/docs-check-template.yml

# Advanced usage with parameters
stages:
  - stage: Validate
    jobs:
      - template: .azdo/docs-check-template.yml
        parameters:
          displayName: 'Check Documentation Quality'
          dependsOn: [MegaLinter]
          condition: succeeded('MegaLinter')
```

## Build Pipeline Integration

The documentation check template is integrated into our Azure DevOps pipeline in the PR stage, where it:

1. **Validates Terraform Documentation**:
   - Runs `tf-docs-check.sh` to determine if Terraform documentation needs updating
   - Generates build errors with remediation instructions if documentation is outdated

2. **Performs Language Path Checks**:
   - Scans for URLs with 'en-us' language path segments
   - Creates source-linked warnings for each problematic URL
   - Makes internationalization issues visible during PR reviews

## Terraform Documentation Checks

The template validates that Terraform module documentation is up-to-date by:

1. Installing the `terraform-docs` utility if not already present
2. Executing `tf-docs-check.sh` to check if documentation needs updating
3. Failing the build with instructions if documentation is outdated

### How to Fix Terraform Documentation Issues

If the build fails due to outdated Terraform documentation:

1. Run `./scripts/update-all-terraform-docs.sh` locally
2. Commit and push the updated documentation files
3. The build will then pass if no other issues are found

## Link Language Path Checks

The template scans for URLs with language-specific paths (e.g., 'en-us') by:

1. Running `link-lang-check.py` to identify problematic URLs in all git-tracked text files
2. Generating build warnings with file locations and line numbers
3. Making it easy to locate and fix internationalization issues

### How to Fix Link Issues

When links with language paths are detected:

1. Manually edit the files to remove the 'en-us/' segment from URLs
2. Or run `python3 scripts/link-lang-check.py -f` to automatically fix all occurrences
3. Commit and push the changes

## Why Documentation Quality Matters

### Benefits of Automated Documentation Checks

- **Consistency**: Documentation stays in sync with code
- **Internationalization**: Links work for users in all regions and languages
- **Quality Assurance**: Automated checks catch issues humans might miss
- **Developer Experience**: Clear feedback on how to fix documentation issues
- **Reduced Technical Debt**: Prevents documentation drift over time

### Getting Started in Your Project

1. Copy the `.azdo/docs-check-template.yml` template to your project
2. Copy the related scripts from the `scripts/` directory
3. Reference the template in your pipeline definition
4. Run the scripts locally to fix any initial issues
5. Commit both the template and fixed documentation

## Learn More

- [Terraform Docs Documentation](https://terraform-docs.io/)
- [Microsoft Internationalization Guidelines](https://learn.microsoft.com/en-us/style-guide/global-communications/)
- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/templates)
