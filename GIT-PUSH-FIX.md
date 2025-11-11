# 🔧 Solución: Error de Autenticación en Git Push

## ❌ Error Encontrado

```
remote: Permission to mozadev/agendamiento-cita-medica-backend.git denied to cmoza.
fatal: unable to access 'https://github.com/mozadev/agendamiento-cita-medica-backend.git/': The requested URL returned error: 403
```

**Problema:** Git está usando credenciales de `cmoza` pero el repositorio es de `mozadev`.

---

## ✅ Solución: Usar Personal Access Token (PAT)

### **Paso 1: Crear Personal Access Token en GitHub**

1. Ve a GitHub → **Settings** (tu perfil, no del repo)
2. Scroll down → **Developer settings**
3. **Personal access tokens** → **Tokens (classic)**
4. Click **Generate new token (classic)**
5. Configuración:
   - **Note:** `git-push-agendamiento`
   - **Expiration:** 90 days (o el que prefieras)
   - **Scopes:** Marca `repo` (todos los permisos de repositorio)
6. Click **Generate token**
7. **⚠️ COPIA EL TOKEN INMEDIATAMENTE** (solo se muestra una vez)

---

### **Paso 2: Actualizar Credenciales en macOS**

#### **Opción A: Usar el Token en la URL (Temporal)**

```bash
# Cambiar el remoto para incluir el token
git remote set-url origin https://TU_TOKEN@github.com/mozadev/agendamiento-cita-medica-backend.git

# Reemplaza TU_TOKEN con el token que copiaste
# Ejemplo:
# git remote set-url origin https://ghp_xxxxxxxxxxxx@github.com/mozadev/agendamiento-cita-medica-backend.git
```

#### **Opción B: Limpiar Credenciales Guardadas (Recomendado)**

```bash
# 1. Eliminar credenciales guardadas en Keychain
# Abre Keychain Access (Cmd + Space, busca "Keychain Access")
# Busca "github.com" o "cmoza"
# Elimina las entradas relacionadas

# O desde terminal:
security delete-internet-password -s github.com 2>/dev/null || echo "No credentials found"

# 2. Cambiar el remoto (sin token en la URL)
git remote set-url origin https://github.com/mozadev/agendamiento-cita-medica-backend.git

# 3. Hacer push (te pedirá usuario y password)
# Usuario: mozadev
# Password: Pega tu Personal Access Token (NO tu password de GitHub)
git push -u origin main
```

---

### **Paso 3: Verificar el Remoto**

```bash
# Verificar que el remoto esté correcto
git remote -v

# Debe mostrar:
# origin  https://github.com/mozadev/agendamiento-cita-medica-backend.git (fetch)
# origin  https://github.com/mozadev/agendamiento-cita-medica-backend.git (push)
```

---

## 🔐 Alternativa: Usar SSH (Más Seguro)

Si prefieres usar SSH en lugar de HTTPS:

### **1. Generar SSH Key (si no tienes una)**

```bash
# Verificar si ya tienes una
ls -la ~/.ssh/id_*.pub

# Si no tienes, generar una nueva
ssh-keygen -t ed25519 -C "ceosmore@gmail.com"
# Presiona Enter para usar la ubicación por defecto
# Opcional: agrega una passphrase
```

### **2. Agregar SSH Key a GitHub**

```bash
# Copiar la clave pública
cat ~/.ssh/id_ed25519.pub
# O si usas RSA:
# cat ~/.ssh/id_rsa.pub

# Copia el output completo
```

1. Ve a GitHub → **Settings** → **SSH and GPG keys**
2. Click **New SSH key**
3. **Title:** `MacBook - agendamiento`
4. **Key:** Pega la clave pública
5. Click **Add SSH key**

### **3. Cambiar el Remoto a SSH**

```bash
# Cambiar de HTTPS a SSH
git remote set-url origin git@github.com:mozadev/agendamiento-cita-medica-backend.git

# Verificar
git remote -v

# Hacer push (no pedirá credenciales)
git push -u origin main
```

---

## ✅ Verificación

Después de configurar, verifica:

```bash
# Ver el remoto
git remote -v

# Intentar push
git push -u origin main
```

---

## 🚀 Después del Push

Una vez que el push sea exitoso:

1. ✅ Ve a GitHub → Tu repositorio
2. ✅ Ve a **Actions** (arriba)
3. ✅ Verás el workflow ejecutándose automáticamente
4. ✅ El pipeline creará los recursos AWS (tarda ~25-30 min)

---

## 📊 Resumen de Opciones

| Método | Pros | Contras |
|--------|------|---------|
| **PAT en URL** | Rápido | Token visible en remoto |
| **PAT en prompt** | Más seguro | Hay que ingresarlo cada vez |
| **SSH** | Más seguro, sin tokens | Requiere configurar SSH key |

**Recomendación:** SSH (más seguro a largo plazo) o PAT en prompt (más rápido ahora).

---

✨ **Una vez que resuelvas la autenticación, el push funcionará y el pipeline se ejecutará automáticamente!**

