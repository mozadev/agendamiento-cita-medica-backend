# 🚀 Guía de Despliegue - Agendamiento Citas Médicas

## 📋 Prerequisitos

### 1. ✅ Herramientas Instaladas
```bash
# Verificar instalaciones
node --version        # >= 18.x
npm --version         # >= 9.x
aws --version         # AWS CLI v2
serverless --version  # >= 4.x
```

### 2. ✅ Cuenta AWS Configurada
```bash
# Verificar credenciales
aws sts get-caller-identity

# Si no está configurado:
aws configure
# AWS Access Key ID: [TU_ACCESS_KEY]
# AWS Secret Access Key: [TU_SECRET_KEY]
# Default region: us-east-1
# Default output: json
```

### 3. ✅ Permisos IAM Requeridos
Tu usuario/rol de AWS necesita permisos para:
- ✅ CloudFormation (crear/actualizar stacks)
- ✅ Lambda (crear/actualizar funciones)
- ✅ API Gateway (crear/actualizar APIs)
- ✅ DynamoDB (crear tablas)
- ✅ SNS (crear topics)
- ✅ SQS (crear queues)
- ✅ EventBridge (crear buses y reglas)
- ✅ IAM (crear roles para Lambda)
- ✅ CloudWatch Logs (crear log groups)
- ✅ S3 (subir código Lambda)

---

## 🗄️ PASO 1: Crear Bases de Datos RDS

### Opción A: Via AWS Console (Recomendado para inicio)

#### 1.1. RDS para PERÚ

1. Ve a **AWS Console → RDS → Create Database**
2. Configuración:
   - **Engine**: MySQL 8.0
   - **Template**: Free tier (para testing) o Production
   - **DB Instance Identifier**: `appointments-pe-db`
   - **Master username**: `admin`
   - **Master password**: [contraseña segura]
   - **DB instance class**: db.t3.micro (free tier) o db.t3.small
   - **Storage**: 20 GB
   - **VPC**: Default VPC
   - **Public access**: Yes (solo para desarrollo)
   - **Security group**: Crear nuevo o usar existente
   - **Database name**: `appointments_pe`

3. **Espera ~5-10 minutos** hasta que el estado sea "Available"

4. **Copia el Endpoint**: Ejemplo: `appointments-pe-db.abc123.us-east-1.rds.amazonaws.com`

#### 1.2. RDS para CHILE

Repite el proceso anterior con:
- **DB Instance Identifier**: `appointments-cl-db`
- **Database name**: `appointments_cl`

#### 1.3. Configurar Security Group

1. Ve a **RDS → appointments-pe-db → Connectivity & security**
2. Click en el Security Group
3. **Inbound rules** → Edit
4. Agrega regla:
   - **Type**: MySQL/Aurora
   - **Port**: 3306
   - **Source**: 
     - Para dev: `0.0.0.0/0` (⚠️ NO usar en producción)
     - Para prod: Solo el Security Group de Lambda

5. Repite para `appointments-cl-db`

#### 1.4. Inicializar Schemas

```bash
# Conectar a RDS Perú
mysql -h appointments-pe-db.abc123.us-east-1.rds.amazonaws.com \
      -u admin \
      -p \
      appointments_pe

# Ejecutar el schema
mysql> source docs/database-schema.sql;
mysql> exit;

# Conectar a RDS Chile
mysql -h appointments-cl-db.abc123.us-east-1.rds.amazonaws.com \
      -u admin \
      -p \
      appointments_cl

# Ejecutar el schema
mysql> source docs/database-schema.sql;
mysql> exit;
```

### Opción B: Via AWS CLI

```bash
# Crear RDS para Perú
aws rds create-db-instance \
  --db-instance-identifier appointments-pe-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0 \
  --master-username admin \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --db-name appointments_pe \
  --publicly-accessible \
  --region us-east-1

# Crear RDS para Chile
aws rds create-db-instance \
  --db-instance-identifier appointments-cl-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0 \
  --master-username admin \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --db-name appointments_cl \
  --publicly-accessible \
  --region us-east-1

# Verificar estado (esperar hasta "available")
aws rds describe-db-instances \
  --db-instance-identifier appointments-pe-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

---

## ⚙️ PASO 2: Configurar Variables de Entorno

### 2.1. Crear archivo .env

```bash
# Copiar el ejemplo
cp .env.example .env

# Editar con tus valores
nano .env  # o vim, code, etc.
```

### 2.2. Actualizar valores en .env

```bash
# Obtener endpoint de RDS Perú
aws rds describe-db-instances \
  --db-instance-identifier appointments-pe-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text

# Obtener endpoint de RDS Chile
aws rds describe-db-instances \
  --db-instance-identifier appointments-cl-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

Tu `.env` debe verse así:

