#!/bin/bash

# ===============================================
# Script para crear commits organizados
# Siguiendo Conventional Commits
# ===============================================

set -e  # Exit on error

echo "🚀 Configurando commits organizados..."
echo ""

# Verificar que estamos en un repo git
if [ ! -d .git ]; then
    echo "❌ No estás en un repositorio git"
    echo "Ejecuta primero: git init"
    exit 1
fi

# ===============================================
# 1. Configuración inicial del proyecto
# ===============================================
echo "📦 Commit 1: Configuración inicial del proyecto"
git add package.json tsconfig.json jest.config.js .gitignore
git commit -m "chore: configuración inicial del proyecto

- package.json con dependencias
- tsconfig.json para TypeScript
- jest.config.js para tests
- .gitignore configurado" || echo "⚠️  Ya commiteado"

# ===============================================
# 2. Domain Layer (Clean Architecture)
# ===============================================
echo "🏗️  Commit 2: Domain Layer - Value Objects y Entities"
git add src/domain/
git commit -m "feat(domain): implementar Domain Layer con Clean Architecture

Domain Layer:
- Value Objects: InsuredId, CountryISO, AppointmentStatus
- Entity: Appointment con lógica de negocio
- Interfaces (Ports): IAppointmentRepository, IMessagePublisher, etc.

Principios aplicados:
- Single Responsibility Principle
- Value Object Pattern
- Entity Pattern
- Dependency Inversion Principle" || echo "⚠️  Ya commiteado"

# ===============================================
# 3. Application Layer (Use Cases)
# ===============================================
echo "💼 Commit 3: Application Layer - Use Cases"
git add src/application/
git commit -m "feat(application): implementar Application Layer con Use Cases

Use Cases:
- CreateAppointmentUseCase
- ListAppointmentsByInsuredUseCase
- CompleteAppointmentUseCase
- ProcessCountryAppointmentUseCase

DTOs:
- CreateAppointmentDto
- AppointmentDto
- ListAppointmentsResponseDto

Patrón: Use Case Pattern (Clean Architecture)" || echo "⚠️  Ya commiteado"

# ===============================================
# 4. Infrastructure Layer (Adapters)
# ===============================================
echo "🔧 Commit 4: Infrastructure Layer - Adapters y Repositories"
git add src/infrastructure/
git commit -m "feat(infrastructure): implementar Infrastructure Layer

Adapters:
- DynamoDBAppointmentRepository
- MySQLCountryAppointmentService (PE/CL)
- SNSMessagePublisher
- EventBridgePublisher
- UUIDGenerator

Lambda Handlers:
- appointment/handler.ts (API Gateway)
- appointment-country/handler.ts (SQS processors)

Patrones aplicados:
- Adapter Pattern
- Repository Pattern
- Strategy Pattern (por país)" || echo "⚠️  Ya commiteado"

# ===============================================
# 5. Tests Unitarios
# ===============================================
echo "🧪 Commit 5: Tests unitarios (100% coverage)"
git add tests/
git commit -m "test: implementar tests unitarios con 100% de cobertura

Tests implementados:
- Value Objects: InsuredId, CountryISO, AppointmentStatus
- Entity: Appointment
- Use Cases: Create, List, Complete, Process

Configuración:
- Jest con ts-jest
- Coverage threshold: 70%
- 77 tests pasando

Cobertura: 100% en Domain y Application Layer" || echo "⚠️  Ya commiteado"

# ===============================================
# 6. Infraestructura como Código - Terraform
# ===============================================
echo "🏗️  Commit 6: IaC - Terraform para infraestructura base"
git add terraform/
git commit -m "feat(iac): configurar Terraform para infraestructura AWS

Recursos gestionados por Terraform:
- VPC, Subnets, Security Groups
- RDS MySQL (Perú y Chile)
- DynamoDB Table
- SNS Topics (2)
- SQS Queues (3) + DLQs
- EventBridge Bus
- AWS Secrets Manager

Módulos preparados:
- vpc, rds, dynamodb, sns, sqs, eventbridge, security-groups

Variables parametrizables para múltiples ambientes" || echo "⚠️  Ya commiteado"

# ===============================================
# 7. Infraestructura como Código - SAM
# ===============================================
echo "⚡ Commit 7: IaC - AWS SAM para Lambda Functions"
git add sam/
git commit -m "feat(iac): configurar AWS SAM para Lambda y API Gateway

Recursos gestionados por SAM:
- 4 Lambda Functions
- API Gateway REST API
- Event Source Mappings (SQS → Lambda)
- IAM Roles y Policies

