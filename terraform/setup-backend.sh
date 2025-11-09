#!/bin/bash

# Script para configurar el backend S3 de Terraform
# Ejecutar una vez antes del primer deploy

set -e

REGION="us-east-1"
BUCKET_NAME="agendamiento-citas-terraform-state-$(date +%s)"
LOCK_TABLE_NAME="terraform-state-lock"

echo "🔧 Configurando backend S3 para Terraform..."
echo ""

# 1. Crear bucket S3 para el state
echo "📦 Creando bucket S3: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# 2. Habilitar versionado en el bucket
echo "📝 Habilitando versionado en el bucket..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# 3. Habilitar encriptación
echo "🔐 Habilitando encriptación..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 4. Bloquear acceso público
echo "🔒 Bloqueando acceso público..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 5. Crear tabla DynamoDB para lock
echo "🔐 Creando tabla DynamoDB para lock: $LOCK_TABLE_NAME"
aws dynamodb create-table \
  --table-name $LOCK_TABLE_NAME \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION \
  --tags Key=Project,Value=AgendamientoCitas Key=ManagedBy,Value=Terraform

# Esperar a que la tabla esté activa
echo "⏳ Esperando a que la tabla esté activa..."
aws dynamodb wait table-exists --table-name $LOCK_TABLE_NAME --region $REGION

echo ""
echo "✅ Backend configurado exitosamente!"
echo ""
echo "📋 Información del backend:"
echo "   Bucket S3: $BUCKET_NAME"
echo "   Tabla DynamoDB: $LOCK_TABLE_NAME"
echo "   Región: $REGION"
echo ""
echo "🔧 Próximos pasos:"
echo "   1. Actualizar terraform/main.tf con el nombre del bucket:"
echo "      bucket = \"$BUCKET_NAME\""
echo "   2. Descomentar el bloque 'backend \"s3\"' en terraform/main.tf"
echo "   3. Ejecutar: cd terraform && terraform init -migrate-state"
echo ""

