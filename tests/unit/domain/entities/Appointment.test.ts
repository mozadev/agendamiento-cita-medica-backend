import { Appointment } from '../../../../src/domain/entities/Appointment';
import { InsuredId } from '../../../../src/domain/value-objects/InsuredId';
import { CountryISO } from '../../../../src/domain/value-objects/CountryISO';

describe('Appointment Entity', () => {
  const validInsuredId = InsuredId.create('12345');
  const validCountryISO = CountryISO.create('PE');
  const validScheduleId = 100;

  describe('create', () => {
    it('should create a valid appointment', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      expect(appointment.getAppointmentId()).toBe('apt-123');
      expect(appointment.getInsuredId().equals(validInsuredId)).toBe(true);
      expect(appointment.getScheduleId()).toBe(validScheduleId);
      expect(appointment.getCountryISO().equals(validCountryISO)).toBe(true);
      expect(appointment.getStatus().isPending()).toBe(true);
    });

    it('should create appointment with metadata', () => {
      const metadata = { source: 'web', priority: 'high' };
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO,
        metadata
      );

      expect(appointment.getMetadata()).toEqual(metadata);
    });

    it('should throw error for invalid scheduleId (zero)', () => {
      expect(() =>
        Appointment.create('apt-123', validInsuredId, 0, validCountryISO)
      ).toThrow('ScheduleId must be a positive integer');
    });

    it('should throw error for invalid scheduleId (negative)', () => {
      expect(() =>
        Appointment.create('apt-123', validInsuredId, -1, validCountryISO)
      ).toThrow('ScheduleId must be a positive integer');
    });

    it('should throw error for invalid scheduleId (decimal)', () => {
      expect(() =>
        Appointment.create('apt-123', validInsuredId, 1.5, validCountryISO)
      ).toThrow('ScheduleId must be a positive integer');
    });
  });

  describe('markAsCompleted', () => {
    it('should mark pending appointment as completed', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      appointment.markAsCompleted();

      expect(appointment.getStatus().isCompleted()).toBe(true);
      expect(appointment.getCompletedAt()).toBeDefined();
    });

    it('should throw error when transitioning from invalid state', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      appointment.cancel();

      expect(() => appointment.markAsCompleted()).toThrow('Cannot transition from');
    });
  });

  describe('markAsFailed', () => {
    it('should mark appointment as failed with reason', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      appointment.markAsFailed('Connection timeout');

      expect(appointment.getStatus().isFailed()).toBe(true);
      expect(appointment.getMetadata()?.failureReason).toBe('Connection timeout');
    });

    it('should throw error when transitioning from invalid state to failed', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      appointment.markAsCompleted();

      expect(() => appointment.markAsFailed()).toThrow('Cannot transition from');
    });
  });

  describe('cancel', () => {
    it('should cancel appointment with reason', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      appointment.cancel('User requested cancellation');

      expect(appointment.getStatus().isCancelled()).toBe(true);
      expect(appointment.getMetadata()?.cancellationReason).toBe('User requested cancellation');
    });

    it('should throw error when transitioning from invalid state to cancelled', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      appointment.cancel();
      
      // Cancelled cannot transition to cancelled again
      expect(() => appointment.cancel()).toThrow('Cannot transition from');
    });
  });

  describe('fromPersistence', () => {
    it('should recreate appointment from persistence data', () => {
      const props = {
        appointmentId: 'apt-456',
        insuredId: InsuredId.create('67890'),
        scheduleId: 200,
        countryISO: CountryISO.create('CL'),
        status: Appointment.create('temp', validInsuredId, 100, validCountryISO).getStatus(),
        createdAt: new Date('2024-01-01'),
        updatedAt: new Date('2024-01-02'),
        metadata: { source: 'mobile' },
      };

      const appointment = Appointment.fromPersistence(props);

      expect(appointment.getAppointmentId()).toBe('apt-456');
      expect(appointment.getInsuredId().getValue()).toBe('67890');
      expect(appointment.getScheduleId()).toBe(200);
      expect(appointment.getCountryISO().getValue()).toBe('CL');
      expect(appointment.getMetadata()).toEqual({ source: 'mobile' });
    });
  });

  describe('toPersistence', () => {
    it('should convert to persistence format', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      const persistence = appointment.toPersistence();

      expect(persistence.appointmentId).toBe('apt-123');
      expect(persistence.insuredId).toBe('12345');
      expect(persistence.scheduleId).toBe(100);
      expect(persistence.countryISO).toBe('PE');
      expect(persistence.status).toBe('pending');
      expect(persistence.createdAt).toBeDefined();
      expect(persistence.updatedAt).toBeDefined();
    });
  });

  describe('toDTO', () => {
    it('should convert to DTO format', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      const dto = appointment.toDTO();

      expect(dto.appointmentId).toBe('apt-123');
      expect(dto.insuredId).toBe('12345');
      expect(dto.scheduleId).toBe(100);
      expect(dto.countryISO).toBe('PE');
      expect(dto.status).toBe('pending');
    });

    it('should include completedAt in DTO when completed', () => {
      const appointment = Appointment.create(
        'apt-123',
        validInsuredId,
        validScheduleId,
        validCountryISO
      );

      appointment.markAsCompleted();
      const dto = appointment.toDTO();

      expect(dto.completedAt).toBeDefined();
      expect(dto.status).toBe('completed');
    });
  });

  describe('getters', () => {
    it('should return all properties correctly', () => {
      const metadata = { test: true };
      
      const appointment = Appointment.create(
        'apt-999',
        validInsuredId,
        validScheduleId,
        validCountryISO,
        metadata
      );

      expect(appointment.getAppointmentId()).toBe('apt-999');
      expect(appointment.getInsuredId()).toEqual(validInsuredId);
      expect(appointment.getScheduleId()).toBe(100);
      expect(appointment.getCountryISO()).toEqual(validCountryISO);
      expect(appointment.getStatus().isPending()).toBe(true);
      expect(appointment.getCreatedAt()).toBeDefined();
      expect(appointment.getUpdatedAt()).toBeDefined();
      expect(appointment.getMetadata()).toEqual(metadata);
      expect(appointment.getCompletedAt()).toBeUndefined();
    });
  });
});

