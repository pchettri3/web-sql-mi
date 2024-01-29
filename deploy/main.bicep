/*
  This Bicep file creates an Azure resource group for each application instance specified in the appInstanceName array parameter.
  It requires several parameters such as subscription, environmentlist, environment, location, locationlist, azServiceName, azService, app, appInstanceName, sitesLocation, sitesPropertiesSiteConfigLinuxFxVersion, configPropertiesRemoteDebuggingVersion, sitesSubscriptionId, sitesKind, configPropertiesLinuxFxVersion, configPropertiesScmType, and sitesIdentityType.
  The module ApplicationResourceGroups is used to create the resource groups using the parameters specified in the for loop.
*/
targetScope = 'subscription'

param subscription string
//param workspaceId string
//param lawSubscription string 
param lawResourceGroup string


var subprefix = take(subscription, 4)
param environmentlist object
param environment string
param appInstanceName string
param Location string 
param locationlist object
param adminUsername string
param PrivateDnsId string
param tenantId string
param userID string 

//replace(replace(replace(workspaceId, 'subph', lawSubscription), 'rgph', lawResourceGroup), 'lawph', lawName) //changed from param


//@secure()
//param deploymentTier string = 'tier2'

@secure()
param administratorLoginPassword string

param Linuxversion string
//param dbdeployType string
param configPropertiesRemoteDebuggingVersion string
param sitesSubscriptionId string
param sitesKind string
param orgPrefix string
var networkResourceGroup  = '${orgPrefix}-${locationlist[Location]}-${environmentlist[environment]}-ntw-rg'
//'${orgPrefix}-${locationlist[Location]}-${environmentlist[environment]}-ntw-rg' //changed from param

param DeployStorage string
param configPropertiesScmType string
param sitesIdentityType string 
param existingSubnetAddressPrefix string 
//param sitesResourceGroup string
//param sqlMiAddressPrefix string
//param PrivateDnsId string
//param sitesResourceGroup string = '${orgPrefix}-${locationlist[Location]}-${environmentlist[environment]}-app-rg'

@description('global variables')
var kvPrivateDnsSubId  = replace(replace(PrivateDnsId, 'subph', subscription), 'rgph', networkResourceGroup) //changed from param
var lawName  = '${orgPrefix}-${locationlist[Location]}-${environmentlist[environment]}-law' //changed from param
var regworkspaceId  =  '/subscriptions/${subscription}/resourceGroups/${lawResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${lawName}'
var resouceGroupAppSuffix = replace(appInstanceName, '-${environment}', '')
//var workspaceId = contains(Location,'westus3')? amerworkspaceId : contains(Location,'southeastasia')? apacworkspaceId : euworkspaceId

module ApplicationResourceGroups './Modules/appResourceGroup.bicep' = {//[for (ap,i) in appInstanceName : {

  name: '${appInstanceName}${subprefix}'

  params: {
    resourceGroupName: '${orgPrefix}-${locationlist[Location]}-${environmentlist[environment]}-apps-${resouceGroupAppSuffix}-rg'

    tags: {}

    configPropertiesRemoteDebuggingVersion: configPropertiesRemoteDebuggingVersion
    sitesSubscriptionId: sitesSubscriptionId
    sitesKind: sitesKind

    configPropertiesScmType: configPropertiesScmType
    sitesIdentityType: sitesIdentityType
    networkResourceGroup: networkResourceGroup
    Linuxversion: Linuxversion
    //dbdeployType: dbdeployType
    //appName: appInstanceName
    appInstanceName: appInstanceName
    tenantId: tenantId
    userID: userID

    sitesLocation: Location
    sqlMiAddressPrefix: existingSubnetAddressPrefix
    DeployStorage: DeployStorage
    sitesName: appInstanceName
    adminUsername: adminUsername
    administratorLoginPassword: administratorLoginPassword
    PrivateDnsId: kvPrivateDnsSubId
    workspaceId: regworkspaceId
    existingSubnetAddressPrefix: existingSubnetAddressPrefix
  //sitesResourceGroup: sitesResourceGroup
 //deploymentTier : deploymentTier
// sharedPrivateDNSID: sharedPrivateDNSID
     
  }
}

output dbServerOutput object = ApplicationResourceGroups.outputs.moduleResourceOutput
output kvPrivateDnsSubId string = kvPrivateDnsSubId
//output webAppName string= ApplicationResourceGroups.outputs.webAppName
