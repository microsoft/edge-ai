# Bicep Test Framework Selection

Date: **2025-05-22** [Format=YYYY-MM-DD]

## Status

- [x] Draft
- [ ] Proposed
- [ ] Accepted
- [ ] Deprecated
- [ ] Superseded by

## Decision

We need to establish a standardized approach for testing Bicep templates in our infrastructure as code (IaC) pipeline to ensure consistency, quality, and adherence to best practices, with an approach that mirrors our existing Terraform testing capabilities.

## Context

Azure Bicep templates form a critical part of our infrastructure deployment strategy, particularly for cloud resources. As our infrastructure grows in complexity, we need a robust testing framework to validate Bicep templates before deployment to ensure they:

1. Are syntactically correct and following best practices
1. Comply with organizational standards and naming conventions
1. Adhere to security best practices
1. Produce the expected resource configurations when deployed

Currently, testing of Bicep files is manual and inconsistent across teams. Without a standardized testing approach, we risk:

- Configuration drift between environments
- Security vulnerabilities from improperly configured resources
- Deployment failures that impact production services
- Difficulty in maintaining and understanding templates over time

Our repository already has a robust testing approach for Terraform modules using the built-in Terraform testing framework (tftest.hcl files). This testing approach allows for both unit testing and integration testing, providing both pre-deployment validation and post-deployment verification.

We need a similar capability for Bicep templates that offers:

- A standardized structure mirroring our Terraform test organization
- Support for both unit and integration tests
- The ability to test both functional correctness and compliance with best practices
- Integration with our existing CI/CD pipelines

## Decision drivers

- **Reliability**: Need to catch errors before deployment to production environments
- **Standardization**: Enforce consistent patterns across all infrastructure components
- **Shift Left**: Move testing earlier in the development lifecycle
- **Developer Experience**: Make testing accessible and user-friendly for infrastructure developers
- **CI/CD Integration**: Must integrate smoothly with our existing CI/CD pipelines
- **Maturity**: Solution should be well-supported and have an active community
- **Coverage**: Should cover multiple testing scenarios (syntax, security, policy compliance)
- **Feature Parity**: Should provide capabilities similar to our Terraform testing approach
- **Organization**: Should follow a similar directory structure and naming convention as our Terraform tests

## Considered options

### 1. Experimental Bicep Test Framework

The Bicep team at Microsoft has been developing an experimental test framework that allows for client-side tests without deploying to Azure. It introduces `assert` statements and `test` blocks.

**Pros:**

- Native to Bicep - tight integration with the language
- Client-side testing without deployment
- Simple assertion syntax that fits naturally with Bicep
- Potential future integration with official Bicep tooling
- Most similar to Terraform's testing framework in concept and structure

**Cons:**

- Currently in experimental stage and development is on hold
- Limited functionality compared to mature testing frameworks
- Uncertain future support and timeline for production readiness
- Only tests basic properties - cannot validate actual deployed resources

**Risks:**

- Investing in a framework that might be abandoned or significantly changed
- Limited testing scope could miss important validation scenarios
- Would require custom extensions to cover all our testing needs

### 2. Pester Framework with PowerShell

Pester is a testing and mocking framework for PowerShell that can be adapted to test Bicep files through custom test scripts.

**Pros:**

- Mature framework with extensive documentation
- Highly customizable for specific testing needs
- Can be integrated into CI/CD pipelines
- Can validate both Bicep files and deployment results
- Well-established in Microsoft ecosystem
- Can be structured to mirror our Terraform test organization

**Cons:**

- Requires PowerShell knowledge
- Not specific to Bicep - custom test scripts needed
- More complex setup compared to native solutions
- Test maintenance adds overhead

**Risks:**

- Test scripts may diverge between teams without strict governance
- Higher learning curve for developers not familiar with PowerShell
- Test suite maintenance can become a significant overhead

### 3. PSRule for Azure

PSRule for Azure is a static analysis tool that validates Azure resources against the Azure Well-Architected Framework and custom organizational rules.

**Pros:**

- Specifically designed for validating Azure resources
- 260+ built-in rules based on Well-Architected Framework
- Can run pre-deployment with Bicep files
- Integrates with VS Code, Azure DevOps, and GitHub Actions
- Supports custom rule creation for organization-specific requirements
- Results can be published to Azure Monitor

**Cons:**

