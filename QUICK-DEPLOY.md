# ⚡ Guía Rápida de Despliegue

## 🎯 Lo que necesitas ANTES de desplegar:

### 1. ✅ RDS MySQL (2 instancias)
- Una para Perú
- Una para Chile

### 2. ✅ Variables de entorno configuradas
- Endpoints de RDS
- Credenciales de bases de datos

### 3. ✅ AWS CLI configurado
- Credenciales válidas
- Región: us-east-1

---

## 🚀 Pasos Rápidos (5 pasos)

### **PASO 1:** Configurar AWS
```bash
# Verificar
aws sts get-caller-identity

# Si no configurado:
aws configure
```

### **PASO 2:** Crear RDS (elegir opción)

#### Opción A: Script Automático ⚡
```bash
# Ejecutar script
./scripts/create-rds.sh

# Esperar 5-10 minutos
```

#### Opción B: Manual (AWS Console)
1. AWS Console → RDS → Create Database
2. MySQL 8.0, db.t3.micro
3. DB Identifier: `appointments-pe-db`
4. Database name: `appointments_pe`
5. Repetir para Chile (`appointments-cl-db`)

### **PASO 3:** Configurar Variables
```bash
# Copiar plantilla
cp env.example .env

# Editar con tus endpoints RDS
nano .env

# Debe verse así:
RDS_PE_HOST=appointments-pe-db.abc.us-east-1.rds.amazonaws.com
RDS_PE_DATABASE=appointments_pe
RDS_PE_USER=admin
RDS_PE_PASSWORD=TuPassword123!

RDS_CL_HOST=appointments-cl-db.def.us-east-1.rds.amazonaws.com
RDS_CL_DATABASE=appointments_cl
RDS_CL_USER=admin
RDS_CL_PASSWORD=TuPassword123!
```

### **PASO 4:** Inicializar Schemas

#### Opción A: Script Automático ⚡
```bash
./scripts/init-database.sh
```

#### Opción B: Manual
```bash
# Conectar a cada RDS y ejecutar
mysql -h <RDS_HOST> -u admin -p appointments_pe < docs/database-schema.sql
mysql -h <RDS_HOST> -u admin -p appointments_cl < docs/database-schema.sql
```

### **PASO 5:** Desplegar 🚀
```bash
# Cargar variables
export $(cat .env | xargs)

# Desplegar
npm run deploy:dev
```

---

## ✅ Verificación

```bash
# Guardar URL del API
API_URL="https://abc123.execute-api.us-east-1.amazonaws.com/dev"

# Test 1: Crear agendamiento
curl -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{"insuredId": "12345", "scheduleId": 100, "countryISO": "PE"}'

# Test 2: Listar agendamientos
curl "$API_URL/appointments/12345"
```

---

## ⚠️ Troubleshooting Rápido

### "Cannot connect to RDS"
```bash
# 1. Verificar Security Group
# AWS Console → RDS → Security → Inbound Rules
# Debe permitir MySQL (3306) desde 0.0.0.0/0 o tu IP

# 2. Verificar estado RDS
aws rds describe-db-instances \
  --db-instance-identifier appointments-pe-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

### "AccessDenied" en despliegue
```bash
# Verificar permisos IAM
aws iam get-user
# Tu usuario necesita permisos de:
# CloudFormation, Lambda, API Gateway, DynamoDB, SNS, SQS, EventBridge, IAM
```

### "Module not found" en Lambda
```bash
# Reinstalar y redesplegar
rm -rf node_modules package-lock.json
npm install
npm run build
npm run deploy:dev
```

---

## 💰 Costos Estimados

**Free Tier (primer año):**
- Lambda: GRATIS (1M requests/mes)
- DynamoDB: GRATIS (25 GB)
- API Gateway: GRATIS (1M requests/mes)
- RDS db.t3.micro: GRATIS (750 horas/mes)

**Después:**
- ~$35-40/mes (uso moderado)
- RDS = $15/instancia (~$30/mes)
- Resto = $5-10/mes

---

## 🗑️ Eliminar Todo (Cleanup)

```bash
# Eliminar stack de AWS
serverless remove --stage dev

# Eliminar RDS
aws rds delete-db-instance \
  --db-instance-identifier appointments-pe-db \
  --skip-final-snapshot

aws rds delete-db-instance \
  --db-instance-identifier appointments-cl-db \
  --skip-final-snapshot
```

---

## 📚 Más Información

Ver **DEPLOYMENT.md** para guía detallada con:
- Monitoreo y logs
- Configuración de producción
- Security best practices
- Troubleshooting avanzado

---

**¡Listo en 10 minutos!** ⚡

