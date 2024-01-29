param location string
param resourceGroupName string
param administratorLogin string 
param tags object
@secure()
param administratorLoginPassword string 
param peSubnetId string
param sharedPrivateDNSID string
var sqlMiPrivateDNS = replace(sharedPrivateDNSID, 'vaultcore.azure', 'database.windows')
param subnetId string 

//param privateDnsZoneArmResourceId string
var serverName = replace(resourceGroupName, 'rg', 'sqlmi')
//var backupRetentionDays = contains(resourceGroupName, 'prd') ? 30 : 15



resource  sqlManagedInstance  'Microsoft.Sql/managedInstances@2023-02-01-preview' = {
  name: serverName
  location: location
  tags: tags
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 4
    size: 'GP_Gen5_4'
  }

  properties: {
   // isGeneralPurposeV2: false //Try removing this
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    subnetId: subnetId
    licenseType: 'BasePrice'
  //  hybridSecondaryUsage: 'Active' //Try removing this 
    vCores: 4
    storageSizeInGB: 64
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    publicDataEndpointEnabled: false
    proxyOverride: 'Proxy'
    timezoneId: 'US Mountain Standard Time'
    minimalTlsVersion: '1.2'
    requestedBackupStorageRedundancy: 'Local'
    zoneRedundant: false
    pricingModel: 'Regular' //Try removing this
  }
}


resource sqlMiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  //parent: keyVaultResource
  name: '${serverName}-pe'
  location: location 
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${sqlManagedInstance.name}-PrivateLink'
        properties: {
          groupIds: [
            'managedInstance'
          ]
          privateLinkServiceId: sqlManagedInstance.id
          privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
      ]
      manualPrivateLinkServiceConnections: []
      customNetworkInterfaceName: '${serverName}-pe-nic'
    subnet: {
       id:peSubnetId //'${VnetName}/subnets/${privateEndPointSubnetName}'
     }
       
  }
}
resource PrivanteEndPointDnsRecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: sqlMiPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink_database_windows_net'
        properties: {
          privateDnsZoneId: sqlMiPrivateDNS
        }
      }
    ]
  }
}
/*
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: bool
      login: 'string'
      principalType: 'string'
      sid: 'string'
      tenantId: 'string'
    }
    
    
    
    
    
    
    */
