import { ProcessCountryAppointmentUseCase } from '../../../../src/application/use-cases/ProcessCountryAppointmentUseCase';
import { ICountryAppointmentService } from '../../../../src/domain/interfaces/ICountryAppointmentService';
import { IEventPublisher } from '../../../../src/domain/interfaces/IEventPublisher';
import { IIdGenerator } from '../../../../src/domain/interfaces/IIdGenerator';

describe('ProcessCountryAppointmentUseCase', () => {
  let useCase: ProcessCountryAppointmentUseCase;
  let mockCountryService: jest.Mocked<ICountryAppointmentService>;
  let mockEventPublisher: jest.Mocked<IEventPublisher>;
  let mockIdGenerator: jest.Mocked<IIdGenerator>;

  beforeEach(() => {
    mockCountryService = {
      processAppointment: jest.fn(),
      getCountry: jest.fn(),
      canHandle: jest.fn(),
    } as jest.Mocked<ICountryAppointmentService>;

    mockEventPublisher = {
      publishEvent: jest.fn(),
      publishEvents: jest.fn(),
    } as jest.Mocked<IEventPublisher>;

    mockIdGenerator = {
      generate: jest.fn().mockReturnValue('event-123'),
      generateWithPrefix: jest.fn().mockReturnValue('event-123'),
    } as jest.Mocked<IIdGenerator>;

    useCase = new ProcessCountryAppointmentUseCase(
      mockCountryService,
      mockEventPublisher,
      mockIdGenerator
    );
  });

  describe('execute', () => {
    const validDto = {
      appointmentId: 'apt-123',
      insuredId: '12345',
      scheduleId: 100,
      countryISO: 'PE',
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    it('should process appointment successfully', async () => {
      mockCountryService.canHandle.mockReturnValue(true);
      mockCountryService.processAppointment.mockResolvedValue(undefined);
      mockEventPublisher.publishEvent.mockResolvedValue(undefined);

      await useCase.execute(validDto);

      expect(mockCountryService.canHandle).toHaveBeenCalledWith(
        expect.objectContaining({ value: 'PE' })
      );
      expect(mockCountryService.processAppointment).toHaveBeenCalledWith(
        expect.objectContaining({
          props: expect.objectContaining({
            appointmentId: 'apt-123',
          }),
        })
      );
      expect(mockEventPublisher.publishEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          eventType: 'AppointmentCompleted',
          eventId: 'event-123',
        })
      );
    });

    it('should throw error when service cannot handle country', async () => {
      mockCountryService.canHandle.mockReturnValue(false);

      await expect(useCase.execute(validDto)).rejects.toThrow(
        'Service cannot handle country: PE'
      );

      expect(mockCountryService.processAppointment).not.toHaveBeenCalled();
    });

    it('should throw error when processing fails', async () => {
      mockCountryService.canHandle.mockReturnValue(true);
      mockCountryService.processAppointment.mockRejectedValue(
        new Error('Database connection failed')
      );

      await expect(useCase.execute(validDto)).rejects.toThrow(
        'Failed to process appointment in PE database: Database connection failed'
      );

      expect(mockEventPublisher.publishEvent).not.toHaveBeenCalled();
    });

    it('should validate insuredId format', async () => {
      const invalidDto = { ...validDto, insuredId: 'invalid' };

      await expect(useCase.execute(invalidDto)).rejects.toThrow(
        'InsuredId must contain only numbers'
      );
    });

    it('should validate countryISO format', async () => {
      const invalidDto = { ...validDto, countryISO: 'XX' };

      await expect(useCase.execute(invalidDto)).rejects.toThrow(
        'Invalid country ISO code: XX'
      );
    });

    it('should validate status format', async () => {
      const invalidDto = { ...validDto, status: 'invalid-status' };

      await expect(useCase.execute(invalidDto)).rejects.toThrow(
        'Invalid appointment status: invalid-status'
      );
    });

    it('should process appointment for Chile', async () => {
      const clDto = { ...validDto, countryISO: 'CL' };
      mockCountryService.canHandle.mockReturnValue(true);
      mockCountryService.processAppointment.mockResolvedValue(undefined);
      mockEventPublisher.publishEvent.mockResolvedValue(undefined);

      await useCase.execute(clDto);

      expect(mockCountryService.canHandle).toHaveBeenCalledWith(
        expect.objectContaining({ value: 'CL' })
      );
      expect(mockEventPublisher.publishEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            countryISO: 'CL',
          }),
        })
      );
    });

    it('should include metadata in appointment', async () => {
      const dtoWithMetadata = { 
        ...validDto, 
        metadata: { source: 'mobile', priority: 'high' } 
      };
      mockCountryService.canHandle.mockReturnValue(true);
      mockCountryService.processAppointment.mockResolvedValue(undefined);
      mockEventPublisher.publishEvent.mockResolvedValue(undefined);

      await useCase.execute(dtoWithMetadata);

      expect(mockCountryService.processAppointment).toHaveBeenCalledWith(
        expect.objectContaining({
          props: expect.objectContaining({
            metadata: { source: 'mobile', priority: 'high' },
          }),
        })
      );
    });
  });
});

