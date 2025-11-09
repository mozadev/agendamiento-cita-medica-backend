/**
 * DTO: AppointmentDto
 * Data Transfer Object para representación de agendamientos
 */
export interface AppointmentDto {
  appointmentId: string;
  insuredId: string;
  scheduleId: number;
  countryISO: string;
  status: string;
  createdAt: string;
  updatedAt: string;
  completedAt?: string;
  metadata?: Record<string, any>;
}

export interface ListAppointmentsResponseDto {
  appointments: AppointmentDto[];
  total: number;
  insuredId: string;
}

