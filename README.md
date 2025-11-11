# 🏥 Sistema de Agendamiento de Citas Médicas

Sistema backend serverless para agendamiento de citas médicas multi-país (Perú y Chile) construido con AWS, TypeScript y Clean Architecture.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Arquitectura](#arquitectura)
- [Tecnologías](#tecnologías)
- [Requisitos Previos](#requisitos-previos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Despliegue](#despliegue)
- [Uso de la API](#uso-de-la-api)
- [Pruebas](#pruebas)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Principios y Patrones](#principios-y-patrones)

## ✨ Características

- ✅ **Procesamiento Asíncrono**: Respuesta inmediata con procesamiento en segundo plano
- ✅ **Multi-País**: Soporte para Perú (PE) y Chile (CL) con bases de datos independientes
- ✅ **Arquitectura Serverless**: 100% AWS sin servidores que administrar
- ✅ **Clean Architecture**: Separación clara de responsabilidades
- ✅ **SOLID Principles**: Código mantenible y escalable
- ✅ **Type-Safe**: TypeScript para mayor confiabilidad
- ✅ **Tested**: Pruebas unitarias con Jest
- ✅ **Documented**: OpenAPI/Swagger para documentación de API

## 🏗️ Arquitectura

### Flujo de Datos

```
┌─────────────┐
│  Cliente    │
│  (Web App)  │
└──────┬──────┘
       │ 1. POST /appointments
       ▼
┌─────────────────────┐
│   API Gateway       │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐     ┌──────────────┐
│  Lambda             │────▶│  DynamoDB    │
│  appointment        │  2  │  (pending)   │
└──────┬──────────────┘     └──────────────┘
       │ 3
       ▼
┌─────────────────────┐
│  SNS Topic          │
│  (filter: country)  │
└──────┬──────┬───────┘
       │      │
    PE │      │ CL
       ▼      ▼
  ┌────────┐ ┌────────┐
  │SQS_PE  │ │SQS_CL  │
  └────┬───┘ └───┬────┘
       │         │
       ▼         ▼
  ┌──────────┐ ┌──────────┐     ┌─────────────┐
  │Lambda_PE │ │Lambda_CL │────▶│ MySQL RDS   │
  └────┬─────┘ └────┬─────┘  4  │ (per country)│
       │            │            └─────────────┘
       │            │
       └────┬───────┘
            │ 5
            ▼
       ┌──────────────┐
       │ EventBridge  │
       └──────┬───────┘
              │ 6
              ▼
         ┌─────────┐
         │   SQS   │
         └────┬────┘
              │
              ▼
       ┌─────────────────┐     ┌──────────────┐
       │  Lambda         │────▶│  DynamoDB    │
       │  appointment    │     │  (completed) │
       └─────────────────┘     └──────────────┘
```

### Componentes AWS

| Servicio | Propósito |
|----------|-----------|
| **API Gateway** | Punto de entrada HTTP REST |
| **Lambda (appointment)** | Crear agendamiento y consultar estados |
| **Lambda (appointment_pe/cl)** | Procesar agendamientos por país |
| **DynamoDB** | Almacén de estados de agendamiento |
| **SNS** | Distribución de mensajes con filtrado por país |
| **SQS** | Colas por país + cola de completación |
| **EventBridge** | Bus de eventos para notificaciones |
| **RDS MySQL** | Base de datos relacional por país |

## 🛠️ Tecnologías

- **Runtime**: Node.js 20.x
- **Lenguaje**: TypeScript 5.x
- **Framework**: Serverless Framework 4.x
- **Cloud Provider**: AWS
- **Base de Datos**: DynamoDB + MySQL (RDS)
- **Testing**: Jest
- **Bundler**: esbuild
- **Documentación**: OpenAPI 3.0

## 📦 Requisitos Previos

1. **Node.js**: v18 o superior
2. **npm** o **yarn**
3. **AWS CLI**: Configurado con credenciales
4. **Serverless Framework**: `npm install -g serverless`
5. **Cuenta AWS**: Con permisos para:
   - Lambda
   - API Gateway
   - DynamoDB
   - SNS/SQS
   - EventBridge
   - CloudFormation
   - IAM

## 🚀 Instalación

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd agendamiento-cita-media

# 2. Instalar dependencias
npm install

# 3. Compilar TypeScript (opcional, esbuild lo hace automáticamente)
npm run build
```

## ⚙️ Configuración

### Variables de Entorno

Crear archivo `.env` (opcional, para desarrollo local):

```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_PROFILE=default

# DynamoDB
APPOINTMENTS_TABLE=appointments-dev

# SNS/SQS
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123456789012:appointments-topic-dev
SQS_PE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/appointment-queue-pe-dev
SQS_CL_URL=https://sqs.us-east-1.amazonaws.com/123456789012/appointment-queue-cl-dev

# EventBridge
EVENTBRIDGE_BUS_NAME=appointments-bus-dev

# RDS Perú
RDS_PE_HOST=peru-db.xxxxx.us-east-1.rds.amazonaws.com
RDS_PE_DATABASE=appointments_pe
RDS_PE_USER=admin
RDS_PE_PASSWORD=your-secure-password

# RDS Chile
RDS_CL_HOST=chile-db.xxxxx.us-east-1.rds.amazonaws.com
RDS_CL_DATABASE=appointments_cl
RDS_CL_USER=admin
RDS_CL_PASSWORD=your-secure-password
```

### Configurar RDS

#### 1. Crear instancias RDS MySQL

```bash
# Perú
aws rds create-db-instance \
  --db-instance-identifier appointments-pe-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password YourPassword123 \
  --allocated-storage 20

# Chile
aws rds create-db-instance \
  --db-instance-identifier appointments-cl-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password YourPassword123 \
  --allocated-storage 20
```

#### 2. Crear tablas

Conectarse a cada base de datos y ejecutar:

```sql
CREATE TABLE IF NOT EXISTS appointments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id VARCHAR(50) UNIQUE NOT NULL,
  insured_id VARCHAR(5) NOT NULL,
  schedule_id INT NOT NULL,
  country_iso VARCHAR(2) NOT NULL,
  status VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  metadata JSON,
  INDEX idx_insured_id (insured_id),
  INDEX idx_appointment_id (appointment_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 🚀 Despliegue

### Desarrollo

```bash
# Desplegar en stage dev
npm run deploy:dev

# O directamente
serverless deploy --stage dev
```

### Producción

```bash
# Desplegar en stage prod
npm run deploy:prod

# O directamente
serverless deploy --stage prod
```

### Verificar Despliegue

```bash
# Ver información del stack
serverless info --stage dev

# Ver logs
serverless logs -f appointment --stage dev

# Ver logs en tiempo real
serverless logs -f appointment --stage dev --tail
```

### Eliminar Stack

```bash
# Eliminar todos los recursos
serverless remove --stage dev
```

## 📡 Uso de la API

### Endpoints

Base URL: `https://<api-id>.execute-api.<region>.amazonaws.com/<stage>`

#### 1. Crear Agendamiento

**Request:**
```bash
curl -X POST https://your-api-url/dev/appointments \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "12345",
    "scheduleId": 100,
    "countryISO": "PE",
    "metadata": {
      "source": "web",
      "centerId": 4,
      "specialtyId": 3,
      "medicId": 4,
      "date": "2024-11-09T12:30:00Z"
    }
  }'
```

**Response:**
```json
{
  "appointmentId": "APT-abc12345",
  "insuredId": "12345",
  "scheduleId": 100,
  "countryISO": "PE",
  "status": "pending",
  "message": "El agendamiento está en proceso",
  "createdAt": "2024-11-07T10:30:00.000Z"
}
```

#### 2. Listar Agendamientos

**Request:**
```bash
curl -X GET https://your-api-url/dev/appointments/12345
```

**Response:**
```json
{
  "appointments": [
    {
      "appointmentId": "APT-abc12345",
      "insuredId": "12345",
      "scheduleId": 100,
      "countryISO": "PE",
      "status": "completed",
      "createdAt": "2024-11-07T10:30:00.000Z",
      "updatedAt": "2024-11-07T10:30:15.000Z",
      "completedAt": "2024-11-07T10:30:15.000Z"
    }
  ],
  "total": 1,
  "insuredId": "12345"
}
```

### Códigos de Estado

| Código | Descripción |
|--------|-------------|
| 200 | Éxito en consulta |
| 201 | Recurso creado exitosamente |
| 400 | Error en datos de entrada |
| 500 | Error interno del servidor |

### Documentación Swagger

Acceder a la documentación completa en:
- Archivo local: `docs/openapi.yaml`
- Swagger UI: Usar [Swagger Editor](https://editor.swagger.io/) con el archivo YAML

## 🧪 Pruebas

### Ejecutar Todas las Pruebas

```bash
npm test
```

### Ejecutar con Cobertura

```bash
npm test -- --coverage
```

### Ejecutar en Modo Watch

```bash
npm run test:watch
```

### Ejecutar Solo Pruebas Unitarias

```bash
npm run test:unit
```

### Cobertura Esperada

El proyecto está configurado para mantener:
- **Branches**: ≥70%
- **Functions**: ≥70%
- **Lines**: ≥70%
- **Statements**: ≥70%

## 📁 Estructura del Proyecto

```
agendamiento-cita-media/
├── src/
│   ├── domain/                      # Capa de Dominio (Entidades, VOs, Interfaces)
│   │   ├── entities/
│   │   │   └── Appointment.ts       # Entidad raíz
│   │   ├── value-objects/
│   │   │   ├── InsuredId.ts         # Value Object: ID del asegurado
│   │   │   ├── CountryISO.ts        # Value Object: Código de país
│   │   │   └── AppointmentStatus.ts # Value Object: Estados
│   │   └── interfaces/              # Puertos (abstracciones)
│   │       ├── IAppointmentRepository.ts
│   │       ├── IMessagePublisher.ts
│   │       ├── IEventPublisher.ts
│   │       ├── ICountryAppointmentService.ts
│   │       └── IIdGenerator.ts
│   │
│   ├── application/                 # Capa de Aplicación (Casos de Uso)
│   │   ├── dtos/                    # Data Transfer Objects
│   │   │   ├── CreateAppointmentDto.ts
│   │   │   └── AppointmentDto.ts
│   │   └── use-cases/               # Lógica de negocio
│   │       ├── CreateAppointmentUseCase.ts
│   │       ├── ListAppointmentsByInsuredUseCase.ts
│   │       ├── CompleteAppointmentUseCase.ts
│   │       └── ProcessCountryAppointmentUseCase.ts
│   │
│   └── infrastructure/              # Capa de Infraestructura (Implementaciones)
│       ├── adapters/                # Adaptadores de servicios externos
│       │   ├── UUIDGenerator.ts
│       │   ├── SNSMessagePublisher.ts
│       │   └── EventBridgePublisher.ts
│       ├── repositories/            # Implementaciones de repositorios
│       │   ├── DynamoDBAppointmentRepository.ts
│       │   └── MySQLCountryAppointmentService.ts
│       └── lambdas/                 # Handlers de Lambda
│           ├── appointment/
│           │   └── handler.ts       # POST /appointments, GET /appointments/{id}
│           └── appointment-country/
│               └── handler.ts       # Procesamiento por país
│
├── tests/                           # Pruebas
│   ├── unit/                        # Pruebas unitarias
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── value-objects/
│   │   └── application/
│   │       └── use-cases/
│   └── integration/                 # Pruebas de integración
│
├── docs/                            # Documentación
│   └── openapi.yaml                 # Especificación OpenAPI/Swagger
│
├── serverless.yml                   # Configuración de infraestructura
├── tsconfig.json                    # Configuración de TypeScript
├── jest.config.js                   # Configuración de Jest
├── package.json                     # Dependencias y scripts
└── README.md                        # Este archivo
```

## 🎯 Principios y Patrones

### Principios SOLID Aplicados

#### 1. **Single Responsibility Principle (SRP)**
- Cada clase tiene una única razón para cambiar
- Ejemplo: `InsuredId` solo valida y representa IDs de asegurado

#### 2. **Open/Closed Principle (OCP)**
- Abierto para extensión, cerrado para modificación
- Ejemplo: Agregar nuevo país sin modificar código existente

#### 3. **Liskov Substitution Principle (LSP)**
- Las implementaciones pueden sustituir sus interfaces
- Ejemplo: `DynamoDBAppointmentRepository` implementa `IAppointmentRepository`

#### 4. **Interface Segregation Principle (ISP)**
- Interfaces específicas en lugar de generales
- Ejemplo: `IMessagePublisher`, `IEventPublisher` separados

#### 5. **Dependency Inversion Principle (DIP)**
- Dependencias sobre abstracciones, no implementaciones
- Ejemplo: Use cases dependen de interfaces, no de clases concretas

### Patrones de Diseño Implementados

#### 1. **Clean Architecture (Hexagonal)**
- **Capas**: Domain → Application → Infrastructure
- **Puertos y Adaptadores**: Interfaces y sus implementaciones
- **Independencia**: El dominio no conoce detalles de infraestructura

#### 2. **Repository Pattern**
- Abstrae el acceso a datos
- Implementación: `DynamoDBAppointmentRepository`

#### 3. **Strategy Pattern**
- Algoritmos intercambiables
- Implementación: `MySQLCountryAppointmentService` por país

#### 4. **Factory Pattern**
- Creación controlada de objetos
- Implementación: `Appointment.create()`, `CountryISO.create()`

#### 5. **Adapter Pattern**
- Adapta interfaces externas
- Implementación: `SNSMessagePublisher`, `EventBridgePublisher`

#### 6. **Use Case Pattern**
- Encapsula lógica de negocio específica
- Implementación: Todos los Use Cases

#### 7. **Value Object Pattern**
- Objetos inmutables identificados por su valor
- Implementación: `InsuredId`, `CountryISO`, `AppointmentStatus`

## 📚 Referencias

- [Clean Architecture - Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [AWS Serverless](https://aws.amazon.com/serverless/)
- [Serverless Framework](https://www.serverless.com/)
- [TypeScript Best Practices](https://www.typescriptlang.org/)

## 👨‍💻 Autor

** Cesar Moza**
- Reto Técnico Backend - Rimac

## 📄 Licencia

MIT License - ver archivo LICENSE para más detalles

---

**¡Gracias por revisar este proyecto!** 🙏

Para cualquier pregunta o sugerencia, no dudes en contactarme.

