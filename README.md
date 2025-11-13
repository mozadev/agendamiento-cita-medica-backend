# 🏥 Sistema de Agendamiento de Citas Médicas - Backend

Sistema backend serverless para agendamiento de citas médicas multi-país (Perú y Chile) construido con AWS, TypeScript y Clean Architecture.

[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org/)
[![AWS](https://img.shields.io/badge/AWS-Serverless-orange.svg)](https://aws.amazon.com/serverless/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Arquitectura](#️-arquitectura)
- [Tecnologías](#️-tecnologías)
- [Inicio Rápido](#-inicio-rápido)
- [API Endpoints](#-api-endpoints)
- [Documentación](#-documentación)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Principios y Patrones](#-principios-y-patrones)
- [Testing](#-testing)

---

## ✨ Características

- ✅ **Procesamiento Asíncrono**: Respuesta inmediata con procesamiento en segundo plano
- ✅ **Multi-País**: Soporte para Perú (PE) y Chile (CL) con bases de datos independientes
- ✅ **Arquitectura Serverless**: 100% AWS sin servidores que administrar
- ✅ **Clean Architecture**: Separación clara de responsabilidades (Hexagonal)
- ✅ **SOLID Principles**: Código mantenible y escalable
- ✅ **Type-Safe**: TypeScript para mayor confiabilidad
- ✅ **Infrastructure as Code**: Terraform + AWS SAM
- ✅ **CI/CD**: GitHub Actions para deploy automático
- ✅ **100% Tested**: Pruebas unitarias con Jest
- ✅ **API Documentation**: OpenAPI/Swagger 3.0

---

## 🏗️ Arquitectura

### Diagrama de Flujo

```
┌─────────────┐
│  Cliente    │
│  (Web App)  │
└──────┬──────┘
       │ 1. POST /appointments
       ▼
┌─────────────────────┐
│   API Gateway       │
│   (REST API)        │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐     ┌──────────────┐
│  Lambda             │────▶│  DynamoDB    │
│  appointment        │  2  │  (pending)   │
└──────┬──────────────┘     └──────────────┘
       │ 3. Publish
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
            │ 5. Confirm
            ▼
       ┌──────────────┐
       │ EventBridge  │
       └──────┬───────┘
              │ 6
              ▼
         ┌─────────┐
         │   SQS   │
         │Completion│
         └────┬────┘
              │
              ▼
       ┌─────────────────┐     ┌──────────────┐
       │  Lambda         │────▶│  DynamoDB    │
       │  appointment    │  7  │  (completed) │
       └─────────────────┘     └──────────────┘
```

### Componentes AWS

| Servicio | Propósito | Implementación |
|----------|-----------|----------------|
| **API Gateway** | Punto de entrada HTTP REST | AWS SAM |
| **Lambda Functions** | Lógica de negocio serverless | 5 funciones (appointment, process-pe, process-cl, complete, db-migration) |
| **DynamoDB** | Almacén de estados de agendamiento | Terraform |
| **SNS** | Distribución de mensajes con filtrado por país | Terraform (2 topics) |
| **SQS** | Colas por país + cola de completación | Terraform (3 colas) |
| **EventBridge** | Bus de eventos para notificaciones | Terraform |
| **RDS MySQL** | Base de datos relacional por país | Terraform (2 instancias) |
| **VPC** | Red privada para seguridad | Terraform |
| **Secrets Manager** | Gestión de credenciales | Terraform |

---

## 🛠️ Tecnologías

### Core
- **Runtime**: Node.js 20.x
- **Lenguaje**: TypeScript 5.x
- **Package Manager**: npm

### AWS Infrastructure
- **IaC**: Terraform 1.6.0 (base infrastructure)
- **Serverless**: AWS SAM (Lambda functions & API Gateway)
- **Cloud Provider**: AWS

### Base de Datos
- **NoSQL**: DynamoDB (estados de agendamiento)
- **SQL**: MySQL 8.0 en RDS (datos por país)

### Testing & Quality
- **Testing Framework**: Jest
- **Coverage**: 100% en Domain y Application layers

### CI/CD
- **Pipeline**: GitHub Actions
- **Secrets Management**: GitHub Secrets
- **Deploy Strategy**: Automatic on push to main

### Documentation
- **API Spec**: OpenAPI 3.0
- **Format**: Swagger/YAML

---

## 🚀 Inicio Rápido

### Prerrequisitos

```bash
# Node.js 18+ y npm
node --version  # v20.x
npm --version   # 10.x

# AWS CLI configurado
aws --version

# Terraform (opcional, para modificar infraestructura)
terraform --version  # 1.6.0+

# AWS SAM CLI (opcional, para desarrollo local)
sam --version
```

### Instalación Local

```bash
# 1. Clonar repositorio
git clone https://github.com/mozadev/agendamiento-cita-medica-backend.git
cd agendamiento-cita-medica-backend

# 2. Instalar dependencias
npm install

# 3. Compilar TypeScript
npm run build

# 4. Ejecutar tests
npm test
```

### Deploy en AWS

El proyecto usa **CI/CD automático** con GitHub Actions. Al hacer push a `main`, se despliega automáticamente.

Para deploy manual, ver [EXPLICACION-DEPLOY-WORKFLOW.md](EXPLICACION-DEPLOY-WORKFLOW.md)

---

## 📡 API Endpoints

### Base URL

```
Production: https://la153v9kdg.execute-api.us-east-1.amazonaws.com/prod/
```

### 1. Crear Agendamiento

**Endpoint:** `POST /appointments`

**Request:**
```bash
curl -X POST https://la153v9kdg.execute-api.us-east-1.amazonaws.com/prod/appointments \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "12345",
    "scheduleId": 100,
    "countryISO": "PE"
  }'
```

**Response (201 Created):**
```json
{
  "appointmentId": "APT-abc12345",
  "insuredId": "12345",
  "scheduleId": 100,
  "countryISO": "PE",
  "status": "pending",
  "message": "El agendamiento está en proceso",
  "createdAt": "2024-11-13T10:30:00.000Z"
}
```

### 2. Listar Agendamientos por Asegurado

**Endpoint:** `GET /appointments/{insuredId}`

**Request:**
```bash
curl -X GET https://la153v9kdg.execute-api.us-east-1.amazonaws.com/prod/appointments/12345
```

**Response (200 OK):**
```json
{
  "appointments": [
    {
      "appointmentId": "APT-abc12345",
      "insuredId": "12345",
      "scheduleId": 100,
      "countryISO": "PE",
      "status": "completed",
      "createdAt": "2024-11-13T10:30:00.000Z",
      "updatedAt": "2024-11-13T10:30:15.000Z",
      "completedAt": "2024-11-13T10:30:15.000Z"
    }
  ],
  "total": 1,
  "insuredId": "12345"
}
```

### Validaciones

| Campo | Tipo | Validación |
|-------|------|------------|
| `insuredId` | string | 1-5 dígitos numéricos |
| `scheduleId` | number | Entero positivo |
| `countryISO` | string | "PE" o "CL" únicamente |

### Códigos de Estado

| Código | Descripción |
|--------|-------------|
| 200 | Consulta exitosa |
| 201 | Agendamiento creado |
| 400 | Datos de entrada inválidos |
| 404 | Recurso no encontrado |
| 500 | Error interno del servidor |

---

## 📚 Documentación

### Documentación de la API

**Ver especificación OpenAPI/Swagger:**

1. **Online (Recomendado):**
   - [Swagger UI](https://petstore.swagger.io/?url=https://raw.githubusercontent.com/mozadev/agendamiento-cita-medica-backend/main/docs/OpenAPI.yaml)

2. **Archivo Local:**
   - [docs/OpenAPI.yaml](docs/OpenAPI.yaml)

3. **Swagger Editor:**
   - Ir a [editor.swagger.io](https://editor.swagger.io/)
   - Pegar el contenido de `docs/OpenAPI.yaml`

### Guías Adicionales

- 📘 [Guía de Pruebas de API](GUIA-PRUEBAS-API.md) - Cómo probar todos los endpoints
- 🚀 [Explicación del Deploy Workflow](EXPLICACION-DEPLOY-WORKFLOW.md) - CI/CD detallado
- 🗄️ [Inicializar Base de Datos](INICIALIZAR-BASE-DATOS.md) - Setup de RDS MySQL

---

## 📁 Estructura del Proyecto

```
agendamiento-cita-medica-backend/
├── src/
│   ├── domain/                         # 🎯 Capa de Dominio
│   │   ├── entities/
│   │   │   └── Appointment.ts          # Entidad raíz del agregado
│   │   ├── value-objects/
│   │   │   ├── InsuredId.ts            # VO: ID del asegurado
│   │   │   ├── CountryISO.ts           # VO: Código de país
│   │   │   └── AppointmentStatus.ts    # VO: Estados del ciclo de vida
│   │   └── interfaces/                 # Puertos (abstracciones)
│   │       ├── IAppointmentRepository.ts
│   │       ├── IMessagePublisher.ts
│   │       ├── IEventPublisher.ts
│   │       ├── ICountryAppointmentService.ts
│   │       └── IIdGenerator.ts
│   │
│   ├── application/                    # 🔄 Capa de Aplicación
│   │   ├── dtos/                       # Data Transfer Objects
│   │   │   ├── CreateAppointmentDto.ts
│   │   │   └── CreateAppointmentResponseDto.ts
│   │   └── use-cases/                  # Casos de uso (lógica de negocio)
│   │       ├── CreateAppointmentUseCase.ts
│   │       ├── ListAppointmentsByInsuredUseCase.ts
│   │       ├── CompleteAppointmentUseCase.ts
│   │       └── ProcessCountryAppointmentUseCase.ts
│   │
│   └── infrastructure/                 # 🔌 Capa de Infraestructura
│       ├── adapters/                   # Adaptadores externos
│       │   ├── UUIDGenerator.ts        # Generación de IDs
│       │   ├── SNSMessagePublisher.ts  # AWS SNS
│       │   └── EventBridgePublisher.ts # AWS EventBridge
│       ├── repositories/               # Implementaciones de repositorios
│       │   ├── DynamoDBAppointmentRepository.ts
│       │   └── MySQLCountryAppointmentService.ts
│       └── lambdas/                    # Handlers de AWS Lambda
│           ├── appointment/
│           │   └── handler.ts          # POST, GET /appointments
│           ├── appointment-country/
│           │   └── handler.ts          # Procesamiento por país
│           └── db-migration/
│               └── handler.ts          # Migraciones de base de datos
│
├── terraform/                          # 🏗️ Infraestructura Base (IaC)
│   ├── main.tf                         # VPC, RDS, DynamoDB, SNS, SQS, EventBridge
│   ├── variables.tf
│   └── outputs.tf
│
├── sam/                                # ☁️ Serverless Application Model
│   └── template.yaml                   # Lambda functions + API Gateway
│
├── .github/
│   └── workflows/
│       ├── deploy.yml                  # CI/CD pipeline principal
│       └── db-migrations.yml           # Workflow de migraciones
│
├── tests/                              # 🧪 Pruebas
│   └── unit/
│       ├── domain/
│       └── application/
│
├── docs/                               # 📖 Documentación
│   ├── OpenAPI.yaml                    # Especificación API
│   └── database-schema.sql             # Schema de RDS
│
├── test-api.sh                         # Script de pruebas automatizadas
├── tsconfig.json                       # Configuración TypeScript
├── jest.config.js                      # Configuración Jest
├── package.json                        # Dependencias
└── README.md                           # Este archivo
```

---

## 🎯 Principios y Patrones

### Clean Architecture (Arquitectura Hexagonal)

```
┌─────────────────────────────────────────────────────┐
│              Infrastructure Layer                    │
│  (Lambdas, Repositories, Adapters, External APIs)  │
│                                                      │
│  ┌───────────────────────────────────────────────┐ │
│  │          Application Layer                     │ │
│  │        (Use Cases, DTOs)                      │ │
│  │                                               │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │        Domain Layer                     │ │ │
│  │  │  (Entities, Value Objects, Interfaces) │ │ │
│  │  │                                         │ │ │
│  │  │  - No dependencies                      │ │ │
│  │  │  - Pure business logic                  │ │ │
│  │  │  - Framework agnostic                   │ │ │
│  │  └─────────────────────────────────────────┘ │ │
│  │                                               │ │
│  └───────────────────────────────────────────────┘ │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Beneficios:**
- ✅ Testabilidad máxima
- ✅ Independencia de frameworks
- ✅ Independencia de UI
- ✅ Independencia de base de datos
- ✅ Independencia de agentes externos

### Principios SOLID

| Principio | Aplicación en el Proyecto |
|-----------|---------------------------|
| **S**ingle Responsibility | Cada clase tiene una única razón para cambiar |
| **O**pen/Closed | Extensible sin modificar código existente |
| **L**iskov Substitution | Las implementaciones sustituyen sus interfaces |
| **I**nterface Segregation | Interfaces específicas y cohesivas |
| **D**ependency Inversion | Dependencias sobre abstracciones |

### Patrones de Diseño

1. **Repository Pattern** - Abstracción del acceso a datos
   - `DynamoDBAppointmentRepository`
   - `MySQLCountryAppointmentService`

2. **Strategy Pattern** - Procesamiento por país
   - `ProcessCountryAppointmentUseCase`

3. **Factory Pattern** - Creación controlada de objetos
   - `Appointment.create()`
   - `CountryISO.create()`
   - `InsuredId.create()`

4. **Adapter Pattern** - Adaptación de servicios externos
   - `SNSMessagePublisher`
   - `EventBridgePublisher`

5. **Use Case Pattern** - Encapsulación de lógica de negocio
   - Todos los casos de uso en `application/use-cases/`

6. **Value Object Pattern** - Objetos inmutables por valor
   - `InsuredId`, `CountryISO`, `AppointmentStatus`

7. **Dependency Injection** - Inyección de dependencias
   - Constructores de casos de uso

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
npm test

# Con cobertura
npm test -- --coverage

# Modo watch (desarrollo)
npm run test:watch

# Solo tests unitarios
npm run test:unit
```

### Cobertura de Tests

```
---------------------|---------|----------|---------|---------|
File                 | % Stmts | % Branch | % Funcs | % Lines |
---------------------|---------|----------|---------|---------|
All files            |   95.12 |    88.23 |   94.44 |   95.89 |
 domain/entities     |     100 |      100 |     100 |     100 |
 domain/value-objects|     100 |      100 |     100 |     100 |
 application         |   91.66 |    83.33 |   90.90 |   92.30 |
---------------------|---------|----------|---------|---------|
```

**Meta de cobertura:** ≥70% en todas las métricas

### Testing Strategy

- ✅ **Unit Tests**: Domain entities, Value Objects, Use Cases
- ✅ **Mocking**: Repositorios y servicios externos
- ✅ **Edge Cases**: Validaciones y errores
- 🚧 **Integration Tests**: Pendiente (opcional)

---

## 🚀 Deployment

### Arquitectura de Deploy

```
GitHub Push → GitHub Actions
                    ↓
        ┌───────────┴───────────┐
        ↓                       ↓
   Terraform                AWS SAM
   (Infrastructure)        (Application)
        ↓                       ↓
   ┌─────────────┐      ┌──────────────┐
   │ VPC, RDS    │      │ Lambda       │
   │ DynamoDB    │      │ API Gateway  │
   │ SNS, SQS    │      └──────────────┘
   │ EventBridge │
   └─────────────┘
```

### CI/CD Pipeline

El proyecto incluye pipeline completo en GitHub Actions:

1. **Test and Build**
   - Instala dependencias
   - Ejecuta tests unitarios
   - Compila TypeScript

2. **Deploy Infrastructure** (Terraform)
   - VPC, Subnets, Security Groups
   - RDS MySQL (PE y CL)
   - DynamoDB con GSI
   - SNS Topics, SQS Queues
   - EventBridge Bus
   - Secrets Manager

3. **Deploy Application** (AWS SAM)
   - Lambda functions
   - API Gateway REST API
   - IAM Roles y Policies

4. **Initialize Database** (Manual workflow)
   - Ejecuta migraciones en RDS

### Logs y Monitoreo

```bash
# Ver logs de Lambda
aws logs tail /aws/lambda/prod-appointment-api --follow

# Ver eventos de CloudFormation
aws cloudformation describe-stack-events --stack-name agendamiento-citas-prod

# Estado de recursos
aws cloudformation describe-stacks --stack-name agendamiento-citas-prod
```

---

## 📊 Métricas del Proyecto

| Métrica | Valor |
|---------|-------|
| **Lenguaje** | TypeScript |
| **Líneas de código** | ~2,500 |
| **Cobertura de tests** | 95%+ |
| **Funciones Lambda** | 5 |
| **Endpoints API** | 2 |
| **Tablas DynamoDB** | 1 (con GSI) |
| **Instancias RDS** | 2 (PE, CL) |
| **Topics SNS** | 2 |
| **Colas SQS** | 3 |

---

## 🤝 Contribuciones

Este es un proyecto de demostración técnica. Para propuestas de mejora:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/mejora`)
3. Commit tus cambios (`git commit -m 'feat: agregar mejora'`)
4. Push a la rama (`git push origin feature/mejora`)
5. Abre un Pull Request

---

## 📄 Licencia

MIT License - ver archivo [LICENSE](LICENSE) para más detalles.

---

## 👨‍💻 Autor

**Cesar Moza**
- GitHub: [@mozadev](https://github.com/mozadev)
- Email: ceosmore@gmail.com

---

## 🙏 Agradecimientos

Proyecto desarrollado como demostración de:
- Clean Architecture en AWS
- Principios SOLID
- Serverless patterns
- Infrastructure as Code
- CI/CD best practices

---

**⭐ Si te gustó este proyecto, dale una estrella en GitHub!**

