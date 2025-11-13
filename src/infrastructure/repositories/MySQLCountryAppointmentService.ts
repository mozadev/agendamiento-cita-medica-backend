import { createPool, Pool, PoolOptions } from 'mysql2/promise';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import { Appointment } from '../../domain/entities/Appointment';
import { CountryISO, CountryCode } from '../../domain/value-objects/CountryISO';
import { ICountryAppointmentService } from '../../domain/interfaces/ICountryAppointmentService';

const secretsManager = new SecretsManagerClient({ region: process.env.AWS_REGION || 'us-east-1' });

/**
 * Service: MySQLCountryAppointmentService
 * Implementación del servicio de agendamiento por país usando MySQL (RDS)
 * 
 * Patrón de diseño: Strategy Pattern
 * - Cada instancia implementa la estrategia específica de un país
 * 
 * PASO 4 del flujo: Guarda en RDS MySQL del país correspondiente
 */
export class MySQLCountryAppointmentService implements ICountryAppointmentService {
  private readonly pool: Pool;
  private readonly country: CountryISO;

  constructor(country: CountryISO, poolConfig: PoolOptions) {
    this.country = country;
    this.pool = createPool({
      ...poolConfig,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 0
    });
  }

  /**
   * Factory method para crear servicios por país
   * Obtiene credenciales de Secrets Manager
   */
  static async createForCountry(countryCode: CountryCode): Promise<MySQLCountryAppointmentService> {
    const country = CountryISO.create(countryCode);
    
    // Obtener ARN del secret según el país
    const secretArn = countryCode === CountryCode.PERU
      ? process.env.RDS_PERU_SECRET_ARN
      : process.env.RDS_CHILE_SECRET_ARN;

    if (!secretArn) {
      throw new Error(`Secret ARN not configured for country: ${countryCode}`);
    }

    // Obtener credenciales de Secrets Manager
    const command = new GetSecretValueCommand({ SecretId: secretArn });
    const response = await secretsManager.send(command);
    
    if (!response.SecretString) {
      throw new Error(`Secret ${secretArn} does not contain SecretString`);
    }

    const secret = JSON.parse(response.SecretString);
    
    const config: PoolOptions = {
      host: secret.host,
      database: secret.database || (countryCode === CountryCode.PERU ? 'appointments_pe' : 'appointments_cl'),
      user: secret.username,
      password: secret.password,
      port: secret.port || 3306
    };

    return new MySQLCountryAppointmentService(country, config);
  }

  async processAppointment(appointment: Appointment): Promise<void> {
    const connection = await this.pool.getConnection();

    try {
      await connection.beginTransaction();

      // Insertar el agendamiento en la tabla de MySQL
      const query = `
        INSERT INTO appointments (
          appointment_id,
          insured_id,
          schedule_id,
          country_iso,
          status,
          created_at,
          updated_at,
          metadata
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          status = VALUES(status),
          updated_at = VALUES(updated_at),
          metadata = VALUES(metadata)
      `;

      const values = [
        appointment.getAppointmentId(),
        appointment.getInsuredId().getValue(),
        appointment.getScheduleId(),
        appointment.getCountryISO().getValue(),
        appointment.getStatus().getValue(),
        appointment.getCreatedAt(),
        appointment.getUpdatedAt(),
        JSON.stringify(appointment.getMetadata() || {})
      ];

      await connection.execute(query, values);
      await connection.commit();
    } catch (error) {
      await connection.rollback();
      throw new Error(
        `Failed to save appointment in ${this.country.getValue()} database: ${(error as Error).message}`
      );
    } finally {
      connection.release();
    }
  }

  getCountry(): CountryISO {
    return this.country;
  }

  canHandle(countryISO: CountryISO): boolean {
    return this.country.equals(countryISO);
  }

  /**
   * Cierra el pool de conexiones (útil para testing y cleanup)
   */
  async close(): Promise<void> {
    await this.pool.end();
  }
}

