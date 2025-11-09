/**
 * Value Object: AppointmentStatus
 * Representa los estados posibles de un agendamiento
 * 
 * Principio SOLID aplicado: Open/Closed Principle
 * - Cerrado para modificación pero abierto para extensión (podemos agregar más estados)
 */
export enum Status {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

export class AppointmentStatus {
  private readonly value: Status;

  private constructor(value: Status) {
    this.value = value;
  }

  public static createPending(): AppointmentStatus {
    return new AppointmentStatus(Status.PENDING);
  }

  public static createCompleted(): AppointmentStatus {
    return new AppointmentStatus(Status.COMPLETED);
  }

  public static createFailed(): AppointmentStatus {
    return new AppointmentStatus(Status.FAILED);
  }

  public static createCancelled(): AppointmentStatus {
    return new AppointmentStatus(Status.CANCELLED);
  }

  public static fromString(value: string): AppointmentStatus {
    const status = Object.values(Status).find(s => s === value);
    
    if (!status) {
      throw new Error(`Invalid appointment status: ${value}`);
    }

    return new AppointmentStatus(status);
  }

  public isPending(): boolean {
    return this.value === Status.PENDING;
  }

  public isCompleted(): boolean {
    return this.value === Status.COMPLETED;
  }

  public isFailed(): boolean {
    return this.value === Status.FAILED;
  }

  public isCancelled(): boolean {
    return this.value === Status.CANCELLED;
  }

  public canTransitionTo(newStatus: AppointmentStatus): boolean {
    // Reglas de transición de estados
    const transitions: Record<Status, Status[]> = {
      [Status.PENDING]: [Status.COMPLETED, Status.FAILED, Status.CANCELLED],
      [Status.COMPLETED]: [Status.CANCELLED],
      [Status.FAILED]: [Status.PENDING],
      [Status.CANCELLED]: []
    };

    return transitions[this.value].includes(newStatus.value);
  }

  public getValue(): Status {
    return this.value;
  }

  public equals(other: AppointmentStatus): boolean {
    return this.value === other.value;
  }

  public toString(): string {
    return this.value;
  }
}

