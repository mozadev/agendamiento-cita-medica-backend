# 👤 Crear Usuario IAM para este MacBook

## 🎯 Objetivo

Crear un usuario IAM específico para este MacBook, separado de `cesar-dev` (tu otra MacBook).

**Nombre sugerido:** `fabrizio-dev` o `fabrizio-macbook`

---

## 📋 Paso 1: Crear Usuario IAM en AWS Console

### 1.1. Acceder a IAM

1. Ve a **AWS Console**: https://console.aws.amazon.com/
2. Busca **IAM** en la barra de búsqueda
3. Click en **IAM** → **Users**

### 1.2. Crear Nuevo Usuario

1. Click en **Create user**
2. **User name**: `fabrizio-dev` (o el nombre que prefieras)
3. **Provide user access to the AWS Management Console**: ❌ **NO marcar** (solo CLI)
4. Click **Next**

### 1.3. Asignar Permisos

**Opción A: Para Desarrollo (Recomendado)**

1. Selecciona **Attach policies directly**
2. Busca y selecciona: **`AdministratorAccess`**
   - ⚠️ Solo para desarrollo/testing
   - Para producción, usa permisos más específicos

**Opción B: Permisos Específicos (Más Seguro)**

Crea una política personalizada con solo los permisos necesarios:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "lambda:*",
        "apigateway:*",
        "dynamodb:*",
        "rds:*",
        "sns:*",
        "sqs:*",
        "events:*",
        "secretsmanager:*",
        "iam:*",
        "ec2:*",
        "logs:*",
        "xray:*",
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Para este proyecto, usa Opción A (AdministratorAccess)** ya que es desarrollo.

### 1.4. Revisar y Crear

1. Click **Next**
2. Revisa la configuración
3. Click **Create user**

---

## 🔑 Paso 2: Crear Access Key

### 2.1. Acceder al Usuario

1. Click en el usuario recién creado (`fabrizio-dev`)
2. Ve a la pestaña **Security credentials**
3. Scroll hasta **Access keys**

### 2.2. Crear Access Key

1. Click en **Create access key**
2. Selecciona **Command Line Interface (CLI)**
3. Marca el checkbox de confirmación
4. Click **Next**
5. (Opcional) Agrega una descripción: `MacBook Fabrizio - Desarrollo`
6. Click **Create access key**

### 2.3. Guardar Credenciales

**⚠️ IMPORTANTE: Guarda estas credenciales AHORA. No podrás verlas después.**

```
Access Key ID: AKIA...
Secret Access Key: wJal...
```

**Opciones para guardar:**
- ✅ Copiar a un gestor de contraseñas (1Password, LastPass, etc.)
- ✅ Guardar en un archivo local (NO commitear)
- ✅ Copiar a GitHub Secrets (después de configurar)

---

## ⚙️ Paso 3: Configurar AWS CLI Localmente

### 3.1. Configurar con el Nuevo Usuario

```bash
aws configure
```

**Ingresa:**
```
AWS Access Key ID [None]: AKIA... (del nuevo usuario)
AWS Secret Access Key [None]: wJal... (del nuevo usuario)
Default region name [None]: us-east-1
Default output format [None]: json
```

### 3.2. Verificar Configuración

```bash
# Verificar que funciona
aws sts get-caller-identity

# Debe mostrar:
# {
#     "UserId": "AIDA...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/fabrizio-dev"
# }
```

---

## 🔐 Paso 4: Configurar Múltiples Perfiles (Opcional)

Si quieres tener ambos usuarios configurados (cesar-dev y fabrizio-dev):

### 4.1. Configurar Perfil para este MacBook

```bash
aws configure --profile fabrizio-dev
```

**Ingresa las credenciales del nuevo usuario**

### 4.2. Usar Perfil Específico

```bash
# Usar perfil de este MacBook
aws sts get-caller-identity --profile fabrizio-dev

# Usar perfil de la otra MacBook (si lo configuras)
aws sts get-caller-identity --profile cesar-dev
```

### 4.3. Configurar Perfil por Defecto

```bash
# Hacer fabrizio-dev el perfil por defecto
export AWS_PROFILE=fabrizio-dev

# O agregar a ~/.zshrc para que persista
echo 'export AWS_PROFILE=fabrizio-dev' >> ~/.zshrc
source ~/.zshrc
```

---

## 📊 Comparación de Usuarios

| Aspecto | cesar-dev (otra MacBook) | fabrizio-dev (este MacBook) |
|---------|-------------------------|----------------------------|
| **Usuario IAM** | `cesar-dev` | `fabrizio-dev` |
| **Access Key** | AKIA... (diferente) | AKIA... (diferente) |
| **Máquina** | MacBook Cesar | MacBook Fabrizio |
| **Proyecto** | Otros proyectos | agendamiento-citas |
| **Auditoría** | Separada | Separada |
| **Rotación** | Independiente | Independiente |

---

## ✅ Checklist

```
Creación de Usuario:
├─ [ ] Usuario IAM creado: fabrizio-dev
├─ [ ] Permisos asignados: AdministratorAccess (dev)
├─ [ ] Access Key creada
├─ [ ] Credenciales guardadas de forma segura
└─ [ ] AWS CLI configurado localmente

Verificación:
├─ [ ] aws sts get-caller-identity funciona
├─ [ ] Muestra el usuario correcto (fabrizio-dev)
└─ [ ] Puede listar recursos (aws s3 ls, etc.)
```

---

## 🚀 Próximos Pasos

Una vez configurado:

1. ✅ **Configurar GitHub Secrets** con las mismas credenciales
2. ✅ **Probar Terraform**: `cd terraform && terraform init`
3. ✅ **Probar SAM**: `cd sam && sam build` (después de terraform)
4. ✅ **Deploy**: Push a GitHub y dejar que Actions haga el deploy

---

## 🔒 Seguridad

### ✅ Mejores Prácticas

1. **Nunca compartas credenciales entre máquinas**
   - Cada máquina = Usuario IAM diferente

2. **Rota credenciales regularmente**
   - Cada 90 días (recomendado)
   - O inmediatamente si se comprometen

3. **Usa permisos mínimos en producción**
   - AdministratorAccess solo para dev
   - Permisos específicos para prod

4. **Habilita MFA para producción**
   - Multi-Factor Authentication
   - Requiere token adicional

5. **Monitorea uso de credenciales**
   - CloudTrail registra todas las acciones
   - Revisa logs regularmente

---

## 🐛 Troubleshooting

### Error: "Access Denied"

```bash
# Verificar que el usuario tiene permisos
aws iam get-user --user-name fabrizio-dev

# Verificar políticas adjuntas
aws iam list-attached-user-policies --user-name fabrizio-dev
```

### Error: "Invalid credentials"

```bash
# Verificar que estás usando las credenciales correctas
aws configure list

# Verificar que el perfil es correcto
aws sts get-caller-identity
```

---

## 📚 Referencias

- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Creating IAM Users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
- [Managing Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

---

**🎯 ¿Listo para crear el usuario? Sigue los pasos arriba y luego ejecuta `aws configure`**

