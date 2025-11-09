import { Appointment } from '../../domain/entities/Appointment';
import { InsuredId } from '../../domain/value-objects/InsuredId';
import { CountryISO } from '../../domain/value-objects/CountryISO';
import { AppointmentStatus } from '../../domain/value-objects/AppointmentStatus';
import { ICountryAppointmentService } from '../../domain/interfaces/ICountryAppointmentService';
import { IEventPublisher, DomainEvent } from '../../domain/interfaces/IEventPublisher';
import { IIdGenerator } from '../../domain/interfaces/IIdGenerator';

/**
 * Use Case: ProcessCountryAppointmentUseCase
 * Procesa agendamientos específicos por país
 * 
 * PASOS 4 y 5 del flujo:
 * - Lambda (appointment_pe/cl) lee del SQS
 * - Guarda en RDS MySQL del país
 * - Publica evento de completación a EventBridge
 * 
 * Principios SOLID aplicados:
 * - Single Responsibility: Procesa agendamientos por país
 * - Strategy Pattern: Usa el servicio específico del país
 * - Dependency Inversion: Depende de abstracciones
 */
export interface ProcessCountryAppointmentDto {
  appointmentId: string;
  insuredId: string;
  scheduleId: number;
  countryISO: string;
  status: string;
  createdAt: string;
  metadata?: Record<string, any>;
}

export class ProcessCountryAppointmentUseCase {
  constructor(
    private readonly countryAppointmentService: ICountryAppointmentService,
    private readonly eventPublisher: IEventPublisher,
    private readonly idGenerator: IIdGenerator
  ) {}

  async execute(dto: ProcessCountryAppointmentDto): Promise<void> {
    // 1. Validar y crear value objects
    const insuredId = InsuredId.create(dto.insuredId);
    const countryISO = CountryISO.create(dto.countryISO);
    const status = AppointmentStatus.fromString(dto.status);

    // 2. Verificar si el servicio puede manejar este país (Strategy Pattern)
    if (!this.countryAppointmentService.canHandle(countryISO)) {
      throw new Error(
        `Service cannot handle country: ${countryISO.getValue()}`
      );
    }

    // 3. Reconstruir la entidad desde el mensaje
    const appointment = Appointment.fromPersistence({
      appointmentId: dto.appointmentId,
      insuredId,
      scheduleId: dto.scheduleId,
      countryISO,
      status,
      createdAt: new Date(dto.createdAt),
      updatedAt: new Date(),
      metadata: dto.metadata
    });

    // 4. Procesar el agendamiento en RDS del país (PASO 4)
    try {
      await this.countryAppointmentService.processAppointment(appointment);
    } catch (error) {
      throw new Error(
        `Failed to process appointment in ${countryISO.getValue()} database: ${(error as Error).message}`
      );
    }

    // 5. Publicar evento de completación a EventBridge (PASO 5)
    const completionEvent: DomainEvent = {
      eventId: this.idGenerator.generate(),
      eventType: 'AppointmentCompleted',
      source: 'appointment.service',
      timestamp: new Date(),
      data: {
        appointmentId: appointment.getAppointmentId(),
        insuredId: appointment.getInsuredId().getValue(),
        scheduleId: appointment.getScheduleId(),
        countryISO: appointment.getCountryISO().getValue(),
        processedAt: new Date().toISOString()
      }
    };

    await this.eventPublisher.publishEvent(completionEvent);
  }
}

