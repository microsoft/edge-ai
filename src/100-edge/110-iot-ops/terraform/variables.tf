/*
 * Optional Variables
 */

variable "trust_config_source" {
  type    = string
  default = "SelfSigned"
  validation {
    condition     = contains(["SelfSigned", "CustomerManagedByoIssuer", "CustomerManagedGenerateIssuer"], var.trust_config_source)
    error_message = "TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'"
  }
  description = "TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'. Defaults to SelfSigned. When choosing CustomerManagedGenerateIssuer, ensure connectedk8s proxy is enabled on the cluster for current user. When choosing CustomerManagedByoIssuer, ensure an Issuer and ConfigMap resources exist in the cluster."
}

variable "byo_issuer_trust_settings" {
  type = object({
    issuer_name    = string
    issuer_kind    = string
    configmap_name = string
    configmap_key  = string
  })
  default = null
  validation {
    condition     = var.trust_config_source == "CustomerManagedByoIssuer" ? var.byo_issuer_trust_settings != null : var.byo_issuer_trust_settings == null
    error_message = "If 'trust_config_source' is 'CustomerManagedByoIssuer' then 'byo_issuer_trust_settings' must be non-null. If 'trust_config_source' is any other value, then 'byo_issuer_trust_settings' must be null."
  }
  validation {
    condition = var.byo_issuer_trust_settings == null ? true : alltrue([
      for _, value in var.byo_issuer_trust_settings : (value != null && value != "")
    ])
    error_message = "All fields are required for 'byo_issuer_trust_settings'."
  }
  description = "Settings for CustomerManagedByoIssuer (Bring Your Own Issuer) trust configuration"
}

variable "aio_ca" {
  type = object({
    root_ca_cert_pem  = string
    ca_cert_chain_pem = string
    ca_key_pem        = string
  })
  sensitive = true
  default   = null
  validation {
    condition     = var.aio_ca == null ? true : (var.aio_ca.ca_cert_chain_pem != "" && var.aio_ca.ca_key_pem != "" && var.aio_ca.root_ca_cert_pem != "")
    error_message = "The values for ca_key_pem, ca_cert_chain_pem and root_ca_cert_pem must be provided"
  }

  validation {
    condition     = var.trust_config_source != "SelfSigned" || var.aio_ca == null
    error_message = "AIO CA cannot be provided when Trust Source is set to SelfSigned"
  }
  description = "CA certificate for the MQTT broker, can be either Root CA or Root CA with any number of Intermediate CAs. If not provided, a self-signed Root CA with a intermediate will be generated. Only valid when Trust Source is set to CustomerManaged"
}

variable "aio_platform_config" {
  type = object({
    install_cert_manager  = bool
    install_trust_manager = bool
  })
  default = {
    install_cert_manager  = true
    install_trust_manager = true
  }
  validation {
    condition     = var.trust_config_source == "CustomerManagedByoIssuer" ? (var.aio_platform_config.install_cert_manager == false && var.aio_platform_config.install_trust_manager == false) : true
    error_message = "When trust_config_source is CustomerManagedByoIssuer, install_cert_manager and install_trust_manager must be false because these should always be installed as a pre-requisite"
  }
  description = "Install cert-manager and trust-manager extensions"
}

variable "enable_opc_ua_simulator" {
  type        = bool
  default     = true
  description = "Deploy OPC UA Simulator to the cluster"
}

variable "should_enable_otel_collector" {
  type        = bool
  description = "Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap"
  default     = true
}

variable "should_assign_key_vault_roles" {
  description = "Whether to assign Key Vault roles to provided Secret Sync identity."
  type        = bool
  default     = true
}

/*
 * Akri REST HTTP Connector Configuration
 */

variable "should_enable_akri_rest_connector" {
  type        = bool
  default     = false
  description = "Deploy Akri REST HTTP Connector template to the IoT Operations instance"
}

variable "akri_rest_connector_config" {
  type = object({
    template_name        = optional(string, "rest-http-connector")
    image_tag            = optional(string, "latest")
    log_level            = optional(string, "Info")
    replicas             = optional(number, 1)
    mqtt_broker_host     = optional(string, "aio-mq-dmqtt-frontend:8883")
    mqtt_broker_audience = optional(string, "aio-mq")
    mqtt_ca_configmap    = optional(string, "aio-ca-trust-bundle-test-only")
  })
  default     = {}
  description = "Configuration for the Akri REST HTTP Connector. Only used when should_enable_akri_rest_connector is true."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.akri_rest_connector_config.template_name))
    error_message = "Connector template name must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition     = contains(["Trace", "Debug", "Info", "Warning", "Error", "Critical"], var.akri_rest_connector_config.log_level)
    error_message = "Log level must be one of: Trace, Debug, Info, Warning, Error, Critical."
  }

  validation {
    condition     = var.akri_rest_connector_config.replicas >= 1 && var.akri_rest_connector_config.replicas <= 10
    error_message = "Connector replicas must be between 1 and 10."
  }
}
