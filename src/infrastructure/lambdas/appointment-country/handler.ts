import { SQSEvent } from 'aws-lambda';
import { ProcessCountryAppointmentUseCase } from '../../../application/use-cases/ProcessCountryAppointmentUseCase';
import { MySQLCountryAppointmentService } from '../../repositories/MySQLCountryAppointmentService';
import { EventBridgePublisher } from '../../adapters/EventBridgePublisher';
import { UUIDGenerator } from '../../adapters/UUIDGenerator';
import { CountryCode } from '../../../domain/value-objects/CountryISO';
import { ProcessCountryAppointmentDto } from '../../../application/use-cases/ProcessCountryAppointmentUseCase';

/**
 * Lambda Handlers: appointment_pe y appointment_cl
 * Procesan agendamientos específicos por país
 * 
 * PASOS 4 y 5 del flujo:
 * - Leen del SQS del país
 * - Guardan en RDS MySQL
 * - Publican evento de completación a EventBridge
 */

// Inicialización de dependencias
const eventPublisher = new EventBridgePublisher();
const idGenerator = new UUIDGenerator();

/**
 * Handler: appointment_pe
 * Procesa agendamientos de Perú
 */
export const processAppointmentPE = async (event: SQSEvent): Promise<void> => {
  await processCountryAppointments(event, CountryCode.PERU);
};

/**
 * Handler: appointment_cl
 * Procesa agendamientos de Chile
 */
export const processAppointmentCL = async (event: SQSEvent): Promise<void> => {
  await processCountryAppointments(event, CountryCode.CHILE);
};

/**
 * Función compartida para procesar agendamientos por país
 * Patrón: Template Method
 */
async function processCountryAppointments(
  event: SQSEvent,
  country: CountryCode
): Promise<void> {
  // 1. Crear servicio específico del país (Strategy Pattern)
  const countryService = await MySQLCountryAppointmentService.createForCountry(country);

  // 2. Crear caso de uso
  const useCase = new ProcessCountryAppointmentUseCase(
    countryService,
    eventPublisher,
    idGenerator
  );

  // 3. Procesar cada mensaje del batch
  for (const record of event.Records) {
    try {
      // 4. Parsear mensaje de SNS que viene vía SQS
      const message = JSON.parse(record.body);
      
      // El mensaje puede venir directamente o estar envuelto
      const appointmentData = message.Message ? JSON.parse(message.Message) : message;

      console.log(`Processing appointment for ${country}:`, appointmentData.appointmentId);

      // 5. Crear DTO
      const dto: ProcessCountryAppointmentDto = {
        appointmentId: appointmentData.appointmentId,
        insuredId: appointmentData.insuredId,
        scheduleId: appointmentData.scheduleId,
        countryISO: appointmentData.countryISO,
        status: appointmentData.status,
        createdAt: appointmentData.createdAt,
        metadata: appointmentData.metadata
      };

      // 6. Ejecutar caso de uso (PASOS 4 y 5)
      await useCase.execute(dto);

      console.log(`Appointment processed successfully for ${country}:`, dto.appointmentId);

    } catch (error) {
      console.error(`Error processing appointment for ${country}:`, error);
      
      // Log del error para CloudWatch
      console.error('Error details:', {
        messageId: record.messageId,
        body: record.body,
        error: (error as Error).message,
        stack: (error as Error).stack
      });

      // Lanzar error para que el mensaje vaya a DLQ
      throw error;
    }
  }

  // 7. Cerrar conexiones (cleanup)
  await countryService.close();
}

