# 🏗️ Guía de Infraestructura como Código (IaC)

## 📚 Tabla de Contenido
- [Arquitectura](#arquitectura)
- [Herramientas](#herramientas)
- [Estructura del Proyecto](#estructura)
- [Configuración Inicial](#configuración-inicial)
- [Despliegue](#despliegue)
- [CI/CD con GitHub Actions](#cicd)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Arquitectura

### Stack Tecnológico:

```
┌─────────────────────────────────────────────────────────┐
│                   INFRAESTRUCTURA                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  TERRAFORM (Infraestructura Base)                        │
│  ├─ VPC & Networking                                     │
│  ├─ RDS MySQL (Perú y Chile)                            │
│  ├─ DynamoDB Table                                       │
│  ├─ SNS Topics                                           │
│  ├─ SQS Queues + DLQs                                    │
│  ├─ EventBridge Bus                                      │
│  ├─ Security Groups                                      │
│  └─ AWS Secrets Manager                                  │
│                                                          │
│  AWS SAM (Compute)                                       │
│  ├─ Lambda Functions (4)                                 │
│  ├─ API Gateway REST API                                 │
│  └─ Event Source Mappings                                │
│                                                          │
│  GITHUB ACTIONS (CI/CD)                                  │
│  ├─ Test & Build                                         │
│  ├─ Deploy Terraform                                     │
│  ├─ Deploy SAM                                           │
│  ├─ Initialize Databases                                 │
│  └─ Integration Tests                                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### ¿Por qué esta arquitectura?

| Herramienta | Responsabilidad | Justificación |
|-------------|-----------------|---------------|
| **Terraform** | Infraestructura base (RDS, VPC, DynamoDB, SNS, SQS) | ✅ Mejor para recursos de larga duración<br>✅ State management robusto<br>✅ Módulos reutilizables<br>✅ Multi-cloud si necesitas |
| **SAM** | Lambda Functions & API Gateway | ✅ Testing local con `sam local`<br>✅ Debugging más fácil<br>✅ Integración nativa con AWS<br>✅ Menos verboso para Lambdas |
| **GitHub Actions** | CI/CD | ✅ Integración nativa con GitHub<br>✅ Secrets management<br>✅ GRATIS para repos públicos<br>✅ Runners en la nube |

---

## 🛠️ Herramientas

### Prerequisitos

```bash
# 1. Terraform
brew install terraform
terraform --version  # >= 1.6.0

# 2. AWS SAM CLI
brew install aws-sam-cli
sam --version  # >= 1.100.0

# 3. AWS CLI
brew install awscli
aws --version  # >= 2.0

# 4. Node.js
nvm install 20
node --version  # >= 20.x

# 5. jq (para scripts)
brew install jq
```

---

## 📁 Estructura del Proyecto

```
.
├── terraform/                    # 🔧 Infraestructura base
│   ├── main.tf                   # Configuración principal
│   ├── variables.tf              # Variables
│   ├── outputs.tf                # Outputs
│   ├── terraform.tfvars          # Valores por ambiente
│   └── modules/                  # Módulos reutilizables
│       ├── vpc/
│       ├── rds/
│       ├── dynamodb/
│       ├── sns/
│       ├── sqs/
│       ├── eventbridge/
│       └── security-groups/
│
├── sam/                          # ⚡ Lambda Functions
│   ├── template.yaml             # SAM template
│   └── samconfig.toml            # Configuración SAM
│
├── .github/
│   └── workflows/
│       ├── deploy.yml            # 🚀 Deploy pipeline
│       ├── pr-check.yml          # ✅ PR validation
│       └── destroy.yml           # 🗑️ Cleanup pipeline
│
├── docs/
│   ├── database-schema.sql       # Schema SQL
│   └── openapi.yaml              # API docs
│
├── src/                          # 💻 Código fuente
├── tests/                        # 🧪 Tests
└── dist/                         # 📦 Build output
```

---

## ⚙️ Configuración Inicial

### 1. Configurar GitHub Secrets

Ve a tu repositorio en GitHub:
**Settings → Secrets and variables → Actions → New repository secret**

#### Secrets Requeridos:

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID          = AKIA...
AWS_SECRET_ACCESS_KEY      = wJal...
AWS_REGION                 = us-east-1

# RDS Peru
RDS_PE_USERNAME            = admin
RDS_PE_PASSWORD            = [contraseña-segura-16-chars]
RDS_PE_HOST                = [se obtiene después del deploy terraform]
RDS_PE_DATABASE            = appointments_pe

# RDS Chile
RDS_CL_USERNAME            = admin
RDS_CL_PASSWORD            = [contraseña-segura-16-chars]
RDS_CL_HOST                = [se obtiene después del deploy terraform]
RDS_CL_DATABASE            = appointments_cl
```

#### Secrets por Environment (opcional):

GitHub permite secrets específicos por environment (dev, staging, prod):

**Settings → Environments → New environment**

### 2. Configurar Terraform Backend (Recomendado para Producción)

```bash
# Crear bucket S3 para state
aws s3 mb s3://agendamiento-citas-terraform-state --region us-east-1

# Crear tabla DynamoDB para lock
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Descomentar en terraform/main.tf:
# backend "s3" {
#   bucket         = "agendamiento-citas-terraform-state"
#   key            = "terraform.tfstate"
#   region         = "us-east-1"
#   dynamodb_table = "terraform-state-lock"
#   encrypt        = true
# }
```

### 3. Configurar AWS Credentials Localmente

```bash
aws configure
# AWS Access Key ID: [tu key]
# AWS Secret Access Key: [tu secret]
# Default region name: us-east-1
# Default output format: json
```

---

## 🚀 Despliegue

### Opción A: Deploy Automatizado (GitHub Actions) ⭐ RECOMENDADO

```bash
# 1. Hacer commit y push a develop (para dev/staging)
git add .
git commit -m "feat: initial infrastructure setup"
git push origin develop

# 2. GitHub Actions automáticamente:
#    ✅ Ejecuta tests
#    ✅ Build del código
#    ✅ Despliega Terraform
#    ✅ Despliega SAM
#    ✅ Inicializa databases
#    ✅ Ejecuta integration tests

# 3. Para producción, merge a main:
git checkout main
git merge develop
git push origin main
```

### Opción B: Deploy Manual (Local)

#### Paso 1: Desplegar Infraestructura (Terraform)

```bash
cd terraform

# Inicializar Terraform
terraform init

# Ver el plan
terraform plan \
  -var="environment=dev" \
  -var="rds_pe_master_username=admin" \
  -var="rds_pe_master_password=YourPassword123!" \
  -var="rds_cl_master_username=admin" \
  -var="rds_cl_master_password=YourPassword123!" \
  -out=tfplan

# Aplicar cambios
terraform apply tfplan

# Guardar outputs
terraform output -json > ../sam/infrastructure-outputs.json
```

#### Paso 2: Inicializar Databases

```bash
# Obtener endpoints
RDS_PE_HOST=$(terraform output -raw rds_peru_endpoint | cut -d':' -f1)
RDS_CL_HOST=$(terraform output -raw rds_chile_endpoint | cut -d':' -f1)

# Ejecutar schemas
mysql -h $RDS_PE_HOST -u admin -p appointments_pe < docs/database-schema.sql
mysql -h $RDS_CL_HOST -u admin -p appointments_cl < docs/database-schema.sql
```

#### Paso 3: Build del Código

```bash
cd ..
npm install
npm run build
```

#### Paso 4: Desplegar Lambdas (SAM)

```bash
cd sam

# Build
sam build

# Deploy
sam deploy \
  --stack-name agendamiento-citas-dev \
  --parameter-overrides \
    Environment=dev \
    VpcId=vpc-xxx \
    PrivateSubnetIds=subnet-xxx,subnet-yyy \
    LambdaSecurityGroupId=sg-xxx \
    DynamoDBTableName=appointments-dev \
    ... \
  --capabilities CAPABILITY_IAM \
  --resolve-s3

# Ver la URL del API
sam list stack-outputs --stack-name agendamiento-citas-dev
```

---

## 🔄 CI/CD con GitHub Actions

### Workflow Automático

```yaml
Trigger: Push to main/develop o Pull Request

Jobs:
  1. test-and-build
     ├─ Install dependencies
     ├─ Run linter
     ├─ Run unit tests (100% coverage)
     ├─ Build TypeScript
     └─ Upload artifacts
  
  2. deploy-terraform
     ├─ Setup Terraform
     ├─ Configure AWS credentials (from GitHub Secrets)
     ├─ Terraform plan
     ├─ Terraform apply (only on push to main/develop)
     └─ Export outputs
  
  3. deploy-sam
     ├─ Download build artifacts
     ├─ Setup SAM CLI
     ├─ SAM build
     ├─ SAM deploy (with Terraform outputs as parameters)
     └─ Export API URL
  
  4. init-databases
     ├─ Install MySQL client
     ├─ Get RDS credentials from Secrets Manager
     ├─ Execute database-schema.sql (Peru)
     └─ Execute database-schema.sql (Chile)
  
  5. integration-tests
     ├─ Test POST /appointments
     ├─ Test GET /appointments/{insuredId}
     └─ Verify responses
  
  6. notify
     └─ Send success/failure notification
```

### Branches Strategy

```
main (prod)
  ↑
  └── develop (staging)
        ↑
        └── feature/* (dev - PR only)
```

| Branch | Environment | Auto-Deploy | Approval |
|--------|-------------|-------------|----------|
| `feature/*` | - | ❌ No (PR check only) | - |
| `develop` | staging | ✅ Yes | No |
| `main` | prod | ✅ Yes | Recommended |

### Configurar Branch Protection

**Settings → Branches → Add rule**

Para `main`:
- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass before merging
  - test-and-build
  - deploy-terraform
  - deploy-sam
  - integration-tests
- ✅ Require branches to be up to date
- ✅ Require conversation resolution before merging

---

## 🧪 Testing Local

### Test Lambdas Localmente con SAM

```bash
# Iniciar API local
sam local start-api \
  --parameter-overrides \
    Environment=dev \
    VpcId=vpc-local \
    ... \
  --env-vars env.json

# Test en otra terminal
curl http://localhost:3000/appointments \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"insuredId": "12345", "scheduleId": 100, "countryISO": "PE"}'
```

### Invocar Lambda directamente

```bash
# Crear evento de test
cat > event.json << EOF
{
  "body": "{\"insuredId\":\"12345\",\"scheduleId\":100,\"countryISO\":\"PE\"}",
  "httpMethod": "POST",
  "path": "/appointments"
}
EOF

# Invocar
sam local invoke AppointmentFunction --event event.json
```

---

## 🔍 Monitoreo y Logs

### CloudWatch Logs

```bash
# Ver logs en tiempo real
sam logs \
  --stack-name agendamiento-citas-dev \
  --name AppointmentFunction \
  --tail

# Filtrar errores
sam logs \
  --stack-name agendamiento-citas-dev \
  --name AppointmentFunction \
  --filter "ERROR"
```

### X-Ray Tracing

Habilitado automáticamente en SAM template:
```yaml
Tracing: Active
```

Ver traces en:
**AWS Console → X-Ray → Service Map**

### CloudWatch Metrics

```bash
# Ver métricas de Lambda
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=dev-appointment-api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

---

## 🗑️ Cleanup / Destroy

### Eliminar Stack Completo

```bash
# 1. Eliminar SAM stack
sam delete --stack-name agendamiento-citas-dev --no-prompts

# 2. Eliminar Terraform
cd terraform
terraform destroy \
  -var="environment=dev" \
  -var="rds_pe_master_username=admin" \
  -var="rds_pe_master_password=YourPassword123!" \
  -var="rds_cl_master_username=admin" \
  -var="rds_cl_master_password=YourPassword123!"
```

### Via GitHub Actions

Trigger workflow `destroy.yml`:
```bash
gh workflow run destroy.yml -f environment=dev
```

---

## 🐛 Troubleshooting

### Error: "No module named 'sam'"
```bash
# Reinstalar SAM CLI
brew uninstall aws-sam-cli
brew install aws-sam-cli
```

### Error: "Terraform state lock"
```bash
# Forzar unlock (CUIDADO)
terraform force-unlock <LOCK_ID>
```

### Error: "Cannot connect to RDS"
```bash
# Verificar Security Group
terraform output lambda_security_group_id
aws ec2 describe-security-groups --group-ids <SG_ID>

# Verificar que Lambda está en VPC correcta
aws lambda get-function-configuration \
  --function-name dev-appointment-api
```

### Error en GitHub Actions: "AWS credentials not found"
```bash
# Verificar secrets en GitHub
gh secret list

# Agregar secret
gh secret set AWS_ACCESS_KEY_ID
```

---

## 📊 Costos Estimados

### Infraestructura (Terraform):
- **VPC**: GRATIS
- **RDS db.t3.micro (×2)**: $15/mes cada una = $30/mes
- **DynamoDB (bajo volumen)**: $1-2/mes
- **SNS/SQS**: <$1/mes
- **EventBridge**: <$1/mes
- **Secrets Manager**: $0.40/secret/mes = $0.80/mes

### Compute (SAM):
- **Lambda**: GRATIS (1M requests/mes en Free Tier)
- **API Gateway**: GRATIS (1M requests/mes en Free Tier)
- **CloudWatch Logs**: $0.50/GB

**TOTAL**: ~$35-40/mes (después de Free Tier)

---

## 🎯 Mejores Prácticas

### ✅ DO
- ✅ Usar Secrets Manager para credenciales
- ✅ Habilitar backup de RDS (7 días mínimo)
- ✅ Usar Multi-AZ en producción
- ✅ Implementar DLQs en SQS
- ✅ Habilitar X-Ray tracing
- ✅ Configurar CloudWatch Alarms
- ✅ Usar tags consistentes
- ✅ Versionar terraform state en S3
- ✅ Implementar Branch Protection

### ❌ DON'T
- ❌ No hardcodear credenciales
- ❌ No usar RDS público en producción
- ❌ No desplegar sin tests
- ❌ No ignorar Terraform plan
- ❌ No hacer `terraform destroy` en prod sin backup
- ❌ No usar `--force` sin entender el impacto

---

## 📚 Referencias

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [GitHub Actions for AWS](https://github.com/aws-actions)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

**🚀 ¡Tu infraestructura como código está lista para producción!**

