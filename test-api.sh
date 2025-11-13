#!/bin/bash

# ============================================
# Script de Prueba para API de Agendamiento
# ============================================

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurar API URL
# Obtener desde CloudFormation si no está configurada
if [ -z "$API_URL" ]; then
  echo -e "${BLUE}🔍 Obteniendo API URL desde CloudFormation...${NC}"
  API_URL=$(aws cloudformation describe-stacks \
    --stack-name agendamiento-citas-prod \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
    --output text 2>/dev/null)
  
  if [ -z "$API_URL" ] || [ "$API_URL" == "None" ]; then
    echo -e "${RED}❌ No se pudo obtener API URL automáticamente${NC}"
    echo -e "${YELLOW}💡 Configura manualmente: export API_URL='https://xxxxx.execute-api.us-east-1.amazonaws.com/prod'${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✅ API URL: $API_URL${NC}"
echo ""

# Contador de tests
TESTS_PASSED=0
TESTS_FAILED=0

# Función para hacer test
test_endpoint() {
  local name=$1
  local method=$2
  local url=$3
  local data=$4
  local expected_field=$5
  
  echo -e "${BLUE}📝 Test: $name${NC}"
  
  if [ "$method" == "POST" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$url" \
      -H "Content-Type: application/json" \
      -d "$data")
  else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$url" \
      -H "Content-Type: application/json")
  fi
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
    if [ ! -z "$expected_field" ]; then
      VALUE=$(echo "$BODY" | jq -r ".$expected_field // empty" 2>/dev/null)
      if [ ! -z "$VALUE" ] && [ "$VALUE" != "null" ]; then
        echo -e "${GREEN}✅ Test pasado (HTTP $HTTP_CODE)${NC}"
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "$VALUE"  # Retornar valor para usar en siguientes tests
        return 0
      else
        echo -e "${RED}❌ Test falló: Campo '$expected_field' no encontrado${NC}"
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
      fi
    else
      echo -e "${GREEN}✅ Test pasado (HTTP $HTTP_CODE)${NC}"
      echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
      TESTS_PASSED=$((TESTS_PASSED + 1))
      return 0
    fi
  else
    echo -e "${RED}❌ Test falló (HTTP $HTTP_CODE)${NC}"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# ============================================
# Tests
# ============================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧪 Iniciando Tests de API${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test 1: Crear appointment para Perú
echo -e "${YELLOW}Test 1/5: Crear appointment para Perú${NC}"
APPOINTMENT_ID_PE=$(test_endpoint \
  "Crear appointment PE" \
  "POST" \
  "$API_URL/appointments" \
  '{"insuredId": "12345", "scheduleId": 100, "countryISO": "PE"}' \
  "appointmentId")

if [ $? -eq 0 ] && [ ! -z "$APPOINTMENT_ID_PE" ]; then
  echo -e "${GREEN}   Appointment ID: $APPOINTMENT_ID_PE${NC}"
fi
echo ""

# Test 2: Crear appointment para Chile
echo -e "${YELLOW}Test 2/5: Crear appointment para Chile${NC}"
APPOINTMENT_ID_CL=$(test_endpoint \
  "Crear appointment CL" \
  "POST" \
  "$API_URL/appointments" \
  '{"insuredId": "67890", "scheduleId": 200, "countryISO": "CL"}' \
  "appointmentId")

if [ $? -eq 0 ] && [ ! -z "$APPOINTMENT_ID_CL" ]; then
  echo -e "${GREEN}   Appointment ID: $APPOINTMENT_ID_CL${NC}"
fi
echo ""

# Test 3: Listar appointments del asegurado 12345
echo -e "${YELLOW}Test 3/5: Listar appointments del asegurado 12345${NC}"
test_endpoint \
  "Listar appointments" \
  "GET" \
  "$API_URL/appointments/12345" \
  "" \
  "appointments"
echo ""

# Test 4: Validación - InsuredId inválido (debe fallar)
echo -e "${YELLOW}Test 4/5: Validación - InsuredId inválido (debe fallar)${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{"insuredId": "123", "scheduleId": 100, "countryISO": "PE"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "400" ]; then
  echo -e "${GREEN}✅ Test pasado: Validación funcionó correctamente (HTTP 400)${NC}"
  echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}❌ Test falló: Debería retornar 400 (HTTP $HTTP_CODE)${NC}"
  echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Test 5: Validación - CountryISO inválido (debe fallar)
echo -e "${YELLOW}Test 5/5: Validación - CountryISO inválido (debe fallar)${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{"insuredId": "12345", "scheduleId": 100, "countryISO": "MX"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "400" ]; then
  echo -e "${GREEN}✅ Test pasado: Validación funcionó correctamente (HTTP 400)${NC}"
  echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}❌ Test falló: Debería retornar 400 (HTTP $HTTP_CODE)${NC}"
  echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# ============================================
# Resumen
# ============================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Resumen de Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Tests pasados: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests fallidos: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 ¡Todos los tests pasaron!${NC}"
  exit 0
else
  echo -e "${RED}⚠️  Algunos tests fallaron${NC}"
  exit 1
fi

