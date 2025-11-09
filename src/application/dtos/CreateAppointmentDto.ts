/**
 * DTO: CreateAppointmentDto
 * Data Transfer Object para creación de agendamientos
 * 
 * Patrón: DTO (Data Transfer Object)
 * - Separa la capa de presentación de la lógica de negocio
 */
export interface CreateAppointmentDto {
  insuredId: string;
  scheduleId: number;
  countryISO: string;
  metadata?: Record<string, any>;
}

export interface CreateAppointmentResponseDto {
  appointmentId: string;
  insuredId: string;
  scheduleId: number;
  countryISO: string;
  status: string;
  message: string;
  createdAt: string;
}

