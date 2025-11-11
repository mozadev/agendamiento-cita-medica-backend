import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import * as mysql from 'mysql2/promise';
import * as fs from 'fs';
import * as path from 'path';

const secretsManager = new SecretsManagerClient({ region: process.env.AWS_REGION || 'us-east-1' });

interface MigrationEvent {
  action: 'apply' | 'verify' | 'force';
  country: 'peru' | 'chile' | 'both';
}

interface RDSSecret {
  host: string;
  username: string;
  password: string;
  dbname: string;
  port?: number;
}

export const handler = async (event: MigrationEvent) => {
  console.log('🚀 Iniciando migración de base de datos...', JSON.stringify(event));

  const action = event.action || 'apply';
  const country = event.country || 'both';

  try {
    // Obtener secrets de RDS
    const peruSecret = await getRDSSecret(process.env.RDS_PERU_SECRET_ARN!);
    const chileSecret = await getRDSSecret(process.env.RDS_CHILE_SECRET_ARN!);

    const results: any = {
      action,
      timestamp: new Date().toISOString(),
      peru: null,
      chile: null,
    };

    // Ejecutar migraciones según el país
    if (country === 'peru' || country === 'both') {
      console.log('📊 Ejecutando migración para Perú...');
      results.peru = await runMigration(peruSecret, action);
    }

    if (country === 'chile' || country === 'both') {
      console.log('📊 Ejecutando migración para Chile...');
      results.chile = await runMigration(chileSecret, action);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Migración completada exitosamente',
        results,
      }),
    };
  } catch (error: any) {
    console.error('❌ Error en migración:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error en migración',
        error: error.message,
        stack: error.stack,
      }),
    };
  }
};

async function getRDSSecret(secretArn: string): Promise<RDSSecret> {
  try {
    const command = new GetSecretValueCommand({ SecretId: secretArn });
    const response = await secretsManager.send(command);
    
    if (!response.SecretString) {
      throw new Error(`Secret ${secretArn} no tiene SecretString`);
    }

    return JSON.parse(response.SecretString);
  } catch (error: any) {
    throw new Error(`Error obteniendo secret ${secretArn}: ${error.message}`);
  }
}

async function runMigration(secret: RDSSecret, action: string): Promise<any> {
  const { host, username, password, dbname, port = 3306 } = secret;

  let connection: mysql.Connection | null = null;

  try {
    // Crear conexión
    connection = await mysql.createConnection({
      host,
      port,
      user: username,
      password,
      database: dbname,
      multipleStatements: true, // Permitir múltiples statements
    });

    if (action === 'verify') {
      // Solo verificar conexión
      return await verifyConnection(connection, host, dbname);
    }

    // Leer el schema SQL
    // En Lambda, el código está en /var/task
    // Intentar múltiples rutas posibles
    const possiblePaths = [
      path.join(__dirname, '../../../../docs/database-schema.sql'), // Desarrollo local
      path.join(process.cwd(), 'docs/database-schema.sql'), // Lambda
      '/var/task/docs/database-schema.sql', // Lambda absoluto
    ];
    
    let schema = '';
    let schemaPath = '';
    for (const possiblePath of possiblePaths) {
      if (fs.existsSync(possiblePath)) {
        schemaPath = possiblePath;
        schema = fs.readFileSync(possiblePath, 'utf-8');
        console.log(`📄 Schema SQL encontrado en: ${schemaPath}`);
        break;
      }
    }
    
    if (!schema) {
      throw new Error(`No se pudo encontrar database-schema.sql. Rutas intentadas: ${possiblePaths.join(', ')}`);
    }

    if (action === 'force') {
      // Eliminar tablas existentes primero (peligroso)
      console.log('⚠️  FORCE: Eliminando tablas existentes...');
      await connection.query(`
        DROP TABLE IF EXISTS appointments;
        DROP TABLE IF EXISTS schedules;
        DROP TABLE IF EXISTS medical_centers;
        DROP TABLE IF EXISTS specialties;
        DROP TABLE IF EXISTS medics;
      `);
    }

    // Ejecutar schema SQL
    console.log(`📝 Ejecutando schema SQL (action: ${action})...`);
    await connection.query(schema);

    // Verificar que las tablas se crearon
    const tables = await verifyTables(connection);
    
    return {
      success: true,
      host,
      dbname,
      tables,
      message: `Migración ${action} completada exitosamente`,
    };
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

async function verifyConnection(
  connection: mysql.Connection,
  host: string,
  dbname: string
): Promise<any> {
  try {
    // Intentar query simple
    const [rows] = await connection.query('SELECT 1 as test');
    
    const tables = await verifyTables(connection);
    
    return {
      success: true,
      host,
      dbname,
      tables,
      message: 'Conexión verificada exitosamente',
    };
  } catch (error: any) {
    return {
      success: false,
      host,
      dbname,
      error: error.message,
      message: 'Error verificando conexión',
    };
  }
}

async function verifyTables(connection: mysql.Connection): Promise<string[]> {
  try {
    const [rows] = await connection.query('SHOW TABLES') as any[];
    
    // Extraer nombres de tablas del resultado
    const tables: string[] = [];
    if (rows && rows.length > 0) {
      // El resultado puede venir en diferentes formatos dependiendo de la versión de mysql2
      const firstRow = rows[0];
      const tableNameKey = Object.keys(firstRow)[0]; // Ej: "Tables_in_appointments_pe"
      
      for (const row of rows) {
        tables.push(row[tableNameKey]);
      }
    }
    
    return tables;
  } catch (error: any) {
    console.warn('Error verificando tablas:', error.message);
    return [];
  }
}

