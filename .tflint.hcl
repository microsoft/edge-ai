# TFLint Configuration
# See: https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md
# Based on MegaLinter default: https://github.com/oxsecurity/megalinter/blob/main/TEMPLATES/.tflint.hcl

config {
  call_module_type = "local"
  force            = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Disabled by MegaLinter default template
rule "terraform_required_providers" {
  enabled = false
}

# TODO: Re-enable after adding lifecycle prevent_destroy blocks
# Tracked by: https://github.com/microsoft/edge-ai/issues/104
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
