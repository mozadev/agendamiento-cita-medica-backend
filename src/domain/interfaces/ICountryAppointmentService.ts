import { Appointment } from '../entities/Appointment';
import { CountryISO } from '../value-objects/CountryISO';

/**
 * Interface: ICountryAppointmentService
 * Puerto de salida para procesamiento específico de cada país (RDS)
 * 
 * Principios SOLID aplicados:
 * - Strategy Pattern: Cada país implementa su propia estrategia
 * - Open/Closed: Abierto para agregar nuevos países sin modificar código existente
 */
export interface ICountryAppointmentService {
  /**
   * Procesa y guarda el agendamiento en la base de datos del país
   */
  processAppointment(appointment: Appointment): Promise<void>;

  /**
   * Obtiene el país que maneja este servicio
   */
  getCountry(): CountryISO;

  /**
   * Valida si el servicio puede procesar este país
   */
  canHandle(countryISO: CountryISO): boolean;
}

