# GitFlow Branching Strategy

## Introduction

This project uses the [GitFlow branching strategy](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).
It helps manage features, hotfixes, and releases with rules for branch creation, merging, and deletion.

## How it works

![GitFlow](./media/gitflow-overview.svg)

### Develop and main Branches

Using the GitFlow branching strategy means maintaining two branches: `develop` and `main`.

Traditional GitFlow utilizes a develop and main branch. For this accelerator we will use a main branch for both, however, they will reside in different repositories:

- GitFlow develop branch -> main in [AzDO](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/_git/IaC%20for%20the%20Edge?path=%2F&version=GBmain&_a=contents)
- GitFlow main branch -> main in [GitHub](https://github.com/commercial-software-engineering/Iac-for-the-Edge/tree/main)

### Feature Branches

![GitFlowFeatureBranches](./media/gitflow-feature-branches.svg)

Feature branches are created based on the `develop` (AzDO main) branch. They are used to develop new features for the upcoming future release. When a feature is complete, it gets merged back into `develop` (AzDO main). Feature branches should never interact directly with `main`.

### Release Branches

![GitFlowReleaseBranches](./media/gitflow-release-branches.svg)

Once `develop` (AzDO main) has acquired enough features for a release (or a predetermined release date is approaching), you create a `release` branch off of `develop` (AzDO main).

Release cycles might not be so important and interesting in the scope of the AI Flagship Accelerator project, but it is a good practice to have a dedicated branch for preparing releases.

Once the release is ready to ship, it will get merged into `main` and `develop` (AzDO main), then the `release` branch will be deleted. It's important to merge back into `develop` (AzDO main) because critical updates may have been added to the `release` branch and they need to be accessible to new features.

### AzDO to GitHub Sync

Once the changes are merged into `develop` (AzDO main), the changes are synced to GitHub `main` branch. This is handled automatically by utilizing the Azure DevOps Pipeline [AzDO to GitHub](/.azdo/github-push.yaml).

### Hotfix Branches

![GitflowHotfixBranches](./media/gitflow-hotfix-branches.svg)

Maintenance or `hotfix` branches are used to quickly patch production releases that exist in the GitHub `main` or in Azure Devops `release` branches. This is the only branch that should fork directly off of `main`. As soon as the fix is complete, it should be merged into both `main` and `develop` (or the current `release` branch), and `main` should be tagged with an updated version number.

Most likely, we have bugfix or feature branches for our use-case that will be maintained in the AzDO repository and based on the `develop` (AzDO main) branch.

#### GitHub to AzDO Sync

Once hotfixes are applied to the `main` branch in GitHub, the changes are synced to the `develop` branch in AzDO. This is covered once per hour on a pull-based mechanism due to secure authentication from AzDO to GitHub by using a GitHub App. The Sync is executed by the Azure DevOps Pipeline [GitHub to AzDO](/.azdo/github-pull.yaml).

## References

- [Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
