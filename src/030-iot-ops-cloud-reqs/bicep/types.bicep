@export()
@description('Settings for the Storage Account.')
type StorageAccountSettings = {
  @description('Tier for the Storage Account.')
  tier: 'Standard' | 'Premium'

  @description('Replication Type for the Storage Account.')
  replicationType: 'LRS' | 'ZRS' | 'GRS' | 'GZRS' | 'RAGRS' | 'RAGZRS'
}
