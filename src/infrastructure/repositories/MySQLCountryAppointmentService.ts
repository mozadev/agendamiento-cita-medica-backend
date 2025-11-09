import { createPool, Pool, PoolOptions } from 'mysql2/promise';
import { Appointment } from '../../domain/entities/Appointment';
import { CountryISO, CountryCode } from '../../domain/value-objects/CountryISO';
import { ICountryAppointmentService } from '../../domain/interfaces/ICountryAppointmentService';

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
   */
  static createForCountry(countryCode: CountryCode): MySQLCountryAppointmentService {
    const country = CountryISO.create(countryCode);
    
    const config: PoolOptions = countryCode === CountryCode.PERU
      ? {
          host: process.env.RDS_PE_HOST || 'localhost',
          database: process.env.RDS_PE_DATABASE || 'appointments_pe',
          user: process.env.RDS_PE_USER || 'admin',
          password: process.env.RDS_PE_PASSWORD || 'password'
        }
      : {
          host: process.env.RDS_CL_HOST || 'localhost',
          database: process.env.RDS_CL_DATABASE || 'appointments_cl',
          user: process.env.RDS_CL_USER || 'admin',
          password: process.env.RDS_CL_PASSWORD || 'password'
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

