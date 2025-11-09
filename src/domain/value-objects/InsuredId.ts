/**
 * Value Object: InsuredId
 * Representa el código del asegurado (5 dígitos, puede tener ceros por delante)
 * 
 * Principio SOLID aplicado: Single Responsibility
 * - Esta clase tiene una única responsabilidad: validar y representar un ID de asegurado
 */
export class InsuredId {
  private readonly value: string;

  private constructor(value: string) {
    this.value = value;
  }

  /**
   * Factory method para crear un InsuredId validado
   * @param value - String del ID del asegurado
   * @returns InsuredId validado
   * @throws Error si el formato no es válido
   */
  public static create(value: string): InsuredId {
    this.validate(value);
    return new InsuredId(this.format(value));
  }

  private static validate(value: string): void {
    if (!value) {
      throw new Error('InsuredId cannot be empty');
    }

    // Validar que sea numérico
    if (!/^\d+$/.test(value)) {
      throw new Error('InsuredId must contain only numbers');
    }

    // Validar longitud (máximo 5 dígitos después de quitar ceros)
    const numericValue = parseInt(value, 10);
    if (numericValue < 0 || numericValue > 99999) {
      throw new Error('InsuredId must be between 0 and 99999');
    }
  }

  /**
   * Formatea el ID a 5 dígitos con ceros por delante
   */
  private static format(value: string): string {
    return value.padStart(5, '0');
  }

  public getValue(): string {
    return this.value;
  }

  public equals(other: InsuredId): boolean {
    return this.value === other.value;
  }

  public toString(): string {
    return this.value;
  }
}

