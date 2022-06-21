@description('Name of the namespace the queue should recide')
param NamespaceName string
@description('Name of the queue')
param QueueName string
@description('ISO 8601 default message timespan to live value.')
param TimeToLive string = 'P30D'
@description('ISO 8601 timeSpan structure that defines the duration of the duplicate detection history.')
param DuplicateTimeWindows string = 'PT30M'
@description('A value indicating if this queue requires duplicate detection.')
param DuplicateDetection bool = false
@description('A value indicating if this queue requires duplicate detection.')
param MaxSizeInKilobytes int = 1024
@description('Sku of Service Bus Namespace')
@allowed([
  'Premium'
  'Standard'
  'Basic'
])
param NamespaceSku string


resource ns 'Microsoft.ServiceBus/namespaces@2021-06-01-preview'  existing = {
  name: NamespaceName

}

// workaround to avoid duplicate name validation error.
var premQ = ('Premium' == NamespaceSku) ? QueueName : 'dummy'
var stdQ = ('Premium' != NamespaceSku) ? QueueName : 'dummy'

// The queue will be created in a premium NS
resource premiumQueue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = if ('Premium' == NamespaceSku){
  name: premQ
  parent: ns 
  properties: {

    deadLetteringOnMessageExpiration: false
    defaultMessageTimeToLive: TimeToLive
    duplicateDetectionHistoryTimeWindow: DuplicateTimeWindows
    enableBatchedOperations: true
    enablePartitioning: false
    lockDuration: 'PT5M'
    maxDeliveryCount: 10
    maxMessageSizeInKilobytes: MaxSizeInKilobytes // only in premium
    requiresDuplicateDetection: DuplicateDetection
    requiresSession: false
  }
}

// The queue will be created in a standard or basic NS
resource standardQueue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = if ('Premium' != NamespaceSku){
  name: stdQ
  parent: ns 
  properties: {

    deadLetteringOnMessageExpiration: false
    defaultMessageTimeToLive: TimeToLive
    duplicateDetectionHistoryTimeWindow: DuplicateTimeWindows
    enableBatchedOperations: true
    enablePartitioning: false
    lockDuration: 'PT5M'
    maxDeliveryCount: 10

    requiresDuplicateDetection: DuplicateDetection
    requiresSession: false
  }
}


