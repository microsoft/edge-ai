# Register providers

This folder contains a script that will register the required resource providers in your subscription.
This script only needs to be run once per subscription.

```bash
./register-azure-providers.sh aio-azure-resource-providers.txt
```

or

```pwsh
./register-azure-providers.ps1 -filePath azure-providers.txt
```

## Script prerequisites

- To register resource providers, you need permission to do the /register/action operation, which is included in subscription Contributor and Owner roles. For more information, see [Azure resource providers and types](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types).

## FAQ

- [Q] When I'm running the `register-azure-providers` script, I keep getting 'Bad Request' on register providers. What should I do?
- [A] Make sure you’ve cloned the repository with LF (Unix line endings). You can clone using WSL or Git for Windows while forcing Git to use LF endings.
  If you’re using Git for Windows, please set `core.autocrlf` to `false`, by running the following command:
  `git config --global core.autocrlf false`
