# Register providers

This folder contains a script that will register the required resource providers in your subscription.
This script only needs to be run once per subscription.

```bash
./register_providers.sh
```

## Script prerequisites

- To register resource providers, you need permission to do the /register/action operation, which is included in subscription Contributor and Owner roles. For more information, see [Azure resource providers and types](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types).
