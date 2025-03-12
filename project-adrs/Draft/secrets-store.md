# Secrets Store

## Overview

As part of the AI flagship development cycles it is also important to consider security of secrets that are used in the project. This document describes how we maintain sensitive data like subscriptionID, clientId, certs, and secrets.

## KeyVault Inventory

KeyVault **kv-ai-on-edge-azdo** in the underlying Azure subscription is used to maintain all the secrets for the project.

## Azure DevOps Library/Variable Group

The KeyVault is linked to Azure DevOps Variable Groups **ai-on-edge-secrets** and **azdo-build-vars** which make secrets available and accessible to the Azure DevOps Pipelines.

## Documentation References

### Azure KeyVault

- [Azure Key Vault basic concepts](https://learn.microsoft.com/azure/key-vault/general/basic-concepts)
- [About keys, secrets, and certificates](https://learn.microsoft.com/azure/key-vault/general/about-keys-secrets-certificates)
- [Secure access to a key vault](https://learn.microsoft.com/azure/key-vault/general/secure-your-key-vault)

### Azure DevOps Secrets Management

- [Use Azure Key Vault secrets in Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/release/azure-key-vault?view=azure-devops)
- [Define variables in Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch)
- [Variable groups for Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml)
- [Link secrets from Azure Key Vault to Variable Groups](https://learn.microsoft.com/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml#link-secrets-from-an-azure-key-vault)
- [Use secrets from variable groups in Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml#use-a-variable-group)

### GitHub Secrets Management

- [Encrypted secrets in GitHub Actions](https://docs.github.com/actions/security-guides/encrypted-secrets)
- [Using secrets in GitHub Actions](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions)
- [Environment secrets in GitHub](https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment#environment-secrets)
- [Organization-level secrets](https://docs.github.com/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-organization)

### Integration between Azure Key Vault and GitHub

- [Use Key Vault secrets in GitHub Actions workflows](https://learn.microsoft.com/azure/developer/github/github-key-vault)
- [Azure Key Vault Actions for GitHub](https://github.com/marketplace/actions/azure-key-vault-get-secrets)
- [Authentication in GitHub Actions using Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux#use-the-azure-login-action-with-a-service-principal-secret)
