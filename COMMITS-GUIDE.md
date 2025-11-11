# 📝 Guía de Commits Profesionales

## 🎯 Conventional Commits

### Formato

```
<tipo>(<scope>): <descripción corta>

<descripción larga (opcional)>

<footer (opcional)>
```

### Tipos

| Tipo | Cuándo usar | Ejemplo |
|------|-------------|---------|
| `feat` | Nueva funcionalidad | `feat(api): endpoint de agendamiento` |
| `fix` | Corrección de bug | `fix(domain): validación de InsuredId` |
| `docs` | Solo documentación | `docs: actualizar README` |
| `style` | Formato (sin cambio lógico) | `style: formatear código` |
| `refactor` | Refactorización | `refactor(usecase): simplificar lógica` |
| `test` | Agregar tests | `test: cobertura de Use Cases` |
| `chore` | Tareas de mantenimiento | `chore: actualizar dependencias` |
| `ci` | CI/CD | `ci: configurar GitHub Actions` |
| `perf` | Mejora de performance | `perf: optimizar queries DynamoDB` |

---

## 📦 Estrategia para Este Proyecto

### Commit 1: Configuración Inicial
```bash
git add package.json tsconfig.json jest.config.js .gitignore
git commit -m "chore: configuración inicial del proyecto

- package.json con dependencias
- tsconfig.json para TypeScript strict mode
- jest.config.js para tests unitarios
- .gitignore configurado"
```

---

### Commit 2: Domain Layer
```bash
git add src/domain/
git commit -m "feat(domain): implementar Domain Layer con Clean Architecture

Domain Layer completo:
- Value Objects: InsuredId, CountryISO, AppointmentStatus
- Entity: Appointment con lógica de negocio
- Interfaces (Ports): 5 interfaces para inversión de dependencias

Principios SOLID aplicados:
- Single Responsibility Principle
- Open/Closed Principle
- Dependency Inversion Principle

Patrones de diseño:
- Value Object Pattern
- Entity Pattern
- Factory Method Pattern"
```

---

### Commit 3: Application Layer
```bash
git add src/application/
git commit -m "feat(application): implementar Application Layer con Use Cases

Use Cases implementados:
- CreateAppointmentUseCase: crear agendamiento
- ListAppointmentsByInsuredUseCase: listar por asegurado
- CompleteAppointmentUseCase: marcar como completado
- ProcessCountryAppointmentUseCase: procesar por país

DTOs:
- CreateAppointmentDto
- AppointmentDto
- ListAppointmentsResponseDto

Patrón: Use Case Pattern (Clean Architecture)"
```

---

### Commit 4: Infrastructure Layer
```bash
git add src/infrastructure/
git commit -m "feat(infrastructure): implementar Infrastructure Layer

Adapters implementados:
- DynamoDBAppointmentRepository: persistencia principal
- MySQLCountryAppointmentService: procesamiento por país
- SNSMessagePublisher: publicación de mensajes
- EventBridgePublisher: eventos de dominio
- UUIDGenerator: generación de IDs

Lambda Handlers:
- appointment/handler.ts: API Gateway endpoints
- appointment-country/handler.ts: procesadores SQS

Patrones aplicados:
- Adapter Pattern
- Repository Pattern
- Strategy Pattern (servicios por país)"
```

---

### Commit 5: Tests Unitarios
```bash
git add tests/
git commit -m "test: implementar tests unitarios con 100% de cobertura

Tests implementados (77 tests):
- Value Objects: InsuredId, CountryISO, AppointmentStatus (41 tests)
- Entity: Appointment (21 tests)
- Use Cases: Create, List, Complete, Process (15 tests)

Configuración:
- Jest + ts-jest
- Coverage threshold: 70%
- Todos los tests pasando

Cobertura alcanzada:
- Statements: 100%
- Branches: 100%
- Functions: 100%
- Lines: 100%"
```

---

### Commit 6: Terraform
```bash
git add terraform/
git commit -m "feat(iac): configurar Terraform para infraestructura AWS

Infraestructura base:
- VPC con subnets públicas, privadas y de base de datos
- Security Groups configurados
- RDS MySQL para Perú (db.t3.micro)
- RDS MySQL para Chile (db.t3.micro)
- DynamoDB Table con GSI
- SNS Topics (2) con filtros por país
- SQS Queues (3) + Dead Letter Queues
- EventBridge Bus para eventos
- AWS Secrets Manager para credenciales RDS

Features:
- Módulos reutilizables
- Variables parametrizables
- Outputs para SAM
- Multi-ambiente (dev/staging/prod)
- State en S3 (opcional)"
```

---

### Commit 7: AWS SAM
```bash
git add sam/
git commit -m "feat(iac): configurar AWS SAM para Lambda Functions

Lambda Functions (4):
- AppointmentFunction: API Gateway (POST/GET)
- ProcessPeruAppointmentFunction: SQS processor
- ProcessChileAppointmentFunction: SQS processor
- CompleteAppointmentFunction: SQS processor

API Gateway:
- REST API con CORS
- 2 endpoints configurados
- X-Ray tracing habilitado
- CloudWatch Logs

Configuración:
- VPC integration
- IAM policies automáticas
- Event Source Mappings
- Environment variables desde Terraform"
```

