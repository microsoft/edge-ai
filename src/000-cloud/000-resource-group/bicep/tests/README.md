---
title: Testing Bicep
description: Tests for the Bicep implementation of the resource group component, including testing the useExistingResourceGroup functionality
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - testing
  - bicep
  - resource group
  - azure cli
  - existing resource group
  - integration testing
  - cicd pipeline
estimated_reading_time: 3
---

## Testing Bicep

This directory contains tests for the Bicep implementation of the resource group component.

## Testing the "Existing Resource Group" Functionality

Testing the `useExistingResourceGroup` functionality presents unique challenges because it requires referencing an actual Azure resource. This document outlines the available testing approaches.

### Option 1: Using the Test Script

Execute the provided test script to automatically:

1. Create a temporary resource group in Azure
2. Deploy a Bicep template that references the existing resource group
3. Verify the outputs correctly reference the existing resource group
4. Clean up resources after testing

```sh
./test-existing-resource-group.sh
```

### Option 2: Manual Testing with Azure CLI

If you prefer to test manually:

1. Create a resource group in Azure:

   ```sh
   az group create --name existing-rg-test --location eastus
   ```

2. Deploy the Bicep module with existing resource group parameters:

   ```sh
   az deployment sub create \
     --name test-existing-rg \
     --location eastus \
     --template-file ../main.bicep \
     --parameters useExistingResourceGroup=true resourceGroupName=existing-rg-test \
     --parameters common='{\"resourcePrefix\":\"test\",\"location\":\"eastus\",\"environment\":\"dev\",\"instance\":\"001\"}'
   ```

3. Verify the outputs reference the existing resource group

4. Delete the test resources:

   ```sh
   az group delete --name existing-rg-test --yes
   ```

### Option 3: Integration Testing in CI/CD Pipeline

For automated testing in a CI/CD pipeline, consider:

1. Creating a resource group as part of the pipeline
2. Deploying the component with `useExistingResourceGroup = true`
3. Verifying the outputs reference the existing resource group
4. Cleaning up the resource group

This approach requires custom scripting but provides more reliable automated testing.

### What to Verify in Tests

When testing the existing resource group functionality, verify:

1. The module correctly references the existing resource group instead of creating a new one
2. The module outputs provide the correct resource group ID, name, and location
3. Downstream resources that depend on the resource group are correctly placed in the existing resource group
4. Error handling works as expected when the specified resource group doesn't exist

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
