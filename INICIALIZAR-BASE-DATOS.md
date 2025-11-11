# 🗄️ Guía: Inicializar Base de Datos RDS

## ✅ Opción 1: GitHub Actions (Recomendado - Más Fácil)

### Pasos:

1. **Ve a tu repositorio en GitHub**
   - URL: `https://github.com/mozadev/agendamiento-cita-medica-backend`

2. **Ve a la pestaña "Actions"**
   - Click en "Actions" en el menú superior

3. **Selecciona el workflow "Database Migrations"**
   - En el menú lateral izquierdo, busca "Database Migrations"

4. **Click en "Run workflow"** (botón azul en la parte superior derecha)

5. **Configura los parámetros:**
   - **Environment**: Selecciona `prod` (o `dev` si tienes otro ambiente)
   - **Migration action**: Selecciona `apply` (aplica las migraciones)

6. **Click en "Run workflow"** (botón verde)

7. **Espera a que termine** (2-5 minutos)
   - El workflow:
     - ✅ Se conectará a las instancias RDS (Perú y Chile)
     - ✅ Creará las bases de datos si no existen
     - ✅ Ejecutará el schema SQL (`docs/database-schema.sql`)
     - ✅ Creará las tablas: `appointments`, `schedules`, `medical_centers`, etc.

### Acciones disponibles:

- **`verify`**: Solo verifica la conexión y el estado de las tablas (no hace cambios)
- **`apply`**: Aplica las migraciones (crea tablas si no existen)
- **`force`**: Fuerza la re-aplicación (⚠️ **PELIGROSO** - puede eliminar datos)

---

## ✅ Opción 2: Manual desde tu MacBook (Avanzado)

Si prefieres ejecutarlo manualmente desde tu terminal:

### Prerequisitos:

```bash
# Instalar MySQL client si no lo tienes
brew install mysql-client

# O usar el cliente que ya tienes instalado
```

### Pasos:

1. **Obtener credenciales de RDS desde AWS Secrets Manager:**

```bash
# Configurar AWS CLI (si no está configurado)
aws configure

# Obtener secret de Perú
aws secretsmanager get-secret-value \
  --secret-id "agendamiento-v2-prod-rds-peru-credentials" \
  --region us-east-1 \
  --query SecretString \
  --output text | jq -r '.host, .username, .password, .dbname'

# Obtener secret de Chile
aws secretsmanager get-secret-value \
  --secret-id "agendamiento-v2-prod-rds-chile-credentials" \
  --region us-east-1 \
  --query SecretString \
  --output text | jq -r '.host, .username, .password, .dbname'
```

2. **Conectarte a la base de datos de Perú:**

```bash
# Reemplaza HOST, USERNAME, PASSWORD con los valores obtenidos
mysql -h <PERU_HOST> -u <PERU_USERNAME> -p<PASSWORD> <PERU_DBNAME> < docs/database-schema.sql
```

3. **Conectarte a la base de datos de Chile:**

```bash
# Reemplaza HOST, USERNAME, PASSWORD con los valores obtenidos
mysql -h <CHILE_HOST> -u <CHILE_USERNAME> -p<CHILE_PASSWORD> <CHILE_DBNAME> < docs/database-schema.sql
```

### ⚠️ Nota de Seguridad:

Las instancias RDS están en **subnets privadas** dentro de la VPC. Para conectarte desde tu MacBook, necesitarías:

1. **VPN o Bastion Host** configurado en AWS
2. **O usar AWS Systems Manager Session Manager** para hacer port forwarding
3. **O ejecutar el script desde un EC2 dentro de la VPC**

Por eso, **la Opción 1 (GitHub Actions) es más fácil** - ya tiene acceso a la VPC y puede conectarse directamente.

---

## 📋 Verificar que funcionó:

Después de ejecutar las migraciones, puedes verificar:

### Desde GitHub Actions:
- El workflow mostrará logs de cada paso
- Verás mensajes como:
  - ✅ "Tabla appointments existe"
  - ✅ "Migración aplicada exitosamente"

### Desde AWS Console:
1. Ve a **RDS** → **Databases**
2. Selecciona la instancia de Perú o Chile
3. Click en **"Connectivity & security"**
4. Usa **"Query Editor"** (si está habilitado) o conecta desde un EC2

---

## 🔍 Troubleshooting:

### Error: "Can't connect to MySQL server"
- **Causa**: RDS está en subnets privadas, no accesible desde internet
- **Solución**: Usa GitHub Actions (Opción 1) o configura VPN/Bastion

### Error: "Access denied for user"
- **Causa**: Credenciales incorrectas
- **Solución**: Verifica los secrets en AWS Secrets Manager

### Error: "Table already exists"
- **Causa**: Las tablas ya fueron creadas
- **Solución**: Esto es normal, las migraciones son idempotentes (usa `CREATE TABLE IF NOT EXISTS`)

---

## 📚 Archivos relacionados:

- **Schema SQL**: `docs/database-schema.sql`
- **Workflow de migraciones**: `.github/workflows/db-migrations.yml`
- **Terraform RDS**: `terraform/main.tf` (líneas ~400-550)

---

## ✅ Siguiente paso después de inicializar:

Una vez que las bases de datos estén inicializadas:

1. ✅ Las funciones Lambda podrán conectarse a RDS
2. ✅ Los agendamientos se guardarán en DynamoDB **Y** en RDS (según el país)
3. ✅ Puedes probar la API creando un appointment

**¿Listo para inicializar?** → Ve a GitHub Actions y ejecuta el workflow "Database Migrations" 🚀

