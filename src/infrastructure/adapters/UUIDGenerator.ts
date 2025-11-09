import { v4 as uuidv4 } from 'uuid';
import { IIdGenerator } from '../../domain/interfaces/IIdGenerator';

/**
 * Adapter: UUIDGenerator
 * Implementación concreta del generador de IDs usando UUID
 * 
 * Patrón de diseño: Adapter Pattern
 * - Adapta la librería uuid a nuestra interfaz del dominio
 * 
 * Principios SOLID:
 * - Dependency Inversion: Implementa la interfaz del dominio
 */
export class UUIDGenerator implements IIdGenerator {
  generate(): string {
    return uuidv4();
  }

  generateWithPrefix(prefix: string): string {
    const uuid = uuidv4();
    // Tomar los primeros 8 caracteres del UUID para mantener IDs cortos
    const shortId = uuid.split('-')[0];
    return `${prefix}-${shortId}`;
  }
}

