import { InsuredId } from '../../domain/value-objects/InsuredId';
import { IAppointmentRepository } from '../../domain/interfaces/IAppointmentRepository';
import { AppointmentDto, ListAppointmentsResponseDto } from '../dtos/AppointmentDto';

/**
 * Use Case: ListAppointmentsByInsuredUseCase
 * Lista todos los agendamientos de un asegurado
 * 
 * Principios SOLID aplicados:
 * - Single Responsibility: Solo maneja la consulta de agendamientos
 * - Dependency Inversion: Depende de IAppointmentRepository (abstracción)
 * 
 * Patrón de diseño: Use Case Pattern
 */
export class ListAppointmentsByInsuredUseCase {
  constructor(
    private readonly appointmentRepository: IAppointmentRepository
  ) {}

  async execute(insuredIdValue: string): Promise<ListAppointmentsResponseDto> {
    // 1. Validar y crear value object
    const insuredId = InsuredId.create(insuredIdValue);

    // 2. Obtener agendamientos del repositorio
    const appointments = await this.appointmentRepository.findByInsuredId(insuredId);

    // 3. Convertir a DTOs
    const appointmentDtos: AppointmentDto[] = appointments.map(appointment => ({
      appointmentId: appointment.getAppointmentId(),
      insuredId: appointment.getInsuredId().getValue(),
      scheduleId: appointment.getScheduleId(),
      countryISO: appointment.getCountryISO().getValue(),
      status: appointment.getStatus().getValue(),
      createdAt: appointment.getCreatedAt().toISOString(),
      updatedAt: appointment.getUpdatedAt().toISOString(),
      completedAt: appointment.getCompletedAt()?.toISOString(),
      metadata: appointment.getMetadata()
    }));

    // 4. Retornar respuesta
    return {
      appointments: appointmentDtos,
      total: appointmentDtos.length,
      insuredId: insuredId.getValue()
    };
  }
}

