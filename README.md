# 🏥 Sistema de Agendamiento de Citas Médicas - Backend

Sistema backend serverless para agendamiento de citas médicas multi-país (Perú y Chile) construido con AWS, TypeScript y Clean Architecture.

[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org/)
[![AWS](https://img.shields.io/badge/AWS-Serverless-orange.svg)](https://aws.amazon.com/serverless/)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen.svg)](tests/)
[![Coverage](https://img.shields.io/badge/Coverage-95%25-brightgreen.svg)](tests/)

---

## 📋 Tabla de Contenidos

- [Descripción del Reto](#-descripción-del-reto)
- [Características](#-características)
- [Arquitectura](#️-arquitectura)
- [Tecnologías](#️-tecnologías)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Principios y Patrones](#-principios-y-patrones)
- [Instalación Local](#-instalación-local)
- [Testing](#-testing)
- [Deploy](#-deploy)
- [Uso de la API](#-uso-de-la-api)
- [Documentación API](#-documentación-api)

---

## 📝 Descripción del Reto

**Objetivo:** Crear una aplicación backend serverless en AWS para agendamiento de citas médicas que funcione para múltiples países (Perú y Chile), donde cada país tiene su propio procesamiento y base de datos.

**Flujo de Negocio:**
1. Asegurado elige centro médico, especialidad, médico y horario
2. Presiona "Agendar" en la aplicación web
3. Backend recibe la petición y devuelve respuesta inmediata: "El agendamiento está en proceso"
4. Procesamiento asíncrono por país (diferente para PE y CL)
5. Confirmación del agendamiento cuando se complete

---

## ✨ Características

- ✅ **Procesamiento Asíncrono**: Respuesta inmediata al cliente con procesamiento en segundo plano
- ✅ **Multi-País**: Lógica de negocio independiente por país (PE y CL)
- ✅ **Arquitectura Serverless**: 100% AWS sin administración de servidores
- ✅ **Clean Architecture**: Arquitectura hexagonal con separación de capas
- ✅ **SOLID Principles**: Código mantenible, escalable y testeable
- ✅ **Type-Safe**: TypeScript para mayor confiabilidad
- ✅ **Infrastructure as Code**: Terraform (infraestructura base) + AWS SAM (aplicación)
- ✅ **CI/CD Completo**: GitHub Actions para deploy automático
- ✅ **100% Tested**: Cobertura del 95%+ en Domain y Application layers
- ✅ **API Documentation**: OpenAPI/Swagger 3.0

---

## 🏗️ Arquitectura

### Diagrama de Flujo Completo

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
       │ 3. Publish message
       ▼
┌─────────────────────┐
│  SNS Topic          │
│  (filter: country)  │
└──────┬──────┬───────┘
       │      │
    PE │      │ CL
       ▼      ▼
  ┌────────┐ ┌────────┐
  │SQS PE  │ │SQS CL  │
  └────┬───┘ └───┬────┘
       │ 4       │ 4
       ▼         ▼
  ┌──────────┐ ┌──────────┐     ┌─────────────┐
  │Lambda PE │ │Lambda CL │────▶│ MySQL RDS   │
  └────┬─────┘ └────┬─────┘  5  │ (per country)│
       │            │            └─────────────┘
       │            │
       └────┬───────┘
            │ 6. Publish confirmation
            ▼
       ┌──────────────┐
       │ EventBridge  │
       └──────┬───────┘
              │ 7
              ▼
         ┌─────────┐
         │   SQS   │
         │Completion│
         └────┬────┘
              │ 8
              ▼
       ┌─────────────────┐     ┌──────────────┐
       │  Lambda         │────▶│  DynamoDB    │
       │  appointment    │  9  │  (completed) │
       └─────────────────┘     └──────────────┘
```

### Componentes AWS Desplegados

| Servicio | Propósito | Cantidad |
|----------|-----------|----------|
| **API Gateway** | Punto de entrada HTTP REST | 1 |
| **Lambda Functions** | Lógica de negocio serverless | 5 funciones |
| **DynamoDB** | Estados de agendamiento con GSI | 1 tabla |
| **SNS** | Distribución por país con message filtering | 2 topics |
| **SQS** | Colas de procesamiento | 3 colas |
| **EventBridge** | Bus de eventos para confirmaciones | 1 bus |
| **RDS MySQL** | Base de datos relacional por país | 2 instancias |
| **VPC** | Red privada para seguridad | 1 (2 AZs) |
| **Secrets Manager** | Credenciales de RDS | 2 secrets |

### Lambda Functions

1. **appointment-api** - POST/GET endpoints (crear y listar)
2. **process-appointment-peru** - Procesamiento específico para Perú
3. **process-appointment-chile** - Procesamiento específico para Chile
4. **complete-appointment** - Actualización de estado a completado
5. **db-migration** - Ejecutar migraciones de base de datos

---

## 🛠️ Tecnologías

### Core Stack
```
Runtime:      Node.js 20.x
Lenguaje:     TypeScript 5.x
Package Mgr:  npm
```

### AWS Infrastructure
```
IaC Base:     Terraform 1.6.0
Serverless:   AWS SAM
Cloud:        AWS (us-east-1)
```

### Bases de Datos
```
NoSQL:        DynamoDB (estados)
SQL:          MySQL 8.0 en RDS (datos por país)
```

### DevOps
```
CI/CD:        GitHub Actions
Secrets:      GitHub Secrets
Testing:      Jest (95%+ coverage)
```

### Documentación
```
API Spec:     OpenAPI 3.0 (Swagger)
Formato:      YAML
```

---

## 📁 Estructura del Proyecto

### Arquitectura de 3 Capas (Clean Architecture)

```
src/
├── domain/                         # 🎯 CAPA DE DOMINIO
│   ├── entities/
│   │   └── Appointment.ts          # Entidad raíz con lógica de negocio
│   ├── value-objects/
│   │   ├── InsuredId.ts            # VO: Validación de ID asegurado (5 dígitos)
│   │   ├── CountryISO.ts           # VO: Validación de país (PE, CL)
│   │   └── AppointmentStatus.ts    # VO: Estados (pending, completed, failed)
│   └── interfaces/                 # Puertos (abstracciones)
│       ├── IAppointmentRepository.ts
│       ├── IMessagePublisher.ts
│       ├── IEventPublisher.ts
│       ├── ICountryAppointmentService.ts
│       └── IIdGenerator.ts
│
├── application/                    # 🔄 CAPA DE APLICACIÓN
│   ├── dtos/                       # Data Transfer Objects
│   │   ├── CreateAppointmentDto.ts
│   │   └── CreateAppointmentResponseDto.ts
│   └── use-cases/                  # Casos de uso (lógica de negocio)
│       ├── CreateAppointmentUseCase.ts      # POST /appointments
│       ├── ListAppointmentsByInsuredUseCase.ts  # GET /appointments/{id}
│       ├── ProcessCountryAppointmentUseCase.ts  # Procesamiento por país
│       └── CompleteAppointmentUseCase.ts    # Completar agendamiento
│
└── infrastructure/                 # 🔌 CAPA DE INFRAESTRUCTURA
    ├── adapters/                   # Adaptadores de servicios externos
    │   ├── UUIDGenerator.ts        # Generación de IDs únicos
    │   ├── SNSMessagePublisher.ts  # Publicación a AWS SNS
    │   └── EventBridgePublisher.ts # Publicación a AWS EventBridge
    ├── repositories/               # Implementaciones de repositorios
    │   ├── DynamoDBAppointmentRepository.ts
    │   └── MySQLCountryAppointmentService.ts
    └── lambdas/                    # Handlers de AWS Lambda
        ├── appointment/
        │   └── handler.ts          # API: POST, GET
        ├── appointment-country/
        │   └── handler.ts          # Procesamiento PE/CL
        └── db-migration/
            └── handler.ts          # Migraciones de BD

tests/
└── unit/
    ├── domain/
    │   ├── entities/               # Tests de entidades
    │   └── value-objects/          # Tests de VOs
    └── application/
        └── use-cases/              # Tests de casos de uso
```

### Infraestructura como Código

```
terraform/                          # 🏗️ Infraestructura Base
├── main.tf                         # VPC, RDS, DynamoDB, SNS, SQS, EventBridge
├── variables.tf                    # Variables de configuración
└── outputs.tf                      # Outputs (ARNs, URLs, etc.)

sam/                                # ☁️ Aplicación Serverless
└── template.yaml                   # Lambda functions + API Gateway

.github/workflows/                  # 🔄 CI/CD
├── deploy.yml                      # Pipeline principal (Terraform + SAM)
└── db-migrations.yml               # Workflow de migraciones
```

---

## 🎯 Principios y Patrones

### Clean Architecture (Arquitectura Hexagonal)

```
┌─────────────────────────────────────────────────────┐
│              Infrastructure Layer                    │
│  (Lambdas, Repositories, Adapters, AWS Services)   │
│                                                      │
│  ┌───────────────────────────────────────────────┐ │
│  │          Application Layer                     │ │
│  │     (Use Cases, DTOs, Orchestration)          │ │
│  │                                               │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │        Domain Layer                     │ │ │
│  │  │  (Entities, Value Objects, Interfaces) │ │ │
│  │  │                                         │ │ │
│  │  │  ✓ No dependencies                      │ │ │
│  │  │  ✓ Pure business logic                  │ │ │
│  │  │  ✓ Framework agnostic                   │ │ │
│  │  │  ✓ Independent & testable               │ │ │
│  │  └─────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘

Flujo de Dependencias: Infrastructure → Application → Domain
```

**Ventajas:**
- ✅ Máxima testabilidad (Domain 100% aislado)
- ✅ Independencia de frameworks y librerías
- ✅ Cambio de base de datos sin afectar lógica
- ✅ Fácil agregar nuevos países

### Principios SOLID

| Principio | Implementación |
|-----------|----------------|
| **S**ingle Responsibility | Cada clase tiene una única razón para cambiar (ej: `InsuredId` solo valida IDs) |
| **O**pen/Closed | Extensible sin modificar código (ej: agregar nuevo país) |
| **L**iskov Substitution | Interfaces intercambiables sin romper contratos |
| **I**nterface Segregation | Interfaces específicas (`IMessagePublisher`, `IEventPublisher`) |
| **D**ependency Inversion | Use cases dependen de abstracciones, no implementaciones |

### Patrones de Diseño Aplicados

#### 1. **Repository Pattern**
Abstracción del acceso a datos.
```typescript
interface IAppointmentRepository {
  save(appointment: Appointment): Promise<void>;
  findById(id: string): Promise<Appointment | null>;
  findByInsuredId(insuredId: InsuredId): Promise<Appointment[]>;
}

// Implementaciones:
// - DynamoDBAppointmentRepository
// - MySQLCountryAppointmentService
```

#### 2. **Strategy Pattern**
Algoritmos intercambiables por país.
```typescript
// Estrategia base
interface ICountryAppointmentService {
  process(appointment: Appointment): Promise<void>;
}

// Implementaciones por país con lógica diferente
```

#### 3. **Factory Pattern**
Creación controlada de objetos con validaciones.
```typescript
Appointment.create(...)    // Crea y valida
CountryISO.create("PE")    // Valida y formatea
InsuredId.create("123")    // Valida y formatea a "00123"
```

#### 4. **Adapter Pattern**
Adaptación de servicios externos AWS.
```typescript
SNSMessagePublisher implements IMessagePublisher
EventBridgePublisher implements IEventPublisher
```

#### 5. **Value Object Pattern**
Objetos inmutables identificados por valor.
```typescript
// Value Objects con validaciones incorporadas
InsuredId, CountryISO, AppointmentStatus
```

#### 6. **Use Case Pattern**
Encapsulación de lógica de negocio específica.
```typescript
CreateAppointmentUseCase
ListAppointmentsByInsuredUseCase
ProcessCountryAppointmentUseCase
CompleteAppointmentUseCase
```

---

## 🚀 Instalación Local

### Prerrequisitos

```bash
# Node.js 20+ y npm
node --version  # v20.x
npm --version   # 10.x

# AWS CLI configurado
aws --version
aws configure  # Configurar credenciales

# Terraform (opcional)
terraform --version  # 1.6.0+

# AWS SAM CLI (opcional)
sam --version
```

### Setup del Proyecto

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

# 5. Ver cobertura de tests
npm test -- --coverage
```

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
npm test

# Con cobertura detallada
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

**Alcance de Tests:**
- ✅ Entidades de dominio
- ✅ Value Objects con validaciones
- ✅ Casos de uso (Use Cases)
- ✅ Manejo de errores
- ✅ Edge cases

---

## 📦 Deploy

### Arquitectura de Deploy

El proyecto usa **Terraform** para infraestructura base y **AWS SAM** para la aplicación serverless:

```
GitHub Push → GitHub Actions
                    ↓
        ┌───────────┴───────────┐
        ↓                       ↓
   Terraform                AWS SAM
   (Base Infra)            (Application)
        ↓                       ↓
   ┌─────────────┐      ┌──────────────┐
   │ VPC, Subnets│      │ Lambda       │
   │ RDS MySQL   │      │ API Gateway  │
   │ DynamoDB    │      └──────────────┘
   │ SNS, SQS    │
   │ EventBridge │
   │ Secrets Mgr │
   └─────────────┘
```

### CI/CD Pipeline

**Trigger:** Push a `main` branch

**Jobs:**
1. **Test and Build**
   - Instala dependencias
   - Ejecuta tests unitarios
   - Compila TypeScript

2. **Deploy Infrastructure (Terraform)**
   - Crea/actualiza VPC, subnets, security groups
   - Despliega RDS MySQL (Perú y Chile)
   - Crea DynamoDB con GSI
   - Configura SNS, SQS, EventBridge
   - Gestiona Secrets Manager

3. **Deploy Application (AWS SAM)**
   - Despliega funciones Lambda
   - Configura API Gateway
   - Asigna permisos IAM
   - Conecta con recursos de Terraform

4. **Initialize Database (Manual)**
   - Workflow manual para ejecutar migraciones
   - Crea tablas en RDS
   - Ejecuta desde Lambda dentro de VPC

### Deploy Manual

```bash
# 1. Configurar variables de entorno en GitHub Secrets:
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# RDS_PE_USERNAME, RDS_PE_PASSWORD
# RDS_CL_USERNAME, RDS_CL_PASSWORD

# 2. Push a main ejecuta deploy automático
git push origin main

# 3. Monitorear deploy en GitHub Actions
# Ver: https://github.com/[usuario]/[repo]/actions

# 4. Inicializar base de datos (solo primera vez)
# GitHub Actions → Run workflow → Database Migrations
```

---

## 📡 Uso de la API

### Endpoints Disponibles

**Base URL:** `https://[api-id].execute-api.us-east-1.amazonaws.com/prod/`

> ⚠️ **Nota:** La URL específica se proporciona de manera privada para evitar uso no autorizado y costos innecesarios de AWS.

### 1. Crear Agendamiento

**Endpoint:** `POST /appointments`

**Request Body:**
```json
{
  "insuredId": "12345",
  "scheduleId": 100,
  "countryISO": "PE"
}
```

**Campos:**
- `insuredId` (string): ID del asegurado (1-5 dígitos numéricos)
- `scheduleId` (number): ID del espacio de agendamiento (entero positivo)
- `countryISO` (string): Código de país - solo "PE" o "CL"

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

**Response (400 Bad Request):**
```json
{
  "error": "Invalid country ISO code: MX. Must be one of: PE, CL"
}
```

### 2. Listar Agendamientos por Asegurado

**Endpoint:** `GET /appointments/{insuredId}`

**Path Parameter:**
- `insuredId`: ID del asegurado (ej: "12345")

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

### Estados de Agendamiento

| Estado | Descripción |
|--------|-------------|
| `pending` | Agendamiento recibido, en proceso |
| `completed` | Agendamiento confirmado en base de datos del país |
| `failed` | Error en el procesamiento |
| `cancelled` | Agendamiento cancelado |

### Códigos de Estado HTTP

| Código | Descripción |
|--------|-------------|
| 200 | Consulta exitosa |
| 201 | Recurso creado exitosamente |
| 400 | Error de validación en datos de entrada |
| 404 | Recurso no encontrado |
| 500 | Error interno del servidor |

---

## 📖 Documentación API

### Especificación OpenAPI/Swagger

La API está completamente documentada usando OpenAPI 3.0:

**Archivo:** [`docs/OpenAPI.yaml`](docs/OpenAPI.yaml)

**Visualizar online:**
```bash
# Opción 1: Swagger Editor
https://editor.swagger.io/
# Pegar contenido de docs/OpenAPI.yaml

# Opción 2: Desde el repositorio
# La URL específica se proporciona por email
```

**Contenido de la documentación:**
- ✅ Todos los endpoints (POST, GET)
- ✅ Esquemas de request/response
- ✅ Validaciones y restricciones
- ✅ Ejemplos de uso
- ✅ Códigos de error
- ✅ Descripciones detalladas

---

## 🔒 Seguridad

### Implementaciones de Seguridad

- ✅ **VPC Privada**: Lambdas y RDS en subnets privadas
- ✅ **Security Groups**: Acceso restringido entre componentes
- ✅ **Secrets Manager**: Credenciales de RDS nunca en código
- ✅ **IAM Roles**: Permisos granulares por función Lambda
- ✅ **Encryption**: RDS con encryption at rest
- ✅ **HTTPS Only**: API Gateway solo acepta HTTPS
- ✅ **Input Validation**: Validación estricta en Value Objects

### Variables Sensibles

Todas las credenciales se manejan mediante:
- **GitHub Secrets** (CI/CD)
- **AWS Secrets Manager** (Runtime)
- **Environment Variables** (Lambda)

**Nunca en el código:**
- ❌ Credenciales de base de datos
- ❌ AWS Access Keys
- ❌ API URLs públicas
- ❌ Tokens

---

## 📊 Métricas del Proyecto

| Métrica | Valor |
|---------|-------|
| **Lenguaje Principal** | TypeScript |
| **Líneas de Código** | ~2,500 |
| **Cobertura de Tests** | 95%+ |
| **Funciones Lambda** | 5 |
| **Endpoints API** | 2 |
| **Tablas DynamoDB** | 1 (con GSI) |
| **Instancias RDS** | 2 (PE, CL) |
| **Topics SNS** | 2 |
| **Colas SQS** | 3 |
| **Commits** | 40+ |
| **Tiempo de Deploy** | ~8 min |

---

## 🎓 Aprendizajes y Decisiones Técnicas

### ¿Por qué Clean Architecture?
- Facilita testing (Domain completamente aislado)
- Permite cambiar infraestructura sin afectar lógica
- Escalable para agregar nuevos países

### ¿Por qué Terraform + SAM en vez de solo Serverless Framework?
- **Terraform**: Mejor para recursos complejos (VPC, RDS, networking)
- **SAM**: Optimizado para Lambda + API Gateway
- **Separación de responsabilidades**: Infra base vs Aplicación

### ¿Por qué DynamoDB + RDS?
- **DynamoDB**: Estados rápidos, alta disponibilidad, serverless
- **RDS**: Datos relacionales por país, SQL para reportes

### ¿Por qué SNS + SQS?
- **SNS**: Desacopla productor de consumidores
- **SQS**: Buffer, retry automático, escalabilidad

---

## 🤝 Cómo Contribuir

Este es un proyecto de demostración técnica. Para propuestas:

1. Fork el proyecto
2. Crea una rama feature (`git checkout -b feature/mejora`)
3. Commit cambios (`git commit -m 'feat: agregar mejora'`)
4. Push a la rama (`git push origin feature/mejora`)
5. Abre un Pull Request

**Convenciones de Commits:**
- `feat:` Nueva funcionalidad
- `fix:` Corrección de bugs
- `docs:` Cambios en documentación
- `test:` Agregar o modificar tests
- `refactor:` Refactorización de código
- `chore:` Tareas de mantenimiento

---

## 📄 Licencia

MIT License - ver archivo [LICENSE](LICENSE) para más detalles.

---

## 👨‍💻 Autor

**Cesar Moza**
- GitHub: [@mozadev](https://github.com/mozadev)
- LinkedIn: [Cesar Moza](https://linkedin.com/in/cesar-moza)
- Email: ceosmore@gmail.com

---

## 🙏 Agradecimientos

Proyecto desarrollado como demostración técnica de:
- ✅ Clean Architecture en entorno serverless
- ✅ Principios SOLID aplicados
- ✅ Patrones de diseño enterprise
- ✅ Infrastructure as Code (IaC)
- ✅ CI/CD best practices
- ✅ Testing strategy completa

---

## 📚 Referencias Técnicas

- [Clean Architecture - Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Serverless Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [TypeScript Best Practices](https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html)

---

**⭐ Si te gustó este proyecto, considera darle una estrella en GitHub!**

---

> **Nota Importante:** Este proyecto está desplegado en AWS. Las URLs específicas de la API y credenciales de acceso se proporcionan de manera privada para evitar uso no autorizado y costos innecesarios. Para acceder a la API de prueba, contactar al autor.
