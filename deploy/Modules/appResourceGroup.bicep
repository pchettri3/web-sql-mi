targetScope = 'subscription'
param resourceGroupName string
param tags object
param tenantId string
param userID string
param networkResourceGroup string
param DeployStorage string
param saDeploy bool = DeployStorage == 'yes' ? true : false
param sitesName string
param PrivateDnsId string
param appInstanceName string //array
@secure()
param sitesLocation string
param adminUsername string
param sitesSubscriptionId string
param sitesKind string
param sitesIdentityType string
param Linuxversion string
//param dbdeployType string
//param deploymentTier string 
param  workspaceId string
param sqlMiAddressPrefix string
param dbsubnetSuffix string = 'sqlmi'
//param sitesResourceGroup string
param existingSubnetAddressPrefix string
//param sharedPrivateDNSID string



//var aspSuffix = contains(sitesResourceGroup, 'wus3-prd') ? 'apps-asp' : contains(sitesResourceGroup, 'wus3-npr-dev') ? 'apps-asp01' : contains(sitesResourceGroup, 'wus3-npr-test') ? 'apps-asp01' : contains(sitesResourceGroup, 'sea-npr-dev') ? 'asp001' : 'apps-asp001'

//var aseResourceName = replace(sitesResourceGroup, '-rg', '')
//var aspResourceName = replace(sitesResourceGroup, 'rg', aspSuffix)

var vnetsuffix = contains(networkResourceGroup, 'prd') ? 'app-vnet' : 'vnet'
var pesubnetsuffix = contains(networkResourceGroup, 'prd') ? 'eps-sn' : contains(networkResourceGroup, 'dev' ) || contains(networkResourceGroup, 'test' )   ? 'np-eps-sn' :'np-eps-sn'

var VnetName = replace(networkResourceGroup, 'ntw-rg', vnetsuffix)
var dbSubnetName = replace(networkResourceGroup, 'ntw-rg', '${appInstanceName}-${dbsubnetSuffix}-sn')
@description('Vnet and subent changes on prd and non prd')
//var 
/*
--------------------------------------------------------------- 
Creating resource group for the app deployment
---------------------------------------------------------------
*/
resource appResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: sitesLocation
  tags: tags
}
output rgNames string = resourceGroupName


param configPropertiesRemoteDebuggingVersion string

param configPropertiesScmType string

//param sitesResourceGroup string

/*
--------------------------------------------------------------- 
if dbdeployType is pgsql then dbsubnetSuffix is postgresql else it is mysql.
deployment appends the dbsubnetSuffix to the appInstanceName to create the database subnet name.
---------------------------------------------------------------
*/
//param pgsqldeploy bool = dbdeployType == 'pgsql' ? true : false


@secure()
param administratorLoginPassword string

//@description('This variable is used to determine the suffix for the database subnet based on the value of dbdeployType.')
//param dbsubnetSuffix string = dbdeployType == 'pgsql' ? 'postgresql' : 'mysql'
//var dbSubnetName = replace(networkResourceGroup, 'ntw-rg', '${appInstanceName}-${dbsubnetSuffix}-sn')

//@description('configuring ASE name suffix based on the resource group name') 
//var aseResourceName = replace(sitesResourceGroup, 'ase-rg', '${deploymentTier}-ase')
//var vnetsuffix = contains(networkResourceGroup, '-prd') ? 'prd-vnet' : 'dev-vnet' 
//var vnetsuffix = replace(networkResourceGroup, 'ntw-rg', 'vnet')
//@description('Reference suffix to existing network resource group') 
//var VnetName = replace(networkResourceGroup, 'ntw-rg', 'vnet')

/*
-----------------------------------------------------------------------------------------------
  This variable determines the suffix for the subnet name based on the network resource group.
  If the network resource group contains 'prd', the suffix will be 'ase-endpoints-sn'.
  If the network resource group contains 'wus3-npr' or 'sea-npr', the suffix will be 'endpoint-sn'.
  Otherwise, the suffix will be 'endpoints-sn'.
  -----------------------------------------------------------------------------------------------*/
//var pesubnetsuffix = contains(networkResourceGroup, 'prd') ? 'prd-eps-sn' : contains(networkResourceGroup, 'dev' ) || contains(networkResourceGroup, 'test' )   ? 'np-eps-sn' :'eps-sn'
@description('Vnet and subent changes on prd and non prd')
var privateEndPointSubnetName = replace(networkResourceGroup, 'ntw-rg', pesubnetsuffix)

@description('output from the DNS zone module')
//var privateDnsZoneId = dnsZone.outputs.postgresPrivateDnsZoneId



