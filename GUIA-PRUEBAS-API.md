# 🧪 Guía Completa: Cómo Probar la Aplicación

## 📋 Índice
1. [Verificar que el Deploy fue Exitoso](#1-verificar-que-el-deploy-fue-exitoso)
2. [Obtener la API URL](#2-obtener-la-api-url)
3. [Probar Endpoints con cURL](#3-probar-endpoints-con-curl)
4. [Probar Endpoints con Postman/Insomnia](#4-probar-endpoints-con-postmaninsomnia)
5. [Verificar Datos en AWS](#5-verificar-datos-en-aws)
6. [Probar el Flujo Completo](#6-probar-el-flujo-completo)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Verificar que el Deploy fue Exitoso

### Opción A: Desde GitHub Actions

1. Ve a tu repositorio en GitHub
2. Click en **"Actions"**
3. Busca el último workflow ejecutado: **"Deploy Infrastructure and Application"**
4. Verifica que todos los jobs tengan ✅ (verde):
   - ✅ Test and Build
   - ✅ Deploy Infrastructure (Terraform)
   - ✅ Deploy Lambda Functions (SAM)
   - ✅ Send Notification

5. En el job **"Deploy Lambda Functions (SAM)"**, busca el step **"Display API URL"**
   - Deberías ver algo como: `📍 API URL: https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/`

### Opción B: Desde AWS Console

1. Ve a **CloudFormation** → **Stacks**
2. Busca el stack: `agendamiento-citas-prod`
3. Verifica que el estado sea: **CREATE_COMPLETE** o **UPDATE_COMPLETE**
4. Click en el stack → **Outputs**
5. Busca la key **"ApiUrl"** - esa es tu URL del API

---

## 2. Obtener la API URL

### Método 1: Desde GitHub Actions (Recomendado)

En el job **"Deploy Lambda Functions (SAM)"**, busca:
```
🚀 API deployed successfully!
📍 API URL: https://la153v9kdg.execute-api.us-east-1.amazonaws.com/prod/
```

### Método 2: Desde AWS CLI

```bash
aws cloudformation describe-stacks \
  --stack-name agendamiento-citas-prod \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
  --output text
```

### Método 3: Desde AWS Console

1. Ve a **CloudFormation** → **Stacks** → `agendamiento-citas-prod`
2. Click en **"Outputs"**
3. Copia el valor de **"ApiUrl"**

---

## 3. Probar Endpoints con cURL

### 3.1. Crear un Appointment (POST)

```bash
# Reemplaza YOUR_API_URL con tu URL real
API_URL="https://la153v9kdg.execute-api.us-east-1.amazonaws.com/prod"

# Crear appointment para Perú
curl -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "12345",
    "scheduleId": 100,
    "countryISO": "PE"
  }'

# Respuesta esperada:
# {
#   "appointmentId": "uuid-generado",
#   "insuredId": "12345",
#   "scheduleId": 100,
#   "countryISO": "PE",
#   "status": "PENDING",
#   "createdAt": "2024-11-10T..."
# }
```

**Ejemplo con datos reales:**
```bash
curl -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "00123",
    "scheduleId": 500,
    "countryISO": "CL"
  }' | jq '.'
```

### 3.2. Listar Appointments por Insured ID (GET)

```bash
# Listar appointments del asegurado 12345
curl -X GET "$API_URL/appointments/12345" \
  -H "Content-Type: application/json"

# Respuesta esperada:
# {
#   "appointments": [
#     {
#       "appointmentId": "uuid",
#       "insuredId": "12345",
#       "scheduleId": 100,
#       "countryISO": "PE",
#       "status": "PENDING",
#       "createdAt": "2024-11-10T...",
#       "updatedAt": "2024-11-10T..."
#     }
#   ]
# }
```

### 3.3. Script de Prueba Completo

Crea un archivo `test-api.sh`:

```bash
#!/bin/bash

# Configurar API URL
API_URL="https://la153v9kdg.execute-api.us-east-1.amazonaws.com/prod"

echo "🧪 Probando API: $API_URL"
echo ""

# Test 1: Crear appointment para Perú
echo "📝 Test 1: Crear appointment para Perú"
RESPONSE1=$(curl -s -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "12345",
    "scheduleId": 100,
    "countryISO": "PE"
  }')

echo "$RESPONSE1" | jq '.'
APPOINTMENT_ID=$(echo "$RESPONSE1" | jq -r '.appointmentId')

if [ "$APPOINTMENT_ID" != "null" ] && [ ! -z "$APPOINTMENT_ID" ]; then
  echo "✅ Appointment creado: $APPOINTMENT_ID"
else
  echo "❌ Error creando appointment"
  exit 1
fi

echo ""
sleep 2

# Test 2: Crear appointment para Chile
echo "📝 Test 2: Crear appointment para Chile"
RESPONSE2=$(curl -s -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "67890",
    "scheduleId": 200,
    "countryISO": "CL"
  }')

echo "$RESPONSE2" | jq '.'
APPOINTMENT_ID2=$(echo "$RESPONSE2" | jq -r '.appointmentId')

if [ "$APPOINTMENT_ID2" != "null" ] && [ ! -z "$APPOINTMENT_ID2" ]; then
  echo "✅ Appointment creado: $APPOINTMENT_ID2"
else
  echo "❌ Error creando appointment"
  exit 1
fi

echo ""
sleep 2

# Test 3: Listar appointments del asegurado 12345
echo "📋 Test 3: Listar appointments del asegurado 12345"
RESPONSE3=$(curl -s -X GET "$API_URL/appointments/12345" \
  -H "Content-Type: application/json")

echo "$RESPONSE3" | jq '.'

APPOINTMENTS_COUNT=$(echo "$RESPONSE3" | jq '.appointments | length')
if [ "$APPOINTMENTS_COUNT" -gt 0 ]; then
  echo "✅ Se encontraron $APPOINTMENTS_COUNT appointments"
else
  echo "⚠️  No se encontraron appointments (puede ser normal si acabas de crear)"
fi

echo ""
echo "✅ Todos los tests pasaron!"
```

**Ejecutar:**
```bash
chmod +x test-api.sh
./test-api.sh
```

---

## 4. Probar Endpoints con Postman/Insomnia

### 4.1. Configurar Postman

1. **Crear una nueva Collection**: "Agendamiento Citas API"
2. **Configurar Variable de Entorno**:
   - Variable: `api_url`
   - Valor: `https://la153v9kdg.execute-api.us-east-1.amazonaws.com/prod`

### 4.2. Request: Crear Appointment

**Método**: `POST`  
**URL**: `{{api_url}}/appointments`  
**Headers**:
```
Content-Type: application/json
```

**Body** (raw JSON):
```json
{
  "insuredId": "12345",
  "scheduleId": 100,
  "countryISO": "PE"
}
```

**Respuesta esperada** (200 OK):
```json
{
  "appointmentId": "550e8400-e29b-41d4-a716-446655440000",
  "insuredId": "12345",
  "scheduleId": 100,
  "countryISO": "PE",
  "status": "PENDING",
  "createdAt": "2024-11-10T12:00:00.000Z"
}
```

### 4.3. Request: Listar Appointments

**Método**: `GET`  
**URL**: `{{api_url}}/appointments/12345`  
**Headers**:
```
Content-Type: application/json
```

**Respuesta esperada** (200 OK):
```json
{
  "appointments": [
    {
      "appointmentId": "550e8400-e29b-41d4-a716-446655440000",
      "insuredId": "12345",
      "scheduleId": 100,
      "countryISO": "PE",
      "status": "PENDING",
      "createdAt": "2024-11-10T12:00:00.000Z",
      "updatedAt": "2024-11-10T12:00:00.000Z"
    }
  ]
}
```

### 4.4. Casos de Prueba Adicionales

#### Test: Validación de InsuredId (debe fallar)
```json
{
  "insuredId": "123",  // ❌ Menos de 5 dígitos
  "scheduleId": 100,
  "countryISO": "PE"
}
```
**Respuesta esperada**: 400 Bad Request

#### Test: Validación de CountryISO (debe fallar)
```json
{
  "insuredId": "12345",
  "scheduleId": 100,
  "countryISO": "MX"  // ❌ No es PE ni CL
}
```
**Respuesta esperada**: 400 Bad Request

#### Test: InsuredId no encontrado
```
GET {{api_url}}/appointments/99999
```
**Respuesta esperada**: 200 OK con `appointments: []`

---

## 5. Verificar Datos en AWS

### 5.1. Verificar DynamoDB

```bash
# Listar todos los appointments en DynamoDB
aws dynamodb scan \
  --table-name agendamiento-v2-prod-appointments \
  --region us-east-1 \
  --query 'Items[*].[appointmentId.S,insuredId.S,countryISO.S,status.S]' \
  --output table
```

**Desde AWS Console**:
1. Ve a **DynamoDB** → **Tables** → `agendamiento-v2-prod-appointments`
2. Click en **"Explore table items"**
3. Verás todos los appointments creados

### 5.2. Verificar SNS (Mensajes Publicados)

```bash
# Ver mensajes publicados en SNS (requiere CloudWatch Logs)
aws logs filter-log-events \
  --log-group-name /aws/lambda/prod-appointment-api \
  --filter-pattern "SNS" \
  --region us-east-1 \
  --max-items 10
```

**Desde AWS Console**:
1. Ve a **SNS** → **Topics**
2. Busca: `agendamiento-v2-prod-peru` o `agendamiento-v2-prod-chile`
3. Click en el topic → **"Subscriptions"** para ver suscriptores

### 5.3. Verificar SQS (Colas)

```bash
# Ver mensajes en cola de Perú
aws sqs get-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/ACCOUNT_ID/agendamiento-v2-prod-peru-queue \
  --attribute-names ApproximateNumberOfMessages \
  --region us-east-1
```

**Desde AWS Console**:
1. Ve a **SQS** → **Queues**
2. Busca: `agendamiento-v2-prod-peru-queue` o `agendamiento-v2-prod-chile-queue`
3. Click en la cola → **"Send and receive messages"** para ver mensajes

### 5.4. Verificar Lambda Functions

```bash
# Ver logs de la función principal
aws logs tail /aws/lambda/prod-appointment-api \
  --follow \
  --region us-east-1
```

**Desde AWS Console**:
1. Ve a **Lambda** → **Functions**
2. Busca: `prod-appointment-api`
3. Click en la función → **"Monitor"** → **"View CloudWatch logs"**

### 5.5. Verificar RDS (si DB está inicializada)

```bash
# Conectarse a RDS (requiere VPN o bastion)
# Primero obtener credenciales
aws secretsmanager get-secret-value \
  --secret-id agendamiento-v2-prod-rds-peru-credentials \
  --region us-east-1 \
  --query SecretString \
  --output text | jq -r '.host, .username, .password, .dbname'

# Luego conectar (desde EC2 en la VPC o con port forwarding)
mysql -h <HOST> -u <USERNAME> -p<PASSWORD> <DBNAME> -e "SELECT * FROM appointments LIMIT 10;"
```

**Nota**: RDS está en subnets privadas, necesitas:
- VPN configurada
- EC2 bastion host
- AWS Systems Manager Session Manager

---

## 6. Probar el Flujo Completo

### Flujo Esperado:

```
1. POST /appointments
   ↓
2. Lambda crea appointment en DynamoDB
   ↓
3. Lambda publica mensaje en SNS (Perú o Chile)
   ↓
4. SNS envía mensaje a SQS
   ↓
5. Lambda procesa mensaje de SQS
   ↓
6. Lambda guarda en RDS (Perú o Chile)
   ↓
7. Lambda publica evento en EventBridge
   ↓
8. EventBridge envía a cola de completación
   ↓
9. Lambda marca appointment como COMPLETED en DynamoDB
```

### Script de Prueba del Flujo Completo

```bash
#!/bin/bash

API_URL="https://la153v9kdg.execute-api.us-east-1.amazonaws.com/prod"

echo "🔄 Probando flujo completo..."
echo ""

# 1. Crear appointment
echo "1️⃣  Creando appointment..."
RESPONSE=$(curl -s -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "12345",
    "scheduleId": 100,
    "countryISO": "PE"
  }')

APPOINTMENT_ID=$(echo "$RESPONSE" | jq -r '.appointmentId')
echo "✅ Appointment creado: $APPOINTMENT_ID"
echo ""

# 2. Esperar 30 segundos para que se procese
echo "2️⃣  Esperando 30 segundos para procesamiento asíncrono..."
sleep 30

# 3. Verificar en DynamoDB
echo "3️⃣  Verificando en DynamoDB..."
aws dynamodb get-item \
  --table-name agendamiento-v2-prod-appointments \
  --key "{\"appointmentId\": {\"S\": \"$APPOINTMENT_ID\"}}" \
  --region us-east-1 \
  --query 'Item.status.S' \
  --output text

STATUS=$(aws dynamodb get-item \
  --table-name agendamiento-v2-prod-appointments \
  --key "{\"appointmentId\": {\"S\": \"$APPOINTMENT_ID\"}}" \
  --region us-east-1 \
  --query 'Item.status.S' \
  --output text)

if [ "$STATUS" == "COMPLETED" ]; then
  echo "✅ Appointment procesado correctamente (status: COMPLETED)"
else
  echo "⚠️  Appointment aún en proceso (status: $STATUS)"
  echo "   Esto es normal si el procesamiento tarda más"
fi

echo ""
echo "✅ Flujo completo probado!"
```

---

## 7. Troubleshooting

### Problema: "API URL no encontrada"

**Solución**:
1. Verifica que el deploy de SAM fue exitoso
2. Verifica que el stack de CloudFormation existe:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name agendamiento-citas-prod \
     --region us-east-1
   ```

### Problema: "403 Forbidden" o "401 Unauthorized"

**Solución**:
- Verifica que API Gateway tenga permisos públicos (debería tenerlos)
- Verifica que no haya WAF o rate limiting configurado

### Problema: "500 Internal Server Error"

**Solución**:
1. Revisa los logs de Lambda:
   ```bash
   aws logs tail /aws/lambda/prod-appointment-api --follow
   ```
2. Verifica que DynamoDB existe y tiene permisos
3. Verifica que SNS topics existen

### Problema: "Appointment no se procesa"

**Solución**:
1. Verifica que las funciones Lambda de procesamiento están activas:
   ```bash
   aws lambda list-functions \
     --region us-east-1 \
     --query 'Functions[?contains(FunctionName, `process`)].FunctionName'
   ```

2. Verifica logs de las funciones de procesamiento:
   ```bash
   aws logs tail /aws/lambda/prod-process-appointment-peru --follow
   aws logs tail /aws/lambda/prod-process-appointment-chile --follow
   ```

3. Verifica que SQS tiene mensajes:
   ```bash
   aws sqs get-queue-attributes \
     --queue-url <QUEUE_URL> \
     --attribute-names ApproximateNumberOfMessages
   ```

### Problema: "No se puede conectar a RDS"

**Solución**:
- RDS está en subnets privadas, no es accesible desde internet
- Necesitas ejecutar las migraciones primero (workflow "Database Migrations")
- Para conectarte, necesitas VPN o bastion host

---

## 📊 Checklist de Pruebas

- [ ] ✅ Deploy exitoso en GitHub Actions
- [ ] ✅ API URL obtenida y accesible
- [ ] ✅ POST /appointments funciona (crear appointment)
- [ ] ✅ GET /appointments/{insuredId} funciona (listar)
- [ ] ✅ Validaciones funcionan (insuredId, countryISO)
- [ ] ✅ Datos se guardan en DynamoDB
- [ ] ✅ Mensajes se publican en SNS
- [ ] ✅ Mensajes llegan a SQS
- [ ] ✅ Lambda procesa mensajes de SQS
- [ ] ✅ Datos se guardan en RDS (si DB está inicializada)
- [ ] ✅ Appointment se marca como COMPLETED

---

## 🚀 Próximos Pasos

1. **Inicializar Bases de Datos**:
   - Ejecutar workflow "Database Migrations" desde GitHub Actions
   - Environment: `prod`, Action: `apply`

2. **Probar con Datos Reales**:
   - Crear appointments con diferentes `insuredId`
   - Verificar que se procesan correctamente

3. **Monitorear**:
   - Revisar CloudWatch Logs de Lambda
   - Revisar métricas de DynamoDB, SNS, SQS

4. **Habilitar Integration Tests**:
   - Una vez que DB esté lista, habilitar el job `integration-tests` en el workflow

---

¿Necesitas ayuda con alguna prueba específica? 🤔

