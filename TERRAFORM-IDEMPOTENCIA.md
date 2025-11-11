# 🔄 Cómo Funciona Terraform en Cada Deploy

## ❓ Tu Pregunta

> "Cada vez que hago push se crean todos los servicios, osea si mas adelante hago un cambio en el codigo tambien se eliminaran y se crearan todos los recursos o solo es por esta vez que no esta funcionando todo junto?"

## ✅ Respuesta Corta

**NO, Terraform NO recrea todos los recursos en cada push.** Solo crea/actualiza/elimina lo que **cambió**.

---

## 🎯 Cómo Funciona Terraform (Idempotencia)

### **Principio de Idempotencia**

Terraform es **idempotente**: puedes ejecutarlo múltiples veces y solo hará cambios cuando sea necesario.

### **En Cada Push:**

1. **Terraform Plan** analiza:
   - Estado actual en AWS
   - Estado deseado (tu código)
   - **Diferencia entre ambos**

2. **Terraform Apply** solo ejecuta:
   - ✅ **Crear** recursos que no existen
   - ✅ **Actualizar** recursos que cambiaron
   - ✅ **Eliminar** recursos que ya no están en el código
   - ❌ **NO toca** recursos que no cambiaron

---

## 📊 Ejemplos Prácticos

### **Escenario 1: Cambio en Código de Lambda**

```typescript
// Cambias una línea en handler.ts
export const handler = async (event) => {
  // Código modificado
}
```

**¿Qué pasa en el deploy?**
- ✅ Solo se actualiza el código de Lambda (upload nuevo ZIP)
- ✅ **NO se recrea** VPC, RDS, DynamoDB, etc.
- ✅ **NO se elimina** nada
- ⏱️ Deploy tarda **~2-3 minutos** (solo Lambda)

---

### **Escenario 2: Agregar Nueva Variable de Entorno**

```hcl
# terraform/main.tf
resource "aws_lambda_function" "appointment" {
  environment {
    variables = {
      NEW_VAR = "value"  # ← Nueva variable
    }
  }
}
```

**¿Qué pasa en el deploy?**
- ✅ Solo se actualiza la configuración de Lambda
- ✅ **NO se recrea** la función
- ✅ **NO se recrea** ningún otro recurso
- ⏱️ Deploy tarda **~1 minuto**

---

### **Escenario 3: Cambiar Tamaño de RDS**

```hcl
# terraform/main.tf
resource "aws_db_instance" "peru" {
  instance_class = "db.t3.small"  # Cambió de db.t3.micro
}
```

**¿Qué pasa en el deploy?**
- ✅ Solo se modifica la instancia RDS (puede tardar 10-15 min)
- ✅ **NO se recrea** (solo cambia el tamaño)
- ✅ **NO se pierden datos**
- ✅ **NO se recrea** ningún otro recurso

---

### **Escenario 4: Eliminar un Recurso**

```hcl
# Eliminas este recurso del código
# resource "aws_sns_topic" "old_topic" { ... }
```

**¿Qué pasa en el deploy?**
- ✅ Solo se elimina el SNS topic eliminado
- ✅ **NO se toca** ningún otro recurso
- ⏱️ Deploy tarda **~30 segundos**

---

### **Escenario 5: Sin Cambios**

```bash
# Haces push sin cambiar nada
git commit --allow-empty -m "trigger deploy"
git push
```

**¿Qué pasa en el deploy?**
- ✅ Terraform detecta que no hay cambios
- ✅ Plan muestra: `No changes. Infrastructure is up-to-date.`
- ✅ **NO se ejecuta** ningún cambio
- ⏱️ Deploy tarda **~1 minuto** (solo verificación)

---

## 🔍 Por Qué Ahora Se Están Creando Todos

### **Razón Actual:**

Los recursos **ya existen en AWS** pero **NO están en el estado de Terraform**. Por eso Terraform piensa que no existen y intenta crearlos.

### **Solución Implementada:**

