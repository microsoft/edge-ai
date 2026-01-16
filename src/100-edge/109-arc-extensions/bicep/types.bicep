/*
 * IMPORTANT: The variable names in this file ('certManagerExtensionDefaults',
 * 'containerStorageExtensionDefaults') are explicitly referenced
 * by the aio-version-checker.py script. If you rename these variables or change their structure,
 * you must also update the script and the aio-version-checker-template.yml pipeline.
 */

@export()
@description('The common settings for Azure Arc Extensions.')
type Release = {
  @description('The version of the extension.')
  version: string

  @description('The release train that has the version to deploy (ex., "preview", "stable").')
  train: string

  @description('Whether to automatically upgrade minor versions of the extension.')
  autoUpgradeMinorVersion: bool?
}

@export()
@description('The settings for the cert-manager Extension.')
type CertManagerExtension = {
  @description('Whether to deploy the cert-manager extension.')
  enabled: bool

  @description('The common settings for the extension.')
  release: Release

  settings: {
    @description('Agent operation timeout in minutes.')
    agentOperationTimeoutInMinutes: string
    @description('Enable or disable global telemetry.')
    globalTelemetryEnabled: bool?
  }
}

@export()
var certManagerExtensionDefaults = {
  enabled: true
  release: {
    version: '0.7.0'
    train: 'stable'
    autoUpgradeMinorVersion: false
  }
  settings: {
    agentOperationTimeoutInMinutes: '20'
    globalTelemetryEnabled: true
  }
}

@export()
@description('The settings for the Azure Container Storage for Azure Arc Extension.')
type ContainerStorageExtension = {
  @description('Whether to deploy the container storage extension.')
  enabled: bool

  @description('The common settings for the extension.')
  release: Release

  settings: {
    @description('Whether or not to enable fault tolerant storage in the cluster.')
    faultToleranceEnabled: bool

    @description('The storage class for the cluster. (Otherwise, "acstor-arccontainerstorage-storage-pool" for fault tolerant storage else "default,local-path")')
    diskStorageClass: string?

    @description('The disk mount point for the cluster when using fault tolerant storage. (Otherwise: "/mnt" when using fault tolerant storage)')
    diskMountPoint: string?
  }
}

@export()
var containerStorageExtensionDefaults = {
  enabled: true
  release: {
    version: '2.6.0'
    train: 'stable'
  }
  settings: {
    faultToleranceEnabled: false
  }
}
