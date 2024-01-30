/*
----------------------------------------------------------
Creates an Azure Web App with the specified configuration.
FILEPATH: /c:/Avnet/appTest/aseApp2.bicep

This Bicep code defines the following:
- Parameters for the Web App configuration
- A resource group for the Web App
- A server farm for the Web App
- A hosting environment profile for the Web App
- A Web App with the specified configuration
- A host name binding for the Web App
- A configuration for the Web App
----------------------------------------------------------
*/

param sitesName string
param sitesLocation string
//param Location string
param Linuxversion string
//param sitesAseHostingEnvironmentName string
//param sitesAseHostingEnvironmentId string
param sitesServerfarmsAspId string
param sitesTags object
param sitesKind string
param sitesIdentityType string
param workspaceId string 
param PrivateDnsId string
//param VnetName string
//param resourceGroupName string
param privateEndPointSubnetName string
param configPropertiesRemoteDebuggingVersion string
param VnetId string

param configPropertiesScmType string
//param aspResourceName string
var webPrivateDNS = replace(PrivateDnsId, 'vaultcore.azure', 'azurewebsites')
var SubnetID = '${VnetId}/subnets/${privateEndPointSubnetName}'


resource sitesResource 'Microsoft.Web/sites@2022-03-01' = {
  name: sitesName
  location: sitesLocation
  tags: sitesTags
  kind: sitesKind
  identity: {
    type: sitesIdentityType
  }
  properties: {
    enabled: true //app.parameters.app.value.sitesPropertiesEnabled
   // hostNameSslStates: [
    //  {
     //   name: '${sitesName}.${sitesAseHostingEnvironmentName}.appserviceenvironment.net'
      //  sslState: 'Disabled'
    //    hostType: 'Repository'
     // }

   // ]
    serverFarmId: sitesServerfarmsAspId //sitesServerfarmsAspId
    reserved: true
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: true
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: Linuxversion
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
   // hostingEnvironmentProfile: {
    //  id: sitesAseHostingEnvironmentId 
    //}
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned' 

  }
}

output siteresourceIdentity string = sitesResource.identity.principalId
resource sitesConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: sitesResource
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    linuxFxVersion: Linuxversion
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: configPropertiesRemoteDebuggingVersion
    httpLoggingEnabled: true
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$${sitesName}'
    scmType: configPropertiesScmType
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    appCommandLine: '/home/site/start.sh'
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]

    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    publicNetworkAccess: 'Enabled' // missing on import
    localMySqlEnabled: false
    managedServiceIdentityId: 1 // app.parameters.app.value.configPropertiesManagedServiceIdentityId //missing on import
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    //elasticWebApplicationLimit: 0
    preWarmedInstanceCount: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
  }
}

output sitesResourceName string = sitesResource.name
/*
----------------------------------------------------------
creates existing log analytics workspace variables for each region
Assings workspaceId log analytics based on the region
*/



resource appServiceDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${sitesName}-diag-settings'
  scope: sitesResource
  //location: sitesResource.location
  properties: {
    workspaceId: workspaceId

    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceFileAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        timeGrain: 'PT5M' //ISO8601 format, interval is set for 5 minutes
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 30
        }
      }
    ]
  }
}

resource webappPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${sitesName}-pe'
  location: sitesLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${sitesResource.name}-PrivateLink'
        properties: {
          groupIds: [
            'sites'  //******key value to for RESSOURCE SPECIFIC PE
          ]
          privateLinkServiceId: sitesResource.id
          privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
      ]
      manualPrivateLinkServiceConnections: []
      customNetworkInterfaceName: '${sitesName}-pe-nic'
    subnet: {
       id:SubnetID//'${VnetName}/subnets/${privateEndPointSubnetName}'
     }
       
  }
}


resource PrivanteEndPointDnsRecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: webappPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink_azurewebsites_net'
        properties: {
          privateDnsZoneId: webPrivateDNS
        }
      }
    ]
  }
}
