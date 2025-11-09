/**
 * Interface: IIdGenerator
 * Puerto de salida para generación de IDs únicos
 * 
 * Principios SOLID aplicados:
 * - Dependency Inversion: Abstracción para generación de IDs
 * - Single Responsibility: Solo genera IDs
 */
export interface IIdGenerator {
  /**
   * Genera un ID único
   */
  generate(): string;

  /**
   * Genera un ID con un prefijo
   */
  generateWithPrefix(prefix: string): string;
}

