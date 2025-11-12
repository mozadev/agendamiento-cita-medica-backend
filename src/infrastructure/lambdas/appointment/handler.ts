import { APIGatewayProxyEvent, APIGatewayProxyResult, SQSEvent } from 'aws-lambda';
import { CreateAppointmentUseCase } from '../../../application/use-cases/CreateAppointmentUseCase';
import { ListAppointmentsByInsuredUseCase } from '../../../application/use-cases/ListAppointmentsByInsuredUseCase';
import { CompleteAppointmentUseCase } from '../../../application/use-cases/CompleteAppointmentUseCase';
import { DynamoDBAppointmentRepository } from '../../repositories/DynamoDBAppointmentRepository';
import { SNSMessagePublisher } from '../../adapters/SNSMessagePublisher';
import { UUIDGenerator } from '../../adapters/UUIDGenerator';
import { CreateAppointmentDto } from '../../../application/dtos/CreateAppointmentDto';

/**
 * Lambda Handlers: appointment
 * Maneja las peticiones HTTP y procesamiento de mensajes SQS
 * 
 * PASOS 1 y 6 del flujo
 */

// Inicialización de dependencias (fuera del handler para reutilización)
const repository = new DynamoDBAppointmentRepository();
const messagePublisher = new SNSMessagePublisher();
const idGenerator = new UUIDGenerator();

/**
 * Handler: POST /appointments
 * PASO 1: Crea un nuevo agendamiento
 */
export const createAppointment = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true
  };

  try {
    // 1. Validar body
    if (!event.body) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'Request body is required'
        })
      };
    }

    // 2. Parsear DTO
    const dto: CreateAppointmentDto = JSON.parse(event.body);

    // 3. Validar campos requeridos
    if (!dto.insuredId || !dto.scheduleId || !dto.countryISO) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'Missing required fields: insuredId, scheduleId, countryISO'
        })
      };
    }

    // 4. Ejecutar caso de uso
    const useCase = new CreateAppointmentUseCase(
      repository,
      messagePublisher,
      idGenerator
    );

    const result = await useCase.execute(dto);

    // 5. Retornar respuesta exitosa
    return {
      statusCode: 201,
      headers,
      body: JSON.stringify(result)
    };

  } catch (error) {
    console.error('Error creating appointment:', error);

    const statusCode = (error as Error).message.includes('Invalid') ? 400 : 500;

    return {
      statusCode,
      headers,
      body: JSON.stringify({
        error: (error as Error).message || 'Internal server error'
      })
    };
  }
};

/**
 * Handler: GET /appointments/{insuredId}
 * Lista todos los agendamientos de un asegurado
 */
export const listAppointments = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true
  };

  try {
    // 1. Obtener insuredId del path
    const insuredId = event.pathParameters?.insuredId;

    if (!insuredId) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'insuredId path parameter is required'
        })
      };
    }

    // 2. Ejecutar caso de uso
    const useCase = new ListAppointmentsByInsuredUseCase(repository);
    const result = await useCase.execute(insuredId);

    // 3. Retornar respuesta exitosa
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify(result)
    };

  } catch (error) {
    console.error('Error listing appointments:', error);

    const statusCode = (error as Error).message.includes('Invalid') ? 400 : 500;

    return {
      statusCode,
      headers,
      body: JSON.stringify({
        error: (error as Error).message || 'Internal server error'
      })
    };
  }
};

/**
 * Handler: SQS Consumer
 * PASO 6: Lee mensajes del SQS de completación y actualiza el estado
 */
export const completeAppointment = async (event: SQSEvent): Promise<void> => {
  const useCase = new CompleteAppointmentUseCase(repository);

  // Procesar cada mensaje del batch
  for (const record of event.Records) {
    try {
      const message = JSON.parse(record.body);
      
      // El mensaje puede venir directamente de EventBridge o estar envuelto
      const eventDetail = message.detail || message;

      console.log('Processing completion for appointment:', eventDetail.appointmentId);

      await useCase.execute({
        appointmentId: eventDetail.appointmentId,
        metadata: {
          processedFrom: eventDetail.countryISO,
          processedAt: eventDetail.processedAt
        }
      });

      console.log('Appointment completed successfully:', eventDetail.appointmentId);

    } catch (error) {
      console.error('Error completing appointment:', error);
      // En producción, aquí podríamos reenviar a DLQ o registrar el error
      throw error; // Esto moverá el mensaje a la DLQ configurada
    }
  }
};

/**
 * Handler unificado para API Gateway
 * Enruta a createAppointment o listAppointments según el método HTTP
 */
export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  // API Gateway REST API v1 usa httpMethod y path directamente
  const method = event.httpMethod || '';
  const path = event.path || '';
  
  // Normalizar path: remover stage si existe (ej: /prod/appointments -> /appointments)
  const normalizedPath = path.replace(/^\/[^/]+/, '') || path;

  // POST /appointments -> createAppointment
  if (method === 'POST' && (normalizedPath === '/appointments' || path.endsWith('/appointments'))) {
    return createAppointment(event);
  }

  // GET /appointments/{insuredId} -> listAppointments
  if (method === 'GET' && (normalizedPath.startsWith('/appointments/') || path.includes('/appointments/'))) {
    return listAppointments(event);
  }

  // Método no soportado
  return {
    statusCode: 405,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({
      error: 'Method not allowed',
      method,
      path: normalizedPath
    })
  };
};

