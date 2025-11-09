import {
  EventBridgeClient,
  PutEventsCommand,
  PutEventsRequestEntry
} from '@aws-sdk/client-eventbridge';
import { IEventPublisher, DomainEvent } from '../../domain/interfaces/IEventPublisher';

/**
 * Adapter: EventBridgePublisher
 * Implementación del publicador de eventos usando AWS EventBridge
 * 
 * Patrón de diseño: Adapter Pattern
 * - Adapta AWS SDK EventBridge a nuestra interfaz del dominio
 * 
 * PASO 5 del flujo: Publicación de eventos de completación
 */
export class EventBridgePublisher implements IEventPublisher {
  private readonly eventBridgeClient: EventBridgeClient;
  private readonly eventBusName: string;

  constructor(region?: string, eventBusName?: string) {
    this.eventBridgeClient = new EventBridgeClient({
      region: region || process.env.AWS_REGION || 'us-east-1'
    });
    this.eventBusName = eventBusName || process.env.EVENTBRIDGE_BUS_NAME || '';
  }

  async publishEvent(event: DomainEvent): Promise<void> {
    await this.publishEvents([event]);
  }

  async publishEvents(events: DomainEvent[]): Promise<void> {
    const entries: PutEventsRequestEntry[] = events.map(event => ({
      Source: event.source,
      DetailType: event.eventType,
      Detail: JSON.stringify({
        eventId: event.eventId,
        timestamp: event.timestamp.toISOString(),
        ...event.data
      }),
      EventBusName: this.eventBusName,
      Time: event.timestamp
    }));

    const command = new PutEventsCommand({
      Entries: entries
    });

    const response = await this.eventBridgeClient.send(command);

    // Verificar si hubo errores
    if (response.FailedEntryCount && response.FailedEntryCount > 0) {
      const errors = response.Entries?.filter(entry => entry.ErrorCode)
        .map(entry => `${entry.ErrorCode}: ${entry.ErrorMessage}`)
        .join('; ');
      
      throw new Error(`Failed to publish events: ${errors}`);
    }
  }
}

