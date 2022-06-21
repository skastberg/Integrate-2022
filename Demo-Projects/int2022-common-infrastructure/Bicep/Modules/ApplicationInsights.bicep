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
@description('WorkspaceResourceId that Application insights will use.')
param workspaceResourceId string

targetScope = 'resourceGroup'

var tags = {
  usage: environmentType
  owner: 'Donald'
}


resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${rootName}-insights-${environment}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30
    WorkspaceResourceId: workspaceResourceId
  }
}

///////////////////////////////////////////////////////////
// outputs
///////////////////////////////////////////////////////////
output insightsName string = insights.name
