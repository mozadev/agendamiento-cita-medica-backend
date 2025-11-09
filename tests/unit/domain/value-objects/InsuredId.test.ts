import { InsuredId } from '../../../../src/domain/value-objects/InsuredId';

describe('InsuredId Value Object', () => {
  describe('create', () => {
    it('should create a valid InsuredId with 5 digits', () => {
      const insuredId = InsuredId.create('12345');
      expect(insuredId.getValue()).toBe('12345');
    });

    it('should format InsuredId with leading zeros', () => {
      const insuredId = InsuredId.create('123');
      expect(insuredId.getValue()).toBe('00123');
    });

    it('should handle single digit', () => {
      const insuredId = InsuredId.create('1');
      expect(insuredId.getValue()).toBe('00001');
    });

    it('should handle InsuredId with existing leading zeros', () => {
      const insuredId = InsuredId.create('00456');
      expect(insuredId.getValue()).toBe('00456');
    });

    it('should throw error for empty value', () => {
      expect(() => InsuredId.create('')).toThrow('InsuredId cannot be empty');
    });

    it('should throw error for non-numeric value', () => {
      expect(() => InsuredId.create('abc123')).toThrow('InsuredId must contain only numbers');
    });

    it('should throw error for negative numbers', () => {
      expect(() => InsuredId.create('-123')).toThrow('InsuredId must contain only numbers');
    });

    it('should throw error for numbers greater than 99999', () => {
      expect(() => InsuredId.create('100000')).toThrow('InsuredId must be between 0 and 99999');
    });
  });

  describe('equals', () => {
    it('should return true for equal InsuredIds', () => {
      const id1 = InsuredId.create('123');
      const id2 = InsuredId.create('00123');
      expect(id1.equals(id2)).toBe(true);
    });

    it('should return false for different InsuredIds', () => {
      const id1 = InsuredId.create('123');
      const id2 = InsuredId.create('456');
      expect(id1.equals(id2)).toBe(false);
    });
  });

  describe('toString', () => {
    it('should return string representation', () => {
      const insuredId = InsuredId.create('789');
      expect(insuredId.toString()).toBe('00789');
    });
  });
});

