@description('Will be used as root name for resources and resource groups')
param rootName string
@description('Location of the resource groups')
param location string = resourceGroup().location

@description('What kind of environment we are installing. Allowed values "nonprod" or "prod"')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string = 'nonprod'
@description('Environment identifier')
@allowed([
  'lab'
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'
@description('Id of Log Analytics workspace.')
param logAnalytics_WorkspaceId string
@description('Name of the Namespace')
param sb_namespace string
@description('Sku of the Service Bus Namespace')
@allowed([
  'Premium'
  'Standard'
  'Basic'
])
param sb_sku string

// Application Insights
module appInsights 'Modules/ApplicationInsights.bicep' = {
  name: 'appInsights'
  params: {
    rootName: rootName
    location: location
    environment: environment
    environmentType: environmentType
    workspaceResourceId: logAnalytics_WorkspaceId
  }
}

// App Service Plan
module logicAppsplan 'Modules/LogicAppsPlan.bicep' = {
  name: 'commonLogicAppsPlan'
  params: {
    rootName: rootName
    location: location
    environment: environment
    environmentType: environmentType
    planSize: 'WS1'
    workspaceResourceId: logAnalytics_WorkspaceId
  }
}

// Service Bus Namespace
module serviceBus 'Modules/ServiceBusNamespace.bicep' = {
  name: 'serviceBus'
  params: {
    namespaceName: sb_namespace
    workspaceResourceId: logAnalytics_WorkspaceId
    environment: environment
    environmentType: environmentType
    location: location
    sku: sb_sku
  }
}