---

### Commit 8: CI/CD
```bash
git add .github/
git commit -m "ci: configurar CI/CD pipeline completo con GitHub Actions

Pipeline automatizado (6 jobs):
1. test-and-build: Tests unitarios + build TypeScript
2. deploy-terraform: Infraestructura base
3. deploy-sam: Lambda functions
4. init-databases: Schemas SQL en RDS
5. integration-tests: Tests E2E
6. notify: Notificaciones de resultado

Features:
- Multi-environment: dev/staging/prod
- Secrets management con GitHub Secrets
- Branch protection rules
- Rollback automático en fallos
- Parallel execution cuando es posible

Triggers:
- Push a main/develop
- Pull Request
- Manual (workflow_dispatch)"
```

---

### Commit 9: Documentación
```bash
git add README.md docs/ *.md env.example scripts/
git commit -m "docs: documentación completa y profesional del proyecto

Documentación técnica (2,500+ líneas):
- README.md (518 líneas): Overview completo
- IAC-GUIDE.md (566 líneas): Guía de IaC detallada
- MIGRATION-GUIDE.md (287 líneas): Migración desde Serverless
- RESUMEN-IAC.md (396 líneas): Resumen ejecutivo
- DEPLOYMENT.md (558 líneas): Despliegue manual
- QUICK-DEPLOY.md: Deploy en 10 minutos
- API-ENDPOINTS.md: Documentación de endpoints
- SECURITY.md: Mejores prácticas de seguridad
- AWS-CLI-SETUP.md: Configuración de AWS CLI
- CREATE-IAM-USER.md: Crear usuario IAM

Especificaciones:
- OpenAPI/Swagger: docs/openapi.yaml (358 líneas)
- Database Schema: docs/database-schema.sql (179 líneas)

Scripts de automatización:
- scripts/create-rds.sh: Crear RDS automáticamente
- scripts/init-database.sh: Inicializar schemas

Templates:
- env.example: Variables de entorno
- terraform.tfvars.example: Configuración Terraform"
```

---

## 🎓 Mejores Prácticas

### ✅ DO

1. **Commits atómicos**: Cada commit es una unidad lógica
2. **Mensajes descriptivos**: Explica QUÉ y POR QUÉ
3. **Conventional Commits**: Usa el formato estándar
4. **Commits frecuentes**: No esperes tener todo perfecto
5. **Tests antes de commit**: Asegúrate de que todo funciona

### ❌ DON'T

1. **No commits gigantes**: Dividir en unidades lógicas
2. **No mensajes vagos**: Evita "update", "fix", "changes"
3. **No commits por archivo**: Agrupar por funcionalidad
4. **No código roto**: Cada commit debe compilar/pasar tests
5. **No mezclar concerns**: Un commit = una cosa

---

## 📊 Comparación de Estrategias

### Estrategia A: Por Archivo (❌ NO)

```bash
git add package.json
git commit -m "add package.json"

git add tsconfig.json
git commit -m "add tsconfig"

git add src/domain/entities/Appointment.ts
git commit -m "add appointment"
```

**Problemas:**
- Demasiados commits
- Pierde contexto
- Difícil de revisar
- No profesional

---

### Estrategia B: Por Carpeta Mecánicamente (⚠️ REGULAR)

```bash
git add src/domain/
git commit -m "add domain"

git add src/application/
git commit -m "add application"

git add src/infrastructure/
git commit -m "add infrastructure"
```

**Problemas:**
- Mensajes poco descriptivos
- No explica funcionalidad
- Falta contexto

---

### Estrategia C: Por Funcionalidad (✅ MEJOR)

```bash
git add src/domain/
git commit -m "feat(domain): implementar Domain Layer con Clean Architecture

- Value Objects con validaciones
- Entity Appointment con lógica de negocio
- Interfaces para inversión de dependencias
- Principios SOLID aplicados"
```

**Ventajas:**
- Contexto completo
- Fácil de entender
- Profesional
- Facilita code review

---

### Estrategia D: Todo Junto (❌ NUNCA)

```bash
git add .
git commit -m "initial commit"
```

**Problemas:**
- Imposible de revisar
- Sin historial útil
- No profesional
- Dificulta rollback

---

## 🚀 Recomendación Final

Para este proyecto (entrevista + producción):

**Usar Estrategia C con Conventional Commits**

```bash
# Ejecutar el script que preparé
./setup-git-commits.sh

# O hacer commits manualmente siguiendo los ejemplos arriba
```

Esto demuestra:
- ✅ Conocimiento de Git profesional
- ✅ Organización y planificación
- ✅ Atención al detalle
- ✅ Facilita code review
- ✅ Impresiona en entrevistas

---

## 📚 Referencias

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Best Practices](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project)
- [How to Write Good Commit Messages](https://cbea.ms/git-commit/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)

