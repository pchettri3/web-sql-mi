param sitesLocation string

//param AseHostingEnvironmentId string
param appResourceGroupName string
param ApplicationName string 

var apsResourceName = replace(appResourceGroupName,'apps-${ApplicationName}-rg','${ApplicationName}-asp')

resource aseServerFarmRestringsource 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: apsResourceName
  location: sitesLocation
  tags: {}
  sku: {
    name: 'P1v2'
    tier: 'PremiumV2'
    size: 'P1v2'
    family: 'Pv2'
    capacity: 1
  }
  kind: 'linux'
  properties: {
//    hostingEnvironmentProfile: {
  //    id: AseHostingEnvironmentId
   // }
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}


output serverfarmsId string = aseServerFarmRestringsource.id
output serverfarmsName string = aseServerFarmRestringsource.name
