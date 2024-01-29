param dbSubnetName string
param routeTableID string
param networkResourceGroupID string
param existingSubnetAddressPrefix string
param vnetName string




/*
--------------------------------------------------------------- 
Deploying the subnet for the Azure SQL Managed Instance to apply NSG and RT
---------------------------------------------------------------
*/
resource dbsubnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: '${vnetName}/${dbSubnetName}'
  properties: {
    addressPrefix: existingSubnetAddressPrefix
    routeTable: {
      id: routeTableID
    }
    networkSecurityGroup: {
      id: networkResourceGroupID
    }
    delegations: [
      {
        name: 'managedInstanceDelegation'
        properties: {
          serviceName: 'Microsoft.Sql/managedInstances'
        }
      }
    ]
  }
}

output subnetID string = dbsubnet.id