- More focused on compliance than functional testing
- Requires understanding of PSRule rule creation for custom requirements
- Additional tool in the toolchain
- Does not directly test logical flow within templates

**Risks:**

- May generate false positives for valid design decisions
- Rule governance requires additional management
- May overlap with existing policy enforcement mechanisms

### 4. Combination Approach

Use multiple tools together to provide comprehensive coverage:

- PSRule for standards compliance and best practices
- Pester for functional and integration testing
- ARM Template Toolkit (arm-ttk) for baseline validation
- Bicep built-in linter for syntax checking

**Pros:**

- Comprehensive coverage of different testing aspects
- Leverages strengths of each tool
- Future-proof as tools evolve independently
- Most thorough validation of templates
- Can be organized to mirror our Terraform testing structure

**Cons:**

- Most complex to implement and maintain
- Requires knowledge of multiple frameworks
- May slow down CI/CD pipeline execution
- Potential for conflicting or redundant rules

**Risks:**

- Overhead of maintaining multiple testing frameworks
- Integration complexity between tools
- Potential confusion for developers about which tool to use when

## Decision Conclusion

After evaluating the options, we recommend adopting the **Combination Approach** with:

1. **PSRule for Azure** as the primary compliance validation tool
1. **Pester Framework** for functional testing and custom validations
1. Built-in **Bicep linting** for basic syntax and style checks

This approach should be implemented with a structure that mirrors our existing Terraform testing organization:

- Test files should be organized in a `tests` directory within each Bicep component
- Each test should be in a separate file with a descriptive name following the `.tests.bicep` convention (for Pester tests)
- Tests should be categorized into unit tests (pre-deployment) and integration tests (post-deployment)

The Pester framework will be used to create a wrapper that provides an experience similar to Terraform's testing framework, with the ability to define test scenarios, input variables, and assertions. The PSRule for Azure will provide additional compliance validation similar to the policy checks that Terraform tests perform.

This combined approach allows us to implement testing in phases, starting with the built-in Bicep linter and PSRule for Azure, then expanding to include Pester tests for more complex validation scenarios as our testing practices mature.

While the Experimental Bicep Test Framework most closely resembles Terraform's testing capabilities, its uncertain future makes it risky to adopt as our primary testing strategy. However, we should continue to monitor its development and potentially adopt it if it becomes officially supported.

### PSRule Implementation Details

PSRule for Azure provides comprehensive static analysis capabilities for our Bicep files. This section outlines the specific implementation details for PSRule within our project structure.

#### PSRule Configuration

To enable PSRule to analyze Bicep files, we'll need the following configuration in a `ps-rule.yaml` file at the component root:

```yaml
configuration:
  # Enable expansion for Bicep source files
  AZURE_BICEP_FILE_EXPANSION: true

  # Set minimum Bicep CLI version (for private registry support)
  AZURE_BICEP_MINIMUM_VERSION: '0.35.1'

input:
  pathIgnore:
  # Exclude bicepconfig.json
  - 'bicepconfig.json'
  # Exclude module files with required parameters
  - 'modules/**/*.bicep'
  # Include test files from modules
  - '!modules/**/*.tests.bicep'
```

#### Repository Structure for PSRule

Custom rules and PSRule configurations should follow this structure within each component:

```text
src/
  000-cloud/
    010-security-identity/
      bicep/
        modules/
        tests/
        .ps-rule/  # Custom PSRule rules location
          rules/    # Custom rule definitions
          ps-rule.yaml  # Component-specific configuration
```

#### Custom Rule Creation

Custom rules allow us to enforce organization-specific standards beyond the built-in PSRule checks. Rules should be created in PowerShell as follows:

```powershell
# Example: Custom rule for storage account TLS version enforcement
# File location: .ps-rule/rules/Custom.StorageAccountSecurity.ps1

# Rule documentation comment describing purpose, requirements, and examples
Rule 'Custom.Storage.MinimumTlsVersion' -Type 'Microsoft.Storage/storageAccounts' {
    $Assert.HasFieldValue($TargetObject, 'properties.minimumTlsVersion', '1.2')
}

# Rule to enforce tag requirements
Rule 'Custom.Tags.Required' {
    $requiredTags = @('environment', 'owner', 'costCenter')
    $hasAllTags = $true

    foreach ($tag in $requiredTags) {
        if ($TargetObject.tags -eq $null -or -not $TargetObject.tags.ContainsKey($tag)) {
            $hasAllTags = $false
            break
        }
    }

    return $hasAllTags
}
```

