import { InsuredId } from '../value-objects/InsuredId';
import { CountryISO } from '../value-objects/CountryISO';
import { AppointmentStatus } from '../value-objects/AppointmentStatus';

/**
 * Entity: Appointment
 * Entidad raíz del agregado de agendamiento
 * 
 * Principios SOLID aplicados:
 * - Single Responsibility: La entidad solo maneja su propio estado y lógica de negocio
 * - Open/Closed: Abierto a extensión (nuevos métodos) pero cerrado a modificación
 * 
 * Patrón de diseño: Builder (a través del método static create)
 */
export interface AppointmentProps {
  appointmentId: string;
  insuredId: InsuredId;
  scheduleId: number;
  countryISO: CountryISO;
  status: AppointmentStatus;
  createdAt: Date;
  updatedAt: Date;
  completedAt?: Date;
  metadata?: Record<string, any>;
}

export class Appointment {
  private readonly props: AppointmentProps;

  private constructor(props: AppointmentProps) {
    this.props = props;
  }

  /**
   * Factory method para crear un nuevo agendamiento
   * Patrón: Factory Method
   */
  public static create(
    appointmentId: string,
    insuredId: InsuredId,
    scheduleId: number,
    countryISO: CountryISO,
    metadata?: Record<string, any>
  ): Appointment {
    this.validateScheduleId(scheduleId);

    const props: AppointmentProps = {
      appointmentId,
      insuredId,
      scheduleId,
      countryISO,
      status: AppointmentStatus.createPending(),
      createdAt: new Date(),
      updatedAt: new Date(),
      metadata
    };

    return new Appointment(props);
  }

  /**
   * Factory method para reconstruir desde persistencia
   */
  public static fromPersistence(props: AppointmentProps): Appointment {
    return new Appointment(props);
  }

  private static validateScheduleId(scheduleId: number): void {
    if (!Number.isInteger(scheduleId) || scheduleId <= 0) {
      throw new Error('ScheduleId must be a positive integer');
    }
  }

  /**
   * Marca el agendamiento como completado
   * Aplica reglas de negocio para transición de estados
   */
  public markAsCompleted(): void {
    if (!this.props.status.canTransitionTo(AppointmentStatus.createCompleted())) {
      throw new Error(
        `Cannot transition from ${this.props.status.toString()} to completed`
      );
    }

    this.props.status = AppointmentStatus.createCompleted();
    this.props.completedAt = new Date();
    this.props.updatedAt = new Date();
  }

  /**
   * Marca el agendamiento como fallido
   */
  public markAsFailed(reason?: string): void {
    if (!this.props.status.canTransitionTo(AppointmentStatus.createFailed())) {
      throw new Error(
        `Cannot transition from ${this.props.status.toString()} to failed`
      );
    }

    this.props.status = AppointmentStatus.createFailed();
    this.props.updatedAt = new Date();
    
    if (reason) {
      this.props.metadata = {
        ...this.props.metadata,
        failureReason: reason
      };
    }
  }

  /**
   * Cancela el agendamiento
   */
  public cancel(reason?: string): void {
    if (!this.props.status.canTransitionTo(AppointmentStatus.createCancelled())) {
      throw new Error(
        `Cannot transition from ${this.props.status.toString()} to cancelled`
      );
    }

    this.props.status = AppointmentStatus.createCancelled();
    this.props.updatedAt = new Date();
    
    if (reason) {
      this.props.metadata = {
        ...this.props.metadata,
        cancellationReason: reason
      };
    }
  }

  // Getters
  public getAppointmentId(): string {
    return this.props.appointmentId;
  }

  public getInsuredId(): InsuredId {
    return this.props.insuredId;
  }

  public getScheduleId(): number {
    return this.props.scheduleId;
  }

  public getCountryISO(): CountryISO {
    return this.props.countryISO;
  }

  public getStatus(): AppointmentStatus {
    return this.props.status;
  }

  public getCreatedAt(): Date {
    return this.props.createdAt;
  }

  public getUpdatedAt(): Date {
    return this.props.updatedAt;
  }

  public getCompletedAt(): Date | undefined {
    return this.props.completedAt;
  }

  public getMetadata(): Record<string, any> | undefined {
    return this.props.metadata;
  }

  /**
   * Convierte la entidad a un objeto plano para persistencia
   */
  public toPersistence(): Record<string, any> {
    return {
      id: this.props.appointmentId, // DynamoDB partition key
      appointmentId: this.props.appointmentId,
      insuredId: this.props.insuredId.getValue(),
      scheduleId: this.props.scheduleId,
      countryISO: this.props.countryISO.getValue(),
      status: this.props.status.getValue(),
      createdAt: this.props.createdAt.toISOString(),
      updatedAt: this.props.updatedAt.toISOString(),
      completedAt: this.props.completedAt?.toISOString(),
      metadata: this.props.metadata
    };
  }

  /**
   * Convierte la entidad a formato de respuesta API
   */
  public toDTO(): Record<string, any> {
    return {
      appointmentId: this.props.appointmentId,
      insuredId: this.props.insuredId.getValue(),
      scheduleId: this.props.scheduleId,
      countryISO: this.props.countryISO.getValue(),
      status: this.props.status.getValue(),
      createdAt: this.props.createdAt.toISOString(),
      updatedAt: this.props.updatedAt.toISOString(),
      completedAt: this.props.completedAt?.toISOString(),
      metadata: this.props.metadata
    };
  }
}

