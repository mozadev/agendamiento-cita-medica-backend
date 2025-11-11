# 🔄 Guía de Migración: Serverless Framework → Terraform + SAM

## 📋 Comparación

| Aspecto | Serverless Framework (Actual) | Terraform + SAM (Nuevo) |
|---------|------------------------------|------------------------|
| **Infraestructura** | Todo en serverless.yml | Terraform modules |
| **Lambdas** | serverless.yml | SAM template.yaml |
| **State Management** | No (limitado) | Terraform S3 backend |
| **Testing Local** | serverless offline | `sam local start-api` |
| **CI/CD** | Manual | GitHub Actions automático |
| **Secrets** | Variables en código | GitHub Secrets + AWS Secrets Manager |
| **Multi-environment** | Flags `--stage` | Workspaces + tfvars |
| **Modularidad** | Baja | Alta (módulos reutilizables) |

---

## 🎯 ¿Qué cambia?

### Antes (Serverless Framework):
```yaml
# serverless.yml - TODO en un archivo
provider:
  name: aws
  runtime: nodejs20.x
  
resources:
  Resources:
    MyRDS:
      Type: AWS::RDS::DBInstance
      Properties: ...
    MyLambda:
      Type: AWS::Lambda::Function
      Properties: ...
```

### Después (Terraform + SAM):
```
terraform/
  ├── modules/rds/       # RDS como módulo
  ├── modules/dynamodb/  # DynamoDB como módulo
  └── main.tf            # Orquestador

sam/
  └── template.yaml      # Solo Lambdas
```

---

## 🚀 Pasos de Migración

### Paso 1: Backup Actual (IMPORTANTE)

```bash
# Exportar configuración actual de serverless
serverless info --verbose > serverless-current-state.txt

# Backup DynamoDB
aws dynamodb create-backup \
  --table-name appointments-dev \
  --backup-name pre-migration-backup

# Exportar datos de RDS
mysqldump -h <RDS_HOST> -u admin -p appointments_pe > backup_pe.sql
mysqldump -h <RDS_HOST> -u admin -p appointments_cl > backup_cl.sql
```

### Paso 2: Importar Recursos Existentes a Terraform

Si ya tienes recursos creados con Serverless, puedes importarlos:

```bash
cd terraform

# Importar DynamoDB
terraform import module.dynamodb.aws_dynamodb_table.appointments appointments-dev

# Importar RDS Peru
terraform import module.rds_peru.aws_db_instance.main appointments-pe-db

# Importar RDS Chile
terraform import module.rds_chile.aws_db_instance.main appointments-cl-db

# Importar SNS Topics
terraform import module.sns.aws_sns_topic.peru arn:aws:sns:...
```

### Paso 3: Configurar GitHub Secrets

