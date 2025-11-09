/**
 * Interface: IEventPublisher
 * Puerto de salida para publicación de eventos de dominio (EventBridge)
 * 
 * Principios SOLID aplicados:
 * - Dependency Inversion: Abstracción para Event Bus
 * - Single Responsibility: Solo publica eventos
 */
export interface DomainEvent {
  eventId: string;
  eventType: string;
  source: string;
  timestamp: Date;
  data: Record<string, any>;
}

export interface IEventPublisher {
  /**
   * Publica un evento de dominio
   */
  publishEvent(event: DomainEvent): Promise<void>;

  /**
   * Publica múltiples eventos en batch
   */
  publishEvents(events: DomainEvent[]): Promise<void>;
}