#### CI/CD Integration

PSRule should be integrated into the CI/CD pipeline alongside the existing MegaLinter process:

```yaml
# For GitHub Actions
- name: Analyze with PSRule for Azure
  uses: microsoft/ps-rule@v2.9.0
  with:
    modules: PSRule.Rules.Azure
    inputPath: src/000-cloud/010-security-identity/bicep
    outputFormat: Sarif,NUnit3
    outputPath: reports/ps-rule-results

# For Azure DevOps Pipelines
- task: ps-rule-assert@2
  displayName: Analyze with PSRule for Azure
  inputs:
    inputType: repository
    inputPath: src/000-cloud/010-security-identity/bicep
    modules: PSRule.Rules.Azure
```

#### Rule Governance Process

To maintain quality and consistency, we'll follow this governance process for custom rules:

1. **Rule Naming Convention**:
   - Use `Custom.<Category>.<Requirement>` format
   - Categories should be aligned with Azure resource types or cross-cutting concerns

2. **Rule Documentation Requirements**:
   - Each rule must include a comment block describing purpose
   - Documentation should include examples of compliant and non-compliant resources
   - Include references to relevant security/architecture standards when applicable

3. **Rule Development Workflow**:
   - Create rules in feature branches
   - Include test cases showing rule effectiveness
   - Require peer review from at least one infrastructure SME
   - Test rules against existing resources to validate accuracy

4. **Rule Management**:
   - Review custom rules quarterly for relevance
   - Version rules alongside infrastructure code
   - Document rule exceptions and suppression policies

## Consequences

### Positive

- Improved infrastructure quality and consistency
- Earlier detection of issues before deployment
- Better alignment with Azure Well-Architected Framework
- Standardized testing approach across teams
- Reduced risk of security and compliance issues
- Enhanced developer confidence in infrastructure changes
- Testing parity between Terraform and Bicep components

### Negative

- Learning curve for teams to understand multiple tools
- Additional maintenance overhead for test scripts and rules
- Potential for longer build times due to multiple validation steps
- Need for governance around custom rule creation and maintenance
- Testing approach differences between Terraform and Bicep may cause confusion

## References

### Bicep Test Framework

- [Exploring the Bicep Test Framework][bicep-test-framework] - Overview of the experimental Bicep test framework capabilities
- [Bicep Experimental Test Framework GitHub Issue #11967][bicep-issue-11967] - Official tracking issue for the experimental Bicep test framework
- [Bicep Experimental Test Framework Comment on Development Status][bicep-comment] - Recent comment indicating development is on hold

### Pester Framework for Bicep

- [Pester Unit Tests for Azure Bicep Modules][pester-bicep] - Implementation approach for using Pester with Bicep modules
- [Pester Framework Official Documentation][pester-docs] - Official Pester framework documentation

### PSRule for Azure

- [PSRule Introduction to Infrastructure as Code Testing][psrule-intro] - Introduction to using PSRule for IaC testing
- [PSRule for Azure Official Repository][psrule-azure] - Official PSRule for Azure repository with documentation
- [Using Bicep with PSRule for Azure][psrule-bicep] - Detailed guide for using PSRule with Bicep files

### Terraform Testing Framework

- [Terraform Testing Framework Documentation][terraform-tests] - Official documentation for Terraform's built-in testing framework used as a reference

[bicep-test-framework]: https://rios.engineer/exploring-the-bicep-test-framework-%F0%9F%A7%AA/
[bicep-issue-11967]: https://github.com/Azure/bicep/issues/11967
[bicep-comment]: https://github.com/Azure/bicep/issues/11967#issuecomment-2885294942
[pester-bicep]: https://rios.engineer/pester-unit-tests-for-azure-bicep-modules/
[pester-docs]: https://pester.dev/docs/quick-start
[psrule-intro]: https://techcommunity.microsoft.com/blog/itopstalkblog/psrule-introduction-to-infrastructure-as-code-iac-testing/3580746
[psrule-azure]: https://github.com/Azure/PSRule.Rules.Azure
[psrule-bicep]: https://github.com/Azure/PSRule.Rules.Azure/blob/main/docs/using-bicep.md
[terraform-tests]: https://developer.hashicorp.com/terraform/language/tests
