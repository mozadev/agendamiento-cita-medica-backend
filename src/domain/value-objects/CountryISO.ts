/**
 * Value Object: CountryISO
 * Representa el código ISO del país (PE o CL)
 * 
 * Principio SOLID aplicado: Single Responsibility
 * - Encapsula la lógica de validación de códigos de país
 */
export enum CountryCode {
  PERU = 'PE',
  CHILE = 'CL'
}

export class CountryISO {
  private readonly value: CountryCode;

  private constructor(value: CountryCode) {
    this.value = value;
  }

  public static create(value: string): CountryISO {
    this.validate(value);
    return new CountryISO(value as CountryCode);
  }

  private static validate(value: string): void {
    const validCodes = Object.values(CountryCode);
    
    if (!validCodes.includes(value as CountryCode)) {
      throw new Error(
        `Invalid country ISO code: ${value}. Must be one of: ${validCodes.join(', ')}`
      );
    }
  }

  public getValue(): CountryCode {
    return this.value;
  }

  public isPeru(): boolean {
    return this.value === CountryCode.PERU;
  }

  public isChile(): boolean {
    return this.value === CountryCode.CHILE;
  }

  public equals(other: CountryISO): boolean {
    return this.value === other.value;
  }

  public toString(): string {
    return this.value;
  }
}

