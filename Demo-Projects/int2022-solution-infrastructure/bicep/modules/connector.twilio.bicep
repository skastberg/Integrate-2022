@description('Connection DisplayName')
param DisplayName string
@description('Location of the connection')
param Location string = resourceGroup().location
param connection_name string = 'twilio'

@description('Twilio Account Id.')
@secure()
param sid string
@description('Twilio Access Token.')
@secure()
param token string
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
      sid: sid
      token: token
    }

    api: {
      name: connection_name
      displayName: 'Twilio'
      description: 'Twilio enables apps to send and receive global SMS, MMS and IP messages.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1450/1.0.1450.2361/twilio/icon.png'
      brandColor: '#e22228'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${Location}/managedApis/twilio'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

// Handle connectionKey

param baseTime string = utcNow('u')

var validityTimeSpan = {
  validityTimeSpan: '30'
}

var validTo = dateTimeAdd(baseTime, 'P${validityTimeSpan.validityTimeSpan}D')

var key = environment == 'lab' || environment == 'dev' ? connection_resource.listConnectionKeys('2018-07-01-preview', validityTimeSpan).connectionKey : 'Skipped'

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
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
