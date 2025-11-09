import { Appointment } from '../entities/Appointment';
import { InsuredId } from '../value-objects/InsuredId';

/**
 * Interface: IAppointmentRepository
 * Puerto de salida (Output Port) para persistencia de agendamientos
 * 
 * Principios SOLID aplicados:
 * - Dependency Inversion: Las capas superiores dependen de esta abstracción, no de implementaciones concretas
 * - Interface Segregation: Interface específica para operaciones de repositorio de agendamientos
 * 
 * Patrón de diseño: Repository Pattern
 */
export interface IAppointmentRepository {
  /**
   * Guarda un nuevo agendamiento
   */
  save(appointment: Appointment): Promise<void>;

  /**
   * Busca un agendamiento por su ID
   */
  findById(appointmentId: string): Promise<Appointment | null>;

  /**
   * Busca todos los agendamientos de un asegurado
   */
  findByInsuredId(insuredId: InsuredId): Promise<Appointment[]>;

  /**
   * Actualiza un agendamiento existente
   */
  update(appointment: Appointment): Promise<void>;

  /**
   * Elimina un agendamiento (soft delete)
   */
  delete(appointmentId: string): Promise<void>;
}

