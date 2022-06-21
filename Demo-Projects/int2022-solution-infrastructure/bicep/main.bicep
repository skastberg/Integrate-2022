@description('Location of the connection, defaults to resource group location')
param Location string = resourceGroup().location
@description('Environment identifier')
@allowed([
  'lab'
  'dev'
  'test'
  'prod'
])
param environment string = 'lab'
@description('Bing Maps api key')
@secure()
param BingMaps_ApiKey string
@description('List of queues to create')
param queues array
@description('Service bus namespace name')
param sb_namespace string
@allowed([
  'Premium'
  'Standard'
  'Basic'
])
param sb_sku string
@description('Service bus namespace name resource group')
param sb_namespace_rg string
@description('App service plan to put the Logic App in')
param appServicePlan string
@description('App Insights to log to')
param appInsights string
@description('Twilio Sid')
@secure()
param twilio_sid string
@description('Twilio token')
@secure()
param twilio_token string
@description('Name of the keyvault for connections')
param kv_name string

module kv 'modules/keyvault.bicep' = {
  name: 'kv'
  params: {
    keyVaultName: kv_name
    location: Location
  }
}

module msnweather 'modules/connector.msnweather.bicep' = {
  name: 'msnweatherConnection'
  dependsOn: [
    kv
  ]
  params: {
    DisplayName: 'msnweather'
    Location: Location
    environment: environment
    kv_name: kv_name
  }
}

module bingmaps 'modules/connector.bingmaps.bicep' = {
  name: 'bingMapsConnection'
  dependsOn: [
    kv
  ]
  params: {
    DisplayName: 'bingmaps'
    Location: Location
    ApiKey: BingMaps_ApiKey
    environment: environment
    kv_name: kv_name
  }
}

module twilio 'modules/connector.twilio.bicep' = {
  name: 'twilio'
  dependsOn: [
    kv
  ]
  params: {
    DisplayName: 'twilio'
    sid: twilio_sid
    token: twilio_token
    environment: environment
    Location: Location
    kv_name: kv_name
  }
}

resource sbns 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: sb_namespace
}

module queue 'modules/Queue.bicep' = [for item in queues: {
  name: '${item}${uniqueString(resourceGroup().id)}'
  scope: resourceGroup(sb_namespace_rg)
  params: {
    QueueName: item
    NamespaceName: sb_namespace
    DuplicateDetection: false
    NamespaceSku: sb_sku
  }
}]




// issues with different subscriptions, do manually for now
module eventSubscription 'modules/eventSubscription.bicep' = {
  name: 'eventSubscription'
  scope: resourceGroup('---testSubscription--' , 'Common-rg')
  params: {
    environment: environment
    EventGridTopic: 'sk-events-eg'
    eventTypes: [
      'ResortSnowing'
    ]
    QueueName: 'int2022-snowevents'
    QueueResourceId: '${sbns.id}/queues/int2022-snowevents'
  }
}

module logicApp 'modules/LogicApp.bicep' = {
  name: 'logicApp'
  dependsOn: [
    msnweather
    bingmaps
    twilio
  ]
  params: {
    appInsights: appInsights
    appServicePlan: appServicePlan
    rootName: 'int2022'
    environment: environment
    location: Location
    azureConnections: [
      msnweather.outputs.ConnectionName
      bingmaps.outputs.ConnectionName
      twilio.outputs.ConnectionName
    ]
  }
}

