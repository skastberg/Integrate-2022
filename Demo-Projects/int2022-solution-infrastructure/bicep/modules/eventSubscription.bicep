@description('Name of the event grid topic')
param EventGridTopic string
@description('Name of the service bus queue to send events to')
param QueueName string
@description('Resource id to the queue')
param QueueResourceId string
@description('Environment identifier')
@allowed([
  'lab'
  'dev'
  'test'
  'prod'
])
param environment string 
@description('Array of events to subscribe to.')
param eventTypes array

resource rEventGridTopic 'Microsoft.EventGrid/topics@2021-12-01' existing = {
  name: EventGridTopic
}

resource subs 'Microsoft.EventGrid/topics/eventSubscriptions@2021-10-15-preview' = {
  name: '${QueueName}-${environment}'
  parent: rEventGridTopic
  properties: {
    destination: {
      endpointType: 'ServiceBusQueue'
      properties: {
        resourceId: QueueResourceId
      }
    }
    filter: {
      includedEventTypes: eventTypes
    }
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}
