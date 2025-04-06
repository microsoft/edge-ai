@export()
@description('The storage profile for the VM.')
type StorageProfile = {
  @description('The image reference for the VM.')
  imageReference: {
    publisher: string
    offer: string
    sku: string
    version: string
  }
  @description('The OS disk configuration for the VM.')
  osDisk: {
    createOption: string
    managedDisk: {
      storageAccountType: string
    }
  }
}

@export()
@description('Default storage profile config for VMs, with image reference for Ubuntu Server and OS disk settings with LRS storage.')
var storageProfileDefaults = {
  imageReference: {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
  osDisk: {
    createOption: 'FromImage'
    managedDisk: {
      storageAccountType: 'Standard_LRS'
    }
  }
}
