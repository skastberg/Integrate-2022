@description('Name of the Namespace')
param namespaceName string
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
@description('Sku of the Service Bus Namespace')
@allowed([
  'Premium'
  'Standard'
  'Basic'
])
param sku string = 'Standard'
@description('WorkspaceResourceId that metrics will be sent to.')
param workspaceResourceId string

targetScope = 'resourceGroup'

var tags = {
  usage: environmentType
  description: 'Common Service Bus for ${environment}'
}


// Service Bus Namespace
resource rNS 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: namespaceName
  location: location
  tags: tags
    sku: {
    capacity: 1
    name: sku
    tier: sku
  }
  properties: {
    zoneRedundant: false
  }
}

resource rDiagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${namespaceName}-diag-settings'
  location: location
  properties: {
    workspaceId: workspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    logs: [
      {
        category: 'OperationalLogs'
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 15
        }
      }
      {
        category: 'VNetAndIPFilteringLogs'
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 15
        }
      }
      {
        category: 'RuntimeAuditLogs'
        categoryGroup: null
        enabled: false
        retentionPolicy: {
          enabled: false
          days: 15
        }
      }
      {
        category: 'ApplicationMetricsLogs'
        categoryGroup: null
        enabled: false
        retentionPolicy: {
          enabled: false
          days: 15
        }
      }
    ]
  }

  scope: rNS
}
