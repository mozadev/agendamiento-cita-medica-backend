import { CreateAppointmentUseCase } from '../../../../src/application/use-cases/CreateAppointmentUseCase';
import { IAppointmentRepository } from '../../../../src/domain/interfaces/IAppointmentRepository';
import { IMessagePublisher } from '../../../../src/domain/interfaces/IMessagePublisher';
import { IIdGenerator } from '../../../../src/domain/interfaces/IIdGenerator';
import { CreateAppointmentDto } from '../../../../src/application/dtos/CreateAppointmentDto';

describe('CreateAppointmentUseCase', () => {
  let useCase: CreateAppointmentUseCase;
  let mockRepository: jest.Mocked<IAppointmentRepository>;
  let mockPublisher: jest.Mocked<IMessagePublisher>;
  let mockIdGenerator: jest.Mocked<IIdGenerator>;

  beforeEach(() => {
    // Crear mocks
    mockRepository = {
      save: jest.fn(),
      findById: jest.fn(),
      findByInsuredId: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    };

    mockPublisher = {
      publish: jest.fn(),
      publishWithCountryFilter: jest.fn()
    };

    mockIdGenerator = {
      generate: jest.fn(),
      generateWithPrefix: jest.fn()
    };

    // Crear use case con mocks
    useCase = new CreateAppointmentUseCase(
      mockRepository,
      mockPublisher,
      mockIdGenerator
    );
  });

  describe('execute', () => {
    const validDto: CreateAppointmentDto = {
      insuredId: '12345',
      scheduleId: 100,
      countryISO: 'PE',
      metadata: { source: 'web' }
    };

    it('should create appointment successfully', async () => {
      // Arrange
      const appointmentId = 'APT-abc123';
      mockIdGenerator.generateWithPrefix.mockReturnValue(appointmentId);
      mockRepository.save.mockResolvedValue();
      mockPublisher.publishWithCountryFilter.mockResolvedValue('msg-123');

      // Act
      const result = await useCase.execute(validDto);

      // Assert
      expect(result.appointmentId).toBe(appointmentId);
      expect(result.insuredId).toBe('12345');
      expect(result.scheduleId).toBe(100);
      expect(result.countryISO).toBe('PE');
      expect(result.status).toBe('pending');
      expect(result.message).toBe('El agendamiento está en proceso');

      expect(mockRepository.save).toHaveBeenCalledTimes(1);
      expect(mockPublisher.publishWithCountryFilter).toHaveBeenCalledTimes(1);
      expect(mockIdGenerator.generateWithPrefix).toHaveBeenCalledWith('APT');
    });

    it('should throw error for invalid insuredId', async () => {
      // Arrange
      const invalidDto = { ...validDto, insuredId: 'invalid' };

      // Act & Assert
      await expect(useCase.execute(invalidDto)).rejects.toThrow();
    });

    it('should throw error for invalid countryISO', async () => {
      // Arrange
      const invalidDto = { ...validDto, countryISO: 'US' };

      // Act & Assert
      await expect(useCase.execute(invalidDto)).rejects.toThrow();
    });

    it('should mark as failed if SNS publish fails', async () => {
      // Arrange
      mockIdGenerator.generateWithPrefix.mockReturnValue('APT-abc123');
      mockRepository.save.mockResolvedValue();
      mockRepository.update.mockResolvedValue();
      mockPublisher.publishWithCountryFilter.mockRejectedValue(
        new Error('SNS publish failed')
      );

      // Act & Assert
      await expect(useCase.execute(validDto)).rejects.toThrow(
        'Failed to process appointment'
      );

      expect(mockRepository.update).toHaveBeenCalledTimes(1);
    });
  });
});

