# 🔒 Guía de Seguridad - Secrets y Variables de Entorno

## ⚠️ IMPORTANTE: Nunca commites credenciales

### ❌ NUNCA hacer esto:

```bash
# ❌ NO commitees estos archivos:
.env
.env.local
.env.production
*.pem
*.key
credentials.json
secrets.yaml
```

### ✅ Archivos SEGUROS para commit:

```bash
# ✅ Estos archivos están bien:
.env.example          # Sin valores reales
env.example          # Sin valores reales
terraform.tfvars.example  # Sin valores reales
```

---

## 🔐 Dónde guardar credenciales

### 1. **GitHub Secrets** (Para CI/CD)

**Settings → Secrets and variables → Actions → New repository secret**

```bash
# Secrets requeridos:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
RDS_PE_USERNAME
RDS_PE_PASSWORD
RDS_CL_USERNAME
RDS_CL_PASSWORD
```

**Ventajas:**
- ✅ Encriptados por GitHub
- ✅ No visibles en código
- ✅ No visibles en logs (automáticamente enmascarados)
- ✅ Solo accesibles en workflows

### 2. **AWS Secrets Manager** (Para producción)

Las Lambdas leen credenciales desde Secrets Manager automáticamente.

**No necesitas poner credenciales RDS en GitHub** - Terraform las crea en Secrets Manager.

### 3. **Variables de entorno locales** (Solo para desarrollo)

```bash
# .env (NO commitear)
RDS_PE_HOST=localhost
RDS_PE_PASSWORD=dev-password
```

**Asegúrate de que esté en .gitignore:**

```bash
# Verificar
cat .gitignore | grep "\.env"

# Si no está, agregarlo:
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore
echo ".env.*.local" >> .gitignore
```

---

## ✅ Checklist de Seguridad

Antes de hacer push:

```bash
# 1. Verificar que .env NO esté tracked
git ls-files | grep "\.env$"
# Debe estar vacío

# 2. Verificar .gitignore
cat .gitignore | grep -E "\.env|secrets"

# 3. Verificar que no hay passwords en código
grep -r "password.*=" src/ --exclude-dir=node_modules || echo "✅ No passwords found"

# 4. Verificar que no hay AWS keys en código
grep -r "AKIA" . --exclude-dir=node_modules --exclude-dir=.git || echo "✅ No AWS keys found"
```

---

## 🚨 Si accidentalmente commiteaste secrets

### Opción 1: Si aún no hiciste push

```bash
# Remover del último commit
git reset --soft HEAD~1
git reset HEAD .env
git commit -m "chore: remove sensitive files"
```

### Opción 2: Si ya hiciste push

```bash
# 1. Rotar las credenciales inmediatamente
#    - Cambiar password de RDS
#    - Regenerar AWS keys

# 2. Remover del historial (CUIDADO)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push (solo si es necesario)
git push origin --force --all
```

**⚠️ ADVERTENCIA:** Si el repo es público, considera las credenciales comprometidas.

---

## 📋 Template de .env.example

```bash
# .env.example (SEGURO para commit)
RDS_PE_HOST=your-rds-endpoint.rds.amazonaws.com
RDS_PE_DATABASE=appointments_pe
RDS_PE_USER=admin
RDS_PE_PASSWORD=CHANGE_ME

RDS_CL_HOST=your-rds-endpoint.rds.amazonaws.com
RDS_CL_DATABASE=appointments_cl
RDS_CL_USER=admin
RDS_CL_PASSWORD=CHANGE_ME
```

---

## 🔍 Verificar antes de compartir el repo

```bash
# Script de verificación
#!/bin/bash

echo "🔍 Verificando seguridad del repo..."

# 1. Verificar .env
if git ls-files | grep -q "\.env$"; then
  echo "❌ ERROR: .env está tracked en git!"
  exit 1
fi

# 2. Verificar passwords en código
if grep -r "password.*=.*[^CHANGE_ME]" src/ --exclude-dir=node_modules 2>/dev/null; then
  echo "❌ ERROR: Passwords encontrados en código!"
  exit 1
fi

# 3. Verificar AWS keys
if grep -r "AKIA" . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
  echo "❌ ERROR: AWS keys encontradas en código!"
  exit 1
fi

echo "✅ Repo seguro para compartir!"
```

---

## 📚 Referencias

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [OWASP Secrets Management](https://owasp.org/www-community/vulnerabilities/Use_of_hard-coded_cryptographic_key)

---

**🔒 Recuerda: Si dudas, NO lo commitees.**

