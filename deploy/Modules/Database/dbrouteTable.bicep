
param location string 
param resourceGroupName string 
param sqlMiAddressPrefix string
param tags object 

var nsgSuffix = replace(replace(sqlMiAddressPrefix, '.', '-'), '/', '-')
var Rtname =  replace(resourceGroupName, 'rg', 'sqlmi-rt')
var nsgName = replace(resourceGroupName, 'rg', 'sqlmi-NSG')
var pairedRegion = contains(location, 'eastus' ) ? 'westus' : contains(location,'westus3')? 'eastus': contains(location,'westeurope')? 'northeurope': contains(location,'southeastasia') ? 'eastasia': contains(location,'westus') ? 'eastus':''
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: Rtname
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_subnet-${nsgSuffix}-to-vnetlocal'
        properties: {
          addressPrefix: sqlMiAddressPrefix
          nextHopType: 'VnetLocal'
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }

      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-AzureActiveDirectory'
        properties: {
          addressPrefix: 'AzureActiveDirectory'
          nextHopType: 'Internet'
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
  
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-OneDsCollector'
        properties: {
          addressPrefix: 'OneDsCollector'
          nextHopType: 'Internet'
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }

      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-Storage.${location}'
        properties: {
          addressPrefix: 'Storage.${location}'
          nextHopType: 'Internet'
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }

      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-Storage.${pairedRegion}'
        properties: {
          addressPrefix: 'Storage.${pairedRegion}'
          nextHopType: 'Internet'
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }

      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_optional-AzureCloud.${location}'
        properties: {
          addressPrefix: 'AzureCloud.${location}'
          nextHopType: 'Internet'
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
 

    ]
  }
} 



output routeTableId string = routeTable.id

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgName
  tags: tags
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_tds_inbound'
        properties: {
          description: 'Allow access to data'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_redirect_inbound'
        properties: {
          description: 'Allow inbound redirect traffic to Managed Instance inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11000-11999'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_inbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_outbound'
        properties: {
          description: 'Deny all other outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
   





      //////////////////////////////////////////


      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-healthprobe-in-${nsgSuffix}-v11'
        properties: {
          description: 'Allow Azure Load Balancer inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: sqlMiAddressPrefix
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-internal-in-${nsgSuffix}-v11'
        properties: {
          description: 'Allow MI internal inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: sqlMiAddressPrefix
          destinationAddressPrefix: sqlMiAddressPrefix
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-aad-out-${nsgSuffix}-v11'
        properties: {
          description: 'Allow communication with Azure Active Directory over https'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: sqlMiAddressPrefix
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 101
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-onedsc-out-${nsgSuffix}-v11'
        properties: {
          description: 'Allow communication with the One DS Collector over https'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: sqlMiAddressPrefix
          destinationAddressPrefix: 'OneDsCollector'
          access: 'Allow'
          priority: 102
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-internal-out-${nsgSuffix}-v11'
        properties: {
          description: 'Allow MI internal outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: sqlMiAddressPrefix
          destinationAddressPrefix: sqlMiAddressPrefix
          access: 'Allow'
          priority: 103
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-strg-p-out-${nsgSuffix}-v11'
        properties: {
          description: 'Allow outbound communication with storage over HTTPS'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: sqlMiAddressPrefix
          destinationAddressPrefix: 'Storage.eastus'
          access: 'Allow'
          priority: 104
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-strg-s-out-${nsgSuffix}-v11'
     //   type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          description: 'Allow outbound communication with storage over HTTPS'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: sqlMiAddressPrefix
          destinationAddressPrefix: 'Storage.westus'
          access: 'Allow'
          priority: 105
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Sql-managedInstances_UseOnly_mi-optional-azure-out-${nsgSuffix}'
    //    type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          description: 'Allow AzureCloud outbound https traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: sqlMiAddressPrefix
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }


    ]
  }
}
output networkSecurityGroupId string = networkSecurityGroup.id
