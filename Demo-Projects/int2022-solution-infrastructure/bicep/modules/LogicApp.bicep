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
param appServicePlan string
param appInsights string
param azureConnections array = []


// -------------------------------
targetScope = 'resourceGroup'

// App Service plan
resource rServerFarm 'Microsoft.Web/serverfarms@2021-02-01' existing = {
  name: appServicePlan
}

// Application insights, note 'existing'
resource rAppInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsights
}

// Storage account where the logic app will have all code
resource rStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: toLower('${rootName}stg${environment}')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

// The Logic App itself
resource rLogicApp 'Microsoft.Web/sites@2021-02-01' = {
  name: '${rootName}Workflows${environment}'
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: rServerFarm.id
    siteConfig: {
      use32BitWorkerProcess: true
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: rAppInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: rAppInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${rStorageAccount.name};AccountKey=${rStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${rStorageAccount.name};AccountKey=${rStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower('${rootName}workflows9fa7')
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
      ]
    }
  }
}

resource MyAccessPolicy 'Microsoft.Web/connections/accessPolicies@2016-06-01' = [ for currentCon in azureConnections : {
  name: '${currentCon}/${rLogicApp.name}'
  location: location
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        tenantId: subscription().tenantId
        objectId: rLogicApp.identity.principalId
      }
    }
  }
}]


output LogicAppName string = rLogicApp.name
output LogicAppObjectId string = rLogicApp.identity.principalId