```env
RDS_PE_HOST=appointments-pe-db.abc123.us-east-1.rds.amazonaws.com
RDS_PE_DATABASE=appointments_pe
RDS_PE_USER=admin
RDS_PE_PASSWORD=YourSecurePassword123!

RDS_CL_HOST=appointments-cl-db.def456.us-east-1.rds.amazonaws.com
RDS_CL_DATABASE=appointments_cl
RDS_CL_USER=admin
RDS_CL_PASSWORD=YourSecurePassword123!
```

---

## 📦 PASO 3: Instalar Dependencias (si no lo has hecho)

```bash
# Limpiar e instalar
rm -rf node_modules package-lock.json
npm install

# Verificar que todo compile
npm run build

# Verificar tests (opcional)
npm test
```

---

## 🚀 PASO 4: Desplegar a AWS

### 4.1. Despliegue en DEV

```bash
# Cargar variables de entorno
export $(cat .env | xargs)

# Desplegar
npm run deploy:dev

# O directamente con serverless
serverless deploy --stage dev --verbose
```

### 4.2. Lo que verás durante el despliegue

```
✔ Service deployed to stack agendamiento-cita-medica-dev (90s)

endpoints:
  POST - https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/appointments
  GET - https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/appointments/{insuredId}

functions:
  appointment: agendamiento-cita-medica-dev-appointment (5.2 MB)
  appointmentPE: agendamiento-cita-medica-dev-appointmentPE (5.2 MB)
  appointmentCL: agendamiento-cita-medica-dev-appointmentCL (5.2 MB)
  completeAppointment: agendamiento-cita-medica-dev-completeAppointment (5.2 MB)
```

**⚠️ GUARDA LA URL DEL API GATEWAY** - la necesitarás para probar

### 4.3. Despliegue en PRODUCCIÓN

```bash
# Usar variables de producción
cp .env.example .env.prod
# Editar .env.prod con credenciales de producción

# Cargar variables
export $(cat .env.prod | xargs)

# Desplegar
npm run deploy:prod

# O
serverless deploy --stage prod --verbose
```

---

## ✅ PASO 5: Verificar el Despliegue

### 5.1. Verificar Recursos Creados

```bash
# Verificar stack de CloudFormation
aws cloudformation describe-stacks \
  --stack-name agendamiento-cita-medica-dev \
  --query 'Stacks[0].StackStatus'

# Listar funciones Lambda
aws lambda list-functions \
  --query 'Functions[?starts_with(FunctionName, `agendamiento-cita-medica-dev`)].FunctionName'

# Verificar tabla DynamoDB
aws dynamodb describe-table \
  --table-name appointments-dev

# Verificar SNS Topic
aws sns list-topics \
  --query 'Topics[?contains(TopicArn, `appointments`)]'

# Verificar SQS Queues
aws sqs list-queues \
  --queue-name-prefix appointments
```

### 5.2. Verificar Logs

```bash
# Logs de la lambda principal
serverless logs -f appointment --stage dev --tail

# Logs de lambda PE
serverless logs -f appointmentPE --stage dev --tail

# O via AWS CLI
aws logs tail /aws/lambda/agendamiento-cita-medica-dev-appointment --follow
```

---

## 🧪 PASO 6: Probar el API

### 6.1. Obtener la URL del API

```bash
# Via Serverless
serverless info --stage dev

# O via AWS CLI
aws cloudformation describe-stacks \
  --stack-name agendamiento-cita-medica-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceEndpoint`].OutputValue' \
  --output text
```

### 6.2. Crear un Agendamiento (POST)

```bash
# Guardar URL en variable
API_URL="https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev"

# Crear agendamiento para Perú
curl -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "12345",
    "scheduleId": 100,
    "countryISO": "PE"
  }' | jq

# Respuesta esperada:
# {
#   "appointmentId": "APT-xxxxx",
#   "status": "pending",
#   "message": "El agendamiento está en proceso"
# }
```

### 6.3. Listar Agendamientos (GET)

```bash
# Listar agendamientos del asegurado
curl -X GET "$API_URL/appointments/12345" | jq

# Respuesta esperada:
# {
#   "appointments": [
#     {
#       "appointmentId": "APT-xxxxx",
#       "insuredId": "12345",
#       "scheduleId": 100,
#       "countryISO": "PE",
#       "status": "pending",
#       "createdAt": "2024-01-01T00:00:00.000Z",
#       ...
#     }
#   ],
#   "total": 1,
#   "insuredId": "12345"
# }
```

### 6.4. Verificar Procesamiento Completo

```bash
# Esperar ~5-10 segundos para que se procese
sleep 10

# Verificar en DynamoDB
aws dynamodb get-item \
  --table-name appointments-dev \
  --key '{"appointmentId": {"S": "APT-xxxxx"}}'

