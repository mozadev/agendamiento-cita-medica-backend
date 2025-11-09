import { IAppointmentRepository } from '../../domain/interfaces/IAppointmentRepository';

/**
 * Use Case: CompleteAppointmentUseCase
 * Marca un agendamiento como completado
 * 
 * PASO 6 del flujo:
 * - Lambda appointment lee del SQS de completación
 * - Actualiza el estado a "completed" en DynamoDB
 * 
 * Principios SOLID aplicados:
 * - Single Responsibility: Solo actualiza el estado a completado
 * - Dependency Inversion: Depende de abstracciones
 */
export interface CompleteAppointmentDto {
  appointmentId: string;
  metadata?: Record<string, any>;
}

export class CompleteAppointmentUseCase {
  constructor(
    private readonly appointmentRepository: IAppointmentRepository
  ) {}

  async execute(dto: CompleteAppointmentDto): Promise<void> {
    // 1. Buscar el agendamiento
    const appointment = await this.appointmentRepository.findById(dto.appointmentId);

    if (!appointment) {
      throw new Error(`Appointment not found: ${dto.appointmentId}`);
    }

    // 2. Marcar como completado (aplica reglas de negocio)
    try {
      appointment.markAsCompleted();
    } catch (error) {
      throw new Error(
        `Cannot complete appointment ${dto.appointmentId}: ${(error as Error).message}`
      );
    }

    // 3. Actualizar en DynamoDB (PASO 6)
    await this.appointmentRepository.update(appointment);
  }
}

