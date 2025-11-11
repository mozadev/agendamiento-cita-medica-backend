# 🚀 Flujo Completo de Deployment

## 📋 Resumen Ejecutivo

**NO**, hacer `git push` **NO crea automáticamente** los servicios AWS. Necesitas configurar **GitHub Secrets** primero.

---

## 🔄 Flujo Completo Paso a Paso

### **FASE 1: Preparación (ANTES del Push)**

#### 1.1 Configurar GitHub Secrets

Antes de hacer push, debes configurar estos secrets en GitHub:

**En GitHub:**
```
Settings → Secrets and variables → Actions → New repository secret
```

**Secrets Requeridos:**

```bash
# AWS Credentials (del IAM user que creaste)
AWS_ACCESS_KEY_ID          → Tu Access Key ID
AWS_SECRET_ACCESS_KEY      → Tu Secret Access Key

# RDS Perú
RDS_PE_USERNAME            → Usuario MySQL para Perú
RDS_PE_PASSWORD            → Password MySQL para Perú
RDS_PE_HOST                → Se obtiene después del deploy de Terraform
RDS_PE_DATABASE            → Nombre de la base de datos (ej: appointments_pe)

# RDS Chile
RDS_CL_USERNAME            → Usuario MySQL para Chile
RDS_CL_PASSWORD            → Password MySQL para Chile
RDS_CL_HOST                → Se obtiene después del deploy de Terraform
RDS_CL_DATABASE            → Nombre de la base de datos (ej: appointments_cl)
```

**⚠️ IMPORTANTE:** 
- `RDS_PE_HOST` y `RDS_CL_HOST` se obtienen **DESPUÉS** del primer deploy de Terraform
- Para el primer deploy, puedes usar valores temporales o dejar que falle el job de inicialización

---

### **FASE 2: Push al Repositorio**

```bash
git push origin main
```

**¿Qué pasa cuando haces push?**

1. ✅ GitHub recibe el código
2. ✅ Detecta el workflow en `.github/workflows/deploy.yml`
3. ✅ **INICIA el pipeline automáticamente**

---

### **FASE 3: Pipeline CI/CD (Automático)**

El pipeline ejecuta **5 jobs en secuencia**:

#### **Job 1: Test and Build** ✅
```yaml
- Instala Node.js 20
- Ejecuta: npm ci
- Ejecuta: npm test (tests unitarios)
- Ejecuta: npm run build (compila TypeScript)
- Guarda artifacts en: dist/
```

**Resultado:** Código compilado y validado

---

#### **Job 2: Deploy Infrastructure (Terraform)** 🏗️

**Este es el PRIMER paso que crea recursos AWS:**

```yaml
1. Setup Terraform 1.6.0
2. Configura AWS credentials (desde GitHub Secrets)
3. Determina environment:
   - main → prod
   - develop → staging
   - otros → dev
4. terraform init
5. terraform validate
6. terraform plan
7. terraform apply -auto-approve
```

**Recursos AWS que crea Terraform:**

✅ **VPC** (Virtual Private Cloud)
   - Public Subnets
   - Private Subnets
   - Internet Gateway
   - NAT Gateway
   - Route Tables

✅ **RDS MySQL** (2 instancias)
   - `appointments-rds-pe` (Perú)
   - `appointments-rds-cl` (Chile)
   - En Private Subnets
   - Security Groups configurados

✅ **DynamoDB**
   - `appointments-table-{env}`

✅ **SNS Topics**
   - `appointments-peru-{env}`
   - `appointments-chile-{env}`

✅ **SQS Queues**
   - `appointments-peru-queue-{env}`
   - `appointments-chile-queue-{env}`

✅ **EventBridge Rules**
   - Reglas para procesar eventos

✅ **IAM Roles y Policies**
   - Permisos para Lambda
   - Permisos para acceder a DynamoDB, SNS, RDS, etc.

**Outputs de Terraform:**
- `vpc_id`
- `private_subnet_ids`
- `lambda_security_group_id`
- `dynamodb_table_name`
- `sns_topic_arn_peru`
- `sns_topic_arn_chile`

**⚠️ IMPORTANTE:** 
- Este job tarda **15-20 minutos** (RDS tarda mucho en crearse)
- Si falla, **NO se crean recursos** (rollback automático)

---

