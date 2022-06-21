@description('Will be used as prefix in name for resources')
param rootName string
@description('Location of the resource groups')
param location string = resourceGroup().location
@description('Environment identifier')
@allowed([
  'lab'
  'dev'
  'test'
  'prod'
])
param environment string = 'lab'
@description('What kind of environment we are installing. Allowed values "nonprod" or "prod"')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string = 'nonprod'
@description('Size of the App Service Plan. Allowed values WS1, WS2 and WS3')
@allowed([
  'WS1'
  'WS2'
  'WS3'
])
param planSize string = 'WS1'
@description('WorkspaceResourceId that metrics will be sent to.')
param workspaceResourceId string

targetScope = 'resourceGroup'

var tags = {
  usage: environmentType
  description: 'Common plan for Logic Apps'
}



// App Service plan
resource rServerFarm 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${rootName}-logicApps-${environment}'
  location: location
  tags: tags
  properties: {
    zoneRedundant: false
    targetWorkerCount: 1
  }
  sku: {
    name: planSize
    tier: 'WorkflowStandard'
  }
}

resource rDiagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'la-diag-settings'
  location: location
  properties: {
    workspaceId: workspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
  scope: rServerFarm
}
