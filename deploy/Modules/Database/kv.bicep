
param keyVaultName string
param location string
param VnetName string 
//param VnetId string
param PrivateDnsId string
param privateEndPointSubnetName string 
param resourceGroupName string 
param tenantId string
param userID string


resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: '${VnetName}/${privateEndPointSubnetName}'
}

resource keyVaultResource 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization:false
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: false //true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    
    publicNetworkAccess: 'Disabled'
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: userID
        permissions: {
          keys: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'Decrypt'
            'Encrypt'
            'UnwrapKey'
            'WrapKey'
            'Verify'
            'Sign'
            'Release'
            'Rotate'
            'GetRotationPolicy'
            'SetRotationPolicy'
          ]
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
          storage: [
            'all'
          ]
        }
      } 
      {
        tenantId: tenantId
        objectId: userID
        permissions: {
          keys: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'Decrypt'
            'Encrypt'
            'UnwrapKey'
            'WrapKey'
            'Verify'
            'Sign'
            'Release'
            'Rotate'
            'GetRotationPolicy'
            'SetRotationPolicy'
          ]
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
          storage: [
            'all'
          ]
        }
      }

    ]
    
  }
}
output keyVaultResourceId string = keyVaultResource.id

resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${keyVaultName}-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${keyVaultResource.name}-PrivateLink'
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyVaultResource.id
          privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
      ]
      manualPrivateLinkServiceConnections: []
      customNetworkInterfaceName: '${keyVaultName}-pe-nic'
    subnet: {
       id:peSubnet.id //'${VnetName}/subnets/${privateEndPointSubnetName}'
     }
       
  }
}


resource PrivanteEndPointDnsRecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: kvPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: PrivateDnsId
        }
      }
    ]
  }
}


output KeyVaultPrivateEpId string = kvPrivateEndpoint.id
output KeyVaultPrivateEpName string = kvPrivateEndpoint.name
output peSubnetId string = peSubnet.id