#### **Job 3: Deploy Lambda Functions (SAM)** ⚡

**Este es el SEGUNDO paso que crea recursos AWS:**

```yaml
1. Setup AWS SAM
2. Configura AWS credentials
3. Descarga artifacts del Job 1
4. sam build (compila Lambdas)
5. sam deploy (despliega a AWS)
```

**Recursos AWS que crea SAM:**

✅ **Lambda Functions** (3 funciones)
   - `AppointmentHandler` (crear/listar citas)
   - `ProcessPeruAppointmentHandler`
   - `ProcessChileAppointmentHandler`

✅ **API Gateway**
   - REST API
   - Endpoints:
     - `POST /appointments`
     - `GET /appointments/{insuredId}`

✅ **IAM Roles para Lambda**
   - Permisos específicos por función

✅ **CloudWatch Logs**
   - Log groups para cada Lambda

**Parámetros que pasa SAM (desde Terraform outputs):**
- `VpcId`
- `PrivateSubnetIds`
- `LambdaSecurityGroupId`
- `DynamoDBTableName`
- `SNSTopicArnPeru`
- `SNSTopicArnChile`

**Output:**
- `ApiUrl` → URL del API Gateway (ej: `https://abc123.execute-api.us-east-1.amazonaws.com`)

---

#### **Job 4: Initialize RDS Databases** 🗄️

**Solo se ejecuta en `main` o `develop` (no en PRs):**

```yaml
1. Instala MySQL Client
2. Ejecuta: docs/database-schema.sql en RDS Perú
3. Ejecuta: docs/database-schema.sql en RDS Chile
```

**⚠️ IMPORTANTE:**
- Este job necesita los secrets `RDS_PE_HOST` y `RDS_CL_HOST`
- Estos se obtienen **DESPUÉS** del Job 2 (Terraform)
- Para el primer deploy, puedes:
  1. Dejar que falle este job
  2. Obtener los hosts de Terraform outputs
  3. Agregar los secrets
  4. Re-ejecutar este job manualmente

---

#### **Job 5: Integration Tests** 🧪

```yaml
1. Test: POST /appointments
   - Crea una cita
   - Verifica que retorna appointmentId

2. Test: GET /appointments/{insuredId}
   - Lista citas
   - Verifica que retorna array de appointments
```

**Si los tests pasan:** ✅ Deployment exitoso
**Si los tests fallan:** ❌ Deployment marcado como fallido

---

## 📊 Diagrama de Flujo

```
┌─────────────────┐
│  git push main  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  GitHub Actions Trigger │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Job 1: Test & Build    │
│  - npm test             │
│  - npm run build        │
│  - Guarda dist/         │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Job 2: Terraform       │
│  - terraform init       │
│  - terraform plan       │
│  - terraform apply      │
│                         │
│  Crea:                  │
│  ✅ VPC                 │
│  ✅ RDS (2 instancias)  │
│  ✅ DynamoDB            │
│  ✅ SNS Topics          │
│  ✅ SQS Queues          │
│  ✅ EventBridge         │
│  ✅ IAM Roles           │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Job 3: SAM Deploy      │
│  - sam build            │
│  - sam deploy           │
│                         │
│  Crea:                  │
│  ✅ Lambda Functions    │
│  ✅ API Gateway         │
│  ✅ CloudWatch Logs     │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Job 4: Init Databases  │
│  - Ejecuta SQL schema   │
│  - En RDS Perú          │
│  - En RDS Chile         │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Job 5: Integration Test│
│  - Test POST /appoints  │
│  - Test GET /appoints   │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  ✅ Deployment Success  │
│  📍 API URL disponible  │
└─────────────────────────┘
```

---

## ⚠️ Lo que FALTA antes del Primer Push

### 1. **GitHub Secrets** (OBLIGATORIO)

Sin estos secrets, el pipeline **FALLARÁ**:

```bash
# Mínimo necesario para que funcione:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
RDS_PE_USERNAME
RDS_PE_PASSWORD
RDS_CL_USERNAME
RDS_CL_PASSWORD
```

**Opcionales (se pueden agregar después):**
- `RDS_PE_HOST` → Se obtiene después del deploy de Terraform
- `RDS_CL_HOST` → Se obtiene después del deploy de Terraform
- `RDS_PE_DATABASE` → Default: `appointments_pe`
- `RDS_CL_DATABASE` → Default: `appointments_cl`