/*
---------------------------------------------------------------
Creating new Tier2 app specific ASP for webapp
---------------------------------------------------------------
*/
module aseASP './appServicePlan.bicep' = {
  name: 'ASP${substring(resourceGroupName, 4, length(resourceGroupName) - 8)}-Deploy'
  scope: resourceGroup(appResourceGroup.name)
 // dependsOn: [
    //AseHosting
  //]
  params: {
    sitesLocation: sitesLocation
    appResourceGroupName: appResourceGroup.name
    //AseHostingEnvironmentId: AseHosting.id
    ApplicationName: appInstanceName

  }
}

//var aspName = aseASP.outputs.serverfarmsName
var aspID = aseASP.outputs.serverfarmsId

/*
---------------------------------------------------------------
Deploys web app in Ase hosting environment
---------------------------------------------------------------
*/

    module webAppDeploy './webAppModule/aseWebApp.bicep' = {//[for (ap,i) in appInstanceName : {
      scope: appResourceGroup 
      name: 'Ase-App-${substring(resourceGroupName, 4, length(resourceGroupName) - 8)}-Deploy${appInstanceName}'
     // dependsOn: [
    //    AseHosting
   //   ]
      params: {
        //aspResourceName: aspResourceName
        sitesName: sitesName 
        sitesLocation: sitesLocation

        sitesServerfarmsAspId: aspID
        sitesTags: {}
        sitesKind: sitesKind
        sitesIdentityType: sitesIdentityType
        Linuxversion: Linuxversion
        PrivateDnsId: PrivateDnsId
       // VnetName: VnetName 
      //  resourceGroupName: resourceGroupName
        VnetId: virtualNetwork.id
        configPropertiesRemoteDebuggingVersion: configPropertiesRemoteDebuggingVersion

        privateEndPointSubnetName: privateEndPointSubnetName
        configPropertiesScmType: configPropertiesScmType
        workspaceId: workspaceId

      }
    }
    @description('Location for all resources.')

//var dbSubnetName = replace(resourceGroupName, 'ase-apps-${appName}-rg', '${appInstanceName}-postgresql-sn')

/*
---------------------------------------------------------------
Referencing existing network resource group and Vnet
---------------------------------------------------------------
*/
  resource netResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
    name: networkResourceGroup

  }

  resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
    name: VnetName
    scope: netResourceGroup

  }

  resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
    parent: virtualNetwork
    name: privateEndPointSubnetName
  }
  
 // var dbsubnetID = '${virtualNetwork.id}/subnets/${dbSubnetName}'

/*
---------------------------------------------------------------
Deploys DNS zone for vnet integrated D?NS and adds one vnet link to the zone
---------------------------------------------------------------
*/
  /*module dnsZone './Database/dnszone.bicep' =  if (pgsqldeploy){
    scope: netResourceGroup
    name: '${dbdeployType}-dnsZoneDeployment'
    params: {
      vnetId: virtualNetwork.id
      resourceGroupName: resourceGroupName
      appinstanceName: appInstanceName
      dbdeployType: dbdeployType

    }
  }
  */
 // var sqldbPrivateDNS = replace(PrivateDnsId, 'vaultcore.azure.net', 'mysql.database.azure.com')
/*
------------------------------------------------------------------------------------
Deploys musql DB server if the dbdeployType is mysql else deploys postgresql DB server
--------------------------------------------------------------------------------------
*/
/*
--------------------------------------------------------------- 
deploys new vnet for sqlmi instance
---------------------------------------------------------------
*/
module dbsubnet './Database/dbsubnet.bicep' = {
  scope: netResourceGroup
  dependsOn: [ dbRouteTable ]
  name: 'dbsubnetDeployment${uniqueString(virtualNetwork.name)}'
  params: {

    dbSubnetName: dbSubnetName
    existingSubnetAddressPrefix: existingSubnetAddressPrefix

    routeTableID: routeTableId
    networkResourceGroupID: networkResourceGroupID
    vnetName: virtualNetwork.name
    
    
   
  }
}

output vnetName string = virtualNetwork.name

/*module dnsZone './Database/dnszone.bicep' = {
  scope: netResourceGroup
  name: 'dnsZoneDeployment'
  params: {
    vnetId: virtualNetwork.id
    resourceGroupName: resourceGroupName
    appinstanceName: appInstanceName
    dbdeployType: dbdeployType
   
  }
}*/

module dbRouteTable './Database/dbrouteTable.bicep' = {
  scope: appResourceGroup
  name: 'routeTableDeployment${uniqueString(virtualNetwork.name)}'
  params: {
    location: sitesLocation
    tags: tags
    resourceGroupName: resourceGroupName
    sqlMiAddressPrefix: sqlMiAddressPrefix
  }
}
var routeTableId = dbRouteTable.outputs.routeTableId
var networkResourceGroupID = dbRouteTable.outputs.networkSecurityGroupId

var databaseSubnetID = dbsubnet.outputs.subnetID