Ver [IAC-GUIDE.md](#configuración-inicial)

### Paso 4: Desplegar Nueva Infraestructura

```bash
# Opción A: Via GitHub Actions (push a develop)
git add .
git commit -m "feat: migrate to terraform + sam"
git push origin develop

# Opción B: Manual
cd terraform
terraform init
terraform plan
terraform apply
```

### Paso 5: Migrar Lambdas a SAM

Las Lambdas usan el mismo código, solo cambia el deployment:

```bash
cd sam
sam build
sam deploy --guided  # Primera vez
```

### Paso 6: Verificar Funcionamiento

```bash
# Test API
API_URL=$(aws cloudformation describe-stacks \
  --stack-name agendamiento-citas-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
  --output text)

curl -X POST "$API_URL/appointments" \
  -H "Content-Type: application/json" \
  -d '{"insuredId": "12345", "scheduleId": 100, "countryISO": "PE"}'
```

### Paso 7: Eliminar Stack Serverless Antiguo

```bash
# SOLO DESPUÉS de verificar que todo funciona
serverless remove --stage dev
```

---

## ⚠️ Consideraciones Importantes

### 1. Downtime

La migración puede causar downtime. Recomendaciones:

- ✅ Hacerlo en ambiente dev primero
- ✅ Hacerlo en horario de bajo tráfico
- ✅ Notificar a usuarios si es necesario
- ✅ Tener rollback plan

### 2. URLs del API

La URL del API Gateway puede cambiar:

**Antes:**
```
https://abc123.execute-api.us-east-1.amazonaws.com/dev/appointments
```

**Después:**
```
https://xyz456.execute-api.us-east-1.amazonaws.com/dev/appointments
```

**Solución:** Usa un Custom Domain Name o actualiza clientes.

### 3. Datos Existentes

Los datos en DynamoDB y RDS **NO se pierden** si:
- ✅ Importas correctamente los recursos
- ✅ No ejecutas `destroy` sin querer
- ✅ Tienes backups

### 4. IAM Roles

Los permisos de Lambda pueden cambiar. Verifica que:
- ✅ Lambdas tienen acceso a DynamoDB
- ✅ Lambdas tienen acceso a RDS (via VPC)
- ✅ Lambdas pueden leer Secrets Manager

---

## 🔄 Rollback Plan

Si algo sale mal:

```bash
# 1. Eliminar nueva infraestructura
cd terraform
terraform destroy -auto-approve

cd ../sam
sam delete --stack-name agendamiento-citas-dev --no-prompts

# 2. Restaurar Serverless Framework
git checkout <commit-anterior>
serverless deploy --stage dev

# 3. Restaurar datos (si es necesario)
aws dynamodb restore-table-from-backup \
  --target-table-name appointments-dev \
  --backup-arn <backup-arn>

mysql -h <RDS_HOST> -u admin -p appointments_pe < backup_pe.sql
```

---

## ✅ Checklist de Migración

```
Pre-migración:
├─ [ ] Backup de DynamoDB
├─ [ ] Export de datos RDS
├─ [ ] Documentar URLs actuales
├─ [ ] Documentar configuración actual
└─ [ ] Notificar a equipo

Migración:
├─ [ ] Configurar GitHub Secrets
├─ [ ] Crear terraform.tfvars
├─ [ ] Terraform plan (revisar)
├─ [ ] Terraform apply
├─ [ ] SAM deploy
├─ [ ] Verificar logs
└─ [ ] Tests de integración

Post-migración:
├─ [ ] Actualizar documentación
├─ [ ] Actualizar URLs en clientes
├─ [ ] Monitorear por 24h
├─ [ ] Eliminar stack serverless antiguo
└─ [ ] Eliminar backups antiguos (después de 7 días)
```

---

## 💡 Ventajas de la Nueva Arquitectura

### Para Desarrollo:
- ✅ Testing local más fácil (`sam local start-api`)
- ✅ Debugging con VS Code
- ✅ Hot reload en desarrollo
- ✅ Menos configuración manual

### Para Operaciones:
- ✅ State management robusto (Terraform)
- ✅ Rollback más seguro
- ✅ Módulos reutilizables
- ✅ Better separation of concerns

### Para CI/CD:
- ✅ Pipeline automatizado completo
- ✅ Secrets management seguro
- ✅ Integration tests automáticos
- ✅ Deploy por ambiente (dev/staging/prod)

### Para Seguridad:
- ✅ Credenciales en Secrets Manager
- ✅ No más variables en código
- ✅ Branch protection
- ✅ Approval gates para prod

---

## 🎓 Recursos de Aprendizaje

### Terraform
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Import Existing Resources](https://developer.hashicorp.com/terraform/cli/import)

### SAM
- [SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [SAM Local Testing](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-using-debugging.html)
- [SAM vs Serverless Framework](https://www.serverless.com/blog/comparing-serverless-framework-and-sam)

### GitHub Actions
- [GitHub Actions for AWS](https://github.com/aws-actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Environment Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

**¿Necesitas ayuda con la migración?** Revisa [IAC-GUIDE.md](./IAC-GUIDE.md) para más detalles.

