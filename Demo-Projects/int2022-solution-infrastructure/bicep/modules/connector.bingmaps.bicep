@description('Connection DisplayName')
param DisplayName string
@description('Location of the connection')
param Location string 
@description('The api key to use to call the connector')
@secure()
param ApiKey string
@description('Environment identifier')
@allowed([
  'lab'
  'dev'
  'test'
  'prod'
])
param environment string = 'lab'

param connections_bingmaps_name string = 'bingmaps'
@description('Name of the keyvault for connections')
param kv_name string

targetScope = 'resourceGroup'

resource connection_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: DisplayName
  location: Location
  kind: 'V2'
  properties: {
    displayName: DisplayName
    parameterValues: {
      api_key: ApiKey
    }
    api: {
      name: connections_bingmaps_name
      displayName: 'Bing Maps'
      description: 'Bing Maps'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1567/1.0.1567.2748/${connections_bingmaps_name}/icon.png'
      brandColor: '#008372'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${Location}/managedApis/${connections_bingmaps_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

// Handle connctionKey

param baseTime string = utcNow('u')


var validityTimeSpan ={
  validityTimeSpan:'30'
}

var validTo = dateTimeAdd(baseTime, 'P${validityTimeSpan.validityTimeSpan}D')

var key = environment == 'lab' || environment == 'dev' ? connection_resource.listConnectionKeys('2018-07-01-preview',validityTimeSpan).connectionKey : 'Skipped'

resource kv  'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: kv_name
}

resource kvConnectionKey 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = if (environment == 'lab' || environment == 'dev') {
  parent: kv
  name: '${DisplayName}-connectionKey'
  properties: {
    value: key 
    attributes: {
      exp: dateTimeToEpoch(validTo)
    }
  }
}


output ConnectionName string = connection_resource.name
