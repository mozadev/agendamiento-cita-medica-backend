# 🔐 Guía: Configurar GitHub Secrets para RDS

## 📋 Secrets que Necesitas Crear

### ✅ Ya Configurados
- `AWS_ACCESS_KEY_ID` ✅
- `AWS_SECRET_ACCESS_KEY` ✅

### ⚠️ Faltan (OBLIGATORIOS)
- `RDS_PE_USERNAME`
- `RDS_PE_PASSWORD`
- `RDS_CL_USERNAME`
- `RDS_CL_PASSWORD`

---

## 🎯 Valores Recomendados

### **RDS_PE_USERNAME**
```
admin
```
**O cualquier nombre de usuario válido para MySQL** (sin espacios, sin caracteres especiales)

### **RDS_PE_PASSWORD**
```
TuPasswordSeguro123!
```
**Requisitos:**
- Mínimo 8 caracteres
- Al menos 1 mayúscula
- Al menos 1 minúscula
- Al menos 1 número
- Puede incluir caracteres especiales: `!@#$%^&*()`

**Ejemplos válidos:**
- `Admin123!`
- `Rimac2024#`
- `DevPass123$`

### **RDS_CL_USERNAME**
```
admin
```
**Puede ser el mismo que Perú o diferente**

### **RDS_CL_PASSWORD**
```
TuPasswordSeguro123!
```
**Puede ser el mismo que Perú o diferente (recomendado diferente para seguridad)**

---

## 📝 Pasos para Agregar los Secrets

### **1. Ve a tu Repositorio en GitHub**

```
https://github.com/TU-USUARIO/agendamiento-cita-media
```

### **2. Ve a Settings**

Click en **Settings** (arriba del repositorio)

### **3. Ve a Secrets and variables → Actions**

En el menú lateral izquierdo:
```
Settings
  └─ Secrets and variables
      └─ Actions
```

### **4. Click en "New repository secret"**

### **5. Agrega cada secret uno por uno:**

#### **Secret 1: RDS_PE_USERNAME**
- **Name:** `RDS_PE_USERNAME`
- **Secret:** `admin` (o el que prefieras)
- Click **Add secret**

#### **Secret 2: RDS_PE_PASSWORD**
- **Name:** `RDS_PE_PASSWORD`
- **Secret:** `TuPasswordSeguro123!` (o el que prefieras)
- Click **Add secret**

#### **Secret 3: RDS_CL_USERNAME**
- **Name:** `RDS_CL_USERNAME`
- **Secret:** `admin` (o el que prefieras)
- Click **Add secret**

#### **Secret 4: RDS_CL_PASSWORD**
- **Name:** `RDS_CL_PASSWORD`
- **Secret:** `TuPasswordSeguro123!` (o el que prefieras)
- Click **Add secret**

---

## ✅ Verificación

Después de agregar los 4 secrets, deberías ver:

```
Secrets (6)
├─ AWS_ACCESS_KEY_ID ✅
├─ AWS_SECRET_ACCESS_KEY ✅
├─ RDS_PE_USERNAME ✅
├─ RDS_PE_PASSWORD ✅
├─ RDS_CL_USERNAME ✅
└─ RDS_CL_PASSWORD ✅
```

---

## 🚀 Después de Configurar

Una vez que tengas los 6 secrets configurados:

```bash
# Hacer push
git push origin main

# El pipeline se ejecutará automáticamente
# Terraform usará estos secrets para crear las instancias RDS
```

---

## ⚠️ Notas Importantes

### **Seguridad:**
- ✅ Los secrets están encriptados en GitHub
- ✅ Solo son visibles durante el workflow
- ✅ No se pueden ver después de guardarlos
- ⚠️ **Guarda una copia de las passwords en un lugar seguro** (tu gestor de contraseñas)

### **Passwords:**
- Deben cumplir los requisitos de MySQL
- Se usarán para crear las instancias RDS
- Las necesitarás después para conectarte a las bases de datos

### **Terraform:**
- **NO necesitas configurar Terraform manualmente**
- El workflow de GitHub Actions lo hace todo:
  - `terraform init` → Automático
  - `terraform plan` → Usa los secrets
  - `terraform apply` → Crea los recursos

---

## 🔍 Troubleshooting

### **Error: "Required variable not set"**
→ Verifica que los 4 secrets de RDS estén creados

### **Error: "Invalid password"**
→ Verifica que la password cumpla los requisitos (mínimo 8 caracteres, mayúsculas, números)

### **Error: "Terraform plan failed"**
→ Verifica que todos los secrets estén correctamente escritos (sin espacios extra)

---

## 📊 Resumen

| Secret | Estado | Acción |
|-------|--------|--------|
| `AWS_ACCESS_KEY_ID` | ✅ Configurado | - |
| `AWS_SECRET_ACCESS_KEY` | ✅ Configurado | - |
| `RDS_PE_USERNAME` | ❌ Falta | **Agregar ahora** |
| `RDS_PE_PASSWORD` | ❌ Falta | **Agregar ahora** |
| `RDS_CL_USERNAME` | ❌ Falta | **Agregar ahora** |
| `RDS_CL_PASSWORD` | ❌ Falta | **Agregar ahora** |

**Terraform:** ✅ No necesita configuración manual (el workflow lo maneja)

---

✨ **Una vez que agregues los 4 secrets de RDS, estarás listo para hacer push y deployar!**

