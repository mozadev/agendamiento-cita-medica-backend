#!/bin/bash

# Script para limpiar recursos duplicados en AWS
# Ejecutar: chmod +x cleanup-aws.sh && ./cleanup-aws.sh

set -e

REGION="us-east-1"
PROJECT_PREFIX="agendamiento-citas-prod"

echo "🧹 Limpiando recursos AWS duplicados..."
echo ""

# 1. Eliminar DynamoDB Table
echo "📦 Eliminando DynamoDB Table..."
aws dynamodb delete-table \
  --table-name ${PROJECT_PREFIX}-appointments \
  --region $REGION 2>/dev/null && echo "✅ DynamoDB eliminada" || echo "⚠️  DynamoDB no encontrada o ya eliminada"

# 2. Eliminar EventBridge Bus
echo "📡 Eliminando EventBridge Bus..."
aws events delete-event-bus \
  --name ${PROJECT_PREFIX}-bus \
  --region $REGION 2>/dev/null && echo "✅ EventBridge eliminado" || echo "⚠️  EventBridge no encontrado o ya eliminado"

# 3. Eliminar Secrets Manager - Peru
echo "🔐 Eliminando Secret Manager - Peru..."
aws secretsmanager delete-secret \
  --secret-id ${PROJECT_PREFIX}-rds-peru-credentials \
  --force-delete-without-recovery \
  --region $REGION 2>/dev/null && echo "✅ Secret Peru eliminado" || echo "⚠️  Secret Peru no encontrado"

# 4. Eliminar Secrets Manager - Chile
echo "🔐 Eliminando Secret Manager - Chile..."
aws secretsmanager delete-secret \
  --secret-id ${PROJECT_PREFIX}-rds-chile-credentials \
  --force-delete-without-recovery \
  --region $REGION 2>/dev/null && echo "✅ Secret Chile eliminado" || echo "⚠️  Secret Chile no encontrado"

# 5. Listar VPCs para ver cuántas hay
echo ""
echo "📊 VPCs actuales en tu cuenta:"
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[].[VpcId,Tags[?Key==`Name`].Value|[0],IsDefault]' --output table

echo ""
echo "⚠️  IMPORTANTE: Límite de VPCs alcanzado (5 VPCs)"
echo ""
echo "Para ver VPCs no usadas y eliminarlas:"
echo "  aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[?IsDefault==\`false\`].[VpcId,Tags[?Key==\`Name\`].Value|[0]]' --output table"
echo ""
echo "Para eliminar una VPC específica (CUIDADO):"
echo "  aws ec2 delete-vpc --vpc-id vpc-xxxxx --region us-east-1"
echo ""
echo "✅ Recursos duplicados eliminados"
echo "📝 Puedes hacer git push origin main para re-deployar"