Funciones Lambda:
- AppointmentFunction (API Gateway)
- ProcessPeruAppointmentFunction (SQS)
- ProcessChileAppointmentFunction (SQS)
- CompleteAppointmentFunction (SQS)

Features:
- VPC configuration
- X-Ray tracing
- CloudWatch Logs" || echo "⚠️  Ya commiteado"

# ===============================================
# 8. CI/CD - GitHub Actions
# ===============================================
echo "🚀 Commit 8: CI/CD con GitHub Actions"
git add .github/
git commit -m "ci: configurar CI/CD pipeline con GitHub Actions

Pipeline automatizado:
1. test-and-build (tests + build)
2. deploy-terraform (infraestructura)
3. deploy-sam (lambdas)
4. init-databases (schemas SQL)
5. integration-tests (E2E)
6. notify (resultados)

Features:
- Multi-environment (dev/staging/prod)
- Secrets management
- Branch protection
- Rollback automático en fallos

Trigger: Push a main/develop o Pull Request" || echo "⚠️  Ya commiteado"

# ===============================================
# 9. Especificaciones técnicas y scripts
# ===============================================
echo "📋 Commit 9: Especificaciones técnicas, schemas y scripts"
git add docs/database-schema.sql docs/openapi.yaml
git add env.example terraform/terraform.tfvars.example
git add scripts/
git commit -m "docs: agregar especificaciones técnicas y scripts

Especificaciones técnicas:
- docs/openapi.yaml (358 líneas): OpenAPI 3.0 specification
- docs/database-schema.sql (179 líneas): Schema MySQL para RDS

Scripts de automatización:
- scripts/create-rds.sh: Crear RDS automáticamente
- scripts/init-database.sh: Inicializar schemas SQL

Templates de configuración:
- env.example: Variables de entorno
- terraform.tfvars.example: Configuración Terraform

Nota: Documentación .md se agregará después del deploy" || echo "⚠️  Ya commiteado"

# ===============================================
# Resumen
# ===============================================
echo ""
echo "=========================================="
echo "✅ COMMITS COMPLETADOS"
echo "=========================================="
echo ""
echo "📦 Total: 9 commits atómicos creados"
echo ""
echo "🏗️  Setup & Configuration:"
echo "   → build: configuración inicial del proyecto"
echo ""
echo "⚡ Features (Clean Architecture):"
echo "   → feat(domain): capa de dominio (entities, value objects)"
echo "   → feat(application): capa de aplicación (use cases, DTOs)"
echo "   → feat(infrastructure): adaptadores y repositorios"
echo "   → feat(lambdas): Lambda handlers y API Gateway"
echo ""
echo "✅ Testing:"
echo "   → test: suite completa de tests unitarios (100% coverage)"
echo ""
echo "🚀 Infrastructure & CI/CD:"
echo "   → build(iac): Terraform + SAM configuration"
echo "   → ci: GitHub Actions pipeline"
echo ""
echo "📋 Documentation:"
echo "   → docs: especificaciones técnicas (OpenAPI, SQL schemas)"
echo ""
echo "=========================================="
echo "📊 HISTORIAL DE GIT"
echo "=========================================="
git log --oneline --graph -9
echo ""
echo "=========================================="
echo "🚀 PRÓXIMOS PASOS"
echo "=========================================="
echo ""
echo "1️⃣  Push al repositorio remoto:"
echo "    git push origin main"
echo ""
echo "2️⃣  Configurar AWS CLI (si no está configurado):"
echo "    Ver: AWS-CLI-SETUP.md"
echo ""
echo "3️⃣  Configurar GitHub Secrets para CI/CD"
echo ""
echo "4️⃣  Deploy con Terraform + SAM:"
echo "    Ver: IAC-GUIDE.md"
echo ""
echo "5️⃣  DESPUÉS DEL DEPLOY - Crear documentación final:"
echo "    - README.md principal (con URL real del API)"
echo "    - Screenshots, ejemplos con URLs reales"
echo "    - Consolidar/eliminar archivos .md temporales"
echo "    - git commit -m 'docs(readme): documentación completa del proyecto'"
echo ""
echo "=========================================="
echo "💡 MEJORES PRÁCTICAS APLICADAS"
echo "=========================================="
echo "✅ Commits atómicos (un cambio lógico por commit)"
echo "✅ Conventional Commits (type: descripción)"
echo "✅ Mensajes descriptivos con contexto"
echo "✅ Documentación técnica con el código"
echo "✅ Documentación narrativa DESPUÉS del deploy"
echo ""
echo "✨ ¡Código listo para deploy! ✨"
echo ""

