import { SNSClient, PublishCommand, MessageAttributeValue } from '@aws-sdk/client-sns';
import { IMessagePublisher, MessageAttributes } from '../../domain/interfaces/IMessagePublisher';
import { CountryISO } from '../../domain/value-objects/CountryISO';

/**
 * Adapter: SNSMessagePublisher
 * Implementación del publicador de mensajes usando AWS SNS
 * 
 * Patrón de diseño: Adapter Pattern
 * - Adapta AWS SDK SNS a nuestra interfaz del dominio
 * 
 * PASO 2 del flujo: Publicación a SNS con filtro de país
 */
export class SNSMessagePublisher implements IMessagePublisher {
  private readonly snsClient: SNSClient;
  private readonly topicArn: string;

  constructor(region?: string, topicArn?: string) {
    this.snsClient = new SNSClient({ region: region || process.env.AWS_REGION || 'us-east-1' });
    this.topicArn = topicArn || process.env.SNS_TOPIC_ARN || '';
  }

  async publish(
    message: Record<string, any>,
    attributes?: MessageAttributes
  ): Promise<string> {
    const messageAttributes = this.convertToSNSAttributes(attributes || {});

    const command = new PublishCommand({
      TopicArn: this.topicArn,
      Message: JSON.stringify(message),
      MessageAttributes: messageAttributes
    });

    const response = await this.snsClient.send(command);
    return response.MessageId || '';
  }

  async publishWithCountryFilter(
    message: Record<string, any>,
    countryISO: CountryISO
  ): Promise<string> {
    // SNS Filter Policy: El filtro se aplica en las suscripciones
    // Agregamos el atributo countryISO para el filtrado
    const attributes: MessageAttributes = {
      countryISO: countryISO.getValue()
    };

    return this.publish(message, attributes);
  }

  private convertToSNSAttributes(
    attributes: MessageAttributes
  ): Record<string, MessageAttributeValue> {
    const snsAttributes: Record<string, MessageAttributeValue> = {};

    for (const [key, value] of Object.entries(attributes)) {
      if (typeof value === 'string') {
        snsAttributes[key] = {
          DataType: 'String',
          StringValue: value
        };
      } else if (typeof value === 'number') {
        snsAttributes[key] = {
          DataType: 'Number',
          StringValue: value.toString()
        };
      } else if (typeof value === 'boolean') {
        snsAttributes[key] = {
          DataType: 'String',
          StringValue: value.toString()
        };
      }
    }

    return snsAttributes;
  }
}