---

### 2. **Terraform Backend (OPCIONAL pero RECOMENDADO)**

Actualmente Terraform guarda el state **localmente** en GitHub Actions.

**Para producción, descomenta en `terraform/main.tf`:**

```hcl
backend "s3" {
  bucket         = "agendamiento-citas-terraform-state"
  key            = "terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

**Y crear:**
- S3 bucket para el state
- DynamoDB table para el lock

---

### 3. **Variables de Terraform**

El workflow usa estas variables (desde secrets o defaults):

```hcl
environment              → dev/staging/prod (automático)
rds_pe_master_username   → Desde secret
rds_pe_master_password   → Desde secret
rds_cl_master_username   → Desde secret
rds_cl_master_password → Desde secret
```

---

## 🚀 Pasos para el Primer Deploy

### **Paso 1: Configurar GitHub Secrets**

```bash
# 1. Ve a tu repositorio en GitHub
# 2. Settings → Secrets and variables → Actions
# 3. New repository secret
# 4. Agrega cada uno de los secrets listados arriba
```

### **Paso 2: Push al Repositorio**

```bash
git push origin main
```

### **Paso 3: Monitorear el Pipeline**

```bash
# En GitHub:
# Actions → Ver el workflow ejecutándose
# Ver logs de cada job
```

### **Paso 4: Obtener Outputs de Terraform**

Después de que el Job 2 termine:

```bash
# En GitHub Actions, en el job "Deploy Infrastructure (Terraform)"
# Busca en los logs:
# - RDS endpoint (para RDS_PE_HOST y RDS_CL_HOST)
# - DynamoDB table name
# - SNS topic ARNs
```

### **Paso 5: Agregar Secrets Faltantes**

```bash
# Agrega a GitHub Secrets:
RDS_PE_HOST → Endpoint de RDS Perú
RDS_CL_HOST → Endpoint de RDS Chile
```

### **Paso 6: Re-ejecutar Job de Inicialización (si falló)**

```bash
# En GitHub Actions:
# - Ve al workflow
# - Click en "Initialize RDS Databases"
# - Re-run job
```

---

## 📊 Tiempos Estimados

| Job | Tiempo Estimado | Notas |
|-----|----------------|-------|
| Test & Build | 2-3 min | Rápido |
| Terraform Deploy | 15-20 min | RDS tarda mucho |
| SAM Deploy | 3-5 min | Rápido |
| Init Databases | 1-2 min | Rápido |
| Integration Tests | 30 seg | Muy rápido |
| **TOTAL** | **~25-30 min** | Primera vez |

**Deployments subsecuentes:** ~10-15 min (sin crear RDS)

---

## ✅ Checklist Pre-Deploy

- [ ] GitHub Secrets configurados (mínimo AWS credentials y RDS passwords)
- [ ] IAM User creado con permisos adecuados
- [ ] AWS CLI configurado localmente (para verificar)
- [ ] Código commiteado y pusheado
- [ ] Pipeline configurado en `.github/workflows/deploy.yml`

---

## 🔍 Troubleshooting

### **Error: "AWS credentials not found"**
→ Verifica que `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` estén en GitHub Secrets

### **Error: "Terraform plan failed"**
→ Verifica que los secrets de RDS estén configurados

### **Error: "RDS host not found"**
→ Normal en el primer deploy. Obtén el host de Terraform outputs y agrégalo a secrets

### **Error: "SAM deploy failed"**
→ Verifica que el Job 2 (Terraform) haya terminado exitosamente

### **Error: "Integration tests failed"**
→ Verifica que el API Gateway esté desplegado y accesible

---

## 🎯 Resumen

**NO**, hacer push **NO crea servicios automáticamente** sin configuración previa.

**SÍ**, hacer push **SÍ inicia el pipeline** que crea los servicios, **PERO**:
1. Necesitas configurar GitHub Secrets primero
2. El pipeline tarda ~25-30 minutos
3. Los recursos se crean en orden: Terraform → SAM → Init DBs → Tests

**Flujo:**
```
Push → GitHub Actions → Terraform (crea infra) → SAM (crea Lambdas) → Init DBs → Tests → ✅
```

---

✨ **¡Listo para deploy!** Solo falta configurar los GitHub Secrets y hacer push.

