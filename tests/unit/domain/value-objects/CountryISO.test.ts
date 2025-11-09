import { CountryISO, CountryCode } from '../../../../src/domain/value-objects/CountryISO';

describe('CountryISO Value Object', () => {
  describe('create', () => {
    it('should create a valid CountryISO for Peru', () => {
      const country = CountryISO.create('PE');
      expect(country.getValue()).toBe(CountryCode.PERU);
    });

    it('should create a valid CountryISO for Chile', () => {
      const country = CountryISO.create('CL');
      expect(country.getValue()).toBe(CountryCode.CHILE);
    });

    it('should throw error for invalid country code', () => {
      expect(() => CountryISO.create('US')).toThrow('Invalid country ISO code');
    });

    it('should throw error for empty country code', () => {
      expect(() => CountryISO.create('')).toThrow('Invalid country ISO code');
    });

    it('should throw error for lowercase country code', () => {
      expect(() => CountryISO.create('pe')).toThrow('Invalid country ISO code');
    });
  });

  describe('isPeru', () => {
    it('should return true for Peru', () => {
      const country = CountryISO.create('PE');
      expect(country.isPeru()).toBe(true);
      expect(country.isChile()).toBe(false);
    });
  });

  describe('isChile', () => {
    it('should return true for Chile', () => {
      const country = CountryISO.create('CL');
      expect(country.isChile()).toBe(true);
      expect(country.isPeru()).toBe(false);
    });
  });

  describe('equals', () => {
    it('should return true for equal countries', () => {
      const country1 = CountryISO.create('PE');
      const country2 = CountryISO.create('PE');
      expect(country1.equals(country2)).toBe(true);
    });

    it('should return false for different countries', () => {
      const country1 = CountryISO.create('PE');
      const country2 = CountryISO.create('CL');
      expect(country1.equals(country2)).toBe(false);
    });
  });

  describe('toString', () => {
    it('should return string representation', () => {
      const country = CountryISO.create('PE');
      expect(country.toString()).toBe('PE');
    });
  });
});

