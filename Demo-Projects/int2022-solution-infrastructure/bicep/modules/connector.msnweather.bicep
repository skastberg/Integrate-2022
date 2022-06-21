@description('Connection DisplayName')
param DisplayName string
@description('Location of the connection')
param Location string 
@description('Name of the connection')
param connections_msnweather_name string = 'msnweather'
@description('Environment identifier')
@allowed([
  'lab'
  'dev'
  'test'
  'prod'
])
param environment string = 'lab'
@description('Name of the keyvault for connections')
param kv_name string

targetScope = 'resourceGroup'

resource connection_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: DisplayName
  location: Location
  kind: 'V2'
  properties: {
    displayName: DisplayName
    api: {
      name: connections_msnweather_name
      displayName: 'MSN Weather'
      description: 'MSN Weather gets you the very latest weather forecast, including temperature, humidity, precipitation for your location.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1551/1.0.1551.2693/${connections_msnweather_name}/icon.png'
      brandColor: '#0078d7'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${Location}/managedApis/${connections_msnweather_name}'
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
