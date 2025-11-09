import { Appointment } from '../../domain/entities/Appointment';
import { InsuredId } from '../../domain/value-objects/InsuredId';
import { CountryISO } from '../../domain/value-objects/CountryISO';
import { IAppointmentRepository } from '../../domain/interfaces/IAppointmentRepository';
import { IMessagePublisher } from '../../domain/interfaces/IMessagePublisher';
import { IIdGenerator } from '../../domain/interfaces/IIdGenerator';
import { CreateAppointmentDto, CreateAppointmentResponseDto } from '../dtos/CreateAppointmentDto';

/**
 * Use Case: CreateAppointmentUseCase
 * Implementa el flujo de creación de agendamientos
 * 
 * Principios SOLID aplicados:
 * - Single Responsibility: Solo maneja la creación de agendamientos
 * - Dependency Inversion: Depende de abstracciones (interfaces), no de implementaciones
 * - Open/Closed: Cerrado para modificación, abierto para extensión
 * 
 * Patrón de diseño: Use Case Pattern (Clean Architecture)
 * 
 * PASO 1 del flujo:
 * - Recibe la petición
 * - Guarda en DynamoDB con estado "pending"
 * - Publica mensaje a SNS con filtro de país
 */
export class CreateAppointmentUseCase {
  constructor(
    private readonly appointmentRepository: IAppointmentRepository,
    private readonly messagePublisher: IMessagePublisher,
    private readonly idGenerator: IIdGenerator
  ) {}

  async execute(dto: CreateAppointmentDto): Promise<CreateAppointmentResponseDto> {
    // 1. Validar y crear value objects
    const insuredId = InsuredId.create(dto.insuredId);
    const countryISO = CountryISO.create(dto.countryISO);
    
    // 2. Generar ID único para el agendamiento
    const appointmentId = this.idGenerator.generateWithPrefix('APT');

    // 3. Crear entidad de dominio
    const appointment = Appointment.create(
      appointmentId,
      insuredId,
      dto.scheduleId,
      countryISO,
      dto.metadata
    );

    // 4. Guardar en DynamoDB (PASO 1a)
    await this.appointmentRepository.save(appointment);

    // 5. Publicar mensaje a SNS con filtro de país (PASO 1b → PASO 2)
    try {
      await this.messagePublisher.publishWithCountryFilter(
        {
          appointmentId: appointment.getAppointmentId(),
          insuredId: appointment.getInsuredId().getValue(),
          scheduleId: appointment.getScheduleId(),
          countryISO: appointment.getCountryISO().getValue(),
          status: appointment.getStatus().getValue(),
          createdAt: appointment.getCreatedAt().toISOString(),
          metadata: appointment.getMetadata()
        },
        countryISO
      );
    } catch (error) {
      // En caso de error al publicar, marcamos como fallido
      appointment.markAsFailed('Failed to publish to SNS');
      await this.appointmentRepository.update(appointment);
      throw new Error('Failed to process appointment: ' + (error as Error).message);
    }

    // 6. Retornar respuesta
    return {
      appointmentId: appointment.getAppointmentId(),
      insuredId: appointment.getInsuredId().getValue(),
      scheduleId: appointment.getScheduleId(),
      countryISO: appointment.getCountryISO().getValue(),
      status: appointment.getStatus().getValue(),
      message: 'El agendamiento está en proceso',
      createdAt: appointment.getCreatedAt().toISOString()
    };
  }
}

