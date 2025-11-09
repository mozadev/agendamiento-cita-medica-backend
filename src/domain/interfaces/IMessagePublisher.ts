import { CountryISO } from '../value-objects/CountryISO';

/**
 * Interface: IMessagePublisher
 * Puerto de salida para publicación de mensajes (SNS)
 * 
 * Principios SOLID aplicados:
 * - Dependency Inversion: Abstracción para sistemas de mensajería
 * - Interface Segregation: Interface específica para publicación de mensajes
 */
export interface MessageAttributes {
  [key: string]: string | number | boolean;
}

export interface IMessagePublisher {
  /**
   * Publica un mensaje al tópico SNS
   */
  publish(
    message: Record<string, any>,
    attributes?: MessageAttributes
  ): Promise<string>;

  /**
   * Publica un mensaje con filtro de país
   */
  publishWithCountryFilter(
    message: Record<string, any>,
    countryISO: CountryISO
  ): Promise<string>;
}

