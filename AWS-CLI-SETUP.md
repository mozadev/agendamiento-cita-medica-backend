# 🔧 Configuración de AWS CLI

## ✅ Estado Actual

- ✅ AWS CLI instalado: `aws-cli/2.31.32`
- ⚠️ Credenciales: No configuradas

---

## 🔑 Paso 1: Obtener Credenciales de AWS

### Opción A: Si ya tienes cuenta AWS

1. Ve a **AWS Console** → **IAM** → **Users** → Tu usuario
2. Click en **Security credentials**
3. Click en **Create access key**
4. Selecciona **Command Line Interface (CLI)**
5. Descarga o copia:
   - **Access Key ID**: `AKIA...`
   - **Secret Access Key**: `wJal...`

### Opción B: Si NO tienes cuenta AWS

1. Crea cuenta en: https://aws.amazon.com/
2. Activa Free Tier (12 meses gratis)
3. Ve a IAM y crea un usuario con permisos:
   - `AdministratorAccess` (para desarrollo)
   - O permisos específicos (recomendado para producción)

---

## ⚙️ Paso 2: Configurar AWS CLI

### Configuración Interactiva (Recomendado)

```bash
aws configure
```

**Te pedirá:**
```
AWS Access Key ID [None]: AKIA...
AWS Secret Access Key [None]: wJal...
Default region name [None]: us-east-1
Default output format [None]: json
```

### Configuración Manual

Si prefieres hacerlo manualmente:

```bash
# Crear directorio de configuración
mkdir -p ~/.aws

# Crear archivo de credenciales
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = wJal...
EOF

# Crear archivo de configuración
cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF
```

---

## ✅ Paso 3: Verificar Configuración

```bash
# Verificar que las credenciales funcionan
aws sts get-caller-identity

# Debe mostrar algo como:
# {
#     "UserId": "AIDA...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/tu-usuario"
# }
```

---

## 🔐 Paso 4: Configurar Múltiples Perfiles (Opcional)

Si necesitas trabajar con múltiples cuentas AWS:

```bash
# Perfil para desarrollo
aws configure --profile dev
# Access Key ID: AKIA...
# Secret Access Key: wJal...
# Region: us-east-1
# Output: json

# Perfil para producción
aws configure --profile prod
# Access Key ID: AKIA...
# Secret Access Key: wJal...
# Region: us-east-1
# Output: json

# Usar un perfil específico
aws sts get-caller-identity --profile dev
```

---

## 🚀 Paso 5: Probar Comandos Básicos

```bash
# Listar regiones disponibles
aws ec2 describe-regions --query 'Regions[].RegionName'

# Listar buckets S3 (si tienes)
aws s3 ls

# Ver información de tu cuenta
aws sts get-caller-identity

# Listar stacks de CloudFormation
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE
```

---

## 🔒 Seguridad

### ✅ Mejores Prácticas

1. **Nunca commitees credenciales**
   ```bash
   # Verificar que ~/.aws/ está en .gitignore
   echo ".aws/" >> .gitignore
   ```

2. **Usa IAM Roles en producción**
   - En EC2/Lambda, usa IAM Roles (no access keys)
   - Access keys solo para desarrollo local

3. **Rota credenciales regularmente**
   - Cada 90 días (recomendado)
   - O inmediatamente si se comprometen

4. **Usa MFA para producción**
   - Habilita Multi-Factor Authentication
   - Requiere token adicional para operaciones sensibles

---

## 🐛 Troubleshooting

### Error: "Unable to locate credentials"

```bash
# Verificar que el archivo existe
ls -la ~/.aws/credentials

# Verificar permisos (debe ser 600)
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

### Error: "Access Denied"

```bash
# Verificar permisos del usuario IAM
aws iam get-user

# Verificar políticas adjuntas
aws iam list-attached-user-policies --user-name tu-usuario
```

### Error: "Invalid credentials"

```bash
# Regenerar access key en AWS Console
# IAM → Users → Security credentials → Create access key
# Luego reconfigurar:
aws configure
```

---

## 📚 Comandos Útiles

### Ver Configuración Actual

```bash
# Ver perfil actual
aws configure list

# Ver configuración completa
cat ~/.aws/config
cat ~/.aws/credentials
```

### Cambiar Región

```bash
# Cambiar región por defecto
aws configure set region eu-west-1

# O usar flag en cada comando
aws s3 ls --region eu-west-1
```

### Cambiar Output Format

```bash
# Cambiar a tabla (más legible)
aws configure set output table

# Cambiar a JSON (más técnico)
aws configure set output json

# Cambiar a texto
aws configure set output text
```

---

## 🎯 Próximos Pasos

Una vez configurado AWS CLI:

1. ✅ Verificar credenciales: `aws sts get-caller-identity`
2. ✅ Configurar GitHub Secrets (para CI/CD)
3. ✅ Deploy con Terraform: `cd terraform && terraform init`
4. ✅ Deploy con SAM: `cd sam && sam build && sam deploy`

---

## 📖 Referencias

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

**🔧 ¿Listo para configurar? Ejecuta: `aws configure`**