module msPrivate './Database/sqlmi.bicep' = {
  scope: appResourceGroup
  dependsOn: [ dbsubnet ]
  name: 'sqlManagedInstance${uniqueString(virtualNetwork.name)}'
  params: {
    location: sitesLocation
    resourceGroupName: resourceGroupName
    administratorLogin: adminUsername 
    administratorLoginPassword: administratorLoginPassword 
    tags: tags
    subnetId: databaseSubnetID
    peSubnetId: keyVault.outputs.peSubnetId
    sharedPrivateDNSID: PrivateDnsId
   
  }
}

/*
  This variable `appsuffix` is used to generate a suffix for the appInstanceName.
  If the length of `appInstanceName` is 8 characters, the `appsuffix` will be an empty string.
  Otherwise, it will be the last character of `appInstanceName`.
*/
/*
  This variable `appsuffix` is used to determine the value of the `appsuffix` variable based on the length of the `appInstanceName` string.
  If the length of `appInstanceName` is equal to 7, the `appsuffix` variable is set to an empty string.
  Otherwise, the `appsuffix` variable is set to the last character of the `appInstanceName` string.
*/
var appsuffix = length(appInstanceName) >= 7 ? '' : substring(appInstanceName, length(appInstanceName) - 1, 1)
var appprefix = take(appInstanceName, 6)
var appNameFix = '${appprefix}${appsuffix}'
var keyVaultName = replace(resourceGroupName, 'apps-${sitesName}-rg', '${appNameFix}-kv')

//var siteresourceIdentity = webAppDeploy.outputs.siteresourceIdentity
/*
--------------------------------------------------------------- 
For SA and KV name pick 6 letter from app name and add the last letter of app name 
if it is longer than 6 letter. 
For KV name - are retained for storage account - are replaced with empty string and 
converted to lower case.
---------------------------------------------------------------

---------------------------------------------------------------
Deploys Key vault along with private endpoint connection
---------------------------------------------------------------
*/
//var siteresourceIdentity = AseAppDeploy.outputs.siteresourceIdentity

module keyVault './Database/kv.bicep' = {
  scope: appResourceGroup
  name: 'keyVaultDeployment${uniqueString(resourceGroupName)}'
  params: {
    location: sitesLocation
    tenantId: tenantId
    userID: userID
    keyVaultName: keyVaultName
    VnetName: virtualNetwork.name
    // VnetId: virtualNetwork.id
    privateEndPointSubnetName: privateEndPointSubnetName
    resourceGroupName: netResourceGroup.name
    PrivateDnsId: PrivateDnsId
   

  }
}

/*
--------------------------------------------------------------- 
For SA and KV name pick 6 letter from app name and add the last letter of app name 
if it is longer than 6 letter. 
For storage account - are replaced with empty string and 
converted to lower case.
---------------------------------------------------------------
*/

var saAccountN = replace(replace(resourceGroupName, 'apps-${sitesName}-rg', '${appNameFix}sa'), '-', '')
var saAccountName = toLower(saAccountN) 
var storagePrivateDNS = replace(PrivateDnsId, 'vaultcore.azure', 'file.core.windows')

/*
---------------------------------------------------------------
Deploys Storage acciunt along with private endpoint connection, if the SA deploy is set to yes
---------------------------------------------------------------
*/

var storageID = '/subscriptions/${sitesSubscriptionId}/providers/Microsoft.Security/datascanners/StorageDataScanner'
module appStorageAccount 'storageAccount.bicep' = if (saDeploy) {
  name: 'StorageAccount${uniqueString(resourceGroupName)}'
  scope: appResourceGroup
  params: {
    location: sitesLocation
   // resourceGroupName: resourceGroupName
  //  networkResourceGroup: networkResourceGroup
   // subscriptionId: sitesSubscriptionId
    saAccountName: saAccountName
   // VnetName: virtualNetwork.name
    tenantId: tenantId
    //VnetId: virtualNetwork.id
    //privateEndPointSubnetName: privateEndPointSubnetName
    //: PrivateDnsId
    peSubnetId: peSubnet.id
    storagePrivateDNS: storagePrivateDNS
    storeageId: storageID

  }

}

output moduleResourceOutput object = {
 // dnszone: dnsZone.outputs.privateDnsZoneName
  //privateDnsZoneName: dnsZone.outputs.privateDnsZoneId
  KeyVaultPrivateEpName: keyVault.outputs.KeyVaultPrivateEpName
  peSubnetId: 'The subnet ID for the Key vault PE ${keyVault.outputs.peSubnetId}'

}


var managedIdentityName = replace(resourceGroupName, 'ase-apps-${sitesName}-rg', '${appInstanceName}-mi')

module gitHubManagedIdenmantity 'gitHubManagedIdentity.bicep' = {
  scope: appResourceGroup
  name: 'gitHubManagedIdenmantityDeploy${uniqueString(resourceGroupName)}'
  params: {
    location: sitesLocation
    managedIdentityName: managedIdentityName
    tags: tags
  }
}
