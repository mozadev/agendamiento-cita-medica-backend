import { AppointmentStatus } from '../../../../src/domain/value-objects/AppointmentStatus';

describe('AppointmentStatus Value Object', () => {
  describe('create methods', () => {
    it('should create pending status', () => {
      const status = AppointmentStatus.createPending();
      expect(status.isPending()).toBe(true);
      expect(status.getValue()).toBe('pending');
    });

    it('should create completed status', () => {
      const status = AppointmentStatus.createCompleted();
      expect(status.isCompleted()).toBe(true);
      expect(status.getValue()).toBe('completed');
    });

    it('should create failed status', () => {
      const status = AppointmentStatus.createFailed();
      expect(status.isFailed()).toBe(true);
      expect(status.getValue()).toBe('failed');
    });

    it('should create cancelled status', () => {
      const status = AppointmentStatus.createCancelled();
      expect(status.isCancelled()).toBe(true);
      expect(status.getValue()).toBe('cancelled');
    });
  });

  describe('fromString', () => {
    it('should create status from valid string "pending"', () => {
      const status = AppointmentStatus.fromString('pending');
      expect(status.isPending()).toBe(true);
    });

    it('should create status from valid string "completed"', () => {
      const status = AppointmentStatus.fromString('completed');
      expect(status.isCompleted()).toBe(true);
    });

    it('should create status from valid string "failed"', () => {
      const status = AppointmentStatus.fromString('failed');
      expect(status.isFailed()).toBe(true);
    });

    it('should create status from valid string "cancelled"', () => {
      const status = AppointmentStatus.fromString('cancelled');
      expect(status.isCancelled()).toBe(true);
    });

    it('should throw error for invalid status string', () => {
      expect(() => AppointmentStatus.fromString('invalid')).toThrow(
        'Invalid appointment status: invalid'
      );
    });
  });

  describe('canTransitionTo', () => {
    it('should allow transition from pending to completed', () => {
      const pending = AppointmentStatus.createPending();
      const completed = AppointmentStatus.createCompleted();
      expect(pending.canTransitionTo(completed)).toBe(true);
    });

    it('should allow transition from pending to failed', () => {
      const pending = AppointmentStatus.createPending();
      const failed = AppointmentStatus.createFailed();
      expect(pending.canTransitionTo(failed)).toBe(true);
    });

    it('should allow transition from pending to cancelled', () => {
      const pending = AppointmentStatus.createPending();
      const cancelled = AppointmentStatus.createCancelled();
      expect(pending.canTransitionTo(cancelled)).toBe(true);
    });

    it('should allow transition from completed to cancelled', () => {
      const completed = AppointmentStatus.createCompleted();
      const cancelled = AppointmentStatus.createCancelled();
      expect(completed.canTransitionTo(cancelled)).toBe(true);
    });

    it('should allow transition from failed to pending', () => {
      const failed = AppointmentStatus.createFailed();
      const pending = AppointmentStatus.createPending();
      expect(failed.canTransitionTo(pending)).toBe(true);
    });

    it('should not allow transition from cancelled to any status', () => {
      const cancelled = AppointmentStatus.createCancelled();
      const pending = AppointmentStatus.createPending();
      expect(cancelled.canTransitionTo(pending)).toBe(false);
    });

    it('should not allow transition from completed to pending', () => {
      const completed = AppointmentStatus.createCompleted();
      const pending = AppointmentStatus.createPending();
      expect(completed.canTransitionTo(pending)).toBe(false);
    });
  });

  describe('equals', () => {
    it('should return true for equal statuses', () => {
      const status1 = AppointmentStatus.createPending();
      const status2 = AppointmentStatus.createPending();
      expect(status1.equals(status2)).toBe(true);
    });

    it('should return false for different statuses', () => {
      const status1 = AppointmentStatus.createPending();
      const status2 = AppointmentStatus.createCompleted();
      expect(status1.equals(status2)).toBe(false);
    });
  });

  describe('toString', () => {
    it('should return string representation', () => {
      const status = AppointmentStatus.createPending();
      expect(status.toString()).toBe('pending');
    });
  });
});

