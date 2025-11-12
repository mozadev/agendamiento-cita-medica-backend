import {
  DynamoDBClient,
  PutItemCommand,
  GetItemCommand,
  UpdateItemCommand,
  QueryCommand
} from '@aws-sdk/client-dynamodb';
import { marshall, unmarshall } from '@aws-sdk/util-dynamodb';
import { IAppointmentRepository } from '../../domain/interfaces/IAppointmentRepository';
import { Appointment } from '../../domain/entities/Appointment';
import { InsuredId } from '../../domain/value-objects/InsuredId';
import { CountryISO } from '../../domain/value-objects/CountryISO';
import { AppointmentStatus } from '../../domain/value-objects/AppointmentStatus';

/**
 * Repository: DynamoDBAppointmentRepository
 * Implementación del repositorio usando DynamoDB
 * 
 * Patrón de diseño: Repository Pattern
 * - Encapsula la lógica de acceso a datos
 * - Abstrae la persistencia del dominio
 * 
 * PASOS 1 y 6: Guarda y actualiza en DynamoDB
 */
export class DynamoDBAppointmentRepository implements IAppointmentRepository {
  private readonly dynamoDBClient: DynamoDBClient;
  private readonly tableName: string;

  constructor(region?: string, tableName?: string) {
    this.dynamoDBClient = new DynamoDBClient({
      region: region || process.env.AWS_REGION || 'us-east-1'
    });
    this.tableName = tableName || process.env.DYNAMODB_TABLE || 'appointments';
  }

  async save(appointment: Appointment): Promise<void> {
    const item = appointment.toPersistence();

    const command = new PutItemCommand({
      TableName: this.tableName,
      Item: marshall(item, {
        removeUndefinedValues: true,
        convertClassInstanceToMap: true
      }),
      ConditionExpression: 'attribute_not_exists(appointmentId)'
    });

    try {
      await this.dynamoDBClient.send(command);
    } catch (error: any) {
      if (error.name === 'ConditionalCheckFailedException') {
        throw new Error(`Appointment already exists: ${appointment.getAppointmentId()}`);
      }
      throw error;
    }
  }

  async findById(appointmentId: string): Promise<Appointment | null> {
    const command = new GetItemCommand({
      TableName: this.tableName,
      Key: marshall({ appointmentId })
    });

    const response = await this.dynamoDBClient.send(command);

    if (!response.Item) {
      return null;
    }

    const item = unmarshall(response.Item);
    return this.toDomain(item);
  }

  async findByInsuredId(insuredId: InsuredId): Promise<Appointment[]> {
    const command = new QueryCommand({
      TableName: this.tableName,
      IndexName: 'insuredId-createdAt-index',
      KeyConditionExpression: 'insuredId = :insuredId',
      ExpressionAttributeValues: marshall({
        ':insuredId': insuredId.getValue()
      }),
      ScanIndexForward: false // Orden descendente por fecha
    });

    const response = await this.dynamoDBClient.send(command);

    if (!response.Items || response.Items.length === 0) {
      return [];
    }

    return response.Items.map(item => this.toDomain(unmarshall(item)));
  }

  async update(appointment: Appointment): Promise<void> {
    const item = appointment.toPersistence();

    const command = new UpdateItemCommand({
      TableName: this.tableName,
      Key: marshall({ appointmentId: item.appointmentId }),
      UpdateExpression: 'SET #status = :status, #updatedAt = :updatedAt, #completedAt = :completedAt, #metadata = :metadata',
      ExpressionAttributeNames: {
        '#status': 'status',
        '#updatedAt': 'updatedAt',
        '#completedAt': 'completedAt',
        '#metadata': 'metadata'
      },
      ExpressionAttributeValues: marshall({
        ':status': item.status,
        ':updatedAt': item.updatedAt,
        ':completedAt': item.completedAt || null,
        ':metadata': item.metadata || {}
      }, {
        removeUndefinedValues: true
      }),
      ConditionExpression: 'attribute_exists(appointmentId)'
    });

    try {
      await this.dynamoDBClient.send(command);
    } catch (error: any) {
      if (error.name === 'ConditionalCheckFailedException') {
        throw new Error(`Appointment not found: ${appointment.getAppointmentId()}`);
      }
      throw error;
    }
  }

  async delete(appointmentId: string): Promise<void> {
    // Soft delete: marcamos como cancelled en lugar de eliminar
    const appointment = await this.findById(appointmentId);
    
    if (!appointment) {
      throw new Error(`Appointment not found: ${appointmentId}`);
    }

    appointment.cancel('Deleted by system');
    await this.update(appointment);
  }

  /**
   * Convierte un item de DynamoDB a una entidad de dominio
   */
  private toDomain(item: Record<string, any>): Appointment {
    return Appointment.fromPersistence({
      appointmentId: item.appointmentId || item.id, // DynamoDB usa 'id' como partition key
      insuredId: InsuredId.create(item.insuredId),
      scheduleId: item.scheduleId,
      countryISO: CountryISO.create(item.countryISO),
      status: AppointmentStatus.fromString(item.status),
      createdAt: new Date(item.createdAt),
      updatedAt: new Date(item.updatedAt),
      completedAt: item.completedAt ? new Date(item.completedAt) : undefined,
      metadata: item.metadata
    });
  }
}

