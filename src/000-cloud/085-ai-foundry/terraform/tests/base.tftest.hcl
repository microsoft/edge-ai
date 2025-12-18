provider "azurerm" {
  storage_use_azuread = true
  features {}
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = run.setup_tests.environment
    location        = run.setup_tests.location
    instance        = run.setup_tests.instance
    resource_group  = run.setup_tests.resource_group
  }

  assert {
    condition     = output.ai_foundry_name == "aif-${run.setup_tests.resource_prefix}-${run.setup_tests.environment}-${run.setup_tests.instance}"
    error_message = "AI Foundry account name does not match expected pattern"
  }

  assert {
    condition     = output.ai_foundry_endpoint == "https://aif-${run.setup_tests.resource_prefix}-${run.setup_tests.environment}-${run.setup_tests.instance}.cognitiveservices.azure.com"
    error_message = "AI Foundry endpoint does not match expected pattern"
  }

  assert {
    condition     = length(output.projects) == 0
    error_message = "Projects should be empty when ai_projects is not provided"
  }

  assert {
    condition     = length(output.deployments) == 0
    error_message = "Deployments should be empty when model_deployments is not provided"
  }

  assert {
    condition     = output.private_endpoint == null
    error_message = "Private endpoint should be null when should_enable_private_endpoint is false"
  }
}

run "create_with_project" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = run.setup_tests.environment
    location        = run.setup_tests.location
    instance        = run.setup_tests.instance
    resource_group  = run.setup_tests.resource_group
    ai_projects = {
      sidekick = {
        name         = "aio-sidekick"
        display_name = "AIO Sidekick Project"
        description  = "AI project for AIO Sidekick development"
      }
    }
  }

  assert {
    condition     = length(output.projects) == 1
    error_message = "Expected exactly one project to be created"
  }

  assert {
    condition     = contains(keys(output.projects), "sidekick")
    error_message = "Expected project key 'sidekick' to exist in projects output"
  }
}

run "create_with_model_deployments" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = run.setup_tests.environment
    location        = run.setup_tests.location
    instance        = run.setup_tests.instance
    resource_group  = run.setup_tests.resource_group
    model_deployments = {
      gpt4o = {
        name = "gpt-4o"
        model = {
          format  = "OpenAI"
          name    = "gpt-4o"
          version = "2024-11-20"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 10
        }
      }
      embedding = {
        name = "text-embedding-ada-002"
        model = {
          format  = "OpenAI"
          name    = "text-embedding-ada-002"
          version = "2"
        }
        scale = {
          type     = "Standard"
          capacity = 120
        }
      }
    }
  }

  assert {
    condition     = length(output.deployments) == 2
    error_message = "Expected exactly two deployments to be created"
  }

  assert {
    condition     = contains(keys(output.deployments), "gpt4o")
    error_message = "Expected deployment key 'gpt4o' to exist in deployments output"
  }

  assert {
    condition     = contains(keys(output.deployments), "embedding")
    error_message = "Expected deployment key 'embedding' to exist in deployments output"
  }
}

run "create_with_public_access_disabled" {
  command = plan

  variables {
    resource_prefix                     = run.setup_tests.resource_prefix
    environment                         = run.setup_tests.environment
    location                            = run.setup_tests.location
    instance                            = run.setup_tests.instance
    resource_group                      = run.setup_tests.resource_group
    should_enable_public_network_access = false
    should_enable_local_auth            = false
  }

  assert {
    condition     = output.ai_foundry_name == "aif-${run.setup_tests.resource_prefix}-${run.setup_tests.environment}-${run.setup_tests.instance}"
    error_message = "AI Foundry account should be created even with public access disabled"
  }
}

run "create_full_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = run.setup_tests.environment
    location        = run.setup_tests.location
    instance        = run.setup_tests.instance
    resource_group  = run.setup_tests.resource_group
    ai_projects = {
      sidekick = {
        name         = "aio-sidekick"
        display_name = "AIO Sidekick Project"
        description  = "AI project for AIO Sidekick development"
      }
      analytics = {
        name         = "analytics"
        display_name = "Analytics Project"
        description  = "AI project for analytics workloads"
      }
    }
    model_deployments = {
      gpt4o = {
        name = "gpt-4o"
        model = {
          format  = "OpenAI"
          name    = "gpt-4o"
          version = "2024-11-20"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 10
        }
      }
    }
    tags = {
      environment = "test"
      component   = "ai-foundry"
    }
  }

  assert {
    condition     = length(output.projects) == 2
    error_message = "Expected exactly two projects to be created"
  }

  assert {
    condition     = length(output.deployments) == 1
    error_message = "Expected exactly one deployment to be created"
  }

  assert {
    condition     = output.ai_foundry != null
    error_message = "Microsoft Foundry account output should not be null"
  }
}
