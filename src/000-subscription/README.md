# Register providers

This folder contains scripts that will register the required resource providers in your subscription.
The registration script only needs to be run once per subscription.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- To register resource providers, you need permission to do the /register/action operation, which is included in subscription Contributor and Owner roles. For more information, see [Azure resource providers and types](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types).

## Getting Started

Login to Azure CLI using the below command:

```sh
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```

Run either script example below, depending on your environment.

### Shell Example

```sh
./register-azure-providers.sh aio-azure-resource-providers.txt
```

### PowerShell Example

```pwsh
./register-azure-providers.ps1 -filePath aio-azure-resource-providers.txt
```

### PowerShell Testing

This PowerShell script contains Pester tests `register-azure-providers.ps1`. Ensure you navigate to the current directory and run the following:

```pwsh
Invoke-Pester -Script ./register-azure-providers.Tests.ps1
```

## FAQ

- [Q] When I'm running the `register-azure-providers` script, I keep getting 'Bad Request' on register providers. What should I do?
- [A] Make sure you’ve cloned the repository with LF (Unix line endings). You can clone using WSL or Git for Windows while forcing Git to use LF endings.
  If you’re using Git for Windows, please set `core.autocrlf` to `false`, by running the following command:
  `git config --global core.autocrlf false`
