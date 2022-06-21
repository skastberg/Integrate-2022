@description('Connection DisplayName')
param DisplayName string
@description('Location of the connection')
param Location string = resourceGroup().location
param connection_name string = 'service-now'
@description('Name of the instance for service-now.com or custom URL for migrated account.')
param instance string
@description('Username for this instance.')
param username string
@description('The password for this account.')
@secure()
param password string
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

    parameterValues: {
      instance: instance
      username: username
      password: password
    }

    api: {
      name: connection_name
      displayName: 'ServiceNow'
      description: 'ServiceNow improves service levels, energizes employees, and enables your enterprise to work at lightspeed. Create, read and update records stored within ServiceNow including Incidents, Questions, Users and more.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1544/1.0.1544.2640/service-now/icon.png'
      brandColor: '#D1232B'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${Location}/managedApis/service-now'
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