Con la **importación automática** que acabamos de implementar:

1. ✅ Detecta recursos existentes
2. ✅ Los importa al estado de Terraform
3. ✅ Terraform los reconoce
4. ✅ **NO intenta crearlos de nuevo**

### **Después del Primer Deploy Exitoso:**

Una vez que todos los recursos estén importados y el deploy funcione:

- ✅ **Solo se actualizará** lo que cambies
- ✅ **NO se recreará** todo en cada push
- ✅ Deploys serán **mucho más rápidos**

---

## 📈 Comparación: Antes vs Después

### **Antes (Sin Importación):**

```
Push 1: Crea todo (VPC, RDS, Lambda, etc.) - 15 min
Push 2: Intenta crear todo de nuevo → ERROR (ya existen)
Push 3: Intenta crear todo de nuevo → ERROR (ya existen)
```

### **Ahora (Con Importación):**

```
Push 1: Importa recursos existentes + crea faltantes - 15 min
Push 2: Solo actualiza lo que cambió - 2-3 min
Push 3: Solo actualiza lo que cambió - 2-3 min
Push 4: Sin cambios → No hace nada - 1 min
```

---

## 🎯 Qué Se Actualiza vs Qué Se Recrea

### **Se Actualiza (Sin Recrear):**

- ✅ **Lambda Functions**: Código, variables de entorno, timeout, memory
- ✅ **API Gateway**: Rutas, métodos, integraciones
- ✅ **DynamoDB**: Throughput, índices, tags
- ✅ **SNS/SQS**: Políticas, tags
- ✅ **RDS**: Tamaño, parámetros, tags (sin pérdida de datos)
- ✅ **Security Groups**: Reglas de entrada/salida
- ✅ **Route Tables**: Rutas

### **Se Recrea (Solo Si Cambias Configuración Fundamental):**

- ⚠️ **VPC**: Solo si cambias CIDR block (raro)
- ⚠️ **Subnets**: Solo si cambias CIDR block (raro)
- ⚠️ **RDS**: Solo si cambias engine, engine_version, o eliminas el recurso

---

## 💡 Mejores Prácticas

### **1. Cambios Incrementales**

```bash
# ✅ BIEN: Cambios pequeños y frecuentes
git commit -m "feat: agregar nueva variable de entorno"
git push

# ❌ MAL: Cambios masivos que requieren recrear todo
# (aunque Terraform lo maneja bien, es mejor evitar)
```

### **2. Revisar el Plan Antes de Aplicar**

Terraform siempre muestra qué va a hacer:

```bash
Plan: 1 to add, 2 to change, 0 to destroy.
```

- **1 to add**: Nuevo recurso
- **2 to change**: Recursos que se actualizarán
- **0 to destroy**: Nada se eliminará

### **3. Usar `terraform plan` Localmente**

Antes de hacer push, puedes verificar:

```bash
cd terraform
terraform plan
# Ver qué cambiará sin aplicar
```

---

## 🚀 Resumen

| Situación | ¿Se Recrea Todo? | Tiempo |
|-----------|------------------|--------|
| **Primer deploy** | ✅ Sí (crea todo) | ~15 min |
| **Cambio en Lambda** | ❌ No (solo actualiza) | ~2-3 min |
| **Cambio en variable** | ❌ No (solo actualiza) | ~1 min |
| **Sin cambios** | ❌ No (no hace nada) | ~1 min |
| **Eliminar recurso** | ⚠️ Solo ese recurso | ~30 seg |

---

## ✅ Conclusión

**NO te preocupes**: Una vez que el primer deploy funcione, los siguientes deploys serán **rápidos** y solo actualizarán lo que cambies. Terraform es inteligente y **no recrea todo** en cada push.

**Lo que estás viendo ahora** (crear todo) es solo porque es el **primer deploy** y los recursos no estaban en el estado de Terraform. Después será mucho más eficiente.

---

**Última actualización:** 2025-01-09

