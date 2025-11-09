import { ListAppointmentsByInsuredUseCase } from '../../../../src/application/use-cases/ListAppointmentsByInsuredUseCase';
import { IAppointmentRepository } from '../../../../src/domain/interfaces/IAppointmentRepository';
import { Appointment } from '../../../../src/domain/entities/Appointment';
import { InsuredId } from '../../../../src/domain/value-objects/InsuredId';
import { CountryISO } from '../../../../src/domain/value-objects/CountryISO';

describe('ListAppointmentsByInsuredUseCase', () => {
  let useCase: ListAppointmentsByInsuredUseCase;
  let mockRepository: jest.Mocked<IAppointmentRepository>;

  beforeEach(() => {
    mockRepository = {
      save: jest.fn(),
      findById: jest.fn(),
      findByInsuredId: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    } as jest.Mocked<IAppointmentRepository>;

    useCase = new ListAppointmentsByInsuredUseCase(mockRepository);
  });

  describe('execute', () => {
    it('should return appointments for valid insuredId', async () => {
      const insuredId = '12345';
      const appointments = [
        Appointment.create('apt-1', InsuredId.create(insuredId), 100, CountryISO.create('PE')),
        Appointment.create('apt-2', InsuredId.create(insuredId), 101, CountryISO.create('CL')),
      ];

      mockRepository.findByInsuredId.mockResolvedValue(appointments);

      const result = await useCase.execute(insuredId);

      expect(result).toEqual({
        appointments: expect.arrayContaining([
          expect.objectContaining({
            appointmentId: 'apt-1',
            insuredId: '12345',
          }),
          expect.objectContaining({
            appointmentId: 'apt-2',
            insuredId: '12345',
          }),
        ]),
        total: 2,
        insuredId: '12345',
      });

      expect(mockRepository.findByInsuredId).toHaveBeenCalledWith(
        expect.objectContaining({ value: '12345' })
      );
    });

    it('should return empty array when no appointments found', async () => {
      const insuredId = '99999';
      mockRepository.findByInsuredId.mockResolvedValue([]);

      const result = await useCase.execute(insuredId);

      expect(result).toEqual({
        appointments: [],
        total: 0,
        insuredId: '99999',
      });
    });

    it('should throw error for invalid insuredId', async () => {
      await expect(useCase.execute('invalid')).rejects.toThrow(
        'InsuredId must contain only numbers'
      );

      expect(mockRepository.findByInsuredId).not.toHaveBeenCalled();
    });

    it('should throw error for empty insuredId', async () => {
      await expect(useCase.execute('')).rejects.toThrow(
        'InsuredId cannot be empty'
      );
    });

    it('should handle repository errors', async () => {
      mockRepository.findByInsuredId.mockRejectedValue(new Error('Database error'));

      await expect(useCase.execute('12345')).rejects.toThrow('Database error');
    });
  });
});
