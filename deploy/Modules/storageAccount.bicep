

param location string 
//param resourceGroupName string
param tenantId string
//param subscriptionId string
param saAccountName string 
//param VnetId string
//param VnetName string
//param privateEndPointSubnetName string
//param networkResourceGroup string
param peSubnetId string 
//var SubnetID = '${VnetId}/subnets/${privateEndPointSubnetName}'
param storagePrivateDNS string  
param storeageId string




resource appstorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: saAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
 //   tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      resourceAccessRules: [
        {
          tenantId: tenantId
          resourceId: storeageId
        }
      ]
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource BlobStorage 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: appstorageAccount
  name: 'default'
  //sku: {
 //   name: 'Standard_LRS'
  //  tier: 'Standard'
  //}
  properties: {
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
  }
}

resource saFileService 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: appstorageAccount
  name: 'default'
  //sku: {
    //name: 'Standard_LRS'
 //   tier: 'Standard'
 // }
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 14
    }
  }
}

resource saPrivateEndpoint'Microsoft.Network/privateEndpoints@2023-05-01' = {
  //parent: appstorageAccount
  name: '${saAccountName}-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${saAccountName}-PrivateLink'
        properties: {
          groupIds: [
            'file'
          ]
          privateLinkServiceId: appstorageAccount.id
          privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
      ]
      manualPrivateLinkServiceConnections: []
      customNetworkInterfaceName: '${saAccountName}-pe-nic'
    subnet: {
       id:peSubnetId//'${VnetName}/subnets/${privateEndPointSubnetName}'
     }
       
  }
}


resource saFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: saFileService
  name: '${saAccountName}-fs'
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }

}

resource PrivanteEndPointDnsRecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: saPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink_file_core_windows_net'
        properties: {
          privateDnsZoneId: storagePrivateDNS
        }
      }
    ]
  }
}
