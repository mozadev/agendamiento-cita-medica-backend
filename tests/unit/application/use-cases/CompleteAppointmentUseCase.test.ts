import { CompleteAppointmentUseCase } from '../../../../src/application/use-cases/CompleteAppointmentUseCase';
import { IAppointmentRepository } from '../../../../src/domain/interfaces/IAppointmentRepository';
import { Appointment } from '../../../../src/domain/entities/Appointment';
import { InsuredId } from '../../../../src/domain/value-objects/InsuredId';
import { CountryISO } from '../../../../src/domain/value-objects/CountryISO';

describe('CompleteAppointmentUseCase', () => {
  let useCase: CompleteAppointmentUseCase;
  let mockRepository: jest.Mocked<IAppointmentRepository>;

  beforeEach(() => {
    mockRepository = {
      save: jest.fn(),
      findById: jest.fn(),
      findByInsuredId: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    } as jest.Mocked<IAppointmentRepository>;

    useCase = new CompleteAppointmentUseCase(mockRepository);
  });

  describe('execute', () => {
    it('should complete appointment successfully', async () => {
      const appointment = Appointment.create(
        'apt-123',
        InsuredId.create('12345'),
        100,
        CountryISO.create('PE')
      );

      mockRepository.findById.mockResolvedValue(appointment);
      mockRepository.update.mockResolvedValue(undefined);

      await useCase.execute({ appointmentId: 'apt-123' });

      expect(mockRepository.findById).toHaveBeenCalledWith('apt-123');
      expect(appointment.getStatus().isCompleted()).toBe(true);
      expect(mockRepository.update).toHaveBeenCalledWith(appointment);
    });

    it('should throw error when appointment not found', async () => {
      mockRepository.findById.mockResolvedValue(null);

      await expect(
        useCase.execute({ appointmentId: 'apt-999' })
      ).rejects.toThrow('Appointment not found: apt-999');
      
      expect(mockRepository.update).not.toHaveBeenCalled();
    });

    it('should handle repository update errors', async () => {
      const appointment = Appointment.create(
        'apt-123',
        InsuredId.create('12345'),
        100,
        CountryISO.create('PE')
      );

      mockRepository.findById.mockResolvedValue(appointment);
      mockRepository.update.mockRejectedValue(new Error('Database error'));

      await expect(
        useCase.execute({ appointmentId: 'apt-123' })
      ).rejects.toThrow('Database error');
    });

    it('should handle transition errors', async () => {
      const appointment = Appointment.create(
        'apt-123',
        InsuredId.create('12345'),
        100,
        CountryISO.create('PE')
      );

      // Mark as cancelled first
      appointment.cancel();

      mockRepository.findById.mockResolvedValue(appointment);

      await expect(
        useCase.execute({ appointmentId: 'apt-123' })
      ).rejects.toThrow('Cannot complete appointment apt-123');
    });
  });
});