# Verificar en RDS Perú
mysql -h $RDS_PE_HOST -u admin -p appointments_pe \
  -e "SELECT * FROM appointments WHERE appointment_id = 'APT-xxxxx';"
```

---

## 📊 PASO 7: Monitoreo

### 7.1. CloudWatch Metrics

```bash
# Ver métricas de Lambda
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=agendamiento-cita-medica-dev-appointment \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### 7.2. CloudWatch Logs Insights

```
# Query de ejemplo para buscar errores
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```

### 7.3. X-Ray (si está habilitado)

Agregar en `serverless.yml`:

```yaml
provider:
  tracing:
    lambda: true
    apiGateway: true
```

---

## 🔄 PASO 8: Actualizar el Despliegue

```bash
# Hacer cambios en el código
# ...

# Recompilar
npm run build

# Re-desplegar
npm run deploy:dev

# O desplegar solo una función
serverless deploy function -f appointment --stage dev
```

---

## 🗑️ PASO 9: Eliminar el Stack (Cleanup)

```bash
# Eliminar todos los recursos de AWS
serverless remove --stage dev

# O via AWS CLI
aws cloudformation delete-stack \
  --stack-name agendamiento-cita-medica-dev

# ⚠️ IMPORTANTE: Eliminar RDS manualmente
aws rds delete-db-instance \
  --db-instance-identifier appointments-pe-db \
  --skip-final-snapshot

aws rds delete-db-instance \
  --db-instance-identifier appointments-cl-db \
  --skip-final-snapshot
```

---

## 🐛 Troubleshooting

### Error: "Unable to import module"
```bash
# Verificar que las dependencias estén en el bundle
npm install
npm run build
serverless deploy --stage dev
```

### Error: "Cannot connect to RDS"
```bash
# Verificar Security Group
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx

# Verificar que Lambda tenga acceso a VPC (si RDS no es público)
# Agregar en serverless.yml:
provider:
  vpc:
    securityGroupIds:
      - sg-xxxxx
    subnetIds:
      - subnet-xxxxx
      - subnet-yyyyy
```

### Error: "AccessDenied" en IAM
```bash
# Verificar permisos
aws iam get-user
aws iam list-attached-user-policies --user-name your-username
```

### Logs de errores
```bash
# Ver logs en tiempo real
serverless logs -f appointment --stage dev --tail --filter "ERROR"
```

---

## 📚 Recursos Adicionales

- **Documentación Serverless**: https://www.serverless.com/framework/docs
- **AWS Lambda**: https://docs.aws.amazon.com/lambda/
- **API Gateway**: https://docs.aws.amazon.com/apigateway/
- **DynamoDB**: https://docs.aws.amazon.com/dynamodb/
- **RDS MySQL**: https://docs.aws.amazon.com/rds/

---

## 🎯 Checklist de Despliegue

- [ ] AWS CLI configurado con credenciales válidas
- [ ] Node.js y npm instalados (>= 18.x)
- [ ] Serverless Framework instalado (>= 4.x)
- [ ] RDS MySQL para Perú creado y disponible
- [ ] RDS MySQL para Chile creado y disponible
- [ ] Schemas SQL ejecutados en ambas bases de datos
- [ ] Security Groups configurados para permitir acceso
- [ ] Archivo `.env` creado con endpoints de RDS
- [ ] Dependencias instaladas (`npm install`)
- [ ] Tests pasando (`npm test`)
- [ ] Código compilado (`npm run build`)
- [ ] Despliegue ejecutado (`npm run deploy:dev`)
- [ ] API Gateway URL guardada
- [ ] Tests de integración ejecutados (POST y GET)
- [ ] Logs verificados sin errores
- [ ] Documentación actualizada

---

## 💰 Estimación de Costos AWS (Monthly)

### Tier Gratuito (Free Tier - 12 meses):
- **Lambda**: 1M requests/mes + 400,000 GB-segundos GRATIS
- **DynamoDB**: 25 GB storage + 25 WCU/RCU GRATIS
- **API Gateway**: 1M requests/mes GRATIS
- **RDS db.t3.micro**: 750 horas/mes GRATIS

### Después del Free Tier (aprox):
- **Lambda**: ~$0.20/millón de invocaciones
- **DynamoDB**: ~$1.25/mes (25 GB)
- **API Gateway**: ~$3.50/millón requests
- **RDS db.t3.micro**: ~$15/mes por instancia
- **Total estimado**: ~$35-40/mes (uso moderado)

### Para minimizar costos:
1. Usa RDS solo cuando necesites
2. Configura auto-scaling en DynamoDB
3. Implementa caching en API Gateway
4. Usa Reserved Instances para RDS en producción

---

**¡Listo! Tu aplicación estará desplegada y funcionando en AWS** 🚀

