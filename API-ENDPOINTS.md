# 🌐 API Endpoints - Agendamiento Citas Médicas

## Base URL

```
https://[API_ID].execute-api.us-east-1.amazonaws.com/[STAGE]/
```

**Ejemplo:**
```
https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/
```

---

## Endpoints Disponibles

### 1. Crear Agendamiento

**POST** `/appointments`

**Request:**
```json
{
  "insuredId": "12345",
  "scheduleId": 100,
  "countryISO": "PE"
}
```

**Response:**
```json
{
  "appointmentId": "APT-xxxxx",
  "status": "pending",
  "message": "El agendamiento está en proceso"
}
```

**cURL:**
```bash
curl -X POST "https://[API_URL]/appointments" \
  -H "Content-Type: application/json" \
  -d '{
    "insuredId": "12345",
    "scheduleId": 100,
    "countryISO": "PE"
  }'
```

---

### 2. Listar Agendamientos por Asegurado

**GET** `/appointments/{insuredId}`

**Response:**
```json
{
  "appointments": [
    {
      "appointmentId": "APT-xxxxx",
      "insuredId": "12345",
      "scheduleId": 100,
      "countryISO": "PE",
      "status": "pending",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "total": 1,
  "insuredId": "12345"
}
```

**cURL:**
```bash
curl "https://[API_URL]/appointments/12345"
```

---

## Ambientes

| Ambiente | URL Base | Estado |
|----------|----------|--------|
| **Dev** | `https://[API_ID].execute-api.us-east-1.amazonaws.com/dev/` | ✅ Activo |
| **Staging** | `https://[API_ID].execute-api.us-east-1.amazonaws.com/staging/` | 🔄 Pendiente |
| **Prod** | `https://[API_ID].execute-api.us-east-1.amazonaws.com/prod/` | 🔄 Pendiente |

---

## Documentación Completa

Ver: `docs/openapi.yaml` (Swagger/OpenAPI 3.0)

---

## Testing

### Postman Collection

Importar desde: `docs/postman-collection.json` (si existe)

### Ejemplos de Prueba

```bash
# 1. Crear agendamiento para Perú
curl -X POST "https://[API_URL]/appointments" \
  -H "Content-Type: application/json" \
  -d '{"insuredId": "12345", "scheduleId": 100, "countryISO": "PE"}'

# 2. Crear agendamiento para Chile
curl -X POST "https://[API_URL]/appointments" \
  -H "Content-Type: application/json" \
  -d '{"insuredId": "67890", "scheduleId": 200, "countryISO": "CL"}'

# 3. Listar agendamientos
curl "https://[API_URL]/appointments/12345"
```

---

## Códigos de Estado HTTP

| Código | Significado |
|--------|-------------|
| `200` | ✅ Éxito |
| `201` | ✅ Creado |
| `400` | ❌ Bad Request (validación fallida) |
| `404` | ❌ Not Found |
| `500` | ❌ Error interno del servidor |

---

## Notas

- ✅ API RESTful
- ✅ CORS habilitado
- ✅ X-Ray tracing activado
- ✅ Logs en CloudWatch
- ✅ Rate limiting: 10,000 requests/segundo (default AWS)

---

**Última actualización:** Ver commits en GitHub

