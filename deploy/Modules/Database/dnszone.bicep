param vnetId string
param resourceGroupName string
param appinstanceName string
param dbdeployType string
var dbDnsName = dbdeployType == 'pgsql' ? 'postgres' : 'mysql'


var pvtDnsZonePrefix = replace(resourceGroupName,'-rg','-${dbdeployType}')

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${pvtDnsZonePrefix}.private.${dbDnsName}.database.azure.com'
  location: 'global'
}
output privateDnsZoneId string = privateDnsZone.id
output privateDnsZoneName string = privateDnsZone.name

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${appinstanceName}-${dbDnsName}-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output postgresPrivateDnsZoneId string = privateDnsZone.id

///https://github.com/epomatti/azure-psql-vnet
